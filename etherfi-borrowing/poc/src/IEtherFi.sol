// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Minimal interfaces for the ether.fi Cash Aave V4 instance (Optimism)
/// @notice Read-only research interfaces. No privileged entry points are exercised.

interface ISpoke {
    struct UserAccountData {
        uint256 riskPremium;
        uint256 avgCollateralFactor;
        uint256 healthFactor;
        uint256 totalCollateralValue;
        uint256 totalDebtValueRay;
        uint256 activeCollateralCount;
        uint256 borrowCount;
    }

    function borrow(uint256 reserveId, uint256 amount, address onBehalfOf) external returns (uint256, uint256);
    function supply(uint256 reserveId, uint256 amount, address onBehalfOf) external returns (uint256, uint256);
    function setUsingAsCollateral(uint256 reserveId, bool usingAsCollateral, address onBehalfOf) external;
    function liquidationCall(
        uint256 collateralReserveId,
        uint256 debtReserveId,
        address user,
        uint256 debtToCover,
        bool receiveShares
    ) external;
    function isPositionManagerActive(address positionManager) external view returns (bool);
    function isPositionManager(address user, address positionManager) external view returns (bool);
    function getUserAccountData(address user) external returns (UserAccountData memory);
    function getUserDebt(uint256 reserveId, address user) external view returns (uint256, uint256);
    function getUserSuppliedAssets(uint256 reserveId, address user) external view returns (uint256);
    function getReserveCount() external view returns (uint256);
    function ORACLE() external view returns (address);
    function authority() external view returns (address);
}

interface IEtherFiDataProvider {
    function isEtherFiSafe(address account) external view returns (bool);
    function getCashModule() external view returns (address);
}

interface ILendGateway {
    function borrow(address safe, address asset, uint256 amount, address to) external;
    function isDriver(address account) external view returns (bool);
    function minHealthFactor() external view returns (uint256);
    function roleRegistry() external view returns (address);
}

interface IAaveOracle {
    function getReservePrice(uint256 reserveId) external view returns (uint256);
    function getReserveSource(uint256 reserveId) external view returns (address);
    function decimals() external view returns (uint8);
}

interface IPriceFeed {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
}

interface IOracleSinkPriceFeed is IPriceFeed {
    function sink() external view returns (address);
    function token() external view returns (address);
    function rateMaxStaleness() external view returns (uint256);
    function underlyingUsdFeed() external view returns (address);
}

interface IChainlinkPriceFeed is IPriceFeed {
    function rateFeed() external view returns (address);
    function rateMaxStaleness() external view returns (uint256);
}

interface IOracleSink {
    function peers(uint32 eid) external view returns (bytes32);
    function paused() external view returns (bool);
    function owner() external view returns (address);
    function getPrice(address token) external view returns (uint256, uint64);
    function maxStaleness(address token) external view returns (uint64);
}

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}
