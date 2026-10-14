// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IOFT } from "../layerzero/IOFT.sol";
import { IPrintrTeleport } from "../printr/IPrintrTeleport.sol";
import { IERC20Witness } from "./IERC20Witness.sol";

/**
 * @title ITelecoin
 * @notice Interface for the Telecoin base contract
 * @dev Extends IERC20 for base teleport functionality
 */
interface ITelecoin is IERC20Witness, IOFT {

    /**
     * @notice Struct containing deployment parameters for telecoin contracts
     * @param telecoinId Universal telecoin ID
     * @param name Token name
     * @param symbol Token symbol
     * @param maxSupply Maximum supply of the token
     * @param printr Address of the Printr contract
     */
    struct TelecoinDeployParams {
        bytes32 telecoinId;
        string name;
        string symbol;
        uint256 maxSupply;
        address printr;
    }

    /**
     * @notice Error thrown when a zero address is provided where not allowed
     */
    error ZeroAddress();

    /**
     * @notice Error thrown when an unauthorized account attempts a restricted operation
     * @param account The address that attempted the unauthorized operation
     */
    error UnauthorizedAccount(address account);

    /**
     * @notice Error thrown when ITS protocol is used (deprecated)
     */
    error ITSDeprecated();

    /**
     * @notice Error thrown when an invalid protocol is specified
     */
    error InvalidProtocol();

    /**
     * @notice Error thrown when a native token transfer fails
     */
    error TransferFailed();

    /**
     * @notice Emitted when tokens are teleported in from another chain
     * @param telecoinId The universal token ID
     * @param to The address receiving the tokens
     * @param value The amount of tokens teleported in
     */
    event TeleportIn(bytes32 indexed telecoinId, address indexed to, uint256 value);

    /**
     * @notice Emitted when tokens are teleported out to another chain
     * @param telecoinId The universal token ID
     * @param from The address from which tokens are teleported
     * @param value The amount of tokens teleported out
     */
    event TeleportOut(bytes32 indexed telecoinId, address indexed from, uint256 value);

    /**
     * @notice Returns the universal token ID (deploySalt)
     * @dev This value is immutable and set during contract construction
     * @return The universal token ID based on deployment salt
     */
    function telecoinId() external view returns (bytes32);

    /**
     * @notice Returns the address of the Printr contract that created this token
     * @dev This value is immutable and set during contract construction
     * @return The address of the Printr contract
     */
    function printr() external view returns (address);

    /**
     * @notice Returns the URL of the off-chain metadata JSON for this telecoin
     * @dev Indexer-friendly getter following the OpenSea contractURI convention. The URL
     *      is derived from the immutable telecoinId so it remains stable across chains.
     * @return URL of the metadata JSON (e.g. name, description, image, socials)
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Returns the URL of the off-chain metadata JSON for this telecoin
     * @dev Alias of contractURI(). Mirrors the Solana/Metaplex naming so the same
     *      lookup works whether the consumer expects EVM or Solana conventions.
     * @return URL of the metadata JSON (identical to contractURI())
     */
    function metadataURI() external view returns (string memory);

    /**
     * @notice Quotes the total teleport fee for any protocol
     * @dev Delegates to PrintrTeleport's quoteTeleportFee for fee calculation
     * @param params The teleport parameters struct (includes protocol)
     * @return totalNativeFee The total fee in native currency (protocol fee + bridge fee)
     * @return basePairFee The fee in base pair tokens (0 if base pair is native)
     * @return basePair The base pair address (address(0) if native)
     * @return bridgeFee The bridge-specific gas fee (ITS gas fee or LZ messaging fee)
     */
    function quoteTeleportFee(
        IPrintrTeleport.TeleportParams memory params
    ) external returns (uint256 totalNativeFee, uint256 basePairFee, address basePair, uint256 bridgeFee);

    /**
     * @notice Teleports tokens from sender to a destination chain
     * @param params The teleport parameters struct (includes protocol)
     */
    function teleport(
        IPrintrTeleport.TeleportParams calldata params
    ) external payable;

    /**
     * @notice Teleports tokens from a specified sender to a destination chain
     * @param sender The sender of the tokens (must have approved msg.sender)
     * @param params The teleport parameters struct (includes protocol)
     */
    function teleportFrom(
        address sender,
        IPrintrTeleport.TeleportParams calldata params
    ) external payable;

}
