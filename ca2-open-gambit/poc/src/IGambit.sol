// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

interface IGambitVault {
    function buyUSDG(address token, address receiver) external returns (uint256);
    function sellUSDG(address token, address receiver) external returns (uint256);
    function getRedemptionAmount(address token, uint256 usdgAmount) external view returns (uint256);
    function poolAmounts(address) external view returns (uint256);
    function feeReserves(address) external view returns (uint256);
    function stableTokens(address) external view returns (bool);
    function whitelistedTokens(address) external view returns (bool);
    function getMaxPrice(address) external view returns (uint256);
    function getMinPrice(address) external view returns (uint256);
    function isMintingEnabled() external view returns (bool);
    function gov() external view returns (address);
}

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
    function totalSupply() external view returns (uint256);
}

interface IGmxMigrator {
    function whitelistedTokens(address) external view returns (bool);
    function isMigrationActive() external view returns (bool);
    function admin() external view returns (address);
    function minAuthorizations() external view returns (uint256);
    function migrate(address token, uint256 amount) external;
}
