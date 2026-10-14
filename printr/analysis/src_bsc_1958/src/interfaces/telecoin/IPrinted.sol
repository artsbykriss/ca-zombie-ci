// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/**
 * @title IPrintrTeleportingTelecoin
 * @notice Interface for the PrintrTelecoin contract with teleport and curve completion functionality
 * @dev Extends ITelecoin interface with additional token management functions
 */
interface IPrinted {

    /**
     * @notice Enum representing the teleport type of a Telecoin
     * @dev Values 0-1 are legacy types for backward compatibility with deployed contracts
     *      Values 2-3 are new types that support teleporting by calling methods on a Telecoin
     *      - LegacyMain (0): Legacy Main Telecoin (bool false, uses lock/unlock)
     *      - LegacyTeleporting (1): Legacy Teleporting Telecoin (bool true, uses mint/burn)
     *      - Main (2): New Main Telecoin with Telecoin.teleport() support
     *      - Teleporting (3): New Teleporting Telecoin with Telecoin.teleport() support
     */
    enum TeleportType {
        LegacyMain, // 0 - backward compatible with bool false
        LegacyTeleporting, // 1 - backward compatible with bool true
        Main, // 2 - new Main Telecoin type
        Teleporting // 3 - new Teleporting Telecoin type
    }

    /**
     * @notice Error thrown when attempting to interact with an incomplete curve
     * @dev This error is typically thrown when trying to add liquidity before curve completion
     */
    error CurveIsNotComplete();

    /**
     * @notice Returns the teleport type of this Telecoin
     * @dev Values 0-1 are legacy (backward compatible), values 2-3 support transmitLzSend
     * @return teleportType The TeleportType enum value:
     *         - LegacyMain (0): Legacy Main Telecoin (lock/unlock)
     *         - LegacyTeleporting (1): Legacy Teleporting Telecoin (mint/burn)
     *         - Main (2): New Main Telecoin with transmitLzSend support
     *         - Teleporting (3): New Teleporting Telecoin with transmitLzSend support
     */
    function isTeleporting() external view returns (TeleportType teleportType);

    /**
     * @notice Sets the restricted pool address during curve initialization
     * @dev Can only be called by Printr before completion
     * @param poolAddress The pool address to restrict transfers to
     * @custom:throws UnauthorizedAccount if caller is not Printr or curve is already complete
     * @custom:throws ZeroAddress if pool address is zero
     */
    function setRestrictedPool(
        address poolAddress
    ) external;

    /**
     * @notice Marks the curve as completed, removing transfer restrictions
     * @dev Can only be called by Printr when curve is not already completed
     * @custom:throws UnauthorizedAccount if caller is not Printr or curve is already completed
     */
    function markCurveComplete() external;

}
