// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

interface IEtherexGauge {
    /// @notice Get the amount of stakingToken deposited by an account
    function balanceOf(address) external view returns (uint256);

    /// @notice returns an array with all the addresses of the rewards
    /// @return _rewards array of addresses for rewards
    function rewardsList() external view returns (address[] memory _rewards);

    /// @notice number of different rewards the gauge has facilitated that are 'active'
    /// @return _length the number of individual rewards
    function rewardsListLength() external view returns (uint256 _length);

    /// @notice claims rewards (shadow + any external LP Incentives)
    /// @param account the address to claim for
    /// @param tokens an array of the tokens to claim
    function getReward(address account, address[] calldata tokens) external;

    /// @notice deposit LP tokens to the gauge
    /// @param amount the amount of LP tokens to withdraw
    function deposit(uint256 amount) external;

    /// @notice withdraws all fungible LP tokens from legacy gauges
    function withdrawAll() external;

    /// @notice withdraws fungible LP tokens from legacy gauges
    /// @param amount the amount of LP tokens to withdraw
    function withdraw(uint256 amount) external;
}