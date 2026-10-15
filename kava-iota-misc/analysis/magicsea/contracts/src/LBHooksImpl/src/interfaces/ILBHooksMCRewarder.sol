// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMasterChef} from "./IMasterChef_flat.sol";

import {LBHooksBaseParentRewarder, LBHooksBaseRewarder} from "lb-rewarder/LBHooksBaseParentRewarder.sol";
import {ILBHooksBaseRewarder} from "lb-rewarder/interfaces/ILBHooksBaseRewarder.sol";
import {ILBHooksExtraRewarder} from "lb-rewarder/interfaces/ILBHooksExtraRewarder.sol";

/**
 * @title LB Hooks Rewarder Interface
 * @dev Interface for the LB Hooks Rewarder
 */
interface ILBHooksMCRewarder is ILBHooksBaseRewarder {
    function getPid() external view returns (uint256 pid);

    function getMasterChef() external view returns (IMasterChef masterChef);
}
