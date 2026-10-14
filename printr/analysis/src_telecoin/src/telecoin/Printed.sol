// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrinted } from "../interfaces/telecoin/IPrinted.sol";
import { ITelecoin } from "../interfaces/telecoin/ITelecoin.sol";

import { TeleportingTelecoin } from "./Teleporting.sol";

/**
 * @title PrintrTelecoin
 * @notice Implementation of a Telecoin with teleport capabilities and interchain functionality
 * @dev Extends Telecoin to provide cross-chain functionality via LayerZero
 */
abstract contract Printed is IPrinted {

    /// @notice The teleport type of this Telecoin (Main uses lock/unlock, Teleporting uses mint/burn)
    TeleportType public immutable isTeleporting;

    /// @notice Address of the Printr contract that created this token
    address private immutable printr;

    /**
     * @notice Enum representing the different states of curve completion
     * @dev Used to track the progression of the bonding curve
     * @custom:value NotInitialized - Initial state before any completion actions
     * @custom:value Restricted - State where transfers are restricted to a specific pool
     * @custom:value Completed - Final state where curve is completed and unrestricted
     */
    enum CompletionState {
        NotInitialized, // Not yet initialized
        Restricted, // Restricted to specific pool
        Completed // Curve completed
    }

    /**
     * @notice Struct to pack pool address and state in single storage slot
     * @dev Packs address (160 bits) and state (8 bits) into 256 bits for gas optimization
     * @param pool The address of the liquidity pool (160 bits)
     * @param state The current completion state of the curve (8 bits)
     */
    struct CompletionStatus {
        address pool; // Pool address (160 bits)
        CompletionState state; // Completion state (8 bits)
    }

    /// @notice Tracks the completion status and restricted pool address
    CompletionStatus public completionStatus;

    /**
     * @notice Initializes the token with its basic parameters
     * @param _printr Address of the Printr contract that created this token
     * @param _treasury Address to receive the initial token supply
     * @param _initialSupply The initial supply to mint to treasury
     * @param _teleportType The teleport type of this telecoin (Main, Teleporting, or Legacy variants)
     */
    constructor(
        address _printr,
        address _treasury,
        uint256 _initialSupply,
        TeleportType _teleportType
    ) {
        printr = _printr;
        isTeleporting = _teleportType;

        // Mint the chain total supply directly to the treasury
        _update(address(0), _treasury, _initialSupply);
    }

    /**
     * @notice Sets the restricted pool address during curve initialization
     * @dev Can only be called by Printr before completion. Updates the completion status
     *      to restrict transfers to the specified pool address until curve is marked complete.
     *      Uses atomic storage writes for gas efficiency.
     * @param poolAddress The pool address to restrict transfers to during curve completion phase
     * @custom:throws UnauthorizedAccount if caller is not Printr or curve is already complete
     * @custom:throws ZeroAddress if pool address is zero
     */
    function setRestrictedPool(
        address poolAddress
    ) external {
        if (poolAddress == address(0)) {
            revert ITelecoin.ZeroAddress();
        }
        if (msg.sender != printr || completionStatus.state == CompletionState.Completed) {
            revert ITelecoin.UnauthorizedAccount(msg.sender);
        }

        // Write the entire struct atomically in a single SSTORE
        completionStatus = CompletionStatus({ pool: poolAddress, state: CompletionState.Restricted });
    }

    /**
     * @notice Marks the bonding curve as completed, removing transfer restrictions
     * @dev Can only be called by Printr when curve is not already completed.
     *      Clears the restricted pool address and sets state to Completed, allowing
     *      unrestricted token transfers. Uses atomic storage writes for gas efficiency.
     * @custom:throws UnauthorizedAccount if caller is not Printr or curve is already completed
     */
    function markCurveComplete() external {
        if (msg.sender != printr || completionStatus.state == CompletionState.Completed) {
            revert ITelecoin.UnauthorizedAccount(msg.sender);
        }

        // Write the entire struct atomically in a single SSTORE
        // Clear pool address when marking complete
        completionStatus = CompletionStatus({ pool: address(0), state: CompletionState.Completed });
    }

    /**
     * @notice Internal hook to handle token transfers
     * @dev Prevents adding tokens to liquidity pool before curve completion
     * param from Address tokens are transferred from
     * @param to Address tokens are transferred to
     * param value Amount of tokens being transferred
     * @custom:dev Inheriting contract must call super._update()
     * @custom:throws CurveIsNotComplete if attempting to add to pool before completion
     */
    function _update(
        address,
        /*from*/
        address to,
        uint256 /*value*/
    ) internal virtual {
        // Read entire struct from storage once
        CompletionStatus memory status = completionStatus;

        // Disable adding token to liquidity pool before completion
        if (status.state == CompletionState.Restricted && to == status.pool) {
            revert CurveIsNotComplete();
        }

        // NOTE: Inheriting contract must call ERC20._update()
    }

}
