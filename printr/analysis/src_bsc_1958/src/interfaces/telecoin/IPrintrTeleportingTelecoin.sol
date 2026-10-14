// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrinted } from "./IPrinted.sol";
import { ITeleportingTelecoin } from "./ITeleporting.sol";

/**
 * @title IPrintrTeleportingTelecoin
 * @notice Interface for the PrintrTelecoin contract with teleport and curve completion functionality
 * @dev Extends ITelecoin interface with additional token management functions
 */
interface IPrintrTeleportingTelecoin is IPrinted, ITeleportingTelecoin { }
