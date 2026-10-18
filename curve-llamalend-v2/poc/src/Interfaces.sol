// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVault {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
    function asset() external view returns (address);
    function controller() external view returns (address);
    function amm() external view returns (address);
}

interface IController {
    function total_debt() external view returns (uint256);
    function available_balance() external view returns (uint256);
    function admin_fees() external view returns (uint256);
    function n_loans() external view returns (uint256);
    function loans(uint256) external view returns (address);
    function health(address user, bool full) external view returns (int256);
    function debt(address user) external view returns (uint256);
    function liquidate(address user, uint256 min_x, uint256 frac) external;
    function borrowed_token() external view returns (address);
    function vault() external view returns (address);
    function liquidation_discount() external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IOracle {
    function price() external view returns (uint256);
}
