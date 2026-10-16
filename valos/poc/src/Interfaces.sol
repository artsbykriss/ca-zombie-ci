// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Minimal interfaces for the Valos deployment on Monad (read-only fork calls).

interface IVault {
    function permissionLevel() external view returns (uint8);
    function precision() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function totalQueuedShares() external view returns (uint256);
    function reservedLiquidity() external view returns (uint256);
    function queue() external view returns (uint128, uint128);
    function sharePrice() external view returns (uint256);
    function assetShareRatio() external view returns (uint256);
    function asset() external view returns (address);
    function strategy() external view returns (address);
    function transferableShares() external view returns (bool);
    function allowed(address) external view returns (bool);
    function balanceOf(address) external view returns (uint256);
    function maxWithdraw(address) external view returns (uint256);
    function maxRedeem(address) external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
    function convertToShares(uint256) external view returns (uint256);
    function pendingRedeemRequest(uint256, address) external view returns (uint256);
    function deposit(uint256, address) external returns (uint256);
    function mint(uint256, address) external returns (uint256);
    function requestRedeem(uint256, address, address) external returns (uint256);
    function redeem(uint256, address, address) external returns (uint256);
    function withdraw(uint256, address, address) external returns (uint256);
    function cancelRedeemRequest(address, address) external;
    function transfer(address, uint256) external returns (bool);
    function setAllowed(address[] calldata, bool[] calldata) external;
}

interface IStrategy {
    function loanState() external view returns (uint8);
    function paused() external view returns (bool);
    function scaleFactor() external view returns (uint256);
    function netPrincipal() external view returns (uint256);
    function sharePrice(address) external view returns (uint256);
    function accruedAssets(address) external view returns (uint256);
    function maxDeposit(address, address) external view returns (uint256);
    function borrower() external view returns (address);
    function investmentManager() external view returns (address);
    function accrueInterest() external returns (uint256);
    function updateLateStatus() external;
    function processAvailableWithdrawals() external returns (uint256);
    function acceptDefault() external;
    function borrow(uint256) external;
    function setLenders(address[] calldata, bool[] calldata) external;
    function onRequestRedeem(address, uint256, address, address) external returns (bool, uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
}

error Unauthorized();
error TimelockNotExpired();
