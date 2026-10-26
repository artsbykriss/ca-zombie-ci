// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

interface ISturdyPair {
    function borrowAsset(uint256 _borrowAmount, uint256 _collateralAmount, address _receiver)
        external returns (uint256 _shares);
    function addCollateral(uint256 _collateralAmount, address _borrower) external;
    function updateExchangeRate() external returns (bool, uint256, uint256);
    function exchangeRateInfo()
        external view returns (address oracle, uint32 maxOracleDeviation, uint184 lastTimestamp,
                              uint256 lowExchangeRate, uint256 highExchangeRate);
    function maxLTV() external view returns (uint256);
    function totalAsset() external view returns (uint128 amount, uint128 shares);
    function totalBorrow() external view returns (uint128 amount, uint128 shares);
    function totalCollateral() external view returns (uint256);
    function asset() external view returns (address);
    function collateralContract() external view returns (address);
    function borrowLimit() external view returns (uint256);
    function isLiquidatePaused() external view returns (bool);
}

interface IDualOracle {
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IYearnVault {
    function pricePerShare() external view returns (uint256);
    function token() external view returns (address);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);
}

interface IAggregatorV3 {
    function latestRoundData()
        external view returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
}

interface ISturdyDataProvider {
    struct PairData {
        address asset;
        string assetSymbol;
        uint256 assetDecimals;
        address collateral;
        string collateralSymbol;
        uint256 collateralDecimals;
        address rateContract;
        address oracle;
        uint256 depositLimit;
        uint64 ratePerSec;
        uint64 fullUtilizationRate;
        uint32 feeToProtocolRate;
        uint32 maxOacleDeviation;
        uint256 lowExchangeRate;
        uint256 highExchangeRate;
        uint256 maxLTV;
        uint256 protocolLiquidationFee;
        uint256 totalAsset;
        uint256 totalCollateral;
        uint256 totalBorrow;
        uint256 version;
    }
    struct Strategy {
        address deployedAt;
        address pair;
        PairData pairData;
    }
    function getStrategies() external view returns (Strategy[] memory);
}
