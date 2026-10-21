// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IOFT {
    function token() external view returns (address);
    function peers(uint32 eid) external view returns (bytes32);
}

/// @title IRISExComposer
/// @notice Interface for RISExComposer — a LayerZero v2 compose receiver that executes
///         access-controlled calls with bridged OFT tokens.
/// @dev The compose flow is split across two transactions:
///   Tx1 (_lzReceive): OFT mints tokens to the composer.
///   Tx2 (lzCompose):  Executor triggers this contract to decode the compose payload,
///                     validate policies, execute the whitelisted call, and queue leftovers.
interface IRISExComposer {
    // ── Structs ──────────────────────────────────────────────────────────────

    /// @notice Per-OFT configuration stored on whitelist.
    /// @param whitelisted Whether the OFT is allowed to trigger compose.
    /// @param token The underlying ERC-20 resolved from `IOFT.token()` at whitelist time.
    struct OFTConfig {
        bool whitelisted;
        address token;
    }

    /// @notice Packed per-token accounting — fits in a single storage slot (32 bytes).
    /// @param oftCount Number of whitelisted OFTs referencing this token (max 65 535).
    /// @param totalClaimable Aggregate claimable balance across all receivers.
    /// @param inflightProtected Balance snapshot on last-OFT delist, protecting in-flight funds.
    struct TokenInfo {
        uint16 oftCount;
        uint120 totalClaimable;
        uint120 inflightProtected;
    }

    // ── Errors ───────────────────────────────────────────────────────────────

    /// @notice Caller is not the LayerZero endpoint.
    error InvalidCaller(address caller);

    /// @notice The OFT that sent the compose message is not whitelisted.
    error OFTNotWhitelisted(address oft);

    /// @notice The OFT's underlying token resolved to `address(0)`.
    error OFTTokenNotSet(address oft);

    /// @notice The (target, selector) pair is not permitted by the AccessManager.
    error CallNotWhitelisted(address target, bytes4 selector);

    /// @notice The call target is forbidden (token, OFT, or this contract).
    error InvalidTarget(address target);

    /// @notice The compose message payload could not be ABI-decoded.
    error InvalidComposeMsg();

    /// @notice Rescue attempted on a token still referenced by a whitelisted OFT.
    error ProtectedToken(address token);

    /// @notice `msg.value` must be zero — native token transfers are not accepted.
    error NativeTokenNotAccepted();

    /// @notice The source endpoint ID has no configured peer on the OFT.
    error SrcEidNotAllowed(uint32 srcEid);

    /// @notice Contract balance is below the bridged `amountLD`.
    error InsufficientBalance(uint256 balance, uint256 amountLD);

    /// @notice No claimable funds exist for the caller and token.
    error NothingToClaim(address receiver, address token);

    /// @notice Rescue amount exceeds the available (non-claimable, non-inflight) balance.
    error RescueExceedsAvailable(uint256 available, uint256 requested);

    /// @notice The requested clearance exceeds the current in-flight protected balance.
    error ClearExceedsInflight(uint256 current, uint256 requested);

    // ── Events ───────────────────────────────────────────────────────────────

    /// @notice Emitted when an OFT's whitelist status changes.
    event OFTWhitelistUpdated(address indexed oft, bool allowed);

    /// @notice Emitted when tokens are rescued from the contract.
    event TokensRescued(address indexed token, address indexed to, uint256 amount);

    /// @notice Emitted when a compose target call fails and funds are queued for the receiver.
    event ComposeCallFailed(
        address indexed receiver, address indexed token, uint256 amount, address target, bytes4 selector, bytes reason
    );

    /// @notice Emitted when unconsumed tokens from a successful compose call are queued for the receiver.
    /// @param receiver The address that can claim the queued leftover.
    /// @param token The ERC-20 token queued.
    /// @param amount The leftover amount queued.
    event LeftoverQueued(address indexed receiver, address indexed token, uint256 amount);

    /// @notice Emitted when a user claims queued funds after a failed compose call.
    event FundsClaimed(address indexed receiver, address indexed token, uint256 amount);

    /// @notice Emitted when in-flight protection is recorded on OFT delist.
    event InflightProtectionSet(address indexed token, uint256 amount);

    /// @notice Emitted when the admin clears in-flight protection.
    event InflightProtectionCleared(address indexed token, uint256 amount);

    // ── State-changing functions ─────────────────────────────────────────────

    /// @notice Adds or removes an OFT from the whitelist.
    /// @dev When allowing, resolves and pins `IOFT(oft).token()` and increments the
    ///      token protection count. When removing, clears the pin and decrements it.
    ///      If the last OFT for a token is removed, snapshots the unaccounted balance
    ///      as in-flight protected to prevent rescue() from sweeping pending compose funds.
    function setOFTWhitelist(address oft, bool allowed) external;

    /// @notice Transfers stuck (non-protected) ERC-20 tokens out of the contract.
    /// @dev Reverts with `ProtectedToken` if any whitelisted OFT still references the token.
    ///      Also prevents sweeping funds queued for user claims and in-flight protected funds.
    function rescue(address token, address to, uint256 amount) external;

    /// @notice Claims all queued funds for `msg.sender` for the given token.
    /// @dev Queued funds accumulate from failed compose calls and leftover refunds
    ///      on successful calls. Transfers the full claimable balance and zeros
    ///      the caller's claim slot.
    /// @param token The ERC-20 token to claim.
    function claimFunds(address token) external;

    /// @notice Clears in-flight protection for a token after confirming no pending compose
    ///         messages remain (e.g. via LZ stored message clearing or manual verification).
    function clearInflightProtection(address token, uint256 amount) external;

    // ── View / Pure functions ────────────────────────────────────────────────

    /// @notice ABI-decodes a compose payload into its components.
    function decodeComposeMsg(bytes calldata composeMsg)
        external
        pure
        returns (address receiver, address target, bytes memory data);

    /// @notice Returns the LayerZero endpoint address.
    function getEndpoint() external view returns (address);

    /// @notice Returns the pinned underlying token for a given OFT.
    function getOFTToken(address oft) external view returns (address);

    /// @notice Checks whether a token is currently protected (referenced by any whitelisted OFT).
    function isProtectedToken(address token) external view returns (bool);

    /// @notice Checks whether an OFT is whitelisted.
    function getWhitelistedOFT(address oft) external view returns (bool);

    /// @notice Returns the claimable balance for a receiver and token.
    function getClaimable(address receiver, address token) external view returns (uint256);

    /// @notice Returns the total claimable balance across all receivers for a token.
    function getTotalClaimable(address token) external view returns (uint256);

    /// @notice Returns the in-flight protected balance for a token.
    function getInflightProtected(address token) external view returns (uint256);

    /// @notice Returns the full packed token info struct.
    function getTokenInfo(address token) external view returns (TokenInfo memory);
}
