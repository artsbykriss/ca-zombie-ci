# Child 3 — Cost to move the Hyperliquid BBO mid (BTC & ETH perps), from live order-book depth

**Snapshot:** 2026-10-15 23:10:19–23:10:24 UTC (single synchronized round; fine L2 book + `nSigFigs` 4/3/2 depth for BTC & ETH).
**Purpose:** feed the Papertrade manipulation-cost model. Papertrade prices trades at the HL BBO mid `(bestBid+bestAsk)/2`; the cost of displacing that mid is the cost of moving HL's top of book.
**Machine-readable companion:** `child3-cost-model.json` (same numbers, full precision + assumptions). Raw books: `child3-books-BTC.json`, `child3-books-ETH.json`, all variants in `child3-depthvariants.json`.

---

## TL;DR

| Displacement of BBO mid | BTC — sweep notional | BTC — round-trip $ cost | ETH — sweep notional | ETH — round-trip $ cost |
|---|---|---|---|---|
| **15 bp up** | $43.4M – $57.1M | **$109k – $190k** | $17.7M – $29.3M | **$45k – $111k** |
| **30 bp up** | $57.1M – $83.7M | **$190k – $437k** | $29.3M – $48.6M | **$111k – $294k** |
| 15 bp down | $35.8M – $53.7M | $80k – $166k | $15.1M – $25.4M | $35k – $85k |
| 30 bp down | $53.7M – $94.2M | $166k – $575k | $25.4M – $49.0M | $85k – $303k |

Ranges: **cheapest mechanism (cross-and-rest, "B") → full pure sweep ("A")**, round-trip cost with **both legs taker at HL's current base perp taker fee 0.045% (4.5 bp)**, measured no-refill unwind. At the incident-implied effective fee (2.25 bp) the round-trip totals are ~10–18% lower (full table below). Sweep notional is *capital deployed*, not cost — nearly all of it is recovered on the unwind; the round-trip cost is slippage + fees.

**Natural drift (24 h to 23:06 UTC):** a 15 bp move in **1 min** happens naturally **4.2% of minutes (BTC, ≈2.5×/h)** and **8.4% of minutes (ETH, ≈5.0×/h)**; within **5 min**, 22.1% (BTC) / 33.7% (ETH). Median reversion time after a ≥15 bp 1-min move: 6.5 min (BTC) / 5 min (ETH). Post-snapshot, ETH mid actually drifted **−20.4 bp in 4 min** (pure natural flow, 23:10→23:14 UTC) — i.e., 5–20 bp displacements are routinely within natural drift, and persistence requires continuous defending.

**Incident calibration (Oct 10–11, 2026):** ETH ~$20M flow ↔ 10–20 bp mid matches this book: sweep cost at 15 bp today is $17.7M (mech B) / $29.3M (mech A). $231M total volume / $52k fees = **2.25 bp effective**, ≈ 6.5 round trips of a 15 bp ETH displacement at that rate. Current base taker is 4.5 bp, so the operator was on a discounted/staked tier (or mix); modeled at both.

---

## 1. Method

### 1.1 Data
- `POST https://api.hyperliquid.xyz/info {"type":"l2Book","coin":"BTC"|"ETH"}` — top **20 levels/side** only.
- To see depth beyond 20 levels: same endpoint with `"nSigFigs": 4|3|2`. HL aggregates the full book into ≤20 buckets; verified empirically that **asks round UP** to the bucket grid and **bids round DOWN** (e.g., ETH fine top ask 2447.0 → nS3 label 2450; top bid 2446.9 → nS3 label 2440). BTC nS4/nS3/nS2 = $10/$100/$1,000 buckets; ETH = $0.10/$1/$10 (nS4 reaches ±24 bp BTC, ±80 bp ETH; nS3 reaches ±237 bp BTC, ±798 bp ETH).
- 1-min candles, rolling 24 h (1,441 bars) for volatility.
- Fee schedule: `https://hyperliquid.gitbook.io/hyperliquid-docs/trading/fees` (fetched 2026-10-15).

### 1.2 Book model
Composite per-side ladder = fine 20 levels (exact point masses) → nS4 buckets → nS3 buckets → nS2 buckets, de-overlapped at the fine edge. Bucket depth is integrated as **uniform density within the bucket** (fractional consumption and average price by integral). This yields real, data-driven depth to ±2,400 bp (BTC) / ±7,980 bp (ETH).

Key consistency checks (fine vs nS4 cumulative at the fine edge, and nS3 vs nS4 at the overlap): ETH 0.994–1.053 (essentially identical → bucket semantics + no double count) and BTC 0.78–1.15 vs *non-simultaneous* fetches (BTC tape was falling fast; 0.05–0.7 s between requests → churn noise). Conclusion: composite depth is good to roughly **±10–30% locally**, better away from splice boundaries. All raw material is archived.

### 1.3 Microstructure (critical for Papertrade)
HL perp prices allow ≤5 significant figures → at BTC ≈ $82.3k the tick is **$1** and at ETH ≈ $2.45k it is **$0.10**. Both books are quoted at **exactly a 1-tick spread**, so:

- There is **no free quote-improvement**: you cannot place a resting bid above the best bid without crossing (a bid at the ask is marketable).
- Therefore **any upward mid move requires crossing**; the cheapest "step" is clearing the whole best-ask level:
  - BTC: consume 2.4672 BTC ($202,950) → mid +0.06 bp (pure sweep) / +0.12 bp (rest residual at the ask price).
  - ETH: consume 243.38 ETH ($595,632 — a single whale ask) → mid +0.20 bp / +0.41 bp.
- Downward moves mirror on the bid side (bottom quote $1/$0.1 wide).

### 1.4 Mechanisms modeled
- **A — pure sweep (market buy of asks / sell of bids):** consume levels until the *next untouched ask* `A*` satisfies `(bestBid + A*)/2 ≥ target`. Best bid assumed static. Cost = consumed notional; mid known exactly from level prices.
- **B — cross-and-rest (marketable limit):** limit buy at price `P*` chosen so it consumes asks `≤ P*` and its **residual rests at P\***, making the attacker's order the new best bid. New mid `= (P* + next ask)/2`. Cost = consumed notional (the rest is unfilled inventory at `P*`, with adverse-selection risk if sellers hit it). Same construction mirrored for down moves.
- After any sweep the next best quote is estimated at `P* ± tick` (uniform-density central estimate). For BTC deep moves the nS3 $100 bucket grid admits up to ~+6 bp realized overshoot vs the central estimate (ETH ~±1 bp); labeled `new_mid_label_variant` in JSON brackets this.
- **Duality (exact):** `mechA(m) ≡ mechB(2m)` — both clear the identical ask range (`P*` algebraically identical), so *moving the mid m bp by pure sweep costs the same dollars as moving it 2m bp by cross-and-rest*. This is why mech B costs ≈ half of mech A for the same mid move.

### 1.5 Round-trip cost
- **Unwind (measured, no-refill):** aggressive taker of the exact acquired size through the **untouched opposite ladder** (original bids for a long, original asks for a short). Notional-weighted VWAP both legs.
- `slippage_$ = (sweep VWAP − mid)·size + (mid − unwind VWAP)·size` (sign-adjusted).
- **Fees:** charged on fill notional, both legs taker → `fee_rate × (sweep notional + unwind notional)`. Variants: base taker 4.5 bp / Diamond-staking tier-0 taker 2.7 bp / incident-implied 2.25 bp / maker unwind 1.5 bp.
- **Task-prescribed conservative rule** (`round-trip slippage = 2× sweep slippage`) also computed; it is a good approximation: measured unwind slippage ≈ sweep slippage (mean ratio 1.03, range 0.74–1.35 across all 40 rows), with the rule understating round-trip slippage by at most ~15–20% in the worst rows (both extremes sit in the far-tail-adjacent BTC rows).

---

## 2. Market snapshot (primary dataset)

| | BTC | ETH |
|---|---|---|
| Fetch time (UTC) | 2026-10-15 23:10:19.75 | 2026-10-15 23:10:22.43 |
| Mid (BBO) | **82,257.5** | **2,447.25** |
| Spread | $1.0 (0.122 bp) | $0.10 (0.409 bp) |
| Tick | $1.0 | $0.10 |
| Best bid / ask size | 12.19 BTC / 2.47 BTC | 25.79 ETH / 243.38 ETH |
| Fine 20-level reach | ask +2.37 bp / bid −2.49 bp | ask +7.97 bp / bid −7.97 bp |
| Composite ladder depth (sampled) | ask $296M to +2,400 bp / bid $564M to −2,341 bp | ask $306M to +7,979 bp / bid $216M to −7,957 bp |
| Context | mark 82,299.2 / oracle 82,324.1; OI 41,471 BTC; funding 0.0000125/8h | mark 2,450.2 / oracle 2,450.89; OI 1.094M ETH; funding 0.0000125/8h |

**Regime note:** this snapshot is from a fast *falling* tape (post-move: BTC mid −8.0 bp and ETH mid −20.4 bp within 4 min; ETH realized vol 83% annualized over the prior 24 h). Books during sell-offs are typically thinner on the bid side than calm-market averages for the same hour-of-day. 23:10 UTC is also outside US/EU peak hours → depths here are likely **below** peak-hour depth (i.e., these costs are conservative-low for liquid hours).

---

## 3. Depth context — notional within ±X bp of mid

| distance | BTC ask / bid | ETH ask / bid |
|---|---|---|
| ±0.5 bp | $0.30M / $1.17M | $0.60M / $0.06M |
| ±1 bp | $1.08M / $1.37M | $0.76M / $0.11M |
| ±2.4 bp | $5.93M / $3.40M | $1.74M / $1.29M |
| ±5 bp | $15.6M / $11.3M | $5.22M / $4.66M |
| ±10 bp | $30.4M / $26.1M | $12.4M / $10.1M |
| ±20 bp | $48.8M / $44.0M | $21.9M / $20.4M |
| ±30 bp | $57.2M / $53.8M | $29.5M / $25.6M |
| ±60 bp | $83.8M / $94.3M | $48.6M / $49.0M |

---

## 4. Per-move cost tables

Columns: sweep notional & VWAP (capital deployed), sweep slippage vs mid, measured unwind notional/slippage, fees & **total round-trip $** at 4.5 bp taker both legs, same at 2.25 bp, round-trip as % of sweep notional, and the task's 2×-rule variant. Rounding: $ to 3 significant figures, bp to 0.1.

### 4.1 BTC — up moves (mid 82,257.5)

| move | mech | sweep | sweep VWAP | sweep slip | unwind | unwind slip | fees @4.5bp | **RT total @4.5bp** | RT total @2.25bp | RT % notional | 2×-rule |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 5 bp | A | $30.23M | 82,299.02 | 5.0 bp | $30.19M | 6.2 bp | $27k | **$61k** | $47k | 0.202% | $58k |
| 5 bp | B | $15.47M | 82,280.17 | 2.8 bp | $15.46M | 3.7 bp | $14k | **$24k** | $17k | 0.155% | $22k |
| 10 bp | A | $48.74M | 82,326.06 | 8.3 bp | $48.65M | 10.7 bp | $44k | **$136k** | $114k | 0.280% | $125k |
| 10 bp | B | $30.23M | 82,299.02 | 5.0 bp | $30.19M | 6.2 bp | $27k | **$61k** | $47k | 0.202% | $58k |
| 15 bp | A | $57.08M | 82,346.96 | 10.9 bp | $56.94M | 13.5 bp | $51k | **$190k** | $164k | 0.333% | $175k |
| 15 bp | B | $43.36M | 82,317.17 | 7.3 bp | $43.29M | 8.9 bp | $39k | **$109k** | $90k | 0.251% | $102k |
| 30 bp | A | $83.72M | 82,426.42 | 20.5 bp | $83.35M | 22.8 bp | $75k | **$437k** | $400k | 0.522% | $418k |
| 30 bp | B | $57.08M | 82,346.96 | 10.9 bp | $56.94M | 13.5 bp | $51k | **$190k** | $164k | 0.333% | $175k |
| 60 bp | A | $130.98M | 82,617.95 | 43.8 bp | $129.84M | 43.6 bp | $117k | **$1.26M** | $1.20M | 0.960% | $1.26M |
| 60 bp | B | $83.72M | 82,426.42 | 20.5 bp | $83.35M | 22.8 bp | $75k | **$437k** | $400k | 0.522% | $418k |

### 4.2 BTC — down moves

| move | mech | sweep | sweep VWAP | sweep slip | unwind | unwind slip | fees @4.5bp | **RT total @4.5bp** | RT total @2.25bp | RT % notional | 2×-rule |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 5 bp | A | $25.98M | 82,213.48 | 5.4 bp | $26.00M | 4.4 bp | $23k | **$49k** | $37k | 0.188% | $51k |
| 5 bp | B | $11.02M | 82,232.94 | 3.0 bp | $11.02M | 2.2 bp | $10k | **$16k** | $11k | 0.142% | $17k |
| 10 bp | A | $43.93M | 82,182.93 | 9.1 bp | $44.00M | 7.4 bp | $40k | **$112k** | $92k | 0.255% | $119k |
| 10 bp | B | $25.98M | 82,213.48 | 5.4 bp | $26.00M | 4.4 bp | $23k | **$49k** | $37k | 0.188% | $51k |
| 15 bp | A | $53.72M | 82,158.15 | 12.1 bp | $53.83M | 9.8 bp | $48k | **$166k** | $142k | 0.309% | $178k |
| 15 bp | B | $35.81M | 82,197.30 | 7.3 bp | $35.86M | 6.0 bp | $32k | **$80k** | $64k | 0.223% | $85k |
| 30 bp | A | $94.23M | 82,043.67 | 26.0 bp | $94.72M | 25.8 bp | $85k | **$575k** | $532k | 0.610% | $576k |
| 30 bp | B | $53.72M | 82,158.15 | 12.1 bp | $53.83M | 9.8 bp | $48k | **$166k** | $142k | 0.309% | $178k |
| 60 bp | A | $126.09M | 81,922.11 | 40.8 bp | $127.13M | 41.7 bp | $114k | **$1.16M** | $1.10M | 0.919% | $1.15M |
| 60 bp | B | $94.23M | 82,043.67 | 26.0 bp | $94.72M | 25.8 bp | $85k | **$575k** | $532k | 0.610% | $576k |

### 4.3 ETH — up moves (mid 2,447.25)

| move | mech | sweep | sweep VWAP | sweep slip | unwind | unwind slip | fees @4.5bp | **RT total @4.5bp** | RT total @2.25bp | RT % notional | 2×-rule |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 5 bp | A | $12.23M | 2,448.51 | 5.1 bp | $12.22M | 6.6 bp | $11k | **$25k** | $20k | 0.207% | $24k |
| 5 bp | B | $5.22M | 2,447.96 | 2.9 bp | $5.22M | 3.3 bp | $5k | **$8k** | $6k | 0.152% | $8k |
| 10 bp | A | $21.77M | 2,449.50 | 9.2 bp | $21.73M | 10.9 bp | $20k | **$63k** | $53k | 0.290% | $60k |
| 10 bp | B | $12.23M | 2,448.51 | 5.1 bp | $12.22M | 6.6 bp | $11k | **$25k** | $20k | 0.207% | $24k |
| 15 bp | A | $29.28M | 2,450.53 | 13.4 bp | $29.20M | 15.5 bp | $26k | **$111k** | $98k | 0.379% | $105k |
| 15 bp | B | $17.74M | 2,449.06 | 7.4 bp | $17.71M | 8.9 bp | $16k | **$45k** | $37k | 0.253% | $42k |
| 30 bp | A | $48.57M | 2,453.24 | 24.5 bp | $48.32M | 27.3 bp | $44k | **$294k** | $273k | 0.606% | $281k |
| 30 bp | B | $29.28M | 2,450.53 | 13.4 bp | $29.20M | 15.5 bp | $26k | **$111k** | $98k | 0.379% | $105k |
| 60 bp | A | $69.91M | 2,458.33 | 45.3 bp | $69.29M | 43.7 bp | $63k | **$682k** | $651k | 0.976% | $693k |
| 60 bp | B | $48.57M | 2,453.24 | 24.5 bp | $48.32M | 27.3 bp | $44k | **$294k** | $273k | 0.606% | $281k |

### 4.4 ETH — down moves

| move | mech | sweep | sweep VWAP | sweep slip | unwind | unwind slip | fees @4.5bp | **RT total @4.5bp** | RT total @2.25bp | RT % notional | 2×-rule |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 5 bp | A | $9.94M | 2,445.97 | 5.2 bp | $9.95M | 4.4 bp | $9k | **$18k** | $14k | 0.186% | $19k |
| 5 bp | B | $4.66M | 2,446.49 | 3.1 bp | $4.66M | 2.7 bp | $4k | **$7k** | $5k | 0.148% | $7k |
| 10 bp | A | $20.22M | 2,444.78 | 10.1 bp | $20.26M | 8.5 bp | $18k | **$56k** | $47k | 0.276% | $59k |
| 10 bp | B | $9.94M | 2,445.97 | 5.2 bp | $9.95M | 4.4 bp | $9k | **$18k** | $14k | 0.186% | $19k |
| 15 bp | A | $25.40M | 2,444.06 | 13.0 bp | $25.46M | 11.2 bp | $23k | **$85k** | $73k | 0.333% | $89k |
| 15 bp | B | $15.08M | 2,445.38 | 7.6 bp | $15.10M | 6.3 bp | $14k | **$35k** | $28k | 0.230% | $37k |
| 30 bp | A | $49.02M | 2,440.48 | 27.7 bp | $49.28M | 25.0 bp | $44k | **$303k** | $281k | 0.618% | $316k |
| 30 bp | B | $25.40M | 2,444.06 | 13.0 bp | $25.46M | 11.2 bp | $23k | **$85k** | $73k | 0.333% | $89k |
| 60 bp | A | $75.51M | 2,435.30 | 48.8 bp | $76.28M | 52.1 bp | $68k | **$834k** | $800k | 1.105% | $809k |
| 60 bp | B | $49.02M | 2,440.48 | 27.7 bp | $49.28M | 25.0 bp | $44k | **$303k** | $281k | 0.618% | $316k |

**Planning heuristic ($/bp of mid displacement, round trip, taker 4.5 bp both legs, up-move mech B):** BTC ≈ **$4.8k–7.3k per bp**; ETH ≈ **$1.6k–4.9k per bp**; mech A ≈ 2–3× that. For "size × move" budgeting: RT cost ≈ 0.15–0.25% of deployed notional at 5–15 bp (i.e., 15–25 bp of the deployed capital), rising to ~0.5–1.0% for 30–60 bp.

---

## 5. Fee assumptions (with sources)

| Assumption | Rate | Source |
|---|---|---|
| HL perp **base taker** | **0.045% (4.5 bp)** | HL docs fees page, fetched 2026-10-15 |
| HL perp base maker | 0.015% (1.5 bp); top maker tiers rebate −0.001…−0.003% | same |
| Diamond staking discount (−40%) taker, tier 0 | 2.7 bp | same (staking tiers table) |
| Volume tiers (14-day, weighted) | 4.5 → 2.4 bp taker by tier 6 | same |
| **Incident-implied effective** | **2.25 bp** ($52k / $231M) | task brief, arithmetic confirmed |

Notes: HL fees are assessed per fill on notional (price × size) and both legs pay. The widely quoted "2.25 bp taker" is **not** the current base rate — current base taker is 4.5 bp; 2.25 bp is consistent with a staked, high-volume account (e.g., Diamond tier 1–2 ≈ 2.1–2.4 bp) or a mixed maker/taker flow. Tables are therefore shown at 4.5 bp and 2.25 bp (and 2.7 bp in JSON) with a maker-unwind variant (sell leg at 1.5 bp) — the maker variant lowers the RT fee component from ~9 bp to ~6 bp of sweep notional; assuming a top maker-rebate tier it goes to ~4 bp.

## 6. Volatility / natural-drift context (24 h to 2026-10-15 23:06 UTC)

| Metric | BTC | ETH |
|---|---|---|
| Realized vol, annualized (1-min) | 52.6% | 83.1% |
| \|1-min return\| median / p90 / p99 / max | 3.5 / 10.2 / 29.3 / 59.3 bp | 4.9 / 13.7 / 40.3 / 168 bp |
| P(\|move\| ≥ 5 bp) within 1 min / 5 min | 35.1% / 64.4% | 48.2% / 72.6% |
| **P(≥15 bp) within 1 min / 5 min** | **4.2% / 22.1%** | **8.4% / 33.7%** |
| P(≥30 bp) within 1 min / 5 min | 0.9% / 5.7% | 1.8% / 10.3% |
| P(≥60 bp) within 1 min / 5 min | 0.0% / 1.0% | 0.5% / 2.5% |
| 1-min high-low range ≥15 bp | 8.7% of bars | 18.2% of bars |
| Max drawdown 24 h (1-min closes) | −2.45% | −4.53% |
| Max single-minute drop / rise | −59 / +58 bp | −168 / +110 bp |
| Events ≥15 bp 1-min move | 60 | 121 |
| Median / mean reversion to <½ the move (capped 30 min) | 6.5 / 12.1 min | 5.0 / 12.3 min |
| Still ≥½ displaced after 30 min | 21.7% of events | 27.3% |

**Interpretation for Papertrade:**
- A 10–15 bp mid displacement is **not rare noise**: ETH prints a ≥15 bp 1-min move ~5×/hour; within 5 minutes about a third of windows contain one. Attribution of a 10–20 bp move to manipulation is only meaningful with order-flow evidence, and a manipulated displacement must be re-swept continuously to survive drift.
- Post-snapshot drift confirms this: ETH mid fell 20.4 bp in the ~4 minutes after the snapshot on ordinary flow.
- Book persistence: median price reversion of a ≥15 bp move is 5–6.5 min, but **top-of-book depth refills much faster** — 2–3 s churn samples show top-5 ask notional on BTC going $0.02M → $0.23M within ~10 s right after a down spike, and fine/nS4 snapshots 0.05–0.7 s apart already differ 10–20% on BTC. A one-shot sweep's *price* effect can outlive the depth effect only until MMs re-quote; sustained mid displacement implies repeated sweeping (cost scales ~linearly with the number of re-sweeps needed).
- The 24-h window includes a sharp ETH sell-off (max −168 bp 1-min bar; last price 2,449.6) — a high-volatility day; in calmer regimes both drift and depth behave differently (deeper books, lower drift).

## 7. Sanity check vs the Oct 10–11 incident calibration

Given (from brief): ~$20M HL order flow moved the ETH mid 10–20 bp; the operation traded ~$231M total volume and paid ~$52k in HL fees.

| Comparison | Number |
|---|---|
| ETH sweep cost for 10 / 15 / 20 bp mid, mech B (this book) | $12.2M / $17.7M / $21.8M |
| ETH sweep cost for 10 / 15 / 20 bp mid, mech A (this book) | $21.8M / $29.3M / $38.7M |
| Incident flow | ~$20M for 10–20 bp |
| Verdict | **Consistent with this book's mech-B cost band** ($20M ≈ 18–19 bp mech B ≈ 10 bp mech A). No material depth regime shift between Oct 10–11 and Oct 15 is implied by this cross-check. |
| Fees: $231M / $52k | 2.25 bp effective — below today's 4.5 bp base taker → staked/tiered account or maker/taker mix; at 2.25 bp this corresponds to ≈ 6.5 round trips of a 15 bp ETH displacement (my measured 15 bp ETH RT deploy ≈ $17.7M × 2 legs). |

Caveats on the comparison: (i) my book is a single 23:10 UTC snapshot in a falling market — incident-time depth may differ by ±30%; (ii) "$20M of flow" may include both legs, partial fills across minutes, or multiple cycles — as a single-leg sweep cost the match is at the edge of coincidence; (iii) ETH mid in the incident moved 10–20 bp but the *round trip* costs then are not observable from the brief.

## 8. Caveats and explicit assumptions

1. **Single snapshot** (23:10:19–23:10:24 UTC, 2026-10-15), falling tape; no replenishment, no quote pull-back, no reaction of other participants during the sweep or hold period.
2. **Depth beyond 20 levels** comes from HL's own nSigFigs aggregation (asks rounded up, bids rounded down to $10/$100/$1,000 BTC and $0.10/$1/$10 ETH grids) — genuine book data, but coarse: uniform-within-bucket integration; local errors ±10–30% at splice boundaries (validated against fine book: ETH ratios 0.994–1.053).
3. **Mech A** assumes best bid stays put (realistically, MMs often *pull* during a sweep → true cost higher; conversely hidden/iceberg depth → cost lower). **Mech B** residual rests at the crossed limit and can be adversely selected; it is inventory risk not counted in cash cost.
4. **Next best quote after sweep** estimated at P ± tick (central); BTC nS3 $100 grid allows up to ~+6 bp realized overshoot vs a 10/15/30 bp target; ETH ~±1 bp. A label-edge variant is stored in JSON.
5. **Unwind** is fully aggressive (taker) through the untouched opposite ladder, no refill. Measured unwind slippage ≈ sweep slippage (mean ratio 1.03, worst 1.35), so the task's 2×-rule matches the data within ~±20%; if the book were thinner than sampled beyond ±240 bp (±800 bp ETH), the deep-tail assumption would flatter the unwind. Passive/maker unwind reduces fees but adds holding risk (drift vol shown in §6).
6. **Fees** per the table in §5; attacker assumed to have fee tier analogous to the incident (2.25–4.5 bp). Referral/staking discounts not compound-modeled beyond the variants given.
7. **No queue-position, latency, or MEV competition modeling**; on a busy venue MMs can re-quote faster than a human/API attacker, so realized displacement persistence may be shorter than modeled here.
8. **BBO-mid definition**: if Papertrade's 0x080e precompile ever reads something other than the L2 BBO mid (e.g., mark/oracle: BTC oracle 82,324.1 vs BBO mid 82,257.5 here), displacement economics differ — oracle/mark feeds are not sweep-manipulable in the same way.
9. Rounding: dollars to 3 sig figs in tables ($M 2 dp, fees $1k); bp to 0.1; percentages 3 dp. JSON carries full precision.

## 9. Files

| File | Content |
|---|---|
| `child3-books-BTC.json`, `child3-books-ETH.json` | raw `l2Book` responses (canonical snapshot) + timestamps |
| `child3-depthvariants.json` | all nSigFigs 2/3/4 variants, synchronized round |
| `child3-candles.json` | 1-min 24-h candles (both coins) |
| `child3-churn.json` | 4 top-of-book samples, ~2 s spacing (replenishment evidence) |
| `child3-meta.json` | metaAndAssetCtxs (szDecimals, OI, funding, oracle px) |
| `child3-cost-model.json` | machine-readable: books summary, depth, per-move tables (both coins, up/down, mech A/B), volatility, fee assumptions, incident calibration, caveats |
| `child3-cost-model.md` | this report |
| `child3_fetch.py`, `child3_snapshot.py`, `child3_analysis.py` | reproduction scripts (read-only public API; no keys, no transactions) |
