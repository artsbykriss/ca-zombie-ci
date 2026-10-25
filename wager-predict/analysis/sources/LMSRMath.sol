// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SD59x18} from "@prb/math/src/SD59x18.sol";
import {sd} from "@prb/math/src/sd59x18/Casting.sol";

/// @title  LMSRMath
/// @notice Hanson's Logarithmic Market Scoring Rule (LMSR) math for a binary {A,B} market,
///         in 18-decimal SD59x18 fixed point. **Verbatim port of the audited Phase 1
///         `PredictMarketLMSR` internals** (`_cost`, `_priceA_bps`/`getOdds`, `_deltaSharesForBuy`).
///
/// @dev    PORT FIDELITY: the numeric expressions are byte-for-byte identical to Phase 1 —
///         same max-subtraction numerical-stability trick, same clamps, same revert conditions.
///         The ONLY change is representational: Phase 1's `require(... , "LMSR: ...")` strings
///         become custom errors ({MathOverflow}, {ZeroShares}) to match the Phase 2 standard.
///         The revert *conditions* are unchanged; only the revert *data* differs. Behavioral
///         parity of all non-reverting outputs is proven against the live Phase 1 contract in
///         `test/v2/LMSRMath.test.js`.
///
///         Units: `qA`/`qB`/`b`/`netIn18` are 18-dec; {cost}/{deltaSharesForBuy} return 18-dec;
///         {priceABps}/{oddsBps} return basis points in [0, BPS_DENOM].
library LMSRMath {
    uint256 internal constant BPS_DENOM = 10_000;

    /// @dev Outcome side. Values {A:0, B:1} match Phase 1's `Side` enum exactly.
    enum Side {
        A,
        B
    }

    error MathOverflow();
    error ZeroShares();

    /// @notice LMSR cost function `C(qA,qB) = m + b·ln(e^((qA−m)/b) + e^((qB−m)/b))`, m = max(qA,qB).
    /// @dev    Max-subtraction keeps both exp args ≤ 0 (exp ≤ 1), so no overflow. Clamps a
    ///         negative raw result to 0 exactly as Phase 1 did. Returns 18-dec cost.
    function cost(uint256 qA, uint256 qB, uint256 b) internal pure returns (uint256) {
        SD59x18 bFx = sd(int256(b));
        SD59x18 qAFx = sd(int256(qA));
        SD59x18 qBFx = sd(int256(qB));
        SD59x18 mFx = qAFx >= qBFx ? qAFx : qBFx;

        SD59x18 eA = ((qAFx - mFx) / bFx).exp();
        SD59x18 eB = ((qBFx - mFx) / bFx).exp();
        SD59x18 c = mFx + bFx * (eA + eB).ln();

        int256 raw = c.unwrap();
        return raw < 0 ? 0 : uint256(raw);
    }

    /// @notice Price of side A in basis points (0..BPS_DENOM) from reserves and `b`.
    /// @dev    Returns 5_000 for a fresh market (qA==qB==0), and clamps to BPS_DENOM, as Phase 1.
    function priceABps(uint256 qA, uint256 qB, uint256 b) internal pure returns (uint256) {
        if (qA == 0 && qB == 0) return 5_000;
        SD59x18 bFx = sd(int256(b));
        SD59x18 qAFx = sd(int256(qA));
        SD59x18 qBFx = sd(int256(qB));
        SD59x18 mFx = qAFx >= qBFx ? qAFx : qBFx;
        SD59x18 eA = ((qAFx - mFx) / bFx).exp();
        SD59x18 eB = ((qBFx - mFx) / bFx).exp();
        SD59x18 pA = eA / (eA + eB);
        uint256 pA18 = uint256(pA.unwrap());
        uint256 priceA = (pA18 * BPS_DENOM) / 1e18;
        return priceA > BPS_DENOM ? BPS_DENOM : priceA;
    }

    /// @notice Both side prices in basis points; `priceA + priceB == BPS_DENOM` by construction.
    /// @dev    Mirrors Phase 1 `getOdds`: (0,0) → (5000, 5000).
    function oddsBps(uint256 qA, uint256 qB, uint256 b)
        internal
        pure
        returns (uint256 priceA, uint256 priceB)
    {
        priceA = priceABps(qA, qB, b);
        priceB = BPS_DENOM - priceA;
    }

    /// @notice Inverse cost: share delta Δ on `side` such that `C(post) − C(pre) == netIn18`.
    /// @dev    Closed form with max-subtraction (E = e^((qA−m)/b)+e^((qB−m)/b)):
    ///           buy A: Δ = m + b·ln(E·e^(netIn/b) − e^((qB−m)/b)) − qA   (symmetric for B).
    ///         Reverts {MathOverflow} if the inner term is non-positive, {ZeroShares} if Δ ≤ 0 —
    ///         identical conditions to Phase 1's two `require`s.
    function deltaSharesForBuy(Side side, uint256 qA, uint256 qB, uint256 netIn18, uint256 b)
        internal
        pure
        returns (uint256)
    {
        SD59x18 bFx = sd(int256(b));
        SD59x18 qAFx = sd(int256(qA));
        SD59x18 qBFx = sd(int256(qB));
        SD59x18 netFx = sd(int256(netIn18));
        SD59x18 mFx = qAFx >= qBFx ? qAFx : qBFx;

        SD59x18 eA = ((qAFx - mFx) / bFx).exp();
        SD59x18 eB = ((qBFx - mFx) / bFx).exp();
        SD59x18 E = eA + eB;
        SD59x18 eIn = (netFx / bFx).exp();

        SD59x18 inner;
        SD59x18 baseFx;
        if (side == Side.A) {
            inner = E * eIn - eB;
            baseFx = qAFx;
        } else {
            inner = E * eIn - eA;
            baseFx = qBFx;
        }
        if (inner.unwrap() <= 0) revert MathOverflow();

        SD59x18 delta = mFx + bFx * inner.ln() - baseFx;
        int256 raw = delta.unwrap();
        if (raw <= 0) revert ZeroShares();
        return uint256(raw);
    }
}
