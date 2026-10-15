// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// Minimal interfaces for the Liquid Driver live-state / extraction tests.
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IMasterChefV1 {
    function poolLength() external view returns (uint256);
    function poolInfo(uint256) external view returns (address, uint256, uint256, uint256, uint16);
    function userInfo(uint256, address) external view returns (uint256, uint256);
    function lqdr() external view returns (address);
    function devaddr() external view returns (address);
    function feeAddress() external view returns (address);
    function lqdrPerBlock() external view returns (uint256);
    function deposit(uint256, uint256) external;
    function withdraw(uint256, uint256) external;
    function emergencyWithdraw(uint256) external;
    function pendingLqdr(uint256, address) external view returns (uint256);
    function owner() external view returns (address);
}

interface IMiniChefV2 {
    function poolLength() external view returns (uint256);
    function lpToken(uint256) external view returns (address);
    function strategies(uint256) external view returns (address);
    function userInfo(uint256, address) external view returns (uint256, int256);
    function deposit(uint256, uint256, address) external;
    function withdraw(uint256, uint256, address) external;
    function withdrawAndHarvest(uint256, uint256, address) external;
    function emergencyWithdraw(uint256, address) external;
    function harvest(uint256, address) external;
    function pendingLqdr(uint256, address) external view returns (uint256);
    function massHarvestFromStrategies() external;
    function owner() external view returns (address);
}

interface IStrategy {
    function want() external view returns (address);
    function balanceOf() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function depositor() external view returns (address);
    function governance() external view returns (address);
    function harvesters(address) external view returns (bool);
    function harvest() external;
    function deposit() external;
    function withdraw(uint256) external;
    function withdrawAll() external;
}

interface IVotingEscrow {
    function token() external view returns (address);
    function supply() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function admin() external view returns (address);
    function locked(address) external view returns (int128, uint256);
    function withdraw() external;
}

interface IUniV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
}
