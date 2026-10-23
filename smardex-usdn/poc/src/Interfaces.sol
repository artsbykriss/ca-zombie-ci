// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Minimal interfaces + structs matching the deployed (Etherscan-verified) SMARDEX USDN
// contracts. Struct field order is ABI-significant.

struct PositionId {
    int24 tick;
    uint256 tickVersion;
    uint256 index;
}

struct Position {
    bool validated;
    uint40 timestamp;
    address user;
    uint128 totalExpo;
    uint128 amount;
}

struct LiqTickInfo {
    uint256 totalPositions;
    uint256 totalExpo;
    int256 remainingCollateral;
    uint128 tickPrice;
    uint128 priceWithoutPenalty;
}

struct PreviousActionsData {
    bytes[] priceData;
    uint128[] rawIndices;
}

struct RewardsParameters {
    uint32 gasUsedPerTick;
    uint32 otherGasUsed;
    uint32 rebaseGasUsed;
    uint32 rebalancerGasUsed;
    uint64 baseFeeOffset;
    uint16 gasMultiplierBps;
    uint16 positionBonusMultiplierBps;
    uint128 fixedReward;
    uint128 maxReward;
}

// Pyth structs (must match @pythnetwork/pyth-sdk-solidity PythStructs)
struct PythPrice {
    int64 price;
    uint64 conf;
    int32 expo;
    uint64 publishTime;
}

struct PythPriceFeed {
    bytes32 id;
    PythPrice price;
    PythPrice emaPrice;
}

interface IUsdnProtocol {
    function liquidate(bytes calldata currentPriceData) external payable returns (LiqTickInfo[] memory);

    function getEffectivePriceForTick(int24 tick) external view returns (uint128);

    function getEffectivePriceForTick(int24 tick, uint256 liqMultiplier) external view returns (uint128);

    function getLongPosition(PositionId calldata posId) external view returns (Position memory, uint24);

    function validateOpenPosition(
        address payable validator,
        bytes calldata openPriceData,
        PreviousActionsData calldata previousActionsData
    ) external payable returns (uint8 outcome, PositionId memory posId);

    function getPositionValue(PositionId calldata posId, uint128 price, uint128 timestamp)
        external
        view
        returns (int256);

    function usdnPrice(uint128 currentPrice) external view returns (uint256);

    function getLastPrice() external view returns (uint128);

    function getBalanceVault() external view returns (uint256);

    function getBalanceLong() external view returns (uint256);

    function getTotalLongPositions() external view returns (uint256);

    function getTickSpacing() external view returns (int24);

    function getSecurityDepositValue() external view returns (uint64);

    function getMinLongPosition() external view returns (uint256);

    function getLiquidationPenalty() external view returns (uint24);

    function getSafetyMarginBps() external view returns (uint256);

    function getMiddlewareValidationDelay() external view returns (uint256);

    function initiateDeposit(
        uint128 amount,
        uint256 sharesOutMin,
        address to,
        address payable validator,
        uint256 deadline,
        bytes calldata currentPriceData,
        PreviousActionsData calldata previousActionsData
    ) external payable returns (bool);

    function validateDeposit(address payable validator, bytes calldata priceData, PreviousActionsData calldata)
        external
        payable
        returns (bool);

    function initiateWithdrawal(
        uint152 usdnShares,
        uint256 amountOutMin,
        address to,
        address payable validator,
        uint256 deadline,
        bytes calldata currentPriceData,
        PreviousActionsData calldata previousActionsData
    ) external payable returns (bool);

    function validateWithdrawal(address payable validator, bytes calldata priceData, PreviousActionsData calldata)
        external
        payable
        returns (bool);

    function initiateOpenPosition(
        uint128 amount,
        uint128 desiredLiqPrice,
        uint128 userMaxPrice,
        uint256 userMaxLeverage,
        address to,
        address payable validator,
        uint256 deadline,
        bytes calldata currentPriceData,
        PreviousActionsData calldata previousActionsData
    ) external payable returns (bool, PositionId memory);
}

interface ILiquidationRewardsManager {    function getLiquidationRewards(
        LiqTickInfo[] calldata liquidatedTicks,
        uint256 currentPrice,
        bool rebased,
        uint8 rebalancerAction,
        uint8 action,
        bytes calldata rebaseCallbackResult,
        bytes calldata priceData
    ) external view returns (uint256);

    function getRewardsParameters() external view returns (RewardsParameters memory);
}

interface IPyth {
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256);
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythPriceFeed[] memory);

    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythPriceFeed[] memory);
}

interface IWstETH {    function stEthPerToken() external view returns (uint256);
    function getStETHByWstETH(uint256) external view returns (uint256);
    function getWstETHByStETH(uint256) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function totalShares() external view returns (uint256);
    function sharesOf(address) external view returns (uint256);
    function convertToShares(uint256) external view returns (uint256);
    function convertToTokens(uint256) external view returns (uint256);
}

struct PriceInfo {
    uint256 price;
    uint256 neutralPrice;
    uint256 timestamp;
}

interface IOracleMiddleware {
    // ProtocolAction enum is encoded as uint8: Liquidation = 10, InitiateDeposit = 2
    function parseAndValidatePrice(
        bytes32 actionId,
        uint128 targetTimestamp,
        uint8 action,
        bytes calldata data
    ) external payable returns (PriceInfo memory);

    function getLowLatencyDelay() external view returns (uint16);
    function getValidationDelay() external view returns (uint256);
    function getPythRecentPriceDelay() external view returns (uint64);
    function getConfRatioBps() external view returns (uint16);
}
