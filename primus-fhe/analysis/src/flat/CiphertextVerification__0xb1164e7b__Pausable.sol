// SPDX-License-Identifier: BSD-3-Clause-Clear
// ===== THIRD-PARTY NOTICE — DO NOT EDIT BY HAND =====
//
// Portions derived from zama-ai/fhevm. Copyright © 2025 ZAMA. All rights reserved.
// Modifications Copyright © 2026 Primus Labs.
// Full license terms: see the BSD-3-Clause-Clear notice included in this source distribution.
//
// ===== END THIRD-PARTY NOTICE =====
pragma solidity ^0.8.24;


import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ISpaceBridgeConfig } from "./interfaces/ISpaceBridgeConfig.sol";

abstract contract Pausable is PausableUpgradeable {
    /**
     * @notice The contract's variable storage struct
     */
    struct PausableExStorage {
        address spacebridgeConfig;
    }

    /**
     * @dev Storage location has been computed using the following command:
     * keccak256(abi.encode(uint256(keccak256("fhetransform.spacebridge.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
     */
    bytes32 private constant PAUSABLE_STORAGE_LOCATION =
        0xf249f0079ad11cc8714fb6bc77f8945edd0778ce568af8d36c8772eff8729700;

    /**
     * @notice Error emitted when an address is not the spacebridge config or the owner.
     * @param callerAddress The address that is not the spacebridge config or the owner.
     */
    error NotSpaceBridgeConfigOrOwner(address callerAddress);

    /**
     * @notice Initializes the SpaceBridgeConfig address for the pausable module.
     * @dev Must be called during contract initialization (not in constructor).
     *      This function sets the address of the SpaceBridgeConfig contractc.
     * @param _spacebridgeConfigAddress The address of the deployed SpaceBridgeConfig contract.
     */
    function __PausableWithSpaceBridge_init(address _spacebridgeConfigAddress) internal onlyInitializing {
        require(_spacebridgeConfigAddress != address(0), "Invalid SpaceBridgeConfig address");
        _getPausableExStorage().spacebridgeConfig = _spacebridgeConfigAddress;
    }

    /**
     * @notice Pauses the contract.
     * @dev Can be called either by the SpaceBridgeConfig contract itself or by
     *      the owner of the SpaceBridgeConfig contract. There is no separate
     *      "pauser" role — authorization is delegated to the SpaceBridgeConfig
     *      ownership model.
     *
     *      The SpaceBridgeConfig-address branch is exercised through
     *      {SpaceBridgeConfig.pauseAll}, which lets the owner coordinate an atomic
     *      pause across every registered dependent contract in one transaction.
     *      The owner branch allows pausing this contract directly on its own.
     *
     * Requirements:
     * - The caller must be the SpaceBridgeConfig contract or its owner.
     * - The contract must not already be paused.
     *
     * Reverts:
     * - {NotSpaceBridgeConfigOrOwner} if the caller is not authorized.
     * - {EnforcedPause} (from {PausableUpgradeable}) if already paused.
     */
    function pause() external virtual {
        address callerAddress = msg.sender;
        address spacebridgeConfigAddress = _getPausableExStorage().spacebridgeConfig;

        if (callerAddress != Ownable2StepUpgradeable(spacebridgeConfigAddress).owner() && 
            callerAddress != spacebridgeConfigAddress) {
            revert NotSpaceBridgeConfigOrOwner(callerAddress);
        }
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Can be called either by the SpaceBridgeConfig contract itself (via
     *      {SpaceBridgeConfig.unpauseAll}, for a coordinated unpause of all
     *      registered dependent contracts) or by the owner of the
     *      SpaceBridgeConfig contract (to unpause this contract directly).
     *
     * Requirements:
     * - The caller must be the SpaceBridgeConfig contract or its owner.
     * - The contract must be paused.
     *
     * Reverts:
     * - {NotSpaceBridgeConfigOrOwner} if the caller is not authorized.
     */
    function unpause() external virtual {
        address callerAddress = msg.sender;
        address spacebridgeConfigAddress = _getPausableExStorage().spacebridgeConfig;

        if (callerAddress != Ownable2StepUpgradeable(spacebridgeConfigAddress).owner() && 
            callerAddress != spacebridgeConfigAddress) {
            revert NotSpaceBridgeConfigOrOwner(callerAddress);
        }
        _unpause();
    }

    /**
     * @notice Returns the Pausable storage location.
     */
    function _getPausableExStorage() internal pure returns (PausableExStorage storage $) {
        assembly {
            $.slot := PAUSABLE_STORAGE_LOCATION
        }
    }
}
