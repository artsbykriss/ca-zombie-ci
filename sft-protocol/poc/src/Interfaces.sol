// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
}

/// SFT Protocol lending pool / rSFT share token (TransparentUpgradeableProxy)
interface ILendingPool {
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function sftToken() external view returns (address);
    function rewardContract() external view returns (address);
    function distributor() external view returns (address);
    function redeemPool() external view returns (address);
    function totalPooledFIL() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function sharesOf(address) external view returns (uint256);
    function getUtilizationRate() external view returns (uint256);
    function borrowThreshold() external view returns (uint256);
    function ltv() external view returns (uint256);
    function slope1() external view returns (uint256);
    function startTime() external view returns (uint256);
    function paused() external view returns (bool);

    function deposit() external payable;
    function withdraw(uint256 shares) external;
    function borrow(uint256 orderId, uint256 amount) external;
    function repay(uint256 amount) external;
    function pledge(address user, uint256 arg1, uint256 arg2, uint256 arg3) external;
    function distributeReward(uint256 amount) external;
    function rescueTokens(address token, address to, uint256 amount) external;

    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferShares(address, uint256) external;
}

/// SFT Protocol reward pool / farm (TransparentUpgradeableProxy)
interface IRewardPool {
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function distributor() external view returns (address);
    function sftToken() external view returns (address);

    function stake(uint256 poolId, uint256 amount) external;
    function unstake(uint256 poolId, uint256 orderIndex, uint256 amount) external;
    function batchClaim(uint256[] calldata a, uint256[] calldata b, uint256[] calldata c) external;
    function renewStake(uint256 poolId, uint256 arg1) external;
    function deposit() external payable;
    function withdraw(uint256 amount) external;

    function balanceOf(address) external view returns (uint256);
}

/// SFT Protocol mint/withdraw (swap) pool
interface IMintPool {
    function owner() external view returns (address);
    function oracle() external view returns (address);
    function paused() external view returns (bool);
    function sftToken() external view returns (address);
    function rewardContract() external view returns (address);
    function deposit() external payable;
    function swapFil(uint256 amount) external;
    function borrowLiquidity(uint256 amount) external;
    function pause() external;
    function unpause() external;
}
