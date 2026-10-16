// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import "../constants/Errors.sol";

import {IStrategyVaultHooks} from "../interfaces/IAccountableStrategy.sol";
import {IAuthorizable, IWhitelistable, PermissionLevel} from "../interfaces/IAccess.sol";
import {IAccountableVault, IControllerOperator, VaultState} from "../interfaces/IAccountableAsyncVault.sol";

import {AccessBase} from "../access/AccessBase.sol";
import {Authorizable} from "../access/Authorizable.sol";
import {Whitelistable} from "../access/Whitelistable.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title AccountableVault
/// @notice Base contract for Accountable async vaults
/// @custom:security-contact security@accountable.capital
abstract contract AccountableVault is IAccountableVault, ERC20, AccessBase {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// @notice Underlying asset
    IERC20 internal immutable _asset;

    /// @notice Decimals of the underlying asset
    uint8 internal immutable _underlyingDecimals;

    /// @notice Total assets in the vault
    uint256 internal _totalAssets;

    /// @notice Mapping of vault states by controller
    mapping(address controller => VaultState state) internal _vaultStates;

    /// @notice Minimum amount in wei to prevent dust attacks
    uint256 public constant MIN_AMOUNT_WEI = 10_000;

    /// @notice The loan manager contract that handles deposit/redeem requests
    IStrategyVaultHooks public immutable strategy;

    /// @notice Precision for share calculations
    uint256 public immutable precision;

    /// @notice Mapping of owner addresses to their approved operators
    mapping(address => mapping(address => bool)) public isOperator;

    /// @notice Whether the vault is transferable
    bool public transferableShares;

    /// @notice Ensures only the loan manager can call certain functions
    modifier onlyStrategy() {
        if (msg.sender != address(strategy)) {
            revert Unauthorized();
        }
        _;
    }

    /// @notice Ensures only authorized accounts can call certain functions
    modifier onlyAuth(address receiverOwner, address controller) {
        if (receiverOwner == controller) {
            if (!_isVerified(controller, msg.data)) revert Unauthorized();
        } else {
            address[] memory accounts = new address[](2);
            accounts[0] = receiverOwner;
            accounts[1] = controller;

            if (!_areVerified(accounts, msg.data)) revert Unauthorized();
        }
        _;
    }

    constructor(IERC20 asset_, PermissionLevel permissionLevel_) AccessBase(permissionLevel_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = asset_;
    }

    /// @dev Try to get the decimals of the underlying asset
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool ok, uint8 assetDecimals) {
        (bool success, bytes memory encodedDecimals) =
            address(asset_).staticcall(abi.encodeCall(IERC20Metadata.decimals, ()));

        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /// @inheritdoc IControllerOperator
    function setOperator(address operator, bool approved) public returns (bool) {
        if (msg.sender == operator) {
            revert InvalidOperator();
        }
        isOperator[msg.sender][operator] = approved;
        emit OperatorSet(msg.sender, operator, approved);
        return true;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _underlyingDecimals;
    }

    /// @inheritdoc IERC4626
    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    /// @inheritdoc IERC4626
    function totalAssets() public view returns (uint256) {
        return _totalAssets;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) public virtual override(ERC20, IERC20) returns (bool) {
        _checkTransfer(amount, msg.sender, to);
        strategy.onTransfer(address(this), msg.sender, to, amount);
        return super.transfer(to, amount);
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        override(ERC20, IERC20)
        returns (bool)
    {
        _checkTransfer(amount, from, to);
        strategy.onTransfer(address(this), from, to, amount);
        return super.transferFrom(from, to, amount);
    }

    /// @dev Checks transfer restrictions before executing the underlying transfer
    function _checkTransfer(uint256, address, address to) private {
        if (!transferableShares) revert SharesNotTransferable();
        if (!_isVerified(to, msg.data)) revert Unauthorized();
    }

    /// @inheritdoc IERC4626
    function convertToShares(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, sharePrice(), Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    function convertToAssets(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, sharePrice(), Math.Rounding.Floor);
    }

    /// @inheritdoc IAccountableVault
    function assetShareRatio() public view returns (uint256) {
        uint256 shares = totalSupply();
        uint256 reserved = IStrategyVaultHooks(strategy).accruedAssets(address(this));
        return shares == 0 ? precision : (totalAssets() - reserved).mulDiv(precision, shares, Math.Rounding.Floor);
    }

    /// @dev Computes the assets based on shares and price
    function _convertToAssets(uint256 shares, uint256 price, Math.Rounding rounding)
        internal
        view
        virtual
        returns (uint256 assets)
    {
        assets = shares.mulDiv(price, precision, rounding);
    }

    /// @dev Computes the shares based on assets and price
    function _convertToShares(uint256 assets, uint256 price, Math.Rounding rounding)
        internal
        view
        virtual
        returns (uint256 shares)
    {
        shares = assets.mulDiv(precision, price, rounding);
    }

    /// @inheritdoc IAccountableVault
    function sharePrice() public view returns (uint256) {
        return strategy.sharePrice(address(this));
    }

    /// @inheritdoc IAccountableVault
    function share() public view returns (address) {
        return address(this);
    }

    /// @inheritdoc IAccountableVault
    function getState(address controller) public view returns (VaultState memory) {
        return _vaultStates[controller];
    }

    /// @inheritdoc IAccountableVault
    function lockAssets(uint256 assets, address sender) public onlyStrategy {
        _deposit(sender, assets);
        emit LockAssets(sender, assets);
    }

    /// @inheritdoc IAccountableVault
    function releaseAssets(uint256 assets, address receiver) public onlyStrategy {
        _withdraw(receiver, assets);
        emit ReleaseAssets(receiver, assets);
    }

    /// @inheritdoc IAccountableVault
    function mintShares(uint256 shares, address receiver) public onlyStrategy {
        _mint(receiver, shares);
    }

    /// @inheritdoc IAccountableVault
    function burnShares(uint256 shares, address sender) public onlyStrategy {
        _burn(sender, shares);
    }

    /// @inheritdoc IAccountableVault
    function forceTransferShares(address from, address to, uint256 shares) public onlyStrategy {
        strategy.onTransfer(address(this), from, to, shares);
        _transfer(from, to, shares);
    }

    /// @inheritdoc IAccountableVault
    function setSharesTransferable(bool sharesTransferable_) public onlyStrategy {
        bool oldStatus = transferableShares;
        transferableShares = sharesTransferable_;
        emit SharesTransferableSet(oldStatus, sharesTransferable_);
    }

    /// @inheritdoc IAuthorizable
    function setSigner(address signer_) public override(IAuthorizable, Authorizable) onlyStrategy {
        if (permissionLevel != PermissionLevel.KYC) revert PermissionLevelMismatch();
        super.setSigner(signer_);
    }

    /// @inheritdoc IWhitelistable
    function setAllowed(address[] calldata accounts, bool[] calldata statuses)
        public
        override(IWhitelistable, Whitelistable)
        onlyStrategy
    {
        if (permissionLevel != PermissionLevel.Whitelist) revert PermissionLevelMismatch();
        super.setAllowed(accounts, statuses);
    }

    /// @dev Deposit assets into the vault and increment total assets
    function _deposit(address caller, uint256 assets) internal virtual {
        _totalAssets += assets;
        _asset.safeTransferFrom(caller, address(this), assets);
    }

    /// @dev Withdraw assets from the vault and decrement total assets
    function _withdraw(address receiver, uint256 assets) internal virtual {
        _totalAssets -= assets;
        _asset.safeTransfer(receiver, assets);
    }

    /// @dev Checks if the caller is an approved operator for the owner
    /// @param owner The owner address to check against
    function _checkOperator(address owner) internal view {
        if (owner != msg.sender && !isOperator[owner][msg.sender]) {
            revert InvalidOperator();
        }
    }

    /// @dev Checks if the caller is an approved operator for the controller
    /// @param controller The controller address to check against
    function _checkController(address controller) internal view {
        if (controller != msg.sender && !isOperator[controller][msg.sender]) {
            revert InvalidController();
        }
    }

    /// @dev Checks if the owner has sufficient shares
    /// @param owner The owner address to check
    /// @param shares The amount of shares to check for
    function _checkShares(address owner, uint256 shares) internal view {
        if (balanceOf(owner) < shares || shares == 0) {
            revert InsufficientShares();
        }
    }

    /// @dev Checks if the amount is greater than the minimum amount
    function _checkMinAmount(uint256 amount) internal pure {
        if (amount < MIN_AMOUNT_WEI) revert InsufficientAmount();
    }
}
