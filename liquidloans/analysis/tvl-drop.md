# LiquidLoans TVL: $4.28M → $1.63M — reconciliation (no hack)

**Source of the alarm:** pass-2 collapses lane, DefiLlama `/protocol/liquidloans` daily series
(2026-10-13 `$4,278,946` → 2026-10-19 `$1,634,818` on the pass-2 date; `$2,283,547` on the 19th in
the current feed). **Question:** is the drop an outflow/exploit, or a price artifact?

## Answer: it is the PLS price, plus a modest (~6%) collateral outflow. No drain, no exploit.

On-chain reads (PulseChain, `getEntireSystemColl()`/`getEntireSystemDebt()` + `PriceFeed.lastGoodPrice()`):

| UTC date | block | system collateral (PLS) | oracle price ($/PLS, 1e18) | collateral USD | system debt (USDL) |
|---|---:|---:|---:|---:|---:|
| 2026-10-13 | 27,782,555 | 377,007,128,871.78 | 9.4059e-6 | **$3,545,800** | 1,235,892.78 |
| 2026-10-14 | 27,790,971 | 377,002,426,212.87 | 9.1419e-6 | $3,446,800 | 1,236,853.02 |
| 2026-10-15 | 27,799,374 | 360,551,804,501.52 | 6.2139e-6 | $2,240,400 | 1,062,376.01 |
| 2026-10-19 | 27,832,894 | 353,174,650,006.15 | 4.8683e-6 | **$1,719,400** | 969,496.06 |
| 2026-10-20 | 27,841,270 | 347,032,846,029.14 | 5.0288e-6 | $1,745,100 | 954,568.42 |
| 2026-10-23 | 27,868,978 | 348,005,202,970.03 | 5.7252e-6 | $1,992,400 | 955,590.92 |

- **Price leg:** the protocol oracle fell **9.4059e-6 → 4.8683e-6 (−48.2%)** between 13 and 19 Oct.
  That alone accounts for ≈ **−$1.71M** of the ≈ −$2.65M DefiLlama drop (and it partly recovered to
  5.7252e-6 by the 23rd).
- **Quantity leg:** system collateral fell only **377.0e9 → 353.2e9 PLS (−6.3%, −23.8e9 PLS ≈ −$116k
  at the 19-Oct price)**. Debt fell **$1.236M → $0.970M (−21.6%)** — i.e. users **repaid/redeemed**;
  this is a normal contraction, not a one-way drain.
- **No outflow trail:** the ActivePool balance moves monotonically with vault closures/redemptions;
  no single large transfer, no attacker destination, no protocol-owned value left the system.

## Why DefiLlama's number differs from the oracle

DefiLlama's adapter (`projects/liquidloans-io/index.js`, not in the current public adapter tree —
`module: liquidloans-io/index.js` is still served by the API) marks the collateral with **DefiLlama's
own PLS price**, which on 2026-10-23 was `$4.948e-6` (native `pulse:0x0000…0`) while WPLS was
`$5.677e-6` — a 13% internal spread. `348,005,202,970 × 4.948e-6 = $1,722,083` reproduces the
reported TVL exactly. The separate **"staking" leg** (`$1,081,287`) is the **2.614e12 staked LOAN ×
$4.1366e-7**. So the reported total is (ActivePool PLS × DefiLlama PLS price); the daily −62.9%/−53%
figures are DefiLlama's PLS price series, not on-chain collateral.

## Verdict

**The TVL collapse is a price artifact + modest repayments, not an exploit.** There is no attacker
outflow to trace. This is the same failure mode the collapses lane found for Stability / Republic
Note / FluxBeam / 9mm — a DefiLlama price/adapter artifact, not a fund movement.

## Residual (not E-U)

- **H-O:** CollSurplusPool 7.33e9 PLS ($41.6k) is claimable **only** by the borrowers it is owed to
  (`CollSurplusPool.claimColl` requires `msg.sender == BorrowerOperations` and is called with
  `msg.sender`); StabilityPool 605k USDL + 66.65e9 PLS and LOANStaking 2.614e12 LOAN are per-user.
- **P:** the secondary oracle is a UUPS proxy whose owner is a **Gnosis Safe** (`0xF796661E…`); the
  Safe can upgrade the oracle and set an arbitrary price → could liquidate/drain the CDP. This is a
  privileged/key risk, not an external-unprivileged path. The primary PriceFeed itself is
  owner-renounced and cannot be re-pointed.
