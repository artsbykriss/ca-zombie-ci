// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrintrStorage } from "../printr/IPrintrStorage.sol";

/**
 * @title IPrintrTeleport
 * @notice Interface for PrintrTeleport contract that handles cross-chain messaging with Solana
 * @dev This interface defines the functionality for sending and receiving messages between EVM and Solana
 *      using the Teleport message protocol for token transfers
 */
interface IPrintrTeleport is IPrintrStorage {

    /**
     * @notice Error thrown when payload has invalid length
     */
    error InvalidPayloadLength();

    /**
     * @notice Error thrown when message kind is unexpected
     */
    error UnexpectedMessageKind();

    /**
     * @notice Error thrown when endpoint address is invalid
     */
    error InvalidEndpoint();

    /**
     * @notice Error thrown when solana program address is invalid
     */
    error InvalidSolanaProgram();

    /**
     * @notice Error thrown when sender is not authorized
     */
    error UnauthorizedSender();

    /**
     * @notice Error thrown when contract has insufficient fee balance
     */
    error InsufficientFee();

    /**
     * @notice Error thrown when fee transfer fails
     */
    error FeeTransferFailed();

    /**
     * @notice Error thrown when an invalid protocol is specified
     */
    error InvalidProtocol();

    /**
     * @notice Error thrown when the chain ID length is invalid
     */
    error InvalidChainIdLength();

    /**
     * @notice Error thrown when a non-numeric character is found in chain ID
     */
    error InvalidNumericCharacter();

    /**
     * @notice Error thrown when the endpoint ID is invalid
     */
    error InvalidEndpointId();

    /**
     * @notice Error thrown when calldata is invalid
     */
    error InvalidCalldata();

    /**
     * @notice Error thrown when security level is invalid
     */
    error InvalidSecurityLevel();

    /**
     * @notice Error thrown when protocol is not in global whitelist
     */
    error ProtocolNotWhitelisted();

    /**
     * @notice Error thrown when protocol is in token blacklist
     */
    error ProtocolBlacklisted();

    /**
     * @notice Error thrown when invalid protocol bit position used
     */
    error InvalidProtocolBitPosition();

    /**
     * @notice Error thrown when teleport amount exceeds maximum supported value
     * @dev Maximum supported amount is type(uint64).max * 1e9 (in 18 decimals)
     * @param requestedAmount The amount that was requested to teleport
     * @param maxAmount The maximum amount that can be teleported
     */
    error TeleportAmountOverflow(uint256 requestedAmount, uint256 maxAmount);

    /**
     * @notice Error thrown when ITS protocol is used (deprecated)
     */
    error ITSDeprecated();

    /**
     * @notice Protocol enum for teleportation methods
     * @dev Must match the Protocol enum in ITelecoin for compatibility
     */
    enum TeleportProtocol {
        UNSPECIFIED, // 0 - Used to catch malformed transactions
        ITS, // 1 - DEPRECATED
        LZ_FAST, // 2 - Fast LayerZero channel with minimal confirmations
        LZ_SECURE, // 3 - Secure LayerZero channel with balanced confirmations
        LZ_SLOW // 4 - Slow LayerZero channel with maximum confirmations
    }

    /**
     * @notice Struct containing constructor parameters for teleport deployment
     * @param lzFlatFee Flat fee for LayerZero transfers
     * @param lzBipsFee Basis points fee for LayerZero transfers
     * @param lzEndpoint LayerZero endpoint address for this chain
     * @param fastSolanaLzPeer Solana LayerZero peer address for fast/low security channel
     * @param secureSolanaLzPeer Solana LayerZero peer address for secure/medium security channel
     * @param slowSolanaLzPeer Solana LayerZero peer address for slow/high security channel
     * @param lzReceiveGasLimit Gas limit for LayerZero receive operations
     * @param lzReceiveNativeDrop Native drop amount for LayerZero receive operations
     */
    struct TeleportDeployParams {
        uint256 lzFlatFee;
        uint16 lzBipsFee;
        address lzEndpoint;
        bytes32 fastSolanaLzPeer;
        bytes32 secureSolanaLzPeer;
        bytes32 slowSolanaLzPeer;
        uint128 lzReceiveGasLimit;
        uint128 lzReceiveNativeDrop;
    }

    /**
     * @notice Struct containing teleport parameters
     * @param destChain The destination chain identifier
     * @param destAddress The bytes representation of the address of the recipient
     * @param amount The amount of tokens to be transferred
     * @param metadata Additional data for the cross-chain transfer
     * @param protocol The teleportation protocol to use (ITS, LZ_FAST, LZ_SECURE, LZ_SLOW)
     */
    struct TeleportParams {
        string destChain;
        bytes destAddress;
        uint256 amount;
        bytes metadata;
        TeleportProtocol protocol;
    }

    /**
     * @notice Event emitted when a new LayerZero delegate is set for a channel
     * @param protocol The teleport protocol (LZ_FAST, LZ_SECURE, LZ_SLOW)
     * @param delegate Address of the new LayerZero delegate
     */
    event LzDelegateUpdated(TeleportProtocol indexed protocol, address indexed delegate);

    /**
     * @notice Event emitted when global protocol whitelist is updated
     * @param newWhitelist The new whitelist bitmap
     */
    event TeleportProtocolWhitelistUpdated(bytes32 indexed newWhitelist);

    /**
     * @notice Event emitted when a token's protocol blacklist is updated
     * @param telecoinId The telecoin ID
     * @param newBlacklist The new blacklist bitmap
     */
    event TelecoinProtocolBlacklistUpdated(bytes32 indexed telecoinId, bytes32 indexed newBlacklist);

    /**
     * @notice Event emitted when tokens are teleported to another chain
     * @param telecoinId The ID of the token being transferred
     * @param tokenAddress The address of the token contract
     * @param sourceAddress The address initiating the transfer
     * @param destChain The target chain for the transfer
     * @param destAddress The address on the destination chain
     * @param amount The amount of tokens being transferred
     */
    event Teleporting(
        bytes32 indexed telecoinId,
        address indexed tokenAddress,
        address indexed sourceAddress,
        string destChain,
        bytes destAddress,
        uint256 amount
    );

    // ============================================
    // EXTERNAL FUNCTIONS
    // ============================================

    /**
     * @notice Calculates the universal token ID based on token parameters
     * @dev Returns the telecoinId as a universal token ID that's vendor-agnostic
     * @param tokenParams Parameters for the token deployment
     * @return telecoinId The universal token ID
     */
    function getTelecoinId(
        TelecoinParams calldata tokenParams
    ) external pure returns (bytes32 telecoinId);

    /**
     * @notice Sets the LayerZero delegate address for a specific channel
     * @dev Only callable by the contract owner or authorized account
     * @param protocol The teleport protocol to configure (LZ_FAST, LZ_SECURE, LZ_SLOW)
     * @param delegate Address of the new LayerZero delegate
     */
    function setLzDelegate(
        TeleportProtocol protocol,
        address delegate
    ) external;

    /**
     * @notice Gets the LZChannel address for a specific protocol
     * @param protocol The teleport protocol (LZ_FAST, LZ_SECURE, LZ_SLOW)
     * @return channel Address of the LZChannel contract for this protocol
     */
    function getLzChannel(
        TeleportProtocol protocol
    ) external view returns (address channel);

    /**
     * @notice Updates the global protocol whitelist by enabling and/or disabling protocols
     * @dev Only callable by the contract owner. Processes disable array first, then enable array.
     * @param enable Array of protocols to enable globally
     * @param disable Array of protocols to disable globally
     */
    function updateGlobalProtocols(
        TeleportProtocol[] calldata enable,
        TeleportProtocol[] calldata disable
    ) external;

    /**
     * @notice Gets the global protocol whitelist bitmap
     * @return whitelist Bitmap of enabled protocols
     */
    function getTeleportProtocolWhitelist() external view returns (bytes32 whitelist);

    /**
     * @notice Updates the protocol blacklist for a specific telecoin
     * @dev Only callable by the contract owner. Processes enable array first (removes from blacklist), then disable
     * array (adds to blacklist).
     * @param telecoinId The ID of the telecoin
     * @param enable Array of protocols to enable for this telecoin (remove from blacklist)
     * @param disable Array of protocols to disable for this telecoin (add to blacklist)
     */
    function updateTelecoinProtocols(
        bytes32 telecoinId,
        TeleportProtocol[] calldata enable,
        TeleportProtocol[] calldata disable
    ) external;

    /**
     * @notice Gets a token's protocol blacklist bitmap
     * @param telecoinId The telecoin ID
     * @return blacklist Bitmap of disabled protocols for this token
     */
    function getTelecoinProtocolBlacklist(
        bytes32 telecoinId
    ) external view returns (bytes32 blacklist);

    /**
     * @notice Checks if a protocol is allowed for a specific token
     * @dev Returns true if protocol is in global whitelist AND NOT in token blacklist
     * @param telecoinId The telecoin ID
     * @param protocol The protocol to check
     * @return allowed True if protocol is allowed for this token
     */
    function isProtocolAllowed(
        bytes32 telecoinId,
        TeleportProtocol protocol
    ) external view returns (bool allowed);

    /**
     * @notice Quotes the total teleport fee for any protocol
     * @dev Consolidates fee calculation for LayerZero protocols. ITS is deprecated and reverts.
     * @param token Token address to transfer
     * @param params The teleport parameters struct (includes protocol)
     * @return totalNativeFee The total fee in native currency (protocol fee + bridge fee)
     * @return basePairFee The fee in base pair tokens (0 if base pair is native)
     * @return basePair The base pair address (address(0) if native)
     * @return bridgeFee The bridge-specific gas fee (ITS gas fee or LZ messaging fee)
     */
    function quoteTeleportFee(
        address token,
        TeleportParams calldata params
    ) external returns (uint256 totalNativeFee, uint256 basePairFee, address basePair, uint256 bridgeFee);

    /**
     * @notice Universal teleport function that routes to ITS or LayerZero
     * @dev Routes tokens to the appropriate cross-chain protocol based on params.protocol
     * @param token The token address to teleport
     * @param params The teleport parameters struct (includes protocol)
     */
    function teleport(
        address token,
        TeleportParams calldata params
    ) external payable;

    /**
     * @notice Universal teleport function with witness signature support
     * @dev Called via permitWitnessCall to enable signature-based teleportation
     * @dev Signer must be the first param to protect from permitWitnessCall attacks
     * @param signer Address initiating the teleport, must be first parameter
     * @param telecoinId The telecoin ID instead of token address
     * @param params The teleport parameters struct (includes protocol)
     */
    function witnessTeleport(
        address signer,
        bytes32 telecoinId,
        TeleportParams calldata params
    ) external payable;

    /**
     * @notice Transmits a LayerZero cross-chain token transfer
     * @dev Called by token contracts to initiate LayerZero transfers
     * @dev telecoinId first param, to protect from permitWitnessCall calls
     * @param telecoinId Universal token ID (32 bytes)
     * @param sender Address initiating the transfer
     * @param params The teleport parameters struct
     */
    function transmitLzSend(
        bytes32 telecoinId,
        address sender,
        TeleportParams calldata params
    ) external payable returns (bytes memory receipt);

    /**
     * @notice ITS deprecated - kept for ABI compatibility with old deployed tokens. Always reverts.
     */
    function broadcastInterchainTransfer(
        bytes32 telecoinId,
        address sourceAddress,
        string calldata destChain,
        bytes calldata destAddress,
        uint256 amount
    ) external;

    /**
     * @notice ITS deprecated - kept for ABI compatibility with old deployed tokens. Always reverts.
     */
    function processInterchainTransfer(
        bytes32 telecoinId,
        address sender,
        uint256 amount
    ) external;

    // ============================================
    // EXTERNAL VIEW FUNCTIONS
    // ============================================

    /**
     * @notice Gets the LayerZero endpoint address
     * @return The LayerZero endpoint address
     */
    function lzEndpoint() external view returns (address);

    /**
     * @notice Gets the current gas limit for LayerZero receive operations
     * @return gasLimit Current gas limit
     */
    function lzReceiveGasLimit() external view returns (uint128 gasLimit);

    /**
     * @notice Gets the current native drop amount for LayerZero receive operations
     * @return nativeDrop Current native drop amount
     */
    function lzReceiveNativeDrop() external view returns (uint128 nativeDrop);

    /**
     * @notice Receives teleport messages from authorized channels
     * @dev Called by LZChannel contracts to forward processed messages
     * @param protocol The teleport protocol of the calling channel (LZ_FAST, LZ_SECURE, LZ_SLOW)
     * @param originSender The LayerZero origin sender address (Solana peer or self)
     * @param message The processed teleport payload
     */
    function receiveFromChannel(
        TeleportProtocol protocol,
        bytes32 originSender,
        bytes calldata message
    ) external payable;

}
