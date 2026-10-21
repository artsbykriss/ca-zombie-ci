// SPDX-License-Identifier: MIT
pragma solidity >=0.8.29 <0.9.0;

import { IAccessManaged } from "@openzeppelin/contracts/access/manager/IAccessManaged.sol";

/// @title IPartialPauseManaged
/// @notice Interface for per-function pausing with AccessManaged integration
interface IPartialPauseManaged is IAccessManaged {
    /// @notice Emitted when a function selector is paused
    event PausedFunction(address indexed by, bytes4 indexed selector);

    /// @notice Emitted when a function selector is unpaused
    event UnpausedFunction(address indexed by, bytes4 indexed selector);

    /// @notice Thrown when calling a paused function
    error EnforcedPauseFunction(bytes4 selector);

    /// @notice Thrown when trying to unpause a non-paused function
    error ExpectedPauseFunction(bytes4 selector);

    /// @notice Thrown when attempting to pause/unpause an invalid selector
    error InvalidSelector(bytes4 selector);

    /// @notice Pause a specific function (restricted)
    /// @param selector The function selector to pause
    function pauseFunction(
        bytes4 selector
    ) external;

    /// @notice Unpause a specific function (restricted)
    /// @param selector The function selector to unpause
    function unpauseFunction(
        bytes4 selector
    ) external;

    /// @notice Check if a function is paused (or global pause is active)
    /// @param selector The function selector to check
    /// @return True if paused
    function pausedFunction(
        bytes4 selector
    ) external view returns (bool);

    /// @notice Pause the entire contract (restricted)
    function pause() external;

    /// @notice Unpause the entire contract (restricted)
    function unpause() external;
}
