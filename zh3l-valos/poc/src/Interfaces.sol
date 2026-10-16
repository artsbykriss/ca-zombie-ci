// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function transfer(address, uint256) external returns (bool);
}

interface IAccountableVault {
    error Unauthorized();
    function permissionLevel() external view returns (uint8);
    function allowed(address) external view returns (bool);
    function strategy() external view returns (address);
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function sharePrice() external view returns (uint256);
    function precision() external view returns (uint256);
    function transferableShares() external view returns (bool);
    function totalQueuedShares() external view returns (uint256);
    function reservedLiquidity() external view returns (uint256);
    function deposit(uint256 assets, address receiver, address controller) external returns (uint256);
    function mint(uint256 shares, address receiver, address controller) external returns (uint256);
    function requestRedeem(uint256 shares, address controller, address owner) external returns (uint256);
    function redeem(uint256 shares, address receiver, address controller) external returns (uint256);
    function withdraw(uint256 assets, address receiver, address controller) external returns (uint256);
    function cancelRedeemRequest(address controller, address receiver) external;
    function getState(address controller)
        external
        view
        returns (uint256 pendingRedeemRequest, uint256 maxWithdraw, uint256 redeemShares, uint256 redeemPrice, uint256 withdrawPrice);
}

interface IStrategy {
    function permissionLevel() external view returns (uint8);
    function vault() external view returns (address);
    function dvnPublisher() external view returns (address);
    function loanState() external view returns (uint8);
    function paused() external view returns (bool);
    function sharePrice(address) external view returns (uint256);
    function netPrincipal() external view returns (uint256);
    function scaleFactor() external view returns (uint256);
    function accruedAssets(address) external view returns (uint256);
    function onDeposit(address share, uint256 assets, address, address) external returns (uint256);
    function onMint(address share, uint256 shares, address, address) external returns (uint256);
    function onRequestRedeem(address share, uint256 shares, address controller, address)
        external
        returns (bool, uint256);
    function proposeInterestRate(uint256 interestRate) external;
    function publishRate(uint256 newRate, uint256) external;
    function processAvailableWithdrawals() external returns (uint256);
    function accrueInterest() external returns (uint256);
    function updateLateStatus() external;
}
