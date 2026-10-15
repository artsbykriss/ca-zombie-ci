// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IACLManager {
    /**
     * @notice Sets the admin role for a specific role.
     * @param role The role for which to set the admin.
     * @param adminRole The admin role to be set for the specified role.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new Cega Admin.
     * @param admin The address to be granted Cega Admin role.
     */
    function addCegaAdmin(address admin) external;

    /**
     * @notice Removes a Cega Admin.
     * @param admin The address to be removed from Cega Admin role.
     */
    function removeCegaAdmin(address admin) external;

    /**
     * @notice Adds a new Trader Admin.
     * @param admin The address to be granted Trader Admin role.
     */
    function addTraderAdmin(address admin) external;

    /**
     * @notice Removes a Trader Admin.
     * @param admin The address to be removed from Trader Admin role.
     */
    function removeTraderAdmin(address admin) external;

    /**
     * @notice Adds a new Operator Admin.
     * @param admin The address to be granted Operator Admin role.
     */
    function addOperatorAdmin(address admin) external;

    /**
     * @notice Removes an Operator Admin.
     * @param admin The address to be removed from Operator Admin role.
     */
    function removeOperatorAdmin(address admin) external;

    /**
     * @notice Adds a new Service Admin.
     * @param admin The address to be granted Service Admin role.
     */
    function addServiceAdmin(address admin) external;

    /**
     * @notice Removes a Service Admin.
     * @param admin The address to be removed from Service Admin role.
     */
    function removeServiceAdmin(address admin) external;

    /**
     * @notice Checks if an address is a Cega Admin.
     * @param admin The address to check for Cega Admin role.
     * @return bool True if the address is a Cega Admin, false otherwise.
     */
    function isCegaAdmin(address admin) external view returns (bool);

    /**
     * @notice Checks if an address is a Trader Admin.
     * @param admin The address to check for Trader Admin role.
     * @return bool True if the address is a Trader Admin, false otherwise.
     */
    function isTraderAdmin(address admin) external view returns (bool);

    /**
     * @notice Checks if an address is an Operator Admin.
     * @param admin The address to check for Operator Admin role.
     * @return bool True if the address is an Operator Admin, false otherwise.
     */
    function isOperatorAdmin(address admin) external view returns (bool);

    /**
     * @notice Checks if an address is a Service Admin.
     * @param admin The address to check for Service Admin role.
     * @return bool True if the address is a Service Admin, false otherwise.
     */
    function isServiceAdmin(address admin) external view returns (bool);
}
