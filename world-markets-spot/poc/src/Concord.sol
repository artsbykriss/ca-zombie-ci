// SPDX-License-Identifier: MIT
// World Markets (Concord Exchange) — read-only fork-test constants + tiny helpers.
// Addresses/selectors derived from the public interfaces in World-Markets-Inc/contract-owner
// (IConcordProtocolPub, ISpotOrderBook, IOrderBookAbstract) and from the deployed runtimes.
pragma solidity ^0.8.24;

library Concord {
    // ---- system addresses (MegaETH, chain id 4326) ----
    address constant EXCHANGE = 0x5e3Ae52EbA0F9740364Bd5dd39738e1336086A8b; // proxy
    address constant FACET_MAIN = 0xE1FC1881d1C495B399C9890930aa416e89d691c2; // sload(0x0400..)
    address constant FACET_TRADING = 0x431212aBc35737011DDD7306Fb5229752B6BD115; // sload(0x0100..)
    address constant FACET_BULK = 0xAfbA6B6A8D1B8cacd1Fc12df9E32F23F1a923417; // sload(0x0200..)
    address constant ADMIN = 0xCe46EE0664e02d6FF478f08e580De42EeFA29cC9;

    address constant SPOT_BOOK_WETH_USDM = 0xF818C8Da51f9a712CfBCDDD44D0c445Fa1A104e6;
    address constant LEND_BOOK_USDM = 0x7a5D6c6Bb5c0Cf12DF3401DEA29c42cDaE449Ef1;
    address constant WL_USDM = 0xc2373C03b5f8bC8937177797f103F11544c5E716;
    address constant WL_IMPL = 0xE90eeE54b85845E34f463abc1AbcfAe6D1AeD27B;

    address constant USDM = 0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    // ---- selectors ----
    bytes4 constant SEL_getHighestTokenId = 0x7cb11549;
    bytes4 constant SEL_readTokenConfig = 0xefd8ded2;
    bytes4 constant SEL_getUserId = 0x2b956ff7;
    bytes4 constant SEL_getUserAddress = 0x6da4606d;
    bytes4 constant SEL_getBalance = 0x761966b7;
    bytes4 constant SEL_getSpotOrderBook = 0x828daa7e;
    bytes4 constant SEL_getPerpOrderBook = 0x328f58e2;
    bytes4 constant SEL_getLendOrderBook = 0x73d848dd;
    bytes4 constant SEL_readOrderBookConfig = 0x04bedf6a;
    bytes4 constant SEL_riskAdjustedPortfolioValue = 0xfb21a633;

    bytes4 constant SEL_withdrawErc20 = 0xbd1f4b52;
    bytes4 constant SEL_depositErc20 = 0x6548b40d;
    bytes4 constant SEL_createAccount = 0x9dca362f;
    bytes4 constant SEL_allowTradingForAccount = 0xf42dcf0a;
    bytes4 constant SEL_batchCommands = 0xd803a4cf;
    bytes4 constant SEL_liquidate = 0xc4019421;
    bytes4 constant SEL_payInterestAndFees = 0x9d1c4c83;
    bytes4 constant SEL_markLendPositionAsNonReturnable = 0xe3a898e0;
    bytes4 constant SEL_lifoLenderSwap = 0x51e3716b;
    bytes4 constant SEL_renewLoan = 0x2e618812;
    bytes4 constant SEL_bankruptcy = 0x91680b93;
    bytes4 constant SEL_requestPerpTrueUp = 0x9598c7b1;
    bytes4 constant SEL_newSpotBuyOrder = 0x5175cbc6;
    bytes4 constant SEL_cancelSpotBuyOrder = 0xbf9e8518;
    bytes4 constant SEL_newLendOrder = 0x64ee5a0c;

    bytes4 constant SEL_bulkReadMaxUserId = 0xffffff20;
    bytes4 constant SEL_bulkReadTokenConfigs = 0xffffff01;
    bytes4 constant SEL_changeAdmin = 0xffffff42;
    bytes4 constant SEL_setTokenConfig = 0xffffff88;
    bytes4 constant SEL_setOpsAddress = 0x707789c5;
    bytes4 constant SEL_switchTokenAddress = 0xffffff97;
    bytes4 constant SEL_liqSwap = 0xffffffa1;

    bytes4 constant SEL_haltTrading = 0x795e38bb;
    bytes4 constant SEL_setMinOrderQuantity = 0xbfa806b0;
    bytes4 constant SEL_computeBuyMarketOrderSpecifyIn = 0x4bb52d8e;
    bytes4 constant SEL_computeSellMarketOrderSpecifyIn = 0x27ac088e;
    bytes4 constant SEL_computeBuyMarketOrderSpecifyOut = 0x54e5a52b;
    bytes4 constant SEL_computeSellMarketOrderSpecifyOut = 0x21e1f52b;
    bytes4 constant SEL_countBuyOrders = 0x42439ff8;
    bytes4 constant SEL_countSellOrders = 0x8f06d80a;
    bytes4 constant SEL_bestBidOffer = 0x2de77230;
    bytes4 constant SEL_readMinOrderQuantity = 0x832c822e;
    bytes4 constant SEL_isHalted = 0xc7ff1584;

    bytes4 constant SEL_wl_setManagerAddress = 0x41431908;
    bytes4 constant SEL_wl_setTraderAddress = 0xb6e8b806;
    bytes4 constant SEL_wl_setAdmin = 0x704b6c02;
    bytes4 constant SEL_wl_rescueErc20 = 0x2b88c769;
    bytes4 constant SEL_wl_requestDeposit = 0x0d1e6667;
    bytes4 constant SEL_wl_requestWithdraw = 0x745400c9;

    bytes4 constant SEL_balanceOf = 0x70a08231;

    // ---- custom errors (from IConcordProtocolErrors.sol) ----
    bytes4 constant ERR_CallerIsNotTrader = 0xd07a9d6b;
    bytes4 constant ERR_AdminRoleOnly = 0x10c95c62;
    bytes4 constant ERR_CallerHasNoAccount = 0xfb64298d;
    bytes4 constant ERR_CallerNotPermissioned = 0xaebf6f28;
    bytes4 constant ERR_ExchangeOnlyCall = 0x26e41fb0;
    bytes4 constant ERR_NoSuchPosition = 0xabc24034;
}
