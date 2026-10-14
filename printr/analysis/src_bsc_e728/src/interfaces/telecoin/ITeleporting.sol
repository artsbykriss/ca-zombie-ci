// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ITelecoin } from "./ITelecoin.sol";

/**
 * @title ITeleportingTelecoin
 * @notice Interface for the TeleportingTelecoin contract with teleporting capabilities
 * @dev Extends ITelecoin for teleport functionality via LayerZero
 */
interface ITeleportingTelecoin is ITelecoin {

    /**
     * @notice Teleports tokens into existence for cross-chain transfers
     * @param to Address to receive the tokens
     * @param value Amount of tokens to teleport in
     */
    function teleportIn(
        address to,
        uint256 value
    ) external;

    /**
     * @notice Teleports tokens out of existence for cross-chain transfers
     * @param from Address whose tokens are being teleported out
     * @param value Amount of tokens to teleport out
     */
    function teleportOut(
        address from,
        uint256 value
    ) external;

}
