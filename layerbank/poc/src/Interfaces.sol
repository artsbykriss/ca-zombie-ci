// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
}

/// @dev LayerBank Pool is a stock Aave-v3 Pool behind an EIP-1967 proxy.
/// `getReserveData` returns the 15-field ReserveData struct (each field ABI-padded).
interface IPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function getUserAccountData(address user)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256);
    function getReservesList() external view returns (address[] memory);
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 configuration,
            uint128 liquidityIndex,
            uint128 currentLiquidityRate,
            uint128 variableBorrowIndex,
            uint128 currentVariableBorrowRate,
            uint128 currentStableBorrowRate,
            uint40 lastUpdateTimestamp,
            uint16 id,
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,
            address interestRateStrategyAddress,
            uint128 accruedToTreasury,
            uint128 unbacked,
            uint128 isolationModeTotalDebt
        );
    function ADDRESSES_PROVIDER() external view returns (address);
}

/// @dev Stock AaveOracle: `getAssetPrice` -> `latestAnswer()` with NO `updatedAt` check.
interface IOracle {
    function getAssetPrice(address asset) external view returns (uint256);
    function getSourceOfAsset(address asset) external view returns (address);
    function BASE_CURRENCY_UNIT() external view returns (uint256);
    function setAssetSources(address[] calldata assets, address[] calldata sources) external;
}

interface IAggregator {
    function latestAnswer() external view returns (int256);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
}

interface IPoolAddressesProvider {
    function getPriceOracle() external view returns (address);
    function getACLAdmin() external view returns (address);
    function getACLManager() external view returns (address);
    function owner() external view returns (address);
}

interface IACLManager {
    function isPoolAdmin(address) external view returns (bool);
}
