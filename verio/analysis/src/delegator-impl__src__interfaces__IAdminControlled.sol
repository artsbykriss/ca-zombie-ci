// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IAdminControlled {
    /// @custom:storage-location erc7201:VerioIP.AdminControlled.AdminState
    struct AdminState {
        address admin;
    }

    /// @notice Event emitted when the admin is updated
    /// @param admin The new admin address
    event AdminUpdated(address indexed admin);

    /// @notice Error when caller is not the admin
    /// @param admin The admin address
    error OnlyAdmin(address admin);

    /// @notice Get the current admin address
    /// @return The admin address
    function getAdmin() external view returns (address);

    /// @notice Set the admin address
    /// @param _admin The new admin address
    function setAdmin(address _admin) external;
}
