// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimal interface required by GFangRewardPoolV4; check the chosen deployment's ABI before enabling its gauge.
interface IAlandaleGauge {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
    function rewardsList() external view returns (address[] memory);
    function getReward(address account, address[] calldata tokens) external;
}
