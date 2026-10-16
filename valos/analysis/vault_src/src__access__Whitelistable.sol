// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import {IWhitelistable} from "../interfaces/IAccess.sol";

import {ArrayLengthMismatch} from "../constants/Errors.sol";

/// @title Whitelistable - A contract that allows whitelisting of accounts
/// @notice This contract is used to allow/disallow account access
/// @dev See IWhitelistable for detailed interface documentation
/// @custom:security-contact security@accountable.capital
abstract contract Whitelistable is IWhitelistable {
    /// @notice Mapping to track the allowed status of accounts
    /// @dev Maps an account address to its allowed status
    mapping(address account => bool allowed) public allowed;

    /// @inheritdoc IWhitelistable
    function setAllowed(address[] calldata accounts, bool[] calldata statuses) public virtual {
        if (accounts.length != statuses.length) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < accounts.length;) {
            allowed[accounts[i]] = statuses[i];
            emit AllowedSet(accounts[i], statuses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function allowedMany(address[] memory accounts) public view returns (bool) {
        for (uint256 i = 0; i < accounts.length;) {
            if (!allowed[accounts[i]]) return false;
            unchecked {
                ++i;
            }
        }
        return true;
    }
}
