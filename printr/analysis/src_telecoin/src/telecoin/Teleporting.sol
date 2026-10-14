// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ITeleportingTelecoin } from "../interfaces/telecoin/ITeleporting.sol";

import { Telecoin } from "./Telecoin.sol";

/**
 * @title Teleporting
 * @notice Base ERC20 token with teleport capabilities (mint/burn)
 * @dev Extends Telecoin to provide cross-chain teleport functionality via LayerZero
 */
contract TeleportingTelecoin is ITeleportingTelecoin, Telecoin {

    /**
     * @notice Constructor for TeleportingTelecoin
     * @param params Deployment parameters struct containing token configuration
     */
    constructor(
        TelecoinDeployParams memory params
    ) Telecoin(params) { }

    /**
     * @notice Teleports tokens into existence for cross-chain transfers
     * @dev Can only be called by Printr
     * @param to Address to receive the teleported tokens
     * @param value Amount of tokens to teleport in
     */
    function teleportIn(
        address to,
        uint256 value
    ) public {
        if (msg.sender != printr) {
            revert UnauthorizedAccount(msg.sender);
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        emit TeleportIn(telecoinId, to, value);
        _update(address(0), to, value);
    }

    /**
     * @notice Teleports tokens out of existence for cross-chain transfers
     * @dev Can only be called by Printr
     * @param from Address to teleport tokens from
     * @param value Amount of tokens to teleport out
     */
    function teleportOut(
        address from,
        uint256 value
    ) public {
        if (msg.sender != printr) {
            revert UnauthorizedAccount(msg.sender);
        }
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }

        emit TeleportOut(telecoinId, from, value);
        _decreaseAllowance(from, msg.sender, value);
        _update(from, address(0), value);
    }

}
