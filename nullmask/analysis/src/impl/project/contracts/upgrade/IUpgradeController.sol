// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IUpgradeController
 * @notice Interface for controlling UUPS upgrade permissions
 * @dev Implement this interface to create custom upgrade authorization logic.
 *      The Nullmask contract delegates upgrade authorization to the controller,
 *      allowing the permission mechanism itself to be upgraded by deploying
 *      a new controller (e.g., from admin-only to timelock or multisig).
 */
interface IUpgradeController {
    /**
     * @notice Check if an upgrade is authorized
     * @param caller The address attempting the upgrade (msg.sender of upgradeToAndCall)
     * @param newImplementation The address of the new implementation contract
     * @return True if the upgrade is authorized, false otherwise
     */
    function canUpgrade(address caller, address newImplementation) external view returns (bool);
}
