// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUpgradeController} from "./IUpgradeController.sol";

/**
 * @title AdminUpgradeController
 * @notice Simple single-admin upgrade controller for initial deployment
 * @dev Allows only the admin address to authorize upgrades.
 *      Can be replaced with a more sophisticated controller (timelock, multisig)
 *      by updating the upgradeController in the Nullmask contract.
 */
contract AdminUpgradeController is IUpgradeController {
    /// @notice The admin address that can authorize upgrades
    address public admin;

    /// @notice Emitted when admin is transferred
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /// @notice Thrown when caller is not the admin
    error NotAdmin(address caller);

    /// @notice Thrown when new admin is zero address
    error ZeroAddress();

    constructor(address _admin) {
        if (_admin == address(0)) revert ZeroAddress();
        admin = _admin;
        emit AdminTransferred(address(0), _admin);
    }

    /// @inheritdoc IUpgradeController
    function canUpgrade(address caller, address /* newImplementation */) external view override returns (bool) {
        return caller == admin;
    }

    /**
     * @notice Transfer admin role to a new address
     * @param newAdmin The new admin address
     */
    function transferAdmin(address newAdmin) external {
        if (msg.sender != admin) revert NotAdmin(msg.sender);
        if (newAdmin == address(0)) revert ZeroAddress();

        address previousAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(previousAdmin, newAdmin);
    }

    /**
     * @notice Execute a call on a target contract as this controller
     * @dev Used to call setUpgradeController on Nullmask, which requires
     *      msg.sender == upgradeController. Only admin can call this.
     * @param target The contract to call
     * @param data The calldata to send
     * @return result The return data from the call
     */
    function execute(address target, bytes calldata data) external returns (bytes memory result) {
        if (msg.sender != admin) revert NotAdmin(msg.sender);

        bool success;
        (success, result) = target.call(data);
        if (!success) {
            // Bubble up the revert reason
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
