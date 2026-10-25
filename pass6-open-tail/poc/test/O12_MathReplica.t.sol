// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";

/// @title O12 — fork-free replica of the Ronin BondingCurveManager curve math
/// @notice Mirrors `_quoteBuy`/`_buy`/`sell` from the verified source byte-for-byte, so the
///         rounding / partial-fill (`Ceil`) branch can be fuzzed at high volume without any
///         RPC. The fork suite (O12_RoninBondingCurve) exercises the real deployed contract;
///         this suite proves the algebra for thousands of cases.
contract O12_MathReplica is Test {
    uint256 constant BPS = 10_000;

    struct Market {
        uint256 virtualToken;
        uint256 virtualRonke;
        uint256 tokensSold;
        uint256 ronkeCollected;
    }

    struct Terms {
        uint256 curveSupply;
        uint256 tradingFeeBps;
    }

    /// @dev exact transcription of BondingCurveManager._quoteBuy
    function quoteBuy(Terms memory t, Market memory m, uint256 ronkeIn, uint256 maxOut)
        internal
        pure
        returns (uint256 tokensOut, uint256 spend, uint256 fee)
    {
        uint256 remaining = t.curveSupply - m.tokensSold;
        if (maxOut < remaining) remaining = maxOut;
        fee = (ronkeIn * t.tradingFeeBps) / BPS;
        uint256 net = ronkeIn - fee;
        tokensOut = (m.virtualToken * net) / (m.virtualRonke + net);
        spend = ronkeIn;

        if (tokensOut > remaining) {
            tokensOut = remaining;
            net = ceilDiv(m.virtualRonke * remaining, m.virtualToken - remaining);
            spend = ceilDiv(net * BPS, BPS - t.tradingFeeBps);
            fee = spend - net;
            if (spend > ronkeIn) {
                spend = ronkeIn;
                fee = (spend * t.tradingFeeBps) / BPS;
                net = spend - fee;
                tokensOut = (m.virtualToken * net) / (m.virtualRonke + net);
                if (tokensOut > remaining) tokensOut = remaining;
            }
        }
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /// @dev exact transcription of BondingCurveManager.sell
    function sell(Terms memory t, Market memory m, uint256 tokensIn)
        internal
        pure
        returns (uint256 ronkeOut, Market memory m2)
    {
        uint256 gross = (m.virtualRonke * tokensIn) / (m.virtualToken + tokensIn);
        uint256 fee = (gross * t.tradingFeeBps) / BPS;
        ronkeOut = gross - fee;
        m2 = m;
        m2.virtualToken += tokensIn;
        m2.virtualRonke -= gross;
        m2.tokensSold -= tokensIn;
        m2.ronkeCollected -= gross;
    }

    /// @dev A round trip buy->sell-all must never return more RONKE than it consumed, must not
    ///      underflow the collected counter, and must not decrease k.
    /// forge-config: default.fuzz.runs = 5000
    function testFuzz_roundtrip_never_profitable(
        uint256 tv,
        uint256 rv,
        uint256 curveSupply,
        uint256 tokensSold,
        uint256 feeBps,
        uint256 ronkeIn
    ) public {
        tv = bound(tv, 1e9, 1e30);
        rv = bound(rv, 1e9, 1e30);
        curveSupply = bound(curveSupply, 1, tv);
        tokensSold = bound(tokensSold, 0, curveSupply);
        feeBps = bound(feeBps, 0, 1000);
        ronkeIn = bound(ronkeIn, 1, 1e30);

        Terms memory t = Terms({curveSupply: curveSupply, tradingFeeBps: feeBps});
        Market memory m =
            Market({virtualToken: tv, virtualRonke: rv, tokensSold: tokensSold, ronkeCollected: rv / 2});

        uint256 k0 = m.virtualToken * m.virtualRonke;

        (uint256 tokensOut, uint256 spend, uint256 fee) = quoteBuy(t, m, ronkeIn, type(uint256).max);
        assertLe(spend, ronkeIn, "charged more than offered");
        assertLe(fee, spend, "fee > spend");
        if (tokensOut == 0) return; // DustTrade in the real contract

        uint256 net = spend - fee;
        m.virtualToken -= tokensOut;
        m.virtualRonke += net;
        m.tokensSold += tokensOut;
        m.ronkeCollected += net;
        assertGe(m.virtualToken * m.virtualRonke, k0, "k decreased on buy");

        // The seller cannot sell more than the curve holds / sold.
        if (tokensOut > m.tokensSold) return;
        (uint256 out, Market memory m2) = sell(t, m, tokensOut);

        assertLe(out, spend, "round trip profited");
        assertGe(m2.virtualToken * m2.virtualRonke, m.virtualToken * m.virtualRonke, "k decreased on sell");
    }

    /// @dev The partial-fill branch is the only place two ceilings stack: it must never let a
    ///      buyer take the whole remainder for less than the floor-formula cost.
    /// forge-config: default.fuzz.runs = 5000
    function testFuzz_partial_fill_never_undercharges(
        uint256 tv,
        uint256 rv,
        uint256 curveSupply,
        uint256 tokensSold,
        uint256 feeBps,
        uint256 ronkeIn
    ) public {
        tv = bound(tv, 1e9, 1e30);
        rv = bound(rv, 1e9, 1e30);
        curveSupply = bound(curveSupply, 1, tv);
        tokensSold = bound(tokensSold, 0, curveSupply);
        feeBps = bound(feeBps, 0, 1000);
        ronkeIn = bound(ronkeIn, 1, 1e30);

        Terms memory t = Terms({curveSupply: curveSupply, tradingFeeBps: feeBps});
        Market memory m =
            Market({virtualToken: tv, virtualRonke: rv, tokensSold: tokensSold, ronkeCollected: rv / 2});
        uint256 k0 = m.virtualToken * m.virtualRonke;

        (uint256 tokensOut, uint256 spend, uint256 fee) = quoteBuy(t, m, ronkeIn, type(uint256).max);
        if (tokensOut == 0) return;
        assertLe(spend, ronkeIn, "overcharged");
        uint256 net = spend - fee;
        m.virtualToken -= tokensOut;
        m.virtualRonke += net;
        m.tokensSold += tokensOut;
        assertGe(m.virtualToken * m.virtualRonke, k0, "k decreased (partial-fill)");
    }
}
