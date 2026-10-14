// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrintrPrinting } from "./printr/IPrintrPrinting.sol";
import { IPrintrStorage } from "./printr/IPrintrStorage.sol";
import { IPrintrTrading } from "./printr/IPrintrTrading.sol";

/**
 * @title IPrintrCore
 * @notice Comprehensive interface combining all Printr protocol functionality
 * @dev Aggregates specialized interfaces for storage, printing, trading, cross-chain, and admin features
 *
 * Components:
 * - IPrintrStorage: Core storage and state management
 * - IPrintrPrinting: Token printing and curve management
 * - IPrintrTrading: Token trading and price calculations
 */
interface IPrintrCore is IPrintrStorage, IPrintrPrinting, IPrintrTrading { }
