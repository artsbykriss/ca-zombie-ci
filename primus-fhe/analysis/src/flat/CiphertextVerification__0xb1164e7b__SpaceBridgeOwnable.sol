// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title SpaceBridgeOwnable
 * @dev Ensures that a contract is owned by the SpaceBridge owner, defined as the owner of the SpaceBridgeConfig contract
 */
abstract contract SpaceBridgeOwnable is Initializable {
    address internal spacebridgeConfigAddress;

    /**
     * @dev Reserved storage gap to allow adding new state variables in future upgrades.
     */
    uint256[10] private __gap;

    /**
    * @notice Initializes the SpaceBridge ownership context.
    * @param _spacebridgeConfigAddress The address of the SpaceBridgeConfig contract.
    */
    function __SpaceBridgeOwnable_init(address _spacebridgeConfigAddress) internal onlyInitializing {
        spacebridgeConfigAddress = _spacebridgeConfigAddress;
    }

    /**
     * @notice Error emitted when an address is not the owner of the SpaceBridgeConfig contract.
     * @param sender The address that is not the owner.
     */
    error NotSpaceBridgeOwner(address sender);

    /**
     * @notice Checks if the sender is the owner of the SpaceBridgeConfig contract.
     */
    modifier onlySpaceBridgeOwner() {
        require(spacebridgeConfigAddress != address(0), "SpaceBridgeConfig not initialized");

        if (msg.sender != Ownable2StepUpgradeable(spacebridgeConfigAddress).owner()) {
            revert NotSpaceBridgeOwner(msg.sender);
        }
        _;
    }
}