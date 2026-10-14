// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPrintrFeeDistribution } from "./printr/IPrintrFeeDistribution.sol";
import { IPrintrGetters } from "./printr/IPrintrGetters.sol";
import { IPrintrOwner } from "./printr/IPrintrOwner.sol";
import { IPrintrQuoting } from "./printr/IPrintrQuoting.sol";
import { IPrintrStorage } from "./printr/IPrintrStorage.sol";

/**
 * @title Module Interface
 * @notice Interface for getter, fee distribution, quoting, and owner functionality
 * @dev Combines IPrintrGetters, IPrintrFeeDistribution, IPrintrQuoting, and IPrintrOwner
 *      for the Module implementation contract
 */
interface IModule is IPrintrStorage, IPrintrGetters, IPrintrFeeDistribution, IPrintrQuoting, IPrintrOwner { }
