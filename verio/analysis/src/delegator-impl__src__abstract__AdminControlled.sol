// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../interfaces/IAdminControlled.sol";

abstract contract AdminControlled is IAdminControlled {
    // --- STATE ---

    // keccak256(abi.encode(uint256(keccak256("VerioIP.AdminControlled.AdminState")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant ADMIN_STATE = 0xaf6a715e63be8cbe109eb551e464a046f209a5b42fdc8f5aad7f42a6ad721100;

    function _adminState() internal pure returns (AdminState storage $) {
        assembly {
            $.slot := ADMIN_STATE
        }
    }

    // --- MODIFIERS ---

    modifier onlyAdmin() {
        address admin = _adminState().admin;
        require(msg.sender == admin, OnlyAdmin(admin));
        _;
    }

    // --- GETTERS ---

    /// @inheritdoc IAdminControlled
    function getAdmin() external view returns (address) {
        return _adminState().admin;
    }
}
