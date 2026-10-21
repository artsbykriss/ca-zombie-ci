// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

interface IVault is IERC20 {
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function asset() external view returns (address);
    function pricePerShare() external view returns (uint256);
}

interface ITruthMarket {
    function proposeResolution(uint256 outcome) external;
    function mint(uint256 paymentTokenAmount) external;
    function redeem(uint256 amount) external;
    function settleBonds() external;
    function resolveMarketByCouncil(uint256 outcome) external;
    function getCurrentStatus() external view returns (uint8);
    function currentStatus() external view returns (uint8);
    function winningPosition() external view returns (uint256);
    function firstChallengePeriod() external view returns (uint256);
    function secondChallengePeriod() external view returns (uint256);
    function resolverBondAmount() external view returns (uint256);
    function disputerBondAmount() external view returns (uint256);
    function escalatorBondAmount() external view returns (uint256);
    function resolutionProposedAt() external view returns (uint256);
    function yesToken() external view returns (address);
    function noToken() external view returns (address);
    function paymentToken() external view returns (address);
    function paused() external view returns (bool);
    function bondSettled() external view returns (bool);
    function marketQuestion() external view returns (string memory);
    function statusHistory(uint256 i) external view returns (uint8, uint256, uint256);
}

interface ITruthMarketManager {
    function proposeResolution(address market, uint256 outcome) external;
    function disputeMarket(address market, address disputor) external;
    function resolveMarketByCouncil(address market, uint256 outcome) external;
    function isActiveMarket(address market) external view returns (bool);
    function numberOfActiveMarkets() external view returns (uint256);
    function getActiveMarketAddress(uint256 i) external view returns (address);
    function resolverAddress(address market) external view returns (address);
    function resolverBondAmount() external view returns (uint256);
    function firstChallengePeriod() external view returns (uint256);
    function oracleBonds() external view returns (address);
    function oracleCouncilAddress() external view returns (address);
    function owner() external view returns (address);
    function paused() external view returns (bool);
}

interface IOracleCouncil {
    function openDispute(address market, string calldata reason) external;
    function isOracleCouncilMember(address) external view returns (bool);
    function councilMemberCount() external view returns (uint256);
    function getMarketLastClosedDispute(address market) external view returns (uint256);
}

interface IOracleBonds {
    function getResolverBondForMarket(address market) external view returns (uint256);
    function getDisputorBondForMarket(address market, address disputor) external view returns (uint256);
    function getClaimableBondAmountForMarket(address market) external view returns (uint256);
}

// ---- minimal Uniswap v4 ----
struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

struct SwapParams {
    bool zeroForOne;
    int256 amountSpecified;
    uint160 sqrtPriceLimitX96;
}

interface IPoolManager {
    function unlock(bytes calldata data) external returns (bytes memory);
    function swap(PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        external
        returns (int256);
    function sync(address currency) external;
    function settle() external returns (uint256);
    function take(address currency, address to, uint256 amount) external;
}
