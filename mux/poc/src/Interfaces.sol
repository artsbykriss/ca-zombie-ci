// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

struct PositionOrderExtra {
    uint96 tpPrice;
    uint96 slPrice;
    uint8 tpslProfitTokenId;
    uint32 tpslDeadline;
}

/// Minimal interface for the deployed MUX Leveraged Trading Protocol OrderBook (proxy).
interface IMuxOrderBook {
    // trader entry points
    function placePositionOrder3(
        bytes32 subAccountId,
        uint96 collateralAmount,
        uint96 size,
        uint96 price,
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline,
        bytes32 referralCode,
        PositionOrderExtra calldata extra
    ) external payable;

    function placeLiquidityOrder(uint8 assetId, uint96 rawAmount, bool isAdding) external payable;
    function placeWithdrawalOrder(bytes32 subAccountId, uint96 rawAmount, uint8 profitTokenId, bool isProfit) external;
    function depositCollateral(bytes32 subAccountId, uint256 collateralAmount) external payable;
    function withdrawAllCollateral(bytes32 subAccountId) external;
    function redeemMuxToken(uint8 tokenId, uint96 muxTokenAmount) external;

    // broker/keeper entry points
    function fillPositionOrder(uint64 orderId, uint96 collateralPrice, uint96 assetPrice, uint96 profitAssetPrice) external;
    function fillLiquidityOrder(uint64 orderId, uint96 assetPrice, uint96 mlpPrice, uint96 currentAssetValue, uint96 targetAssetValue) external;
    function fillWithdrawalOrder(uint64 orderId, uint96 collateralPrice, uint96 assetPrice, uint96 profitAssetPrice) external;
    function liquidate(bytes32 subAccountId, uint8 profitAssetId, uint96 collateralPrice, uint96 assetPrice, uint96 profitAssetPrice) external;
    function cancelOrder(uint64 orderId) external;

    // admin
    function addBroker(address newBroker) external;
    function setAggregator(address aggregatorAddress, bool isEnable) external;
    function setCallbackWhitelist(address caller, bool enable) external;
    function pause(bool isPositionOrderPaused_, bool isLiquidityOrderPaused_) external;

    // views
    function getOrderCount() external view returns (uint256);
    function brokers(address broker) external view returns (bool);
    function isPositionOrderPaused() external view returns (bool);
    function isLiquidityOrderPaused() external view returns (bool);
    function owner() external view returns (address);
    function maintainer() external view returns (address);
}

/// Minimal interface for the deployed MUX LiquidityPool (chained proxy).
interface IMuxLiquidityPool {
    function openPosition(bytes32 subAccountId, uint96 amount, uint96 collateralPrice, uint96 assetPrice) external returns (uint96);
    function closePosition(bytes32 subAccountId, uint96 amount, uint8 profitAssetId, uint96 collateralPrice, uint96 assetPrice, uint96 profitAssetPrice) external returns (uint96);
    function liquidate(bytes32 subAccountId, uint8 profitAssetId, uint96 collateralPrice, uint96 assetPrice, uint96 profitAssetPrice) external returns (uint96);
    function withdrawAllCollateral(bytes32 subAccountId) external;
    function getSubAccount(bytes32 subAccountId) external view returns (uint96 collateral, uint96 size, uint32 lastIncreasedTime, uint96 entryPrice, uint128 entryFunding);
    function getAssetAddress(uint8 assetId) external view returns (address);
}

/// The "Pool" named in pass5 (0x45de...) is actually MYX Protocol's Pool implementation.
interface IMyxPool {
    function setLPStableProfit(uint256 pairIndex, int256 profit) external;
    function givebackTradingFee(uint256 pairIndex, uint256 amount) external;
    function updateAveragePrice(uint256 pairIndex, uint256 averagePrice) external;
    function positionManager() external view returns (address);
    function feeCollector() external view returns (address);
    function pairsIndex() external view returns (uint256);
    function router() external view returns (address);
}

/// MUX3 (perps v3) OrderBook — the contract that holds the $8.6M collateral-pool surface.
interface IMux3OrderBook {
    function fillPositionOrder(uint64 orderId) external returns (uint256);
    function owner() external view returns (address);
}

/// MUX3 CollateralPool (beacon proxy target). Fund-moving fns are onlyOrderBook/onlyCore.
interface IMux3CollateralPool {
    function addLiquidity(Mux3AddLiquidityArgs calldata args) external;
    function removeLiquidity(Mux3RemoveLiquidityArgs calldata args) external;
}

struct Mux3AddLiquidityArgs {
    address account;
    uint256 rawCollateralAmount;
    bool isUnwrapWeth;
}

struct Mux3RemoveLiquidityArgs {
    address account;
    uint256 shares;
    address token;
    bool isUnwrapWeth;
    uint256 extraFeeCollateral;
}

interface ICallbackRegister {
    function isCallbackRegistered(address callback) external view returns (bool);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}
