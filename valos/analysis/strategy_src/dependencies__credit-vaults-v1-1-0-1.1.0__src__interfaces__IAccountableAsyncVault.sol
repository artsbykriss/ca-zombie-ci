// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @notice Struct tracking vault state for a controller
struct VaultState {
    /// @notice Maximum shares that can be minted
    uint256 maxMint;
    /// @notice Maximum assets that can be withdrawn
    uint256 maxWithdraw;
    /// @notice Total accumulated assets unclaimed
    uint256 depositAssets;
    /// @notice Total accumulated shares unclaimed
    uint256 redeemShares;
    /// @notice Share price floored for deposit
    uint256 depositPrice;
    /// @notice Share price ceiled for mint
    uint256 mintPrice;
    /// @notice Share price floored for redeem
    uint256 redeemPrice;
    /// @notice Share price ceiled for withdraw
    uint256 withdrawPrice;
    /// @notice Pending deposit amount
    uint256 pendingDepositRequest;
    /// @notice Pending redeem amount
    uint256 pendingRedeemRequest;
}

interface IControllerOperator {
    /// @notice Emitted when an operator's approval status is updated
    /// @param controller The controller address that approved/revoked
    /// @param operator The operator address being approved/revoked
    /// @param approved The new approval status
    event OperatorSet(address indexed controller, address indexed operator, bool approved);

    /// @notice Sets or revokes operator approval for a caller
    /// @param operator The address to set approval for
    /// @param approved True to approve, false to revoke
    /// @return bool True if successful
    function setOperator(address operator, bool approved) external returns (bool);

    /// @notice Checks if an address is an approved operator for a controller
    /// @param controller The controller address to check
    /// @param operator The operator address to check
    /// @return status True if operator is approved for controller
    function isOperator(address controller, address operator) external view returns (bool status);
}

interface IAsyncDeposit {
    /// @notice Emitted when a deposit request is created
    /// @param controller The controller address for the deposit
    /// @param owner The owner address that will receive shares
    /// @param requestId The unique ID for tracking the request
    /// @param sender The address that initiated the request
    /// @param assets The amount of assets being deposited
    event DepositRequest(
        address indexed controller, address indexed owner, uint256 indexed requestId, address sender, uint256 assets
    );

    /// @notice Requests a deposit of assets
    /// @param assets Amount of assets to deposit
    /// @param controller Address controlling the deposit
    /// @param owner Address that will own the shares
    /// @return uint256 Request ID for tracking the deposit
    function requestDeposit(uint256 assets, address controller, address owner) external returns (uint256);

    /// @notice Gets pending deposit amount for a request
    /// @param requestId ID of the deposit request
    /// @param controller Controller address for the request
    /// @return uint256 Amount of assets pending deposit
    function pendingDepositRequest(uint256 requestId, address controller) external view returns (uint256);

    /// @notice Gets claimable deposit amount for a request
    /// @param requestId ID of the deposit request
    /// @param controller Controller address for the request
    /// @return uint256 Amount of assets claimable
    function claimableDepositRequest(uint256 requestId, address controller) external view returns (uint256);
}

interface IAsyncRedeem {
    /// @notice Emitted when a redeem request is created
    /// @param controller The controller address for the redemption
    /// @param owner The owner of the shares being redeemed
    /// @param requestId The unique ID for tracking the request
    /// @param sender The address that initiated the request
    /// @param assets The amount of assets being redeemed
    event RedeemRequest(
        address indexed controller, address indexed owner, uint256 indexed requestId, address sender, uint256 assets
    );

    /// @notice Requests redemption of shares
    /// @param shares Amount of shares to redeem
    /// @param controller Controller address for redemption
    /// @param owner Owner of the shares
    /// @return uint256 Request ID for tracking redemption
    function requestRedeem(uint256 shares, address controller, address owner) external returns (uint256);

    /// @notice Gets pending redeem amount for a request
    /// @param requestId ID of the redeem request
    /// @param controller Controller address for the request
    /// @return uint256 Amount of shares pending redemption
    function pendingRedeemRequest(uint256 requestId, address controller) external view returns (uint256);

    /// @notice Gets claimable redeem amount for a request
    /// @param requestId ID of the redeem request
    /// @param controller Controller address for the request
    /// @return uint256 Amount of shares claimable
    function claimableRedeemRequest(uint256 requestId, address controller) external view returns (uint256);
}

interface IAsyncCancelDeposit {
    /// @notice Emitted when a deposit request is cancelled
    /// @param controller The controller address for the deposit
    /// @param receiver The address that received the cancelled deposit
    /// @param requestId The ID of the cancelled request
    /// @param sender The address that initiated the cancellation
    event CancelDepositRequest(address indexed controller, address indexed receiver, uint256 requestId, address sender);

    /// @notice Cancels a pending deposit request
    /// @param controller Controller address for the request
    /// @param receiver The address that received the cancelled deposit
    function cancelDepositRequest(address controller, address receiver) external;
}

interface IAsyncCancelRedeem {
    /// @notice Emitted when a redeem request is cancelled
    /// @param controller The controller address for the redemption
    /// @param receiver The address that received the cancelled redeem
    /// @param requestId The ID of the cancelled request
    /// @param sender The address that initiated the cancellation
    event CancelRedeemRequest(address indexed controller, address indexed receiver, uint256 requestId, address sender);

    /// @notice Cancels a pending redeem request
    /// @param controller Controller address for the request
    /// @param receiver The address that received the cancelled redeem
    function cancelRedeemRequest(address controller, address receiver) external;
}

interface IAccountableVault is IERC20, IERC20Metadata, IERC4626, IControllerOperator {
    /// @notice Emitted when assets are locked in the vault
    /// @param caller The address that locked the assets
    /// @param assets The amount of assets locked
    event LockAssets(address indexed caller, uint256 assets);

    /// @notice Emitted when locked assets are released
    /// @param caller The address that released the assets
    /// @param assets The amount of assets released
    event ReleaseAssets(address indexed caller, uint256 assets);

    /// @notice Emitted when shares transferability is changed
    /// @param oldStatus The old transferability status
    /// @param newStatus The new transferability status
    event SharesTransferableSet(bool oldStatus, bool newStatus);

    /// @notice Deposits assets and mints shares to receiver
    /// @dev Added for ERC7540 compatibility
    /// @param assets Amount of assets to deposit
    /// @param receiver Address receiving the shares
    /// @param controller Controller address for the deposit
    /// @return uint256 Amount of shares minted
    function deposit(uint256 assets, address receiver, address controller) external returns (uint256);

    /// @notice Mints exact amount of shares by depositing assets
    /// @dev Added for ERC7540 compatibility
    /// @param shares Amount of shares to mint
    /// @param receiver Address receiving the shares
    /// @param controller Controller address for the mint
    /// @return uint256 Amount of assets deposited
    function mint(uint256 shares, address receiver, address controller) external returns (uint256);

    /// @notice Locks assets in the vault
    /// @param assets Amount of assets to lock
    function lockAssets(uint256 assets, address sender) external;

    /// @notice Releases previously locked assets
    /// @param assets Amount of assets to release
    function releaseAssets(uint256 assets, address receiver) external;

    /// @notice Issues shares to a receiver
    /// @param shares Amount of shares to issue
    /// @param receiver Address to receive the shares
    function mintShares(uint256 shares, address receiver) external;

    /// @notice Repossesses shares from a sender
    /// @param shares Amount of shares to repossess
    /// @param sender Address to repossess the shares from
    function burnShares(uint256 shares, address sender) external;

    /// @notice Forces a transfer of shares from one address to another
    /// @param from The address to transfer shares from
    /// @param to The address to transfer shares to
    /// @param shares The amount of shares to transfer
    function forceTransferShares(address from, address to, uint256 shares) external;

    /// @notice Sets the transferability of shares
    /// @param transferable True to set shares transferable, false to set them non-transferable
    function setSharesTransferable(bool transferable) external;

    /// @notice Checks if shares can be transferred
    /// @return bool True if shares are transferable
    function transferableShares() external view returns (bool);

    /// @notice Current asset share ratio
    /// @return uint256 Asset share ratio
    function assetShareRatio() external view returns (uint256);

    /// @notice Gets the current share price
    /// @return uint256 Price per share in assets
    function sharePrice() external view returns (uint256);

    /// @notice The share token address
    /// @return address Share token address
    function share() external view returns (address);

    /// @notice Gets the state of the vault
    /// @param controller The controller address for the vault
    /// @return state The state of the vault given the controller
    function getState(address controller) external view returns (VaultState memory state);
}

interface IAccountableAsyncRedeemVault is IAccountableVault, IAsyncRedeem, IAsyncCancelRedeem, IERC165 {
    /// @notice Emitted when a redeem becomes claimable
    /// @param controller The controller address for the redemption
    /// @param requestId The ID of the redeem request
    /// @param assets The amount of assets to be received
    /// @param shares The amount of shares redeemed
    event RedeemClaimable(address indexed controller, uint256 indexed requestId, uint256 assets, uint256 shares);
}

interface IAccountableAsyncVault is
    IAccountableVault,
    IAsyncDeposit,
    IAsyncRedeem,
    IAsyncCancelDeposit,
    IAsyncCancelRedeem,
    IERC165
{
    /// @notice Emitted when a deposit becomes claimable
    /// @param controller The controller address for the deposit
    /// @param requestId The ID of the deposit request
    /// @param assets The amount of assets deposited
    /// @param shares The amount of shares to be minted
    event DepositClaimable(address indexed controller, uint256 indexed requestId, uint256 assets, uint256 shares);

    /// @notice Emitted when a redeem becomes claimable
    /// @param controller The controller address for the redemption
    /// @param requestId The ID of the redeem request
    /// @param assets The amount of assets to be received
    /// @param shares The amount of shares redeemed
    event RedeemClaimable(address indexed controller, uint256 indexed requestId, uint256 assets, uint256 shares);
}
