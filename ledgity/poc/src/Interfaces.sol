// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IVault {
  function totalAssets() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function getFeeData() external view returns (uint256 feeShares, uint256 pricePerShare);
  function harvestFees() external;
  function updateFeeRates(uint256, uint256, uint256) external;
  function processRequests(uint256[] calldata requestIds, uint256 addAssets) external;
  function burnAndRemintBlacklistedShares(address burnFrom, address remintTo) external;
  function deposit(uint256 assets, address receiver) external returns (uint256);
  function requestWithdrawal(uint256 shares) external payable;
  function liquidityManager() external view returns (address);
  function owner() external view returns (address);
  function lastFeeTime() external view returns (uint256);
  function managementFeeRate() external view returns (uint256);
  function performanceFeeRate() external view returns (uint256);
  function getWithdrawalRequestCount() external view returns (uint256);
  function withdrawalRequests(uint256) external view returns (address user, uint256 amount, uint256 timestamp, bool processed);
  function getBufferAssets() external view returns (uint256);
  function RAY() external view returns (uint256);
  function paused() external view returns (bool);
  function asset() external view returns (address);
}

interface IERC20 {
  function balanceOf(address) external view returns (uint256);
  function approve(address, uint256) external returns (bool);
  function decimals() external view returns (uint8);
}
