// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import "../constants/Errors.sol";

import {IStrategyVaultHooks, IUpdateLateStatus} from "../interfaces/IAccountableStrategy.sol";
import {PermissionLevel} from "../interfaces/IAccess.sol";

import {
    IAccountableAsyncRedeemVault,
    IControllerOperator,
    IAsyncRedeem,
    IAsyncCancelRedeem,
    IAccountableVault,
    VaultState
} from "../interfaces/IAccountableAsyncVault.sol";

import {IAccountableWithdrawalQueue} from "../interfaces/IAccountableWithdrawalQueue.sol";

import {AccountableVault} from "./AccountableVault.sol";
import {AccountableWithdrawalQueue} from "./queue/AccountableWithdrawalQueue.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title AccountableAsyncRedeemVault
/// @notice An ERC4626-compatible vault with ERC7540 asynchronous redemptions
/// @dev Implements IAccountableAsyncRedeemVault interface for async operations and access control
/// @custom:security-contact security@accountable.capital
contract AccountableAsyncRedeemVault is IAccountableAsyncRedeemVault, AccountableWithdrawalQueue, AccountableVault {
    using Math for uint256;

    uint128 private constant INSTANT_REQUEST_ID = 0;

    /// @notice AccountableAsyncVault constructor
    /// @param asset_ The underlying asset token for the vault
    /// @param strategy_ The loan manager contract address
    /// @param sharesTransferable_ Whether shares are transferable
    /// @param name_ The name of the vault issued share token
    /// @param symbol_ The symbol of the vault issued share token
    constructor(
        IERC20 asset_,
        address strategy_,
        bool sharesTransferable_,
        PermissionLevel permissionLevel_,
        string memory name_,
        string memory symbol_,
        uint256 precision_
    ) AccountableWithdrawalQueue(precision_) AccountableVault(asset_, permissionLevel_) ERC20(name_, symbol_) {
        if (strategy_ == address(0)) revert ZeroAddress();

        strategy = IStrategyVaultHooks(strategy_);
        transferableShares = sharesTransferable_;
        precision = precision_;
    }

    /// @inheritdoc IAccountableVault
    function deposit(uint256 assets, address receiver, address controller)
        public
        onlyAuth(receiver, controller)
        returns (uint256 shares)
    {
        _checkMinAmount(assets);
        _checkController(controller);

        uint256 price = strategy.onDeposit(address(this), assets, receiver, controller);
        shares = _convertToShares(assets, price, Math.Rounding.Floor);

        _mint(receiver, shares);
        _deposit(controller, assets);

        try IUpdateLateStatus(address(strategy)).updateLateStatus() {} catch {}

        emit Deposit(controller, receiver, assets, shares);
    }

    /// @inheritdoc IERC4626
    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        shares = deposit(assets, receiver, msg.sender);
    }

    /// @inheritdoc IAccountableVault
    function mint(uint256 shares, address receiver, address controller)
        public
        onlyAuth(receiver, controller)
        returns (uint256 assets)
    {
        _checkMinAmount(shares);
        _checkController(controller);

        uint256 price = strategy.onMint(address(this), shares, receiver, controller);
        assets = _convertToAssets(shares, price, Math.Rounding.Ceil);

        _mint(receiver, shares);
        _deposit(controller, assets);

        try IUpdateLateStatus(address(strategy)).updateLateStatus() {} catch {}

        emit Deposit(controller, receiver, assets, shares);
    }

    /// @inheritdoc IERC4626
    function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
        assets = mint(shares, receiver, msg.sender);
    }

    /// @inheritdoc IAsyncRedeem
    function requestRedeem(uint256 shares, address controller, address owner)
        public
        onlyAuth(owner, controller)
        returns (uint256 requestId)
    {
        _checkOperator(owner);
        _checkController(controller);
        _checkMinAmount(shares);
        _checkShares(owner, shares);

        VaultState storage state = _vaultStates[controller];

        state.pendingRedeemRequest += shares;

        (bool canFulfill, uint256 price) = strategy.onRequestRedeem(address(this), shares, controller, owner);
        if (canFulfill) {
            requestId = INSTANT_REQUEST_ID;
            _fulfillRedeemRequest(INSTANT_REQUEST_ID, controller, shares, price);
        } else {
            requestId = _push(controller, shares);
        }

        _transfer(owner, address(this), shares);

        try IUpdateLateStatus(address(strategy)).updateLateStatus() {} catch {}

        /// @dev RequestId is non-zero if in queue, 0 otherwise (instant fulfill)
        emit RedeemRequest(controller, owner, requestId, msg.sender, shares);
    }

    /// @inheritdoc IAsyncRedeem
    function pendingRedeemRequest(uint256, address controller) public view returns (uint256 pendingShares) {
        pendingShares = _vaultStates[controller].pendingRedeemRequest;
    }

    /// @inheritdoc IAsyncRedeem
    function claimableRedeemRequest(uint256, address controller) public view returns (uint256 claimableShares) {
        claimableShares = maxRedeem(controller);
    }

    /// @inheritdoc IERC4626
    function redeem(uint256 shares, address receiver, address controller)
        public
        onlyAuth(receiver, controller)
        returns (uint256 assets)
    {
        _checkMinAmount(shares);
        _checkController(controller);
        if (shares > maxRedeem(controller)) revert ExceedsMaxRedeem();

        VaultState storage state = _vaultStates[controller];
        uint256 redeemPrice = state.redeemPrice;
        assets = _convertToAssets(shares, redeemPrice, Math.Rounding.Floor);
        uint256 assetsUp = _convertToAssets(shares, redeemPrice, Math.Rounding.Ceil);

        strategy.onRedeem(address(this), shares, receiver, controller);

        _updateReservedLiquidity(assets);
        _updateRedeemState(state, assets, assetsUp, shares, shares);

        _burn(address(this), shares);
        _withdraw(receiver, assets);

        try IUpdateLateStatus(address(strategy)).updateLateStatus() {} catch {}

        emit Withdraw(msg.sender, receiver, controller, assets, shares);
    }

    /// @inheritdoc IERC4626
    function withdraw(uint256 assets, address receiver, address controller)
        public
        onlyAuth(receiver, controller)
        returns (uint256 shares)
    {
        _checkMinAmount(assets);
        _checkController(controller);
        if (assets > maxWithdraw(controller)) revert ExceedsMaxRedeem();

        VaultState storage state = _vaultStates[controller];
        uint256 withdrawPrice = state.withdrawPrice;
        shares = _convertToShares(assets, withdrawPrice, Math.Rounding.Floor);
        uint256 sharesUp = _convertToShares(assets, withdrawPrice, Math.Rounding.Ceil);

        strategy.onWithdraw(address(this), assets, receiver, controller);

        _updateReservedLiquidity(assets);
        _updateRedeemState(state, assets, assets, shares, sharesUp);

        _burn(address(this), shares);
        _withdraw(receiver, assets);

        try IUpdateLateStatus(address(strategy)).updateLateStatus() {} catch {}

        emit Withdraw(msg.sender, receiver, controller, assets, shares);
    }

    function _updateRedeemState(
        VaultState storage state,
        uint256 assets,
        uint256 assetsUp,
        uint256 shares,
        uint256 sharesUp
    ) private {
        uint256 maxWithdraw_ = state.maxWithdraw;
        uint256 redeemShares_ = state.redeemShares;

        if (assets > maxWithdraw_) revert ExceedsRedeemLimit();
        state.maxWithdraw = maxWithdraw_ > assetsUp ? maxWithdraw_ - assetsUp : 0;

        if (shares > redeemShares_) revert ExceedsRedeemLimit();
        state.redeemShares = redeemShares_ > sharesUp ? redeemShares_ - sharesUp : 0;
        if (state.maxWithdraw == 0) state.redeemShares = 0;
        if (state.redeemShares == 0) state.maxWithdraw = 0;
    }

    /// @inheritdoc IAsyncCancelRedeem
    function cancelRedeemRequest(address controller, address receiver) public onlyAuth(receiver, controller) {
        _checkController(controller);
        VaultState storage state = _vaultStates[controller];
        if (state.pendingRedeemRequest == 0) revert NoPendingRedeemRequest();

        bool canCancel = strategy.onCancelRedeemRequest(address(this), controller);
        if (!canCancel) revert CancelRedeemRequestFailed();

        uint256 requestId = _requestIds[controller];
        uint256 pendingShares = state.pendingRedeemRequest;

        state.pendingRedeemRequest = 0;

        _transfer(address(this), receiver, pendingShares);
        _reduce(controller, pendingShares);

        try IUpdateLateStatus(address(strategy)).updateLateStatus() {} catch {}

        emit CancelRedeemRequest(controller, receiver, requestId, msg.sender);
    }

    // ========================================================================== //
    //                             Queue operations                               //
    // ========================================================================== //

    /// @inheritdoc IAccountableWithdrawalQueue
    function fulfillRedeemRequest(address controller, uint256 shares) public onlyStrategy {
        _fulfillRedeemRequest(_requestIds[controller], controller, shares, sharePrice());
        _reduce(controller, shares);
    }

    /// @inheritdoc IAccountableWithdrawalQueue
    function processUpToShares(uint256 maxShares) public onlyStrategy returns (uint256 assetsUsed) {
        assetsUsed = _processUpToShares(maxShares, _liquidity(), sharePrice());
    }

    /// @inheritdoc IAccountableWithdrawalQueue
    function processUpToRequestId(uint256 maxRequestId)
        public
        onlyStrategy
        returns (uint256 processedShares, uint256 assetsUsed)
    {
        (processedShares, assetsUsed) = _processUpToRequestId(maxRequestId, _liquidity(), sharePrice());
    }

    /// @inheritdoc IAccountableWithdrawalQueue
    function previewRequiredShares(uint256 maxAssets)
        public
        view
        returns (uint256 processedShares, uint256 assetsUsed)
    {
        (processedShares, assetsUsed) = _previewRequiredShares(maxAssets, sharePrice());
    }

    /// @inheritdoc IAccountableWithdrawalQueue
    function previewMaxRequestId(uint256 maxAssets) public view returns (uint256 maxRequestId, uint256 assetsUsed) {
        (maxRequestId, assetsUsed) = _previewMaxRequestId(maxAssets, sharePrice());
    }

    /// @dev Computes free liquidity excluding accrued locked assets and reserved queue liquidity
    function _liquidity() internal view returns (uint256) {
        uint256 excludedAssets = strategy.accruedAssets(address(this)) + reservedLiquidity;
        return totalAssets() > excludedAssets ? totalAssets() - excludedAssets : 0;
    }

    /// @dev Fulfills a redeem request
    function _fulfillRedeemRequest(uint128 requestId, address controller, uint256 shares, uint256 price)
        internal
        override
    {
        VaultState storage state = _vaultStates[controller];
        uint256 pendingRedeemRequest_ = state.pendingRedeemRequest;

        if (pendingRedeemRequest_ == 0) revert NoRedeemRequest();
        if (pendingRedeemRequest_ < shares) revert InsufficientAmount();

        uint256 assets = _convertToAssets(shares, price, Math.Rounding.Floor);
        if (assets > _liquidity()) revert InsufficientLiquidity();

        reservedLiquidity += assets;
        state.maxWithdraw += assets;
        state.redeemShares += shares;
        state.pendingRedeemRequest -= shares;

        state.redeemPrice = state.maxWithdraw.mulDiv(precision, state.redeemShares);
        state.withdrawPrice = state.maxWithdraw.mulDiv(precision, state.redeemShares, Math.Rounding.Ceil);

        /// @dev RequestId is non-zero if in queue, 0 otherwise (instant fulfill)
        emit RedeemClaimable(controller, requestId, assets, shares);
    }

    /// @inheritdoc IERC4626
    function maxDeposit(address controller) public view override returns (uint256 maxAssets) {
        maxAssets = strategy.maxDeposit(address(this), controller);
    }

    /// @inheritdoc IERC4626
    function maxMint(address controller) public view override returns (uint256 maxShares) {
        maxShares = _convertToShares(maxDeposit(controller), sharePrice(), Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    function maxRedeem(address controller) public view override returns (uint256 maxShares) {
        VaultState storage state = _vaultStates[controller];
        maxShares = state.redeemShares;
    }

    /// @inheritdoc IERC4626
    function maxWithdraw(address controller) public view override returns (uint256 maxAssets) {
        VaultState storage state = _vaultStates[controller];
        if (state.redeemShares == 0) return 0;
        maxAssets = state.maxWithdraw;
    }

    /// @inheritdoc IERC4626
    /// @notice Preview deposit works for sync deposit vaults
    function previewDeposit(uint256 assets) public view returns (uint256 shares) {
        shares = _convertToShares(assets, sharePrice(), Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    /// @notice Preview mint works for sync deposit vaults
    function previewMint(uint256 shares) public view returns (uint256 assets) {
        assets = _convertToAssets(shares, sharePrice(), Math.Rounding.Ceil);
    }

    /// @inheritdoc IERC4626
    /// @notice Preview functions are not supported for async vaults
    function previewRedeem(uint256) public pure returns (uint256) {
        revert();
    }

    /// @inheritdoc IERC4626
    /// @notice Preview functions are not supported for async vaults
    function previewWithdraw(uint256) public pure returns (uint256) {
        revert();
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IAccountableAsyncRedeemVault).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IAsyncRedeem).interfaceId || interfaceId == type(IAsyncCancelRedeem).interfaceId
            || interfaceId == type(IAccountableVault).interfaceId || interfaceId == type(IERC4626).interfaceId
            || interfaceId == type(IControllerOperator).interfaceId || interfaceId == type(IERC20).interfaceId
            || interfaceId == type(IAccountableWithdrawalQueue).interfaceId
            || interfaceId == type(IERC20Metadata).interfaceId;
    }
}
