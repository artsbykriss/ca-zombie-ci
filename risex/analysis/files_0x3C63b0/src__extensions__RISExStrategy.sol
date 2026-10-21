// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.29;

import {BaseStrategy, ERC20} from "@tokenized-strategy/BaseStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {LibBitmap} from "solady/src/utils/LibBitmap.sol";

import {EpochWithdrawalProtection} from "src/extensions/EpochWithdrawalProtection.sol";

import {IRISExAdapter} from "risex-adapter/interfaces/IRISExAdapter.sol";
import {IRISExStrategy} from "src/interfaces/extensions/IRISExStrategy.sol";

/**
 * @title RISExStrategy
 * @author RiseX Team
 * @notice Abstract base for RISEx Yearn V3 strategies
 * @dev Consolidates shared logic: collateral deployment/withdrawal, equity tracking,
 *      EIP-1271 signature validation, depositor whitelist, and epoch protection.
 *
 *      Child contracts must implement:
 *      - _freeFunds(uint256 amount)
 *      - availableWithdrawLimit(address owner)
 *      - availableDepositLimit(address owner)
 */
abstract contract RISExStrategy is
    BaseStrategy,
    EpochWithdrawalProtection,
    EIP712,
    IRISExStrategy,
    IERC1271
{
    using SafeERC20 for ERC20;
    using SafeCast for int256;
    using SafeCast for uint256;
    using LibBitmap for LibBitmap.Bitmap;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Basis points denominator (100%)
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// @notice Decimal adjustment: RISEx uses 18 decimals, USDC uses 6
    uint256 public constant RISEX_DECIMALS_ADJUSTMENT = 1e12;

    /// @notice EIP-1271 magic value for valid signature
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice RISEx Adapter contract (handles all RISEx interactions)
    IRISExAdapter public immutable i_adapter;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Bitmap of addresses allowed to deposit
    LibBitmap.Bitmap private s_whitelistedDepositors;

    /// @dev Address authorized to sign on behalf of this strategy (session key)
    address private s_signer;

    /// @dev Per-address nonces for EIP-712 replay protection
    mapping(address => uint256) private s_nonces;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param asset_ The underlying asset (USDC)
    /// @param name_ Strategy name for the tokenized vault
    /// @param adapter_ RISEx Adapter address
    constructor(
        address asset_,
        string memory name_,
        address adapter_
    ) BaseStrategy(asset_, name_) EIP712(name_, "1") {
        require(adapter_ != address(0), ZeroAddress());

        i_adapter = IRISExAdapter(adapter_);
        _initEpochProtection(0);
    }

    /*//////////////////////////////////////////////////////////////
                    REQUIRED STRATEGY OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev Deploy funds to RISEx as collateral via adapter.
    ///      Resets epoch idle baseline because TokenizedStrategy.deployFunds() sweeps
    ///      the full loose balance (including pre-existing idle), which would otherwise
    ///      be misclassified as user outflow by the epoch withdrawal tracker.
    function _deployFunds(uint256 amount) internal override {
        ERC20(asset).forceApprove(address(i_adapter), amount);
        i_adapter.deployCollateral(address(asset), amount);
        _syncEpochIdleAfterDeploy(
            uint128(ERC20(asset).balanceOf(address(this)))
        );
        emit DepositedToRISEx(amount);
    }

    /// @dev Harvest and report total assets (idle + RISEx equity)
    function _harvestAndReport()
        internal
        override
        returns (uint256 totalAssets_)
    {
        uint256 idle = ERC20(asset).balanceOf(address(this));
        int256 equity = getAccountEquity();

        if (equity >= 0) {
            totalAssets_ = idle + uint256(equity);
        } else {
            uint256 loss = uint256(-equity);
            totalAssets_ = idle > loss ? idle - loss : 0;
        }

        _resetEpoch(totalAssets_.toUint128(), idle.toUint128());
    }

    /// @dev Emergency withdraw from RISEx via adapter
    function _emergencyWithdraw(uint256 amount) internal override {
        uint256 available = getWithdrawableAmount();
        uint256 toWithdraw = amount < available ? amount : available;

        if (toWithdraw > 0) {
            i_adapter.emergencyWithdraw(
                address(asset),
                toWithdraw,
                address(this)
            );
            emit WithdrawnFromRISEx(toWithdraw);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExStrategy
    function getAccountEquity() public view returns (int256) {
        return i_adapter.getAccountEquity() / int256(RISEX_DECIMALS_ADJUSTMENT);
    }

    /// @inheritdoc IRISExStrategy
    function getWithdrawableAmount() public view returns (uint256) {
        return i_adapter.getWithdrawableUSD() / RISEX_DECIMALS_ADJUSTMENT;
    }

    /// @inheritdoc IRISExStrategy
    function getCollateralBalance() public view returns (int256) {
        return
            i_adapter.getCollateralBalance(address(asset)) /
            int256(RISEX_DECIMALS_ADJUSTMENT);
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Live total assets = idle + equity (floored at 0).
    ///      Returns all components so callers can reuse them without redundant reads.
    function _getLiveTotalAssets()
        internal
        view
        returns (uint256 liveAssets, uint256 idle, int256 equity)
    {
        idle = ERC20(asset).balanceOf(address(this));
        equity = getAccountEquity();

        if (equity >= 0) {
            liveAssets = idle + uint256(equity);
        } else {
            uint256 loss = uint256(-equity);
            liveAssets = idle > loss ? idle - loss : 0;
        }
    }

    /// @dev Revert if live assets are below recorded (stale-loss window).
    ///      Returns idle and equity so callers can reuse them without redundant reads.
    function _requireNoStaleLoss()
        internal
        view
        returns (uint256 idle, int256 equity)
    {
        uint256 liveAssets;
        (liveAssets, idle, equity) = _getLiveTotalAssets();
        require(liveAssets >= TokenizedStrategy.totalAssets(), StaleLoss());
    }

    /// @dev Verify an EIP-712 signature against the signer.
    ///      Checks deadline, verifies nonce, and validates signature.
    function _verifySigner(
        bytes32 structHash,
        uint256 deadline,
        uint256 nonce,
        bytes calldata signature
    ) internal {
        require(block.timestamp <= deadline, ExpiredSignature());

        address signer = s_signer;
        require(signer != address(0), SignerNotSet());
        uint256 current = s_nonces[signer]++;
        require(nonce == current, InvalidNonce());

        bytes32 digest = _hashTypedDataV4(structHash);
        require(
            SignatureChecker.isValidSignatureNow(signer, digest, signature),
            InvalidSignature()
        );
    }

    /*//////////////////////////////////////////////////////////////
                        MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRISExStrategy
    function setMaxEpochOutflowBps(uint16 newBps) external onlyManagement {
        _setMaxEpochOutflowBps(newBps);
    }

    /// @inheritdoc IRISExStrategy
    function setWhitelistedDepositor(
        address depositor,
        bool allowed
    ) external onlyManagement {
        s_whitelistedDepositors.setTo(uint256(uint160(depositor)), allowed);
        emit DepositorWhitelistUpdated(depositor, allowed);
    }

    /// @inheritdoc IRISExStrategy
    function setSigner(address newSigner) external onlyManagement {
        address oldSigner = s_signer;
        s_signer = newSigner;
        emit SignerUpdated(oldSigner, newSigner);
    }

    /// @inheritdoc IRISExStrategy
    function whitelistedDepositor(
        address depositor
    ) public view returns (bool) {
        return s_whitelistedDepositors.get(uint256(uint160(depositor)));
    }

    /// @inheritdoc IRISExStrategy
    function getSigner() public view returns (address) {
        return s_signer;
    }

    /// @inheritdoc IRISExStrategy
    function getNonce() public view returns (uint256) {
        return s_nonces[s_signer];
    }

    /*//////////////////////////////////////////////////////////////
                       EIP-1271 IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC1271
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view override returns (bytes4 magicValue) {
        address signer = s_signer;
        if (signer == address(0)) return bytes4(0);

        if (SignatureChecker.isValidSignatureNow(signer, hash, signature)) {
            return EIP1271_MAGIC_VALUE;
        }
        return bytes4(0);
    }
}
