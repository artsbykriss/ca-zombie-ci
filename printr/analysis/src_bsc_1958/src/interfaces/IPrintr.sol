// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IModule } from "./IModule.sol";
import { IPrintrCore } from "./IPrintrCore.sol";
import { ITeleport } from "./ITeleport.sol";

/**
 * @title IPrintr
 * @notice Master interface combining all Printr protocol functionality
 * @dev Aggregates implementation, teleport, and module interfaces for complete protocol access
 *
 * Components:
 * - IPrintrCore: Core implementation interfaces (storage, printing, trading)
 * - ITeleport: Teleport interfaces (interchain, teleport)
 * - IModule: Module interfaces (getters, fee distribution, owner) - accessed via fallback delegation
 */
interface IPrintr is IPrintrCore, ITeleport, IModule { }
