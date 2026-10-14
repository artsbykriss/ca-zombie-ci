// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// Minimal interfaces for the live Printr deployment (Ethereum mainnet).
/// Selectors verified on-chain 2026-10-14 (block ~26.19M).

interface IPrintrLike {
    function treasury() external view returns (address);
    function legacyTreasury() external view returns (address);
    function wrappedNativeToken() external view returns (address);
    function tradingFee() external view returns (uint16);
    function paused() external view returns (bool);
    function owner() external view returns (address);
}

interface ITreasuryLike {
    function withdraw(address token, address recipient, uint256 amount) external;
    function printr() external view returns (address);
    function collectLiquidityFees(address liquidityModule, uint256 lockId, address token, address basePair, address recipient) external;
}

interface IERC20Like {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}
