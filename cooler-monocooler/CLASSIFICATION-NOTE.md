# CLASSIFICATION-NOTE — Cooler MonoCooler (conditional, E-U $0 today)

**Lead:** ZH4-PASS3 Tier-3 row 13 — "up-only fixed LTV oracle ($3,118/gOHM vs market $5,319); re-arm if gOHM < $3,118".
**Verdict:** **CLOSED as a live E-U path today ($0.00)**. **KEPT as a conditional monitor** with a hard, precisely defined trigger.

## Why this is not E-U today (not a static-gate artefact)

The path was exercised on a pinned-block fork, not inferred:

- `borrow(type(uint128).max)` against 10 gOHM returns **31,192.890054842982841120 USDS** (100% of the oracle) and the position is healthy — the mechanism works.
- The same 10 gOHM cost **$53,373.01** at market → the atomic round-trip is **−$22,180.19**. The sign is structural, not a liquidity artefact: `oracle = 3,119.289` is **58.44%** of `market = 5,337.30`.
- Every one of the **328** borrowing accounts (from 9,020 `Borrow` events) was read with `computeLiquidity()`: **0** liquidatable, **0** above OLTV, max LTV 3,118.439. So the only other permissionless value path (`batchLiquidate`, which pays the caller gOHM without requiring debt repayment) is unreachable.

## Why keep it

The oracle is **up-only by construction** (`CannotDecreaseLtv`), and the policy has **no market-price input at all** (`_initGlobalStateCache` reads only `ltvOracle.currentLtvs()`). Therefore:

1. If gOHM ever trades below the oracle, borrowing becomes free money and the protocol **cannot liquidate** on market price — the borrower simply walks away. Bad debt is structural.
2. The trigger is governance-controlled and ratchets **upward only**: currently 3,119.289 (ramping to 3,123.183 on 2026-10-27), and can rise ≤100/day / +500 per call with a 7-day lead.
3. The loss is concentrated: **56.6% of debt** is one leveraged account (`OrigamiHOhmManager`), already at max LTV.

## Trigger (explicit)

- **Re-arm:** `gOHM` market **< `currentOriginationLtv()`**. Today that is **$3,119.29** (OHM ≈ **$11.586** at index 269.2385); market is $5,337.30 → a **41.56%** drawdown is required.
- **Conditional E-U:** `min(TRSRY sUSDS headroom, DEX-acquirable gOHM) × (1 − P_eff/OLTV)`.
  - headroom today **$3,606,287.84** (3,238,435 sUSDS); fresh-attacker residual **$1,388,432** after incumbents' $2,217,856 of pre-authorised top-up.
  - $716k @ P=2,500 · $1.29M @ 2,000 · $1.87M @ 1,500 · ceiling $3.61M @ P=0 (before DEX slippage).
- **Protocol bad debt (not E-U):** $0 at ≥$3,066.48; **$23.8M** at $2,500; **$44.9M** at $2,000; **$86.9M** at $1,000; **$129.0M** at $0.
- **Secondary monitor:** any account crossing LLTV via interest accrual (~2.00 years from a max-LTV open at 0.49875%/yr) activates the permissionless `batchLiquidate` gOHM bounty.

## Evidence

`README.md` §2–§5; `analysis/accounts_liq.json`; `analysis/exposure.json`; fork run https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39625018533 (5/5 PASS); pinned block 26,241,769.
