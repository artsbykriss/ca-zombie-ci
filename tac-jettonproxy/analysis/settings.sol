// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { ISettings } from "../interfaces/ISettings.sol";
import { SettingsConstants } from "../libs/SettingsConstants.sol";
import { TacInitializable } from "./TacInitializable.sol";

/**
 * @title Settings
 * @dev A contract for storing Cross-Chain Layer configuration
 */
contract Settings is TacInitializable, UUPSUpgradeable, AccessControlUpgradeable, ISettings {

    // Errors
    error InvalidKey(bytes32 key);
    error InvalidUintValue(bytes32 key);
    error ZeroAddress(bytes32 key);
    error ChangingAddressForbidden(bytes32 key);

    // Events
    event UintSettingsUpdated(bytes32 key, uint value);
    event AddressSettingsUpdated(bytes32 key, address value);
    event BoolSettingsUpdated(bytes32 key, bool value);
    event TrustedEVMExecutorsUpdated(address[] indexed executors);
    event TrustedTVMExecutorsUpdated(string[] indexed executors);

    // Constants
    bytes32 public constant ADMIN = keccak256("ADMIN");

    // Mappings for storing settings
    mapping(bytes32 => uint64) private _uintSettings;
    mapping(bytes32 => address) private _addressSettings;
    mapping(bytes32 => bool) private _boolSettings;
    mapping(bytes32 => string) private _stringSettings;
    address[] private _trustedEVMExecutors;
    string[] private _trustedTVMExecutors;

    /**
     * @dev Constructor function to initialize the contract with initial state.
     * @param adminAddress Admin address.
     */
    function initialize(address adminAddress) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        _setRoleAdmin(ADMIN, ADMIN);
        _grantRole(ADMIN, adminAddress);
    }

    /**
     * @dev Upgrades the contract.
     */
    function _authorizeUpgrade(address) internal override onlyRole(ADMIN) {}


    // External methods

    function _checkUintSetting(bytes32 key, uint value) internal pure {

        if (key == SettingsConstants.CONSENSUS_THRESHOLD_GROUPS_KEY) {
            if (value == 0 || value > SettingsConstants.RATE_DECIMALS) {
                revert InvalidUintValue(key);
            }
        } else if (key == SettingsConstants.CONSENSUS_THRESHOLD_IN_GROUP_KEY) {
            if (value == 0 || value > SettingsConstants.RATE_DECIMALS) {
                revert InvalidUintValue(key);
            }
        } else if (key == SettingsConstants.EPOCH_DELAY_KEY) {
            // 5 mins
            if (value > 300) {
                revert InvalidUintValue(key);
            }
        } else if (key == SettingsConstants.TREE_DURATION_KEY) {
            // TODO: Add a check
        } else if (key == SettingsConstants.VALIDITY_DURATION_KEY) {
            // TODO: Add a check
        } else if (key == SettingsConstants.MAX_EPOCH_DURATION_KEY) {
            // TODO: Add a check
        } else if (key == SettingsConstants.ASSET_DEPLOY_FINALIZE_TIME_KEY) {
            // TODO: Add a check
        } else {
            revert InvalidKey(key);
        }
    }

    /**
     * @dev Update trustedEVMExecutors setting.
     * @param trustedEVMExecutors Trusted executors.
     */
    function setTrustedEVMExecutors(address[] memory trustedEVMExecutors) public onlyRole(ADMIN) {
        _trustedEVMExecutors = trustedEVMExecutors;
        emit TrustedEVMExecutorsUpdated(trustedEVMExecutors);
    }

    /**
     * @dev Get trustedEVMExecutors.
     */
    function getTrustedEVMExecutors() public view returns (address[] memory) {
        return _trustedEVMExecutors;
    }

    /**
     * @dev Update trustedTVMExecutors setting.
     * @param trustedTVMExecutors Trusted executors.
     */
    function setTrustedTVMExecutors(string[] memory trustedTVMExecutors) public onlyRole(ADMIN) {
        _trustedTVMExecutors = trustedTVMExecutors;
        emit TrustedTVMExecutorsUpdated(trustedTVMExecutors);
    }

    /**
     * @dev Get trustedTVMExecutors.
     */
    function getTrustedTVMExecutors() public view returns (string[] memory) {
        return _trustedTVMExecutors;
    }

    /**
     * @dev Update a uint64 setting.
     * @param key The setting key.
     * @param value The new value.
     */
    function setUintSetting(bytes32 key, uint64 value) public onlyRole(ADMIN) {
        _checkUintSetting(key, value);
        _uintSettings[key] = value;
        emit SettingsUpdated(key);
    }

    /**
     * @dev Get a uint64 setting.
     * @param key The setting key.
     * @return The setting value.
     */
    function getUintSetting(bytes32 key) public view returns (uint64) {
        return _uintSettings[key];
    }

    function _forbiddenChangingAddress(bytes32 key) internal view {
        if (_addressSettings[key] != address(0)) {
                revert ChangingAddressForbidden(key);
        }
    }

    function _checkAddressSetting(bytes32 key, address value) internal view {
        if (value == address(0)) {
            revert ZeroAddress(key);
        }

        if (key == SettingsConstants.CONSENSUS_ADDRESS_KEY) {
            _forbiddenChangingAddress(key);
        } else if (key == SettingsConstants.CCL_ADDRESS_KEY) {
            _forbiddenChangingAddress(key);
        } else if (key == SettingsConstants.TOKEN_UTILS_ADDRESS_KEY) {
            _forbiddenChangingAddress(key);
        } else {
            revert InvalidKey(key);
        }
    }

    /**
     * @dev Update an address setting.
     * @param key The setting key.
     * @param value The new address value.
     */
    function setAddressSetting(bytes32 key, address value) public onlyRole(ADMIN) {
        _checkAddressSetting(key, value);
        _addressSettings[key] = value;
        emit SettingsUpdated(key);
    }

    /**
     * @dev Get an address setting.
     * @param key The setting key.
     * @return The setting value.
     */
    function getAddressSetting(bytes32 key) public view returns (address) {
        return _addressSettings[key];
    }

    function _checkBoolSetting(bytes32, bool) internal pure {
        return;
    }

    /**
     * @dev Update a bool setting.
     * @param key The setting key.
     * @param value The new bool value.
     */
    function setBoolSetting(bytes32 key, bool value) public onlyRole(ADMIN) {
        _checkBoolSetting(key, value);
        _boolSettings[key] = value;
        emit SettingsUpdated(key);
    }

    /**
     * @dev Get a bool setting.
     * @param key The setting key.
     * @return The setting value.
     */
    function getBoolSetting(bytes32 key) public view returns (bool) {
        return _boolSettings[key];
    }

    function _checkStringSetting(bytes32 key, string memory) internal pure {
        if (key == SettingsConstants.NFT_PREFIX_URI_KEY) {
            return;
        } else if (key == SettingsConstants.FT_PREFIX_IMAGE_KEY) {
            return;
        } else {
            revert InvalidKey(key);
        }
    }

    /**
     * @dev Update a string setting.
     * @param key The setting key.
     * @param value The new string value.
     */
    function setStringSetting(bytes32 key, string memory value) public onlyRole(ADMIN) {
        _checkStringSetting(key, value);
        _stringSettings[key] = value;
        emit SettingsUpdated(key);
    }

    /**
     * @dev Get a string setting.
     * @param key The setting key.
     * @return The setting value.
     */
    function getStringSetting(bytes32 key) public view returns (string memory) {
        return _stringSettings[key];
    }

}
