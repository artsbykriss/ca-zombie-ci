// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrintrStorage } from "./printr/IPrintrStorage.sol";
import { IPrintrTeleport } from "./printr/IPrintrTeleport.sol";

/**
 * @title Teleport Interface
 * @notice Interface for cross-chain operations
 * @dev Aggregates specialized interfaces for teleport functionality
 *
 * Components:
 * - IPrintrStorage: Core storage and state management
 * - IPrintrTeleport: LayerZero teleport functionality for cross-chain operations
 *
 * Note: Owner functions, trading, and fee distribution are handled by Module via fallback delegation
 */
interface ITeleport is IPrintrStorage, IPrintrTeleport { }
