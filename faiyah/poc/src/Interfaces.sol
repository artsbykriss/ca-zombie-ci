// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IFaiyahFactory {
    function idCounter() external view returns (uint256);
    function allPools(uint256 i) external view returns (address);
    function poolImplementation() external view returns (address);
    function stake(address pool, uint256 amount) external;
    function unstake(address pool, uint256 stakeId) external;
    function claimReward(address pool, uint256 stakeId) external;
    function depositReward(address pool, uint256 amount) external;
    function setPoolImplementation(address impl) external;
}

interface IFaiyahPool {
    function totalStaked() external view returns (uint256);
    function totalReward() external view returns (uint256);
    function rewardDebtTotal() external view returns (uint256);
    function apr() external view returns (uint256);
    function claimDelay() external view returns (uint256);
    function unstakeDelay() external view returns (uint256);
    function interestDelay() external view returns (uint256);
    function interestTime() external view returns (uint256);
    function startTime() external view returns (uint256);
    function endTime() external view returns (uint256);
    function stakingToken() external view returns (address);
    function rewardToken() external view returns (address);
    function stakingTokenDecimals() external view returns (uint8);
    function rewardTokenDecimals() external view returns (uint8);
    function status() external view returns (uint8);
    function paused() external view returns (bool);
    function nextStakeId() external view returns (uint256);
    function ownerPool() external view returns (address);
    function factory() external view returns (address);

    function stakes(uint256 id)
        external
        view
        returns (address owner, uint256 amount, uint256 stime, uint256 claimed, uint256 settled);

    function claimableReward(uint256 id) external view returns (bool claimableNow, uint256 amount);

    function stake(address user, uint256 amount) external;
    function unstake(address user, uint256 id) external;
    function claimReward(address user, uint256 id) external;
    function emergencyClose() external;
    function emergencyWithdrawStakingToken(address[] calldata tokens, uint256[] calldata amounts) external;
    function emergencyWithdrawRewardToken(address[] calldata tokens, uint256[] calldata amounts) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}
