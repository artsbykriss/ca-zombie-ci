// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAggregatorV3 {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
}

interface IOracleRouter {
    function priceUSD(address asset) external view returns (uint256 pxWad);
    function priceFeed(address asset)
        external
        view
        returns (
            address agg,
            uint256 lastGoodPriceWad,
            uint32 heartbeat,
            uint16 deviationBps,
            bool enabled,
            bool fallbackOnStale
        );
}

interface IConfigRegistry {
    struct AssetCfg {
        address irm;
        uint16 mmBps;
        bool enabled;
        address ftYieldWrapper;
        bool borrowable;
        bool collateral;
    }

    function getAssetCfg(address asset) external view returns (AssetCfg memory);
    function oracleRouter() external view returns (address);
    function marginHfSafeBps() external view returns (uint16);
    function marginHfTargetBps() external view returns (uint16);
}

interface IPositionsManager {
    function config() external view returns (address);
    function valuesLens() external view returns (address);
    function deposit(address asset, uint256 amt) external;
    function borrow(address asset, uint256 amt) external;
    function withdraw(address asset, uint256 amt) external;
    function getBalance(address user, address token) external view returns (uint256 avail, uint256 hold);
    function astate(address asset)
        external
        view
        returns (
            uint256 borrowIndexWad,
            uint256 cash,
            uint256 borrows,
            uint256 totalSupplied,
            uint256 reserves,
            uint256 totalSuppliedTime,
            uint40 lastAccrual,
            uint32 epoch
        );
}

interface IValuesLens {
    struct AccountSnapshot {
        uint256 equityUSDWad;
        uint256 maintUSDWad;
        uint256 pnlAdjCollUSDWad;
        uint256 collUSDWad;
        uint256 debtUSDWad;
        int256 enginePnLUSDWad;
    }

    function accountValues(address pm, address user) external view returns (AccountSnapshot memory);
}

interface IERC4626Like {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalIdle() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
}
