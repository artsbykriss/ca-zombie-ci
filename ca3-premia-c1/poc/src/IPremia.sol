// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IPool {
    error Pool__InsufficientFunds();

    function balanceOf(address, uint256) external view returns (uint256);
    function settle() external returns (uint256);
}

interface IPoolFactory {
    struct PoolKey {
        address base;
        address quote;
        address oracleAdapter;
        uint256 strike;
        uint256 maturity;
        bool isCallPool;
    }

    function getPoolAddress(PoolKey calldata k) external view returns (address pool, bool isDeployed);
    function deployPool(PoolKey calldata k) external payable returns (address poolAddress);
}

interface IVault {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function getImplementation() external view returns (address);
    function settle() external;
    function trade(
        IPoolFactory.PoolKey calldata poolKey,
        uint256 size,
        bool isBuy,
        uint256 premiumLimit,
        address referrer
    ) external;
    function getQuote(
        IPoolFactory.PoolKey calldata poolKey,
        uint256 size,
        bool isBuy,
        address taker
    ) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);
}

interface IOracleAdapter {
    function getPriceAt(address base, address quote, uint256 target) external view returns (uint256);
}
