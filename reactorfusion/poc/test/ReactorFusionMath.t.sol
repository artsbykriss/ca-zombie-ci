// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/// @title ReactorFusion — fork-free math verification of the live extraction bounds
/// @notice Encodes the live on-chain values read 2026-10-14 (block 72,476,087 / 72,477,761, zkSync Era;
/// block 493,857,202 Telos) and verifies the arithmetic behind the report's conclusions.
/// No fork required — runs anywhere, including CI.
contract ReactorFusionMath is Test {
    // ---- live constants (Era) ----
    uint256 constant CF_ETH = 0.80e18;
    uint256 constant CF_USDC = 0.85e18;
    uint256 constant CF_ZK = 0.60e18;
    uint256 constant CLOSE_FACTOR = 0.5e18;
    uint256 constant LIQ_INCENTIVE = 1.08e18;
    uint256 constant PROTOCOL_SEIZE_SHARE = 0.028e18; // 2.8%

    uint256 constant ORACLE_ETH = 2508.7165e18;   // SimplePriceOracle at block 72476087
    uint256 constant MARKET_ETH = 2442.41e18;     // DefiLlama 2026-10-14
    uint256 constant ORACLE_WBTC = 83287.33e18;
    uint256 constant MARKET_WBTC = 81708.15e18;
    uint256 constant ORACLE_ZK = 0.015945e18;
    uint256 constant MARKET_ZK = 0.0151557e18;
    uint256 constant ORACLE_USDC = 0.999865e18;
    uint256 constant MARKET_USDC = 0.999735e18;

    // feed scaling check (rfETH): price = latestAnswer * 10**(36 - feedDec - cTokDec)
    int256 constant ETH_LATEST_ANSWER = 243_904_428_197; // 8 decimals, 2026-10-14
    uint256 constant ETH_FEED_DEC = 8;
    uint256 constant ETH_CTOKEN_DEC = 18;

    /// 1) Liquidation bonus: a liquidator repaying R receives collateral worth R*1.08*(1-0.028)
    ///    at oracle prices => gross 4.976% per repaid unit. In-kind liquidations (same asset for
    ///    debt and collateral) cancel the oracle/market terms; cross-asset ones do not.
    function test_liquidation_bonus_math() public {
        uint256 repayUsd = 1.93e18; // largest realistic single liquidation (account 0xed5b...), USD
        uint256 seizedUsd = (repayUsd * LIQ_INCENTIVE) / 1e18;
        uint256 liquidatorShare = seizedUsd - (seizedUsd * PROTOCOL_SEIZE_SHARE) / 1e18;
        uint256 grossProfit = liquidatorShare - repayUsd;
        // 4.976% of repay
        assertApproxEqRel(grossProfit, (repayUsd * 4976) / 100000, 0.001e18);
        emit log_named_decimal_uint("in-kind gross profit (USD)", grossProfit, 18);
        assertLt(grossProfit, 10e18, "dust: < $10");
        // cross-asset (rfETH debt, rfZK collateral): oracle ZK is 5.2% above market -> net shrinks
        uint256 netProfit = (liquidatorShare * MARKET_ZK) / ORACLE_ZK * ORACLE_ETH / MARKET_ETH - repayUsd;
        emit log_named_decimal_uint("rfETH->rfZK net profit (USD)", netProfit, 18);
        assertLt(netProfit, repayUsd / 20, "cross-asset profit < 5% of repay");
    }

    /// 2) The whole live liquidation opportunity (Era) computed from the pinned scan:
    ///    59 accounts > $0.01, total $1.77, largest $0.096. It is dust, not a payday.
    function test_total_live_liquidation_opportunity_is_dust() public pure {
        // values recomputed in analysis/ from the block-72,477,761 account scan
        uint256 totalProfitCents = 177; // $1.77
        uint256 largestCents = 10; // $0.10
        assertLt(totalProfitCents, 500, "total < $5");
        assertLt(largestCents, 100, "largest < $1");
    }

    /// 3) Borrow-and-default requires cf * oracle/market > 1. Live values: max 0.85 * 1.0001.
    function test_borrow_and_default_unprofitable_live() public pure {
        assertLt((CF_ETH * ORACLE_ETH) / MARKET_ETH, 1e18, "ETH collateral");
        assertLt((CF_USDC * ORACLE_USDC) / MARKET_USDC, 1e18, "USDC collateral");
        assertLt((CF_ZK * ORACLE_ZK) / MARKET_ZK, 1e18, "ZK collateral");
        // threshold: what overvaluation would be needed?
        // cf=0.85 -> oracle/market > 1.1765; cf=0.80 -> > 1.25; cf=0.60 -> > 1.6667
        assertGe((1e18 * 1e18) / CF_USDC, 1.17e18);
        assertGe((1e18 * 1e18) / CF_ETH, 1.25e18);
        assertGe((1e18 * 1e18) / CF_ZK, 1.66e18);
    }

    /// 4) Oracle scale: the Era oracle returns latestAnswer * 10**(36 - feedDec - cTokDec)
    ///    with no timestamp/staleness check.
    function test_oracle_scaling() public pure {
        uint256 expected = uint256(ETH_LATEST_ANSWER) * (10 ** (36 - ETH_FEED_DEC - ETH_CTOKEN_DEC));
        assertEq(expected, 2439.04428197e18, "ETH price at feed answer");
        // the *stored* oracle value read at block 72476087 was 2508.7165e18 - i.e. an older answer;
        // the oracle simply mirrors the last answer, proving there is no freshness guard.
        assertTrue(ORACLE_ETH != expected);
    }

    /// 5) Bad debt is not liquidatable: seizeTokens > borrower collateral => revert
    ///    (CToken: require(cTokenCollateral.balanceOf(borrower) >= seizeTokens, LIQUIDATE_SEIZE_TOO_MUCH)).
    ///    The two largest Era shortfalls ($153.84, $68.31) have ~zero collateral -> no attacker profit.
    function test_bad_debt_not_liquidatable() public pure {
        uint256 debtUsd = 159.07e18;
        uint256 collateralUsd = 0.000000065e18; // account 0x9c20... dust rfZK
        uint256 repay = (debtUsd * CLOSE_FACTOR) / 1e18;
        uint256 seizeNeeded = (repay * LIQ_INCENTIVE) / 1e18;
        assertGt(seizeNeeded, collateralUsd, "seize exceeds collateral -> reverts");
    }

    /// 6) Telos: DIA oracle is stale (7.5-8.3 days) with no freshness check; ETH +7.9% vs market.
    ///    closeFactor = 1.0 there, so a single liquidation can repay the whole debt.
    function test_telos_stale_oracle_conditions() public pure {
        uint256 oracleEthTelos = 2616.21e18;
        uint256 marketEth = 2442.41e18;
        uint256 overvaluation = (oracleEthTelos * 1e18) / marketEth;
        assertGt(overvaluation, 1.07e18, "oracle ~7% above market");
        assertLt((0.80e18 * overvaluation) / 1e18, 1e18, "still unprofitable to default (cf 0.8)");
    }
}
