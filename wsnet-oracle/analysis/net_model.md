# wsNET/USDG extraction — closed-form net model (for reproducibility)

All quantities in USDG (6-dec) unless stated. Let

* `F` = the market's free liquidity `= totalSupplyAssets − totalBorrowAssets` (the gross ceiling)
* `r0`, `r1` = canonical pair reserves (USDG 6-dec, NET 9-dec); `P0 = r0/r1` = spot (USDG per NET)
* `φ = 162.76` = `treasury.backingPerToken()` (the floor, USDG per NET)
* `I = 4.440900404` = `sNet.index()/1e9` (1 wsNET = `I` NET)
* `L = 0.625` = LLTV, `k` = oracle inflation ratio (inflated price / true price)

## Oracle
`price = clamp(0.90·TWAP, φ, 5·φ) · I · 1e6`  (1e24 effective scale)

With a clean 30-min window (`checkpoint()` then skew then hold ≥1800 s), `TWAP ≈ m·TWAP₀`, so

`k = clamp(0.8756·m, 1, 5)`  where `0.8756 = 0.90·TWAP₀/φ ≈ 0.90·157.5/162.76`

Cap `k = 5` at `m ≈ 5.71`. Break-even `k = 1/L = 1.6` at `m ≈ 1.83`.

## Skew cost (real swap, moving the reserve ratio by m)
To make the post-swap reserve ratio `= m·P0`, a constant-product swap needs
`Δx = r0(√m − 1)` USDG in and yields `netOut = r1(1 − 1/√m)` NET out.
The NET 500 bps fee-on-transfer applies to the buy leg, so the attacker receives `0.95·netOut`.
⇒ effective NET acquisition price (all-in) `= Δx / (0.95·netOut) = P0·√m / 0.95`.

## Capacity
`wsNET = NET/I`; true collateral value `V = wsNET·φ = NET·φ/I`.
`capacity = L·k·V = 0.625·k·(NET·φ/I)`.
Borrow `B = min(F, capacity)`.

## Nets
* **All-in** (NET sourced from the pool by the skew itself): `NET = 0.95·r1(1 − 1/√m)`,
  `B = min(F, 0.625·k·0.95·r1(1−1/√m)·φ/I)`, `net = B − Δx`.
  Because `B` is capacity-bound for `F ≥ capacity`, the all-in net scales with the pool's NET reserve, **not** with `F`.
  **Abort loss** (skew arbed away after the swap) `= Δx − V`.
* **Pre-held** (attacker already holds NET, or buys it off-pool at ≈φ; the skew is a separate, recoverable round-trip):
  `V = F/(L·k)` (sized so `capacity = F`), `B = F`, `net = F − V = F·(1 − 1.6/k)`.
  At the cap `k = 5`: `net = 0.68·F`. **Downside** = the skew round-trip fee/tax only.
* **Single-tx**: `d = 0` ⇒ `TWAP = TWAP₀` ⇒ `k = 1` ⇒ `capacity = 0.625·V ≪ F` ⇒ revert.

## Measured (CI fork, pinned block 97,879,993; free liquidity `F = $460,865.63`; pair `r0 = 167,547.91`, `r1 = 1,061.33 NET`)

| strategy | m | k | Δx (skew cost) | V (collateral) | B (borrow) | **net** |
|---|---|---|---|---|---|---|
| all-in | 4 | 3.488 | 168,052.06 | 82,364.78 | 178,439.55 | +10,387.49 |
| all-in | 5 | 4.361 | 207,723.77 | 91,034.97 | 246,636.50 | +38,912.73 |
| all-in | **6** | **5.000** | 243,589.74 | 97,411.54 | 301,955.21 | **+58,365.47** |
| all-in | 8 | 5.000 | 307,270.95 | 106,448.37 | 329,864.59 | +22,593.64 |
| pre-held | 4 | 3.488 | (round-trip −9,102.95) | 211,919.65 | 460,865.63 | +248,945.99 → **+239,843.04** |
| pre-held | 5 | 4.361 | (round-trip −10,120.33) | 169,508.83 | 460,865.63 | +291,356.80 → **+281,236.47** |
| pre-held | **6** | **5.000** | (round-trip −10,878.67) | 148,214.04 | 460,865.63 | **+312,651.59** → **+301,772.92** |

Downside (arb-back, `test_06`): the oracle fails closed (`Diverged`) ⇒ `B = 0`;
all-in loses `Δx − V = 243,589.74 − 97,411.54 = −146,478.75`; pre-held loses only the round-trip `−10,878.67`.

## Sensitivity
* `F` is dynamic: $305,991 (2026-10-24) → $188,924 (2026-10-25 a.m.) → $460,865.63 (2026-10-25 p.m.).
  Pre-held net ≈ `0.68·F` at the cap ⇒ **$128 k / $208 k / $313 k** respectively.
* All-in net is capacity-bound and insensitive to `F` while `F ≥ capacity`; it scales with the pool's NET reserve
  (a deeper pool both raises the capacity and the cost, but the cost rises faster — see the m-sweep).
