// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../../library/SemanticVersion.sol";

/// @title Versionable Interface
/// @notice Interface for managing the version of a contract
interface IVersionable {
    /// @notice Version structure
    /// @param v The version of the deployed implementation
    /// @param t The timestamp of the version
    /// @custom:storage-location erc7201:VerioIP.Component.Version
    struct Version {
        SemanticVersion.V v;
        uint256 t;
    }

    /// @notice Event emitted when the version is updated
    /// @param version The new version
    event VersionUpdated(string indexed version);

    /// @notice Error when the version is invalid
    error InvalidVersion();

    /// @notice Gets the version of the deployed implementation
    function getVersion() external view returns (string memory);

    /// @notice Sets the version of the deployed implementation
    /// @param _nextVersion The version of the deployed implementation
    function setVersion(string calldata _nextVersion) external;
}
