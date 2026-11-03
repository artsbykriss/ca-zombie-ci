// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IPool {
    struct PositionKey {
        address owner;
        address operator;
        uint256 lower;
        uint256 upper;
        uint8 orderType; // 0 CSUP, 1 CS, 2 LC
    }

    struct Delta {
        int256 collateral;
        int256 longs;
        int256 shorts;
    }

    function deposit(
        PositionKey calldata p,
        uint256 belowLower,
        uint256 belowUpper,
        uint256 size,
        uint256 minMarketPrice,
        uint256 maxMarketPrice
    ) external returns (Delta memory);

    function deposit(
        PositionKey calldata p,
        uint256 belowLower,
        uint256 belowUpper,
        uint256 size,
        uint256 minMarketPrice,
        uint256 maxMarketPrice,
        bool isBidIfStrandedMarketPrice
    ) external returns (Delta memory);

    function withdraw(
        PositionKey calldata p,
        uint256 size,
        uint256 minMarketPrice,
        uint256 maxMarketPrice
    ) external returns (Delta memory);

    function trade(
        uint256 size,
        bool isBuy,
        uint256 premiumLimit,
        address referrer
    ) external returns (uint256 totalPremium, Delta memory delta);

    function settle() external returns (uint256 collateral);

    function getPoolSettings()
        external
        view
        returns (address base, address quote, address oracle, uint256 strike, uint256 maturity, bool isCall);

    function marketPrice() external view returns (uint256);

    function getNearestTicksBelow(uint256 lower, uint256 upper) external view returns (uint256, uint256);

    function balanceOf(address, uint256) external view returns (uint256);
}

interface IVault {
    struct PoolKey {
        address base;
        address quote;
        address oracleAdapter;
        uint256 strike;
        uint256 maturity;
        bool isCallPool;
    }

    function trade(
        PoolKey calldata poolKey,
        uint256 size,
        bool isBuy,
        uint256 premiumLimit,
        address referrer
    ) external;

    function getSettings() external view returns (bytes memory);

    function asset() external view returns (address);

    function totalAssets() external view returns (uint256);
}

interface IVaultRegistry {
    struct VaultInfo {
        address vault;
        address asset;
        bytes32 vaultType;
        uint8 side;
        uint8 optionType;
    }

    function getNumberOfVaults() external view returns (uint256);

    function getVaults() external view returns (VaultInfo[] memory);
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

    function deployPool(PoolKey calldata k) external payable returns (address);
    function getPoolAddress(PoolKey calldata k) external view returns (address pool, bool isDeployed);
    function isPool(address) external view returns (bool);
}
