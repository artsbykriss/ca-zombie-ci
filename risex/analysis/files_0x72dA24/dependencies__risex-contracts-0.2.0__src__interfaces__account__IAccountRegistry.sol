// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29;

/// @title IAccountRegistry
/// @notice Maps addresses to compact uint32 user IDs for storage-efficient order books.
/// @dev User ID 0 is reserved as the "unregistered" sentinel. The first registered account gets ID 1.
interface IAccountRegistry {
    /// @notice Thrown when attempting to register an already-registered account
    error AlreadyRegistered(address account);

    /// @notice Thrown when looking up an address that has no registered userId
    error AccountNotRegistered(address account);

    /// @notice Thrown when looking up a userId that has no registered address
    error UserIdNotRegistered(uint32 userId);

    /// @notice Emitted when a new account is registered
    event AccountRegistered(address indexed account, uint32 indexed userId);

    /// @notice Registers the account if not yet registered; returns its userId
    /// @dev Access restricted via AccessManager (`restricted` modifier)
    /// @param account The address to register
    /// @return userId The assigned (or existing) user ID
    function getOrRegister(
        address account
    ) external returns (uint32 userId);

    /// @notice Returns the userId for an address; reverts if unregistered
    /// @param account The address to look up
    /// @return The userId
    function getUserId(
        address account
    ) external view returns (uint32);

    /// @notice Returns the address for a userId; reverts if invalid
    /// @param userId The user ID to look up
    /// @return The address
    function getAddress(
        uint32 userId
    ) external view returns (address);

    /// @notice Returns the current number of registered accounts
    /// @return The total count of registered accounts
    function getTotalAccounts() external view returns (uint32);
}
