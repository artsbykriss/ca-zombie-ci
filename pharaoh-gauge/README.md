# P3-01 deep-dive — Pharaoh CL `GaugeV2` skipped-period reward inflation (Ramses C4 2024-10 M-01 class)

**Date:** 2026-10-21 · **Chains:** Avalanche C-Chain (material), Linea, Scroll, Mantle (no material value)
**Status:** read-only research. No transaction was signed or sent to any live network. Every state change in this
report happened on a local Foundry/Anvil fork of Avalanche (see `poc/`). Fork PoC: **6/6 tests PASS** in CI.

---

## 1. TL;DR

| Target | Live extractable (unprivileged) | Why | Latent risk |
|---|---|---|---|
| **Pharaoh CL, Avalanche** — 82 dormant CL gauges with a demonstrated skipped week | **≈ $7,272 net** (top single **$1,743.58**, gauge `0xa011554e…5342`, pool `0xf40e2320…0f19`) | `_advancePeriod()` writes a **2-week** span into one period; two attacker positions each at ~50 % of in-range liquidity bypass the 1-week clamp and are each paid the **full period supply** → total claim ≈ **2× the attacker's deposit**, paid out of the gauge's unclaimed float. Permissionless, no roles. **Fork-proven end-to-end (claim + ERC-20 transfer).** | Grows with gauge balances; re-arms if Pharaoh ever resumes CL emissions/bribes |
| Pharaoh CL — top-balance gauges `0x9ded4a78…` ($7,131) and `0x62cc4c46…` ($5,211) | $0 | pools are **active** (every week advanced); a skip cannot be manufactured without stopping all third-party swaps for a week | monitor: if activity dies for 7 days, +$12.3k becomes E-U |
| **Nile CL** (Linea), gauge `0x4d0af1ea…32e1` | **$0** | pre-fix code confirmed, but reward supply = 0 for periods 2961-2964; 30,774 NILE is a legacy balance (H-O), NILE has no deep market | if bribes resume |
| **Nuri CL** (Scroll) | **$0** | pool stale at period 2876; gauge holds 0.0068 NURI (dust) | none |
| **Cleopatra CL** (Mantle) | **$0** | same pre-fix accounting; TVL $12.2k, CLEO has no DEX pair (prior evidence; not re-enumerated) | none |

**Total live E-U now: ≈ $7,271.93** (82 gauges; 99.6 % of it in sAVAX/stAVAX/WAVAX). **Confidence: high** for the
mechanism and the top gauge (fork-executed), **medium-high** for the full 82-gauge sweep (depends on each pool staying
untouched for the target week and on prices at execution).

> **Correction to pass 3 (important).** The pass-3 text described the exploit as one attacker position that
> *dominates* the pool ("~$100 position, s≈1, profit = B_gauge"). That construction **pays $0**: the per-position
> sanity clamp in `Position.positionPeriodSecondsInRange` zeroes any position whose in-range seconds exceed one
> week, and a dominant position accrues **two** weeks. The working construction is **two (or more) positions, each
> below 50 % of in-range liquidity**: each accrues ≤ 1 week, passes the clamp, and each is paid the *entire* period
> supply — total ≈ 2× the attacker's deposit. Pass 3's dollar range ($7.0k / $1.69k top) was right; its call path was
> not, and the final ERC-20 transfer was never executed. Both gaps are closed below.

---

## 2. Total live extractable, with exact classifications

| Category | USD | What it is |
|---|---|---|
| **E-U** — external unprivileged | **$7,271.93** | 82 gauges on pools that skipped a week in the last 6 period advances; balances are sAVAX $3,388.99, stAVAX $2,991.00, WAVAX $868.83 (+$23 memecoins) |
| **H-O** — holder-only | $20,838.96 | remaining gauge float, incl. the two active top-balance gauges ($7,130.97 + $5,210.65); claimable only by the historical LP positions that earned those periods |
| **P** — privileged | $0 | — |
| **S** — stuck | $0 (not separable) | any float whose earning positions were burned is effectively stuck, but not measurable per-position |
| **Total gauge float enumerated** | $28,110.89 | 202 gauges, Avalanche block **98,162,261** (2026-10-21), DefiLlama prices |

`H-O` is not "safe": it is the *source* of the E-U payout. The attacker's inflated claim is paid out of this float,
so an E-U run physically consumes H-O money (see PoC test 6: the gauge balance drops by exactly the attacker's net
profit).

---

## 3. Mechanism, exactly

### 3.1 The pool writes two weeks into one period

Pharaoh CL `ClPool` (beacon `0xaaa32926…0c42` → impl `0x77dd39F2B04a5095B287deab21943d81dCf91CcA`,
Snowtrace-verified) advances **one step per call**:

```solidity
// ClPool.sol:90-131  (impl 0x77dd39F2…)
function _advancePeriod() public override {
    uint256 _lastPeriod = states.lastPeriod;
    if ((States._blockTimestamp() / 1 weeks) != _lastPeriod) {
        uint256 period = States._blockTimestamp() / 1 weeks;
        states.lastPeriod = period;
        (uint160 secondsPerLiquidityCumulativeX128, ...) = Oracle.newPeriod(..., period);
        states.periods[_lastPeriod].endSecondsPerLiquidityPeriodX128 = secondsPerLiquidityCumulativeX128; // :119
        ...
    }
}
```

`Oracle.newPeriod` extrapolates to `period * 1 weeks` with no `-1`:

```solidity
// Oracle.sol:378
uint32 delta = uint32(period) * 1 weeks - last.blockTimestamp;
```

So if the pool's last touch is in week `P` and the next touch is in week `P+2`, the single advance writes
`periods[P].end` at the **start of P+2** — a **two-week** span — and never creates period `P+1`
(`periods(P+1)` is all zeros).

Live confirmation (pool `0xf40e2320…0f19`, block 98,162,895):

| period | previousPeriod | startTick | lastTick | endSecondsPerLiquidityPeriodX128 |
|---|---|---|---|---|
| 2961 | 2956 | 2254 | 2784 | 585103964403466781672065830665107329309609315828 |
| 2962 | 0 | 0 | 0 | 0 |
| 2963 | **2961** | 2784 | 0 | 0 |

`2963 ← 2961` proves week 2962 was skipped in one advance.

### 3.2 The gauge pays by seconds, with a hard 1-week clamp

```solidity
// GaugeV2.sol:370 (impl 0xf556e96b…)
amount = FullMath.mulDiv(baseRewards, periodSecondsInsideX96, WEEK << 96);
```

where `baseRewards = tokenTotalSupplyByPeriod[period][token]`. And in the pool:

```solidity
// Position.sol:941-970 (impl 0x77dd39F2…)
periodSecondsInsideX96 = FullMath.mulDiv(liquidity, secondsPerLiquidityInsideX128, FixedPoint32.Q32);
...
// sanity
if (periodSecondsInsideX96 > 1 weeks * FixedPoint96.Q96) {
    periodSecondsInsideX96 = 0;          // <-- hard zero, not a cap
}
```

`periodSecondsInsideX96 = s × Δt × 2^96`, where `s` is the position's share of active liquidity. For a two-week span:

* `s = 1.0` → `2 weeks·2^96 > 1 week·2^96` → **0 payout** (this kills the pass-3 "dominating position" story);
* `s = 0.5` → `1 week·2^96` → **passes**, payout = `S` (the whole period supply);
* two positions at `s₁ + s₂ ≈ 1` (each < 0.5) → **total payout ≈ 2S**.

### 3.3 The attacker supplies `S`, the gauge float supplies the second `S`

`notifyRewardAmountForPeriod` is permissionless:

```solidity
// GaugeV2.sol:582-584
function notifyRewardAmountForPeriod(address token, uint256 amount, uint256 period) external lock {
    require(isReward[token], "!Whitelisted");
    require(period > _blockTimestamp() / WEEK, "Retro");
```

The attacker deposits `S` of token `T` for a future period `P`, mints **two** large positions at the start of `P`,
ensures `P+1` is untouched, advances at `P+2`, and claims `P` with both positions. Total payout `≈ 2S`, of which `S`
is the attacker's own deposit and `S` comes out of the gauge's pre-existing float. **Net profit ≈ S**, repeatable per
gauge and per reward token until the float is consumed (`S ≤ B_gauge`).

No roles, no whitelist (other than `isReward[T]`, already true for every reward token), no governance, no flash loan.

---

## 4. Live-state assessment

**Avalanche head used:** block **98,162,895** (timestamp 1,792,598,616 = 2026-10-21 16:03 UTC), period **2963**
(2964 starts 2026-10-22 00:00 UTC). Snapshot/pricing at block 98,162,261.

| Item | Value |
|---|---|
| CL factory / beacon / NFP | `0xAAA32926fcE6bE95ea2c51cB4Fcb60836D320C42` |
| Pool impl (beacon → impl) | `0x77dd39F2B04a5095B287deab21943d81dCf91CcA` (pre-fix `_advancePeriod`, `newPeriod` without `−1`) |
| Gauge beacon → impl | `0xAAA2D4987EEd427Ba5E2c933EeFCD75C84b446B7` → `0xf556e96bdc4A0D1C938aAA967985de42980AbF32` (formula `WEEK<<96`, **no cap**) |
| Voter | `0xAAAf3D9CDD3602d117c67D80eEC37a160C8d9869` — `length()=202`, `isAlive(top gauge)=true` |
| Voter PHAR balance | **0.466 PHAR** (emissions effectively exhausted) |
| Gauges enumerated | **202**; 106 are CL pools that answer `lastPeriod()` (the other 96 revert — non-CL/dead entries) |
| Reward tokens scanned | **448** (union of `getRewardTokens()` over all 202 gauges) |
| Reward supply periods 2962, 2963, 2964 | **0 for all 448 tokens / 202 gauges** (1,344 calls, 0 non-zero) — no one is funding any gauge |
| Last funded period, gauge `0xa011554e…` | **2909** (PHAR 3.806e18); sAVAX/stAVAX last funded **2908** (≈ 54 weeks ago) |
| Gauges with a skip in the last 6 advances | **82** (of 106 CL pools), aggregate priced float **$7,271.93** |

**Top 10 by extractable float (all 82 in `analysis/skippable_gauges.csv`):**

| # | USD | Gauge | Pool | Last adv. (prev) | Contents |
|---|---|---|---|---|---|
| 1 | **1,743.58** | `0xa011554ef697e88221217b70b3b3ecdf51345342` | `0xf40e23204b2e1cc94930e15576b9ce47b4ad0f19` | 2963 (2961) | sAVAX 85.756 ($1,096) + stAVAX 54.523 ($648) |
| 2 | 1,368.95 | `0xca2201a9d3c8dad91de9908effdc9077e5ca7098` | `0x80b405b44775f0b1c065b748d087137ddef13376` | 2956 (2953) | stAVAX 57.739 ($686) + sAVAX 53.457 ($683) |
| 3 | 1,040.40 | `0x20285c1de454a40a4cde0257afcaf05bdbe726eb` | `0x0c81fb1de32dc81b7fb4be4309786d23764c446a` | 2956 (2932) | sAVAX 40.578 ($519) + stAVAX 43.935 ($522) |
| 4 | 911.62 | `0xd23c27f63c051aa97ac4942d361335d876be8b80` | `0x66531c847cce6fe55257c6d5405163818dc42295` | 2959 (2955) | sAVAX 35.544 + stAVAX 38.509 |
| 5 | 731.14 | `0x4d779fddbd516b62ff5ffb367693b9b0c8d378da` | `0x365ac0c19b8171151a10ea1af308c476df18b127` | 2962 (2961) | sAVAX 28.497 + stAVAX 30.895 |
| 6 | 440.94 | `0x8fea26e6ff715dc48894dfd6a4ace09289c88503` | `0xa5be8073dc57fbfae8ae86833bbd765bbb682851` | 2963 (2961) | WAVAX 43.196 ($429) + KIMBO |
| 7 | 328.73 | `0xf09070add9ae62adfa01ce593c8558524b057e47` | `0xabe160715c6c2eb46f4d46d2e3feca8b4f4e8e5a` | 2959 (2955) | WAVAX 32.871 ($326) + MEOW |
| 8 | 207.11 | `0xa398fd2b4c308d9ea75dc94ed958a3354bbcb841` | `0x331c4877d87f56241f2d3ff906578842f204567e` | 2947 (2945) | sAVAX 8.078 + stAVAX 8.746 |
| 9 | 189.25 | `0x7e1954bd4e9326ec86ba1823f6bdc1e2028b6f1c` | `0x3a1a343da1d8e6b61bb26f1df5a870f634143dee` | 2942 (2924) | sAVAX 7.381 + stAVAX 7.992 |
| 10 | 115.85 | `0x54411cf448b1d01418956a8e9dc1a855b0dc9357` | `0xc2c7c3049d7020e9bfe1b79ddb41ea55801002df` | 2959 (2950) | WAVAX 11.461 ($114) + TECH |
| | **7,271.93** | **82 gauges** | | | 99.6 % sAVAX/stAVAX/WAVAX |

The two largest balances overall — `0x9ded4a78…` $7,130.97 and `0x62cc4c46…` $5,210.65 — are on **active** pools
(`previousPeriod == n−1` for every recent advance) and are **not** currently extractable; they are H-O.

### Tokens are liquid
sAVAX and stAVAX are the only material components (14.3 k sAVAX-equivalent); both have deep Avalanche markets
(DefiLlama prices $12.7811 / $11.8762 at the snapshot block). WAVAX $9.9263. There is no $7k slippage problem.

---

## 5. What the attacker must do (exact call path)

Preconditions: a CL gauge whose pool will not be touched for one full week; reward token `T` with `isReward[T]=true`
(already true); attacker owns two position NFTs in range.

1. **Fund a future period** (current period 2963 → target `P = 2964`):
   `gauge.notifyRewardAmountForPeriod(T, S, P)` — transfers `S` of `T` from the attacker; sets
   `tokenTotalSupplyByPeriod[P][T] = S`. (`GaugeV2.sol:582`; only `isReward[T]` and `P > now/WEEK`.)
2. **At the start of `P`** (2026-10-22 00:00 UTC for this run) mint **two** positions in range with large, equal
   liquidity (e.g. each ≥ 100× the pool's current active liquidity) via the NFP
   `0xAAA78E8C4241990B4ce159E105dA08129345946A`. Both get a checkpoint for `P` and a `secondsPerLiquidityPeriodStartX128 ≈ 0`.
   (The mint's `advancePeriod` creates period `P`.)
3. **Do not touch the pool during `P+1`.** No swap/mint/burn/collect; `Voter.distribute` must not call the gauge
   (it doesn't — PHAR emissions are exhausted). Dormant pools already go weeks without a touch.
4. **At the start of `P+2`** call `pool._advancePeriod()` (public) — writes `periods[P].end` two weeks after `P` began.
5. **Claim `P`** from both NFTs:
   `gauge.getPeriodReward(P, [T], tokenId, attacker)` (`GaugeV2.sol:387`, requires only NFT ownership).
   Each position receives `≈ S`; total `≈ 2S`; the gauge float is debited by `≈ S`.
6. **Exit** the LP principal (burn/collect). Optional — the positions are dust relative to the profit.

Costs: ~1.5 M gas per gauge (2 mints + 2 claims), at Avalanche ~25 nAVAX/gas ≈ 0.04 AVAX ≈ **$0.37**. Capital `S`
is returned inside the payout; the only real cost is gas and two weeks of price exposure on a dust LP.

Scale: all gauges share the same Unix-week boundary, so one 2-week cycle can cover all 82 gauges. Capital required =
Σ `S_gauge` ≈ $7.3k (recovered + profit), gas ≈ **$30**, net ≈ **$7.2k**.

---

## 6. PoC / fork verification

**Files:** `poc/test/PharaohGauge.t.sol` (single self-contained Foundry test file, vendored `lib/forge-std`).
**Run:** `forge test -vv` from `poc/` (forks Avalanche at head via `AVAX_RPC_URL`, default
`https://api.avax.network/ext/bc/C/rpc`; no key needed, no secret in the repo).
**CI:** GitHub Actions on the public CI repo, `forge test` job.

| Run | URL | Result |
|---|---|---|
| 1 (5 tests) | https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39629612846 | success, 5/5 PASS |
| 2 (6 tests, final) | https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39631152725 | success, **6/6 PASS** in 4.2 s |

| Test | What it proves | Key numbers (fork) |
|---|---|---|
| `test_1_dominantLp_getsZero_clamp` | pool-side 2-week over-extrapolation is real; a **dominant** single position is **zeroed** by the clamp | `periodCumulativesInside(P)=8.574e27 ≈ 2·WEEK·2^128/(L+Latt)`; `positionPeriodSecondsInRange(P)=0`; payout **0** |
| `test_2_halfShare_takesWholePeriod_thirdPartyFunded` | a ~48 % position passes the clamp and is paid the **whole** period supply = 2× its fair share | seconds 4.6097e34 ≈ 0.962 week; supply 5e18; **payout 4.8101e18** (2.00× fair share 2.405e18) |
| `test_3_selfFunded_isBreakeven` | one self-funded position gets back **only its own deposit** | deposit 5e18 → payout **4.8101e18** (≤ deposit) |
| **`test_6_twoPositions_drainGaugeFloat`** | **THE PROFIT PATH** — two positions each ~49.8 % → total payout ≈ 2× deposit, paid from the gauge float | deposit **5e18**; each position 2.2938e17 liquidity (103× pool); seconds 4.7681e34 each; **total payout 9.9507e18 (1.99×)**; **net +4.9507e18**; gauge float 85.756 → 80.805e18 (debit = net) |
| `test_4_legacyPeriods_unclaimable` | a fresh position **cannot** reach legacy periods (checkpoint gate) — the float is only reachable via the funded-period trick | `periodEarned(2909)=0`, `positionPeriodSecondsInRange(2909)=0` |
| `test_5_noCurrentEmissions` | live-state monitor: nobody is funding the gauge | period 2963 supply = 0; 2962 supply = 0 |

**What was executed vs. not.** The final ERC-20 transfer **was executed** (`getPeriodReward` → `safeTransfer`), on a
fork of the live state, with the reference state re-read at each run. Nothing was executed on mainnet. Not executed:
a multi-gauge sweep (the 82-gauge aggregate is a sum of independently verified per-gauge balances; each gauge is the
same code and the same recipe, but only the top gauge's claim was simulated).

---

## 7. Sibling deployments (no material value)

| Deployment | Chain | Status | Why $0 |
|---|---|---|---|
| **Nile CL** `0x4d0af1ea…32e1` | Linea | pre-fix `ClPool`/`GaugeV2` confirmed (same CREATE2 stack, impl `0xed48f13b…`); balance 30,774 NILE + 1,524 xNILE | supply = 0 for 2961-2964; last non-zero 2920 was 0.00039 NILE; NILE has no DefiLlama price and only a ~$90 DEX pool → legacy balance is H-O/dust |
| **Nuri CL** `0x50cdb60a…` | Scroll | pre-fix; pool **stale at period 2876**; gauge holds 0.00683 NURI | no emissions, no market, dust |
| **Cleopatra CL** | Mantle | pre-fix source (prior pass); 103 voter entries; TVL $12,162; CLEO has no DEX pair | not re-enumerated (note only); dust regardless |

Nuri was previously deep-dived for a *different* V3 class; this M-01 gauge skipped-period class is distinct
(confirmed present in the deployed Scroll code by pass 3) but economically dead.

---

## 8. Verdict, residual and latent risk

**Verdict:** the class is **live and profitable**, but the pot is the gauges' **legacy float**, not weekly emissions.
An unprivileged attacker can extract **≈ $7.27k** from 82 dormant Pharaoh CL gauges in one 2-week cycle, top single
**$1.74k**, with ≈ $7.3k of recyclable capital and ≈ $30 of gas. **E-U, high confidence.**

**Residual H-O:** $20.8k of gauge float on the remaining 124 gauges (including the two active top-balance gauges) is
claimable only by historical LP positions. It is not attacker-reachable today.

**Latent / re-arm conditions (monitors):**
1. **Gauge balances grow** — any new `notifyRewardAmount*` on a dormant gauge adds directly to the E-U ceiling.
   Watch `NotifyReward` events and `tokenTotalSupplyByPeriod(current)`.
2. **A pool goes dormant** — if the active top-balance pools (`0xa20c959b…` $7,131 and `0xa71ba393…` $5,211) go
   7 days without a swap/mint/burn/collect, +$12.3k re-arms.
3. **New Ramses-V2-CL forks** — the pre-fix stack is identified by `_advancePeriod` (single step) + `Oracle.newPeriod`
   without `−1`; any new deployment of that bytecode with funded gauges re-arms the same recipe.
4. **Emissions resume** — if Pharaoh re-funds CL gauges (PHAR/bribes), each funded week becomes capturable at 2× by
   the same two-position construction; the ceiling then scales with the weekly notified amount, not the float.

**Blockers:** none for the top gauge. For a full sweep, the forward one-week skip is the only operational
uncertainty (it is the natural state of the 82 pools, but not guaranteed).

---

## 9. Methodology, sources, caveats

* **Source verification:** Snowtrace verified source for `ClPool` impl `0x77dd39F2…` (ClPool.sol:90-131,
  Oracle.sol:363-389, Position.sol:881-977) and `GaugeV2` impl `0xf556e96b…` (GaugeV2.sol:302-372, 387-412, 582-593);
  NFP impl `0x9f10D255…` (MintParams includes `veNFTTokenId`).
* **Live reads:** Avalanche public RPC (`https://api.avax.network/ext/bc/C/rpc`), block 98,162,895 for balances /
  period history; block 98,162,261 for the 202-gauge snapshot. Linea `rpc.linea.build` block 32,387,477; Scroll
  `rpc.scroll.io` block 35,454,612; Mantle `rpc.mantle.xyz` block 102,233,976.
* **Scan:** 202 gauges → 448 reward tokens → `tokenTotalSupplyByPeriod` for periods 2962/2963/2964 = **1,344 calls,
  0 non-zero**. Period chains walked back 6 advances per pool (106 pools): 82 with ≥1 skip, 60 with the latest
  advance skipping.
* **Prices:** DefiLlama `coins.llama.fi/prices/current` at 2026-10-21 (sAVAX $12.7811, stAVAX $11.8762,
  WAVAX $9.9263, USDC $0.9995). PHAR/xPHAR/NURI/CLEO are unpriced and counted at $0.
* **PoC:** Foundry 1.8.5, solc 0.8.24, fork of Avalanche head; all tests run in CI
  (https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39631152725).
* **Caveats:**
  1. The forward skip is assumed, not guaranteed, for each of the 82 pools. The top gauge's pool skipped the most
     recent week (2962) and the 4 weeks before it, so its skip is the safest.
  2. The 82-gauge aggregate assumes the attacker can fund and claim each gauge; it is a sum of per-gauge balances, not
     a single atomic transaction.
  3. Prices move; the USD numbers are at one block. Token amounts are exact.
  4. PHAR and other Pharaoh-native tokens are unpriced; their contribution is excluded, so the true token-denominated
     ceiling is slightly higher but not liquid.
  5. The two active top-balance gauges are excluded; they are the largest single latent re-arm.
  6. No mainnet transaction was signed or sent; nothing here is an instruction to transact.

---

## 10. Files index

```
pharaoh-gauge/
├── README.md                     # this report
├── summary.json                  # machine-readable summary
├── analysis/
│   ├── gauges_snapshot.json      # 202 gauges, tokens, balances, prices, USD (block 98,162,261)
│   ├── skippable_gauges.json     # 82-gauge E-U subset with period chains
│   ├── skippable_gauges.csv      # same, tabular
│   ├── pool_skips.json           # per-pool period chains (last 6 advances)
│   ├── supply_scan_all_gauges.json # 448 tokens × periods 2962-2964 = all zero
│   ├── top_gauges_live.json      # top-5 gauge balances with prices
│   └── nile_nuri.json            # Linea/Scroll live checks
├── poc/
│   ├── foundry.toml
│   ├── lib/forge-std/            # vendored
│   └── test/PharaohGauge.t.sol   # 6 tests, all PASS
├── ci-log.txt                    # full GitHub Actions log (run 39631152725)
├── ci-artifacts/                 # downloaded artifacts (if any)
└── ci-out/                       # (empty; results are in ci-log.txt)
```

*Read-only research · fork-only PoC · no secrets · no mainnet transactions.*
