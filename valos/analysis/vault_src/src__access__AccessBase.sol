// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IAccess, PermissionLevel} from "../interfaces/IAccess.sol";

import {Whitelistable} from "./Whitelistable.sol";
import {Authorizable} from "./Authorizable.sol";

/// @title AccessBase - A base contract for access control extending Whitelistable and Authorizable
/// @notice This contract is used to gate access to callable/interactable contracts
/// @dev See IAccess for detailed interface documentation
/// @custom:security-contact security@accountable.capital
abstract contract AccessBase is IAccess, Whitelistable, Authorizable {
    /// @inheritdoc IAccess
    PermissionLevel public permissionLevel;

    /// @notice Constructor
    /// @param permissionLevel_ The permission level for the contract
    constructor(PermissionLevel permissionLevel_) {
        permissionLevel = permissionLevel_;
    }

    function _isVerified(address account, bytes calldata msgData) internal returns (bool) {
        PermissionLevel _permission = permissionLevel;

        if (_permission == PermissionLevel.KYC) return _verify(account, msgData);

        if (_permission == PermissionLevel.Whitelist) return allowed[account];

        return true;
    }

    function _areVerified(address[] memory accounts, bytes calldata msgData) internal returns (bool) {
        PermissionLevel _permission = permissionLevel;

        if (_permission == PermissionLevel.KYC) return _verifyMany(accounts, msgData);

        if (_permission == PermissionLevel.Whitelist) return allowedMany(accounts);

        return true;
    }
}
