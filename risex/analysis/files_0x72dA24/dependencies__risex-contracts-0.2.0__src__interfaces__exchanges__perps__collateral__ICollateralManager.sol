// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { IPerpsManager } from "src/interfaces/exchanges/perps/engine/IPerpsManager.sol";
import { IFundingRate } from "src/interfaces/exchanges/perps/funding-rate/IFundingRate.sol";
import { IFeeWithdrawal } from "src/interfaces/fee/IFeeWithdrawal.sol";
import { IRISExOracle } from "src/interfaces/oracles/IRISExOracle.sol";
import { IOrdersManager } from "src/interfaces/order-book/IOrdersManager.sol";
import { IPartialPauseManaged } from "src/interfaces/securities/IPartialPauseManaged.sol";
import { LibCumulativeWindow } from "src/libraries/misc/LibCumulativeWindow.sol";
import { LibRateLimiter } from "src/libraries/misc/LibRateLimiter.sol";
import { Currency } from "src/libraries/types/Currency.sol";

/// @title ICollateralManager is the interface for the Collateral Manager
/// @notice Manages collateral deposits and withdrawals with rate limiting and emergency guard
interface ICollateralManager is IPartialPauseManaged, IFeeWithdrawal {
    /// @notice Pending withdrawal state for a user+token pair
    /// @dev Packed into single slot: uint128 (16B) + uint64 (8B) = 24B < 32B
    struct PendingWithdrawal {
        uint128 amount; // Pending amount in TOKEN UNITS (not WAD)
        uint64 requestedAt; // Timestamp of first queue (for audit trail)
    }

    /// @notice Emitted when a withdrawal is queued due to emergency auto-trigger
    /// @param account The account whose withdrawal was queued
    /// @param token The token being withdrawn
    /// @param amount The amount queued (in token units, not WAD)
    /// @param totalPending The total pending amount after this queue (accumulative)
    event PendingWithdrawalRequested(
        address indexed account, address indexed token, uint256 amount, uint256 totalPending
    );

    /// @notice Emitted when a pending withdrawal is successfully released by admin
    /// @param account The account receiving the tokens
    /// @param token The token being released
    /// @param amount The amount released (in token units)
    event PendingWithdrawalReleased(address indexed account, address indexed token, uint256 amount);

    /// @notice Emitted when a user deposits
    /// @param payer The address that pays for the deposit
    /// @param receiver The account that receives the deposited token
    /// @param token The address of the deposited token
    /// @param amount The amount of token deposited
    event DepositedCollateral(address indexed payer, address indexed receiver, address indexed token, uint256 amount);

    /// @notice Emitted when a user withdraws their collateral
    /// @param sender The account from which collateral is withdrawn, and which initiated the withdrawal
    /// @param to The recipient address for the withdrawn tokens
    /// @param token The address of the withdrawn token
    /// @param amount The amount of token withdrawn
    event WithdrawnCollateral(address indexed sender, address indexed to, address indexed token, uint256 amount);

    /// @notice Emitted when a collateral token is supported or unsupported
    /// @param sender The address that set the collateral token support
    /// @param token The address of the collateral token
    /// @param isSupported Whether the token is supported
    event SupportedCollateralToken(address indexed sender, address indexed token, bool isSupported);

    /// @notice Emitted when transferring trading fees to a recipient
    /// @param sender The address that initiated the transfer
    /// @param token The address of the token being transferred
    /// @param amount The amount of fees transferred
    /// @param to The address that receives the fees
    event TransferTradingFees(address indexed sender, address indexed token, uint256 amount, address indexed to);

    /// @notice Emitted when a collateral token market is updated
    /// @param token The address of the token
    /// @param marketId The market ID
    event CollateralTokenMarketUpdated(address indexed token, uint16 indexed marketId);

    /// @notice Thrown when the permit signature has expired
    error SignatureExpired(uint256 deadline);

    /// @notice Thrown when the permit signature is invalid
    error InvalidPermitSignature(address account);

    /// @notice Thrown when the requested amount exceeds the permitted amount
    error InvalidAmount(uint256 maxAmount);

    /// @notice Deposits collateral into the PerpsCollateralManager
    /// @param receiver The account to credit with the deposited collateral
    /// @param token The address of the token to deposit
    /// @param amount The amount of token to deposit
    function deposit(
        address receiver,
        Currency token,
        uint256 amount
    ) external;

    /// @notice Withdraws collateral from the PerpsCollateralManager
    /// @param to The recipient address for the withdrawn tokens
    /// @param token The address of the token to withdraw
    /// @param amount The amount of token to withdraw
    function withdraw(
        address to,
        Currency token,
        uint256 amount
    ) external;

    /// @notice Withdraws collateral on behalf of an owner using a signed permit (Permit2-style)
    /// @dev The signature includes msg.sender as the authorized spender, matching Permit2's trust model.
    ///      Uses sequential nonces for replay protection.
    /// @param permit The permit data (token, amount, nonce, deadline)
    /// @param transferDetails The withdrawal destination and requested amount
    /// @param owner The account authorizing the withdrawal
    /// @param signature The EIP-712 signature from the owner
    function permitTransferFrom(
        ISignatureTransfer.PermitTransferFrom calldata permit,
        ISignatureTransfer.SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Withdraws collateral on behalf of an owner using a signed permit with witness (Permit2-style)
    /// @dev The signature includes msg.sender as the authorized spender plus arbitrary witness data.
    /// @param permit The permit data (token, amount, nonce, deadline)
    /// @param transferDetails The withdrawal destination and requested amount
    /// @param owner The account authorizing the withdrawal
    /// @param witness Additional data hashed into the signed message
    /// @param witnessTypeString The EIP-712 type definition for the witness struct
    /// @param signature The EIP-712 signature from the owner
    function permitWitnessTransferFrom(
        ISignatureTransfer.PermitTransferFrom calldata permit,
        ISignatureTransfer.SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Sets whether a collateral token is supported
    /// @param token The address of the token to set
    /// @param isSupported Whether the token is supported
    function setIsCollateralToken(
        Currency token,
        bool isSupported
    ) external;

    /// @notice Updates the token balance for an account
    /// @param account The account to update the balance for
    /// @param token The token to update the balance for
    /// @param delta The delta of the token balance amount
    function updateTokenBalance(
        address account,
        Currency token,
        int256 delta
    ) external;

    /// @notice Gets the projected token balance of an account
    /// @dev For USDC this includes projected realized PnL from deferred settlements and subtracts
    ///      projected cross funding fees. It does not include unrealized PnL from open positions.
    /// @param account The account to get the token balance for
    /// @param token The address of the token to get the balance for
    function getTokenBalance(
        address account,
        Currency token
    ) external view returns (int256 balance);

    /// @notice Gets the projected total token balance in USDC for an account
    /// @dev Sums token balances in USDC using getTokenBalance semantics. This is projected for
    ///      realized PnL/funding, but still not full account equity while positions remain open.
    /// @param account The account to get the balance for
    function getTotalTokenBalanceInUSDC(
        address account
    ) external view returns (int256);

    /// @notice Gets whether a token is supported as collateral
    /// @param token The address of the token to check
    function getIsCollateralToken(
        Currency token
    ) external view returns (bool);

    /// @notice Returns the full list of supported collateral tokens
    function getSupportedCollateralTokens() external view returns (address[] memory);

    /// @notice Returns the withdrawable USD for an account
    /// @param account The account to check
    function getWithdrawableUSDC(
        address account
    ) external view returns (uint256);

    /// @notice Returns the account equity for an account
    /// @param account The account to check
    function getAccountEquity(
        address account
    ) external view returns (int256);

    /// @notice Returns the OrdersManager contract
    function getOrdersManager() external view returns (IOrdersManager);

    /// @notice Returns the FundingRate contract
    function getFundingRate() external view returns (IFundingRate);

    /// @notice Returns the RISExOracle contract
    function getRisexOracle() external view returns (IRISExOracle);

    /// @notice Returns the PerpsManager contract
    function getPerpsManager() external view returns (IPerpsManager);

    /// @notice Configure rate limit for a specific token
    /// @param token The token to configure
    /// @param config The rate limit configuration
    function configureTokenRateLimit(
        address token,
        LibRateLimiter.Config calldata config
    ) external;

    /// @notice Configure the global rate limit
    /// @param config The rate limit configuration
    function configureGlobalRateLimit(
        LibRateLimiter.Config calldata config
    ) external;

    /// @notice Get current rate limit state for a token
    /// @param token The token to query
    /// @return The current rate limit bucket state
    function getTokenRateLimitState(
        address token
    ) external view returns (LibRateLimiter.Bucket memory);

    /// @notice Get current global rate limit state
    /// @return The current global rate limit bucket state
    function getGlobalRateLimitState() external view returns (LibRateLimiter.Bucket memory);

    /// @notice Configure cumulative withdrawal window
    /// @param config Window configuration (limit and windowBlocks)
    function configureCumulativeWindow(
        LibCumulativeWindow.Config calldata config
    ) external;

    /// @notice Get cumulative window state
    /// @return total Current total in window
    /// @return remaining Remaining capacity
    /// @return blocksUntilReset Blocks until window resets
    function getCumulativeWindowState()
        external
        view
        returns (uint256 total, uint256 remaining, uint256 blocksUntilReset);

    /// @notice Release a pending withdrawal after emergency is cleared
    /// @dev Only callable by COLLATERAL_ROLE. Re-validates all withdraw conditions.
    /// @param account The account to release funds to
    /// @param token The token to release
    function releasePendingWithdrawal(
        address account,
        Currency token
    ) external;

    /// @notice Get pending withdrawal for an account+token pair
    /// @param account The account to query
    /// @param token The token to query
    /// @return The pending withdrawal state (amount=0 if none)
    function getPendingWithdrawal(
        address account,
        Currency token
    ) external view returns (PendingWithdrawal memory);
    // ══════════════════════════════════════════════════════════════════════════════
    // Hot-path ByUserId Functions (avoid address→userId roundtrips)
    // ══════════════════════════════════════════════════════════════════════════════

    /// @notice Updates the token balance for a userId (hot-path, no address resolution)
    /// @param userId The userId to update the balance for
    /// @param token The token to update the balance for
    /// @param delta The delta of the token balance amount
    function updateTokenBalanceByUserId(
        uint32 userId,
        Currency token,
        int256 delta
    ) external;

    /// @notice Gets the token balance of a userId (hot-path, no address resolution)
    /// @param userId The userId to get the token balance for
    /// @param token The address of the token to get the balance for
    function getTokenBalanceByUserId(
        uint32 userId,
        Currency token
    ) external view returns (int256 balance);

    /// @notice Gets the total token balance in USDC for a userId (hot-path, no address resolution)
    /// @param userId The userId to get the balance for
    function getTotalTokenBalanceInUSDCByUserId(
        uint32 userId
    ) external view returns (int256);

    /// @notice Gets the stored token balance sum in USDC without deferred projections.
    /// @dev Only use after _settlePendingBeforeAccountAction has drained all deferred fills for this
    ///      user. The caller must account for cross funding fees separately (e.g. in the margin fold).
    /// @param userId The userId to get the stored balance for
    function getStoredTotalTokenBalanceInUSDCByUserId(
        uint32 userId
    ) external view returns (int256);

    /// @notice Returns the withdrawable USD for a userId (hot-path, no address resolution)
    /// @param userId The userId to check
    function getWithdrawableUSDCByUserId(
        uint32 userId
    ) external view returns (uint256);

    /// @notice Returns the account equity for a userId (hot-path, no address resolution)
    /// @param userId The userId to check
    function getAccountEquityByUserId(
        uint32 userId
    ) external view returns (int256);

    /// @notice Returns the current permit nonce for an account
    /// @param account The account to query
    function nonces(
        address account
    ) external view returns (uint256);

    /// @notice Returns the EIP-712 domain separator
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
