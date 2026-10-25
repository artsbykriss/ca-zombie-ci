// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {LockMint20} from "./LockMint20.sol";
import {AddressLib} from "../libraries/AddressLib.sol";
import {Constants} from "../libraries/Constants.sol";
import {Errors} from "../libraries/Errors.sol";
import {Roles} from "../libraries/Roles.sol";
import {MathLib} from "../libraries/MathLib.sol";
import {IPriceOracle} from "../oracles/interfaces/IPriceOracle.sol";
import {IUSDW, IUsdwEmitted} from "./interfaces/IUSDW.sol";

/// @notice Pending redemption request; deleted on {cancel} or {process}.
/// @dev `user` is the requester whose USDW is locked/burned. `receiver` is the end account that
///      receives the payout stable on {process}, supporting redemptions queued on behalf of another.
struct UsdwRedemptionRequest {
    address user;
    address receiver;
    address payoutToken;
    uint256 usdwAmount;
}

/**
 * @title USDW
 * @notice Permissionless stablecoin: open mint against approved stables, holder redemption
 *         queue, operator settlement.
 * @dev Implements {IUSDW}. Anyone holding an approved input stable may {deposit} — mint is not
 *      gated on the destination. Governance-approved input stables are tracked in
 *      {_inputStableApproved}; mutations are `onlyAdministrator` (timelock via Administrator).
 */
contract USDW is LockMint20, IUSDW, IUsdwEmitted {
    using SafeERC20 for IERC20;
    using AddressLib for address;

    /// @dev USDW storage begins here; `__gap` below reserves upgrade headroom.
    address public treasury;
    address public priceOracle;
    address public depositRecipient;
    address public redemptionSource;
    address public pendingDepositRecipient;

    mapping(address token => bool approved) private _inputStableApproved;

    uint256 public redemptionRequestNonce;
    mapping(uint256 requestId => UsdwRedemptionRequest) private _redemptionRequests;

    uint256[62] private __gap;

    constructor() {
        _disableInitializers();
    }

    /// @notice Proxy initializer; call {setTreasury} post-deploy before any fee-bearing {process}.
    function initialize(
        address administrator_,
        address priceOracle_,
        string memory name_,
        string memory symbol_,
        address depositRecipient_,
        address redemptionSource_,
        address[] calldata initialStables
    ) external initializer {
        administrator_.requireNonZeroContract();
        priceOracle_.requireNonZeroContract();
        depositRecipient_.requireNonZero();
        redemptionSource_.requireNonZero();

        __ERC20_init(name_, symbol_);
        __AccessControl_init(administrator_);
        _metaInit(name_, symbol_);

        priceOracle = priceOracle_;
        depositRecipient = depositRecipient_;
        redemptionSource = redemptionSource_;

        for (uint256 i = 0; i < initialStables.length; i++) {
            _addInputStable(initialStables[i]);
        }
    }

    /// @notice USDW escrowed during a queued payout (same ledger as `LockMint20.lockedLedger`).
    function lockedUsdw(address account) external view returns (uint256) {
        return lockedLedger[account];
    }

    /// @inheritdoc IUSDW
    function setTreasury(address treasury_) external override onlyAdministrator {
        treasury_.requireNonZero();
        treasury = treasury_;
        emit UsdwTreasurySet(treasury_);
    }

    /// @inheritdoc IUSDW
    function setPriceOracle(address priceOracle_) external override onlyAdministrator {
        priceOracle_.requireNonZeroContract();
        priceOracle = priceOracle_;
        emit UsdwPriceOracleSet(priceOracle_);
    }

    /// @inheritdoc IUSDW
    function setDepositRecipient(address depositRecipient_) external override onlyAdministrator {
        depositRecipient_.requireNonZero();
        pendingDepositRecipient = depositRecipient_;
        emit UsdwPendingDepositRecipientSet(depositRecipient_);
    }

    /// @inheritdoc IUSDW
    function acceptDepositRecipient() external override {
        address pending = pendingDepositRecipient;
        if (pending == address(0)) revert Errors.ZeroAddress();
        if (msg.sender != pending) revert Errors.UnauthorizedCaller();
        depositRecipient = pending;
        pendingDepositRecipient = address(0);
        emit UsdwDepositRecipientSet(pending);
    }

    /// @inheritdoc IUSDW
    function setRedemptionSource(address redemptionSource_) external override onlyAdministrator {
        redemptionSource_.requireNonZero();
        redemptionSource = redemptionSource_;
        emit UsdwRedemptionSourceSet(redemptionSource_);
    }

    /// @inheritdoc IUSDW
    function addInputStable(address token) external override onlyAdministrator {
        _addInputStable(token);
    }

    /// @inheritdoc IUSDW
    function removeInputStable(address token) external override onlyAdministrator {
        if (!isInputStable(token)) revert Errors.InvalidAsset(token);
        delete _inputStableApproved[token];
        emit InputStableRemoved(token);
    }

    /// @inheritdoc IUSDW
    function isInputStable(address token) public view override returns (bool) {
        return _inputStableApproved[token];
    }

    /// @inheritdoc LockMint20
    function _requireTokenOperator() internal view override {
        if (!_hasRole(Roles.ISSUER_ROLE, msg.sender)) {
            revert Errors.Unauthorized(msg.sender, Roles.ISSUER_ROLE);
        }
    }

    /// @inheritdoc IUSDW
    function deposit(address backingToken, uint256 backingAmount)
        external
        override
        nonReentrant
        whenNotPaused
        notBlacklisted(msg.sender)
        returns (uint256 usdwOut)
    {
        if (backingAmount == 0) revert Errors.ZeroAmount();
        if (!isInputStable(backingToken)) revert Errors.InvalidAsset(backingToken);

        usdwOut = IPriceOracle(priceOracle).quoteUsdwMint(backingToken, backingAmount);
        if (usdwOut == 0) revert Errors.ZeroAmount();

        IERC20(backingToken).safeTransferFrom(msg.sender, depositRecipient, backingAmount);
        _mint(msg.sender, usdwOut);
        emit UsdwMinted(msg.sender, backingToken, backingAmount, usdwOut);
    }

    /// @inheritdoc IUSDW
    function redemption(address payoutToken, uint256 usdwAmount, address receiver)
        external
        override
        nonReentrant
        whenNotPaused
        notBlacklisted(msg.sender)
        returns (uint256 requestId)
    {
        if (usdwAmount == 0) revert Errors.ZeroAmount();
        if (!isInputStable(payoutToken)) revert Errors.InvalidAsset(payoutToken);
        receiver.requireNonZero();
        _notBlacklisted(receiver);

        uint256 unlocked = balanceOf(msg.sender);
        if (unlocked < usdwAmount) revert Errors.InsufficientShares(unlocked, usdwAmount);

        _lckAdd(msg.sender, usdwAmount);

        redemptionRequestNonce = MathLib.safeAdd(redemptionRequestNonce, 1);
        requestId = redemptionRequestNonce;
        _redemptionRequests[requestId] = UsdwRedemptionRequest({
            user: msg.sender,
            receiver: receiver,
            payoutToken: payoutToken,
            usdwAmount: usdwAmount
        });

        emit RedemptionRequested(requestId, msg.sender, payoutToken, usdwAmount, receiver);
    }

    /// @inheritdoc IUSDW
    function cancel(uint256 requestId) external override nonReentrant notBlacklisted(msg.sender) whenNotPaused {
        UsdwRedemptionRequest storage r = _redemptionRequests[requestId];
        if (msg.sender != r.user) revert Errors.UnauthorizedCaller();

        uint256 locked = _lockOf(r.user);
        if (locked < r.usdwAmount) revert Errors.InsufficientShares(locked, r.usdwAmount);

        address user = r.user;
        address payoutToken = r.payoutToken;
        uint256 u = r.usdwAmount;

        _lckSub(r.user, r.usdwAmount);
        delete _redemptionRequests[requestId];

        emit RedemptionCancelled(requestId, user, payoutToken, u);
    }

    /// @inheritdoc IUSDW
    function process(uint256 requestId, uint256 executionCost)
        external
        override
        onlyOperator
        nonReentrant
        whenNotPaused
    {
        UsdwRedemptionRequest storage r = _redemptionRequests[requestId];
        if (r.user == address(0)) revert Errors.InvalidData();

        uint256 locked = _lockOf(r.user);
        if (locked < r.usdwAmount) revert Errors.InsufficientShares(locked, r.usdwAmount);

        uint256 u = r.usdwAmount;
        uint256 netUsdw = MathLib.safeSub(u, executionCost);
        uint256 payoutAmount = IPriceOracle(priceOracle).quoteUsdwBurn(r.payoutToken, netUsdw);
        if (payoutAmount == 0) revert Errors.ZeroAmount();

        address user = r.user;
        address receiver = r.receiver;
        address payoutToken = r.payoutToken;

        // Checking the blacklist
        _notBlacklisted(user);
        _notBlacklisted(receiver);

        _lckSub(r.user, r.usdwAmount);
        delete _redemptionRequests[requestId];

        _burn(user, u);
        if (executionCost > 0) {
            address treasury_ = treasury;
            treasury_.requireNonZero();
            _mint(treasury_, executionCost);
        }

        IERC20(payoutToken).safeTransferFrom(redemptionSource, receiver, payoutAmount);
        emit RedemptionProcessed(requestId, user, payoutToken, payoutAmount, receiver, executionCost);
    }

    /// @notice View queued redemption metadata by `requestId`.
    function getRedemptionRequest(uint256 requestId) external view returns (UsdwRedemptionRequest memory) {
        return _redemptionRequests[requestId];
    }

    function _addInputStable(address token) private {
        token.requireNonZeroContract();
        if (_inputStableApproved[token]) revert Errors.InvalidData();
        _inputStableApproved[token] = true;
        emit InputStableAdded(token);
    }

    /// @notice ERC-20 decimals; canonical value is {Constants.USDW_TOKEN_DECIMALS}.
    function decimals() public pure virtual override returns (uint8) {
        return Constants.USDW_TOKEN_DECIMALS;
    }
}
