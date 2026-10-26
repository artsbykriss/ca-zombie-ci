# wsNET / USDG Morpho Blue — one-sided oracle guard + thin UniV2 TWAP → full free-liquidity drain

**Finding:** ZH4-PASS7 `P7-CRIT` (campaign's first fork-proven extraction) · **Chain:** Robinhood Chain (4663)
**Date:** 2026-10-25 · **Status:** read-only; PoC fork-verified only; **no mainnet transactions signed or sent**
**Subagent:** wsNET/USDG Morpho-Blue oracle deep-dive (Tier-1 critical, pass 7)

---

## 1 · TL;DR

| target | live extractable (external, unprivileged) | why | latent risk |
|---|---|---|---|
| **wsNET/USDG Morpho Blue market** (LLTV 62.5 %, id `0xaa586d…0589`) on singleton `0x9D53…1010` | **gross = the market's entire free liquidity = $460,865.63** (point-in-time; was $305,991 yesterday, $188,924 earlier today) | `LoopbackOracle.price()` reads a **thin UniV2 spot pair** × sNET index × treasury `backingPerToken`, and its `Diverged` guard is **one-sided** — it only reverts on a *downside* dump (`spot < 0.85·TWAP`). The upward clamp is **5 × floor**. A **held** ×6 skew of the $167 k USDG/NET pair (~30 min) lifts the oracle to the 5.011× cap, after which an unprivileged `borrow` drains the whole free liquidity. | **net** is strategy-dependent and measured below |

**Net (fork-measured in CI at pinned block 97,879,993, free liquidity = $460,865.63):**

| strategy | upside (net) | downside if the skew is arbitraged back |
|---|---|---|
| **Pre-held NET** (attacker already holds ≈ $148 k of NET) | **+$301,772.92** (incl. the −$10,878.67 skew round-trip) … **+$312,651.59** (borrow − collateral) | **−$10,878.67** (skew round-trip fees only) |
| **All-in** (NET is bought from the pool by the skew itself) | **+$58,365.47** (peak, at the 5× cap, capacity-bound) | **−$146,478.75** (the swap is sunk; NET is only worth its backing) |

**Not single-transaction.** A swap resets `blockTimestampLast`, so a same-block (flash-loan) skew contributes **0** to the TWAP (measured ratio **1.0000**). The skew must be **held ≥ 30 min** (`TWAP_MIN_WINDOW`).

**Confidence: HIGH** for the mechanism, the one-sided guard, the free-liquidity ceiling and the all-in net (fork-proven, 7/7 tests). **MEDIUM** for the pre-held net (it assumes an attacker who already holds ≈ 910 NET — 0.59 % of supply — and that no arbitrageur restores the pair during the 30-minute hold; the pair is genuinely inactive, but ~154 k NET sits outside the pool).

---

## 2 · Total live extractable now

> **E-U (gross): $460,865.63** — the whole free liquidity of the wsNET/USDG market at L2 block **97,879,993** (2026-10-25, CI-pinned), transferable by one unprivileged `borrow`.
> **E-U (net, realistic): ≈ $58.4 k (all-in) to ≈ $301.8 k (pre-held NET)** after the cost of holding the skew, with an **arb-back downside of −$10.9 k (pre-held) / −$146.5 k (all-in)**.
> This is **E-U** (no owner/admin/whitelist/insider). The only inputs are public liquidity, public contracts and the attacker's own capital. **No flash-loan path.**

The market's free liquidity is **dynamic** (suppliers deposit/withdraw continuously). Observed within ~2 hours on 2026-10-25: **$188,924 → $462,413 → $460,866**. The campaign README's **$305,991** was correct for its point-in-time; the correct *statement* is "the whole free liquidity, whatever it is at attack time".

---

## 3 · The bug, in exact terms

`LoopbackOracle` = **`src/lending/LoopbackOracle.sol`**, deployed at **`0xCDE9599059f8Ae6D6B9F33A0aF7877827ec75F16`** (1,550 B, **not** a proxy; Sourcify **exact_match** on chain 4663, solc 0.8.30):

```solidity
function price() external view returns (uint256) {
    uint256 twapWad = pairOracle.twapNetUsdg();                 // v2-cumulative TWAP, window ∈ [30 min, 4 h]
    uint256 spotWad = _pairPriceWad();                          // instantaneous r0*1e21/r1
    if (spotWad < twapWad * (BPS - DIVERGENCE_BPS) / BPS) {     // spot < 0.85*TWAP  <-- ONE-SIDED
        revert Diverged();
    }
    uint256 credited = twapWad * (BPS - HAIRCUT_BPS) / BPS;      // 0.90 * TWAP
    uint256 floorWad = treasury.backingPerToken();               // RFV / NET supply
    uint256 cap = floorWad * LendingConstants.PREMIUM_CAP;       // 5 * floor
    if (credited > cap) credited = cap;
    if (credited < floorWad) credited = floorWad;                // floor = LOWER bound
    return credited * sNet.index() / Constants.NET_UNIT * LendingConstants.WAD_TO_MORPHO_PRICE;
}
```

* `LendingConstants`: `HAIRCUT_BPS=1000`, **`PREMIUM_CAP=5`**, **`DIVERGENCE_BPS=1500`**, `LLTV=0.625e18`, `BPS=10000`.
* The **only** tradable leg is the TWAP. `pairOracle` (`PairOracle 0x929631b3…`) and `treasury` (`Treasury 0x04822Ea3…`) are **not pools**; the treasury's POL term is `2√(x·y)` (**k-invariant** under swaps), so trading the pair cannot move the floor.
* The NatSpec claims the guard *"only ever pauses, it never raises credit, so it cannot be exploited upward"* — true as written, but it means there is **no upward guard at all**: credit is bounded only by `5 × floor`.

**Manipulation mechanics** (`PairOracle.twapNetUsdg` / `_currentCumulative`): the TWAP averages the pair ratio over a window `[30 min, 4 h]`; `_currentCumulative` extrapolates the **current** reserves over `(now − tsLast)`. A swap sets `tsLast = now` ⇒ **zero** contribution in the same block. The attacker therefore: ① `checkpoint()` (permissionless, ≥30 min spacing) to pin a fresh observation at ratio 1, ② swap to skew, ③ **hold ≥ 30 min**, ④ borrow.

**Measured** (live `eth_call` stateDiff, block 97,790,883 — `analysis/guard_direction_test.json`):

| manipulation | result |
|---|---|
| spot **down** ×0.5 (d = 0 or 1800 s) | **REVERT `0xefac79d8` (`Diverged`)** |
| up ×2, d = 1800 s | no revert, price ×1.947 |
| up ×6, d = 1800 s | no revert, price ×4.108 |
| up ×10 / ×20, d = 1800 s | no revert, price **×5.011 / ×5.018 = cap** |

⇒ **the guard is one-sided; the ceiling is `5 × floor`.** (This corrects `pass7/oracle.md`'s "×1.15 cap", which was the *downside* guard value.)

---

## 4 · Live-state assessment (all read on-chain; `analysis/live_state.json`)

Pinned fork block **97,879,993** (chain 4663; CI-pinned via `RH_BLOCK` in `ci/run.sh`; `ci-artifacts/result-wsnet-oracle/ci-out/live_state.json`; the local snapshot at 97,857,656 gave the same free liquidity, $460,865.63):

| item | address | value |
|---|---|---|
| Morpho Blue singleton | `0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010` | — |
| wsNET/USDG market (62.5 %) | id `0xaa586d26a6fe62d9c0f0948fede6e2130500ac7a655587447e2d4a37e6330589` | `totalSupplyAssets 1,463,216,968,442` − `totalBorrowAssets 1,002,351,337,858` = **free $460,865.63** |
| wsNET/USDG market (38.5 %) | id `0xf47c7a7a…d33f` | same oracle; free ≈ $1,415 (dust) |
| LoopbackOracle | `0xCDE9599059f8Ae6D6B9F33A0aF7877827ec75F16` | `price() = 7.2280768e26` (1e24) |
| PairOracle | `0x929631b33F4070D6f54477fba3FD27566567dAca` | `twapNetUsdg = 157.50 WAD`, `lastCheckpointAt = 1792958100` |
| Treasury | `0x04822Ea321A0DEE6F40656172F29312104855d66` | `backingPerToken = 162.7615 WAD` |
| sNET | `0xb773ec2C326B7f98a5a83fc098825492F020a4c7` | `index = 4.440900404e9` (1 wsNET = 4.4409 NET) |
| wsNET (collateral) | `0x63C12667638f2Ae6fC6ae09B43D98Ec84a8586eA` | totalSupply 8,465.7 wsNET (permissionless `wrap()`) |
| NET (9 dec, 5 % fee-on-transfer) | `0xCA9c78Dd337A67F6e0077F65F5E9218719d30eDf` | totalSupply 155,060.7 NET |
| USDG (loan, 6 dec) | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` | singleton holds $59.35 M (all markets) |
| canonical UniV2 pair | `0x59F95461E68e0c77605299791E1449f175165B54` | r0 167,329.45 USDG / r1 1,062.72 NET; **$167.3 k per side** |
| Staking | `0xB078cc304A0B264C5F3680DC0488954ACcd02E87` | `enabled = true`, `warmupEpochs = 0` (stake is 1:1, no lockup) |

* `0.9·TWAP (141.8) < floor (162.76)` ⇒ **the price is pinned to the floor today**, so the **full 5× headroom is live**.
* The Treasury owns **274.0 M / 286.4 M LP = 95.7 %** of the canonical pair (passive POL) — the *other* side is retail.
* **Guard re-verified at head:** downward dump → `Diverged`; upward ×6 → no revert (fork tests `test_01`).

### wsNET is the only *funded* custom-pool oracle on chain 4663

`analysis/oracle_selector_scan.json` + `ci-out/oracle_scan.json`: the singleton hosts **≈510–514 markets / 500 distinct oracles** (the API count drifts as markets are added). Classifying every oracle's bytecode:

| selector | # oracles | comment |
|---|---|---|
| **`getReserves()` `0x0902f1ac`** | **1 — the LoopbackOracle** | the finding |
| `slot0()` `0x3850c7bd` | 74 | UniV3-based; **every market using them is unfunded** |
| `latestRoundData()` `0xfeaf968c` | 299 | Chainlink / meta-oracles (incl. the Steakhouse `MetaOracleDeviationTimelock` on USDe) |
| `latestAnswer()` `0x50d25bcd` | 2 | — |
| `getPriceUnsafe()` `0x96834a8a` | 0 | — |

Of the **76** markets whose oracle contains *any* thin-pool selector, exactly **2 are funded** — and both are the **same wsNET/USDG LoopbackOracle market** at two LLTVs (62.5 % and 38.5 %). 41 oracles are EIP-1167 minimal proxies → 5 distinct implementations, none embedding `getReserves`/`slot0`.
⇒ **wsNET is the only funded market whose oracle embeds a thin-pool spot read; there is no funded sibling to rank.** (This corrects the campaign's "11 markets" framing — the real universe is ≈510 markets.)

### Mitigations considered — none preventive

| candidate defence | finding |
|---|---|
| Morpho pause / guardian | **none** — the singleton has no `pause()`; `owner()` (`0x06059563…`) only gates `enableIrm`/`enableLltv` (add-only) and `setFee` (≤ 25 %). |
| Treasury `PremiumSeller` | sells at most `PREMIUM_CLIP_BPS = 25` bps of the pool's NET **per hour** (min interval 1 h) ⇒ ≈ 2.7 NET/h vs. a 600+ NET skew — negligible. |
| Treasury `InverseBond` | mints NET at `backing × (1 − 1.5 %)`, capped at 100 bps of liquid reserves **per epoch** — a *cheap NET source* for the attacker, not a defence. |
| Treasury floor leg | needs a **$15 M donation** to move 1.6×; the POL term is k-invariant under swaps. |
| NET trading tax | 500 bps fee-on-transfer on the canonical pair only — a **cost** to the attacker, not a cap (the fork PoC includes it). |
| Second NET venue | **none found** — `uniswapV2Factory.getPair(NET, WETH) = 0`; the canonical USDG pair is NET's only v2 venue (the campaign found none either). |
| USDG issuer freeze | USDG is a Paxos `PaxosTokenClaimableRewards` with an address-freeze storage layer (`frozen` slot 6, `frozenData` slot 273) and a facet table — an issuer **post-hoc exit risk** for the borrowed USDG, not a preventive defence. |

---

## 5 · What an attacker can and cannot do

**Can (all permissionless, no keys):**
1. **Skew** the canonical USDG/NET pair with a `swap` — buy NET with USDG (the NET 500 bps fee-on-transfer applies to the buy leg).
2. **`checkpoint()`** the PairOracle (permissionless) to pin a clean 30-minute TWAP window.
3. **Hold** the skew ≥ 30 min (TWAP_MIN_WINDOW); the spot must stay above `0.85 × TWAP`.
4. **Acquire wsNET**: `NET.approve(Staking)` → `Staking.stake` → `sNET.approve(wsNET)` → `wsNET.wrap()` (all permissionless, `warmupEpochs = 0`), then `Morpho.supplyCollateral`.
5. **`Morpho.borrow`** USDG up to `min(free liquidity, 0.625 × collateral × inflated price)`.
6. **Default / abandon** the wsNET collateral (no permission needed) and transfer the USDG out (plain ERC-20).

**Cannot:**
* **Flash-loan / single-tx**: a same-block skew leaves the TWAP at ratio **1.0000** (fork-measured) ⇒ capacity stays at the honest ≈ $60.8 k < free ⇒ the borrow reverts (`test_05`).
* **Attack the reference legs**: the treasury floor needs a **$15 M donation** for 1.6×, and its POL term is k-invariant.
* **Profit downward**: `price` is floored at `backingPerToken`, and a dump only *pauses* (`Diverged`).

**Costs & preconditions**
* **Gas**: the whole multi-step attack is ~6–16 M gas (fork); at Robinhood-Chain gas prices this is negligible vs. the extraction. The load-bearing cost is the **hold**.
* **Capital**: all-in needs ≈ $243 k to skew to ×6; pre-held needs ≈ $148 k of NET plus ≈ $207 k of skew USDG (recovered).
* **Hold risk (quantified)**: the skew must survive ~30 min of arbitrage. The pair is genuinely inactive (**24 h volume ≈ $8.7 k; 59 txns/24 h**), but **~154 k NET sits outside the pool**. At a ×6 skew the pool holds ≈ 410 k USDG / 434 NET, so an arbitrageur holding **≈ 662 NET (≈ $108 k)** can sell it back and extract **≈ $135 k** (after the 5 % sell tax) by restoring the ratio — a *larger* profit than the all-in attacker's own ($58.4 k). **The all-in strategy is therefore in a race it can lose; the pre-held strategy is not** (an arb-back costs it only the ≈ $10.9 k round-trip). This is the single most important risk factor.

---

## 6 · PoC / fork verification

Foundry project `poc/` (vendored forge-std, `solc 0.8.24`). Forks chain 4663 at a **pinned block** (`RH_BLOCK`, exported by `ci/run.sh`). **Read-only; the only chain interaction is `eth_getCode`/`eth_call`.**

`forge test -vvv` → **7/7 PASS** in CI at pinned fork block **97,879,993**:
**https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40233146080** (branch `wsnet-oracle`, conclusion `success`; job log mirrored at `ci-artifacts/`). Reproduced locally (7/7) as well.

| test | what it proves |
|---|---|
| `test_00_live_state` | all live values above |
| `test_01_guard_is_one_sided` | down-dump → `Diverged`; up-skew → no revert |
| `test_02_baseline_borrow_reverts` | at the real price, borrowing the free liquidity **reverts** (`insufficient collateral`) |
| `test_03_allin_sweep` | **all-in** attack, m ∈ {2,3,4,5,6,8} (see table) |
| `test_04_preheld_sweep` | **pre-held** attack, collateral sized to cover `free` exactly |
| `test_05_single_tx_no_hold_fails` | same-block skew ⇒ ratio 1.0000 ⇒ borrow reverts |
| `test_06_arb_back_downside` | arb restores the pair ⇒ oracle **fails closed** (`Diverged`) ⇒ borrow 0 |

**All-in (attacker sources NET from the pool via the skew itself)** — `borrowed − usdgSpent`:

| m | price ratio | USDG spent | borrowed | **net** | loss if aborted |
|---|---|---|---|---|---|
| 2 | 1.743 | 69,589.44 | 52,231.21 | −17,378.23 | −21,398.98 |
| 3 | 2.615 | 123,022.65 | 113,099.85 | −9,922.80 | −53,431.34 |
| 4 | 3.488 | 168,052.06 | 178,439.55 | +10,387.49 | −85,687.28 |
| 5 | 4.361 | 207,723.77 | 246,636.50 | +38,912.73 | −116,688.26 |
| **6** | **5.000** | **243,589.74** | **301,955.21** | **+58,365.47** | **−146,478.75** |
| 8 | 5.000 | 307,270.95 | 329,864.59 | +22,593.64 | −200,822.58 |

* Break-even inflation is `1/LLTV = 1.6×` ⇒ the optimum sits where the pool's own NET buys just enough collateral; the cap (`×5`) is reached at m ≈ 5.7.
* The all-in net is **capacity-bound** (borrowed $302 k < free $461 k), so it does not grow with free liquidity; it *does* grow with the pool's NET reserve.
* **Abort loss** = `spent − true collateral value` — the −$146 k downside if the skew is arbed away after the swap.

**Pre-held (attacker already holds NET; the skew is a separate, recoverable round-trip):**

| m | price ratio | collateral (true) | borrowed | **net (borrow − collateral)** | skew round-trip |
|---|---|---|---|---|---|
| 4 | 3.488 | 211,919.65 | 460,865.63 | +248,945.99 | −9,102.95 |
| 5 | 4.361 | 169,508.83 | 460,865.63 | +291,356.80 | −10,120.33 |
| **6** | **5.000** | **148,214.04** | **460,865.63** | **+312,651.59** | **−10,878.67** |

(CI numbers; the local run at block 97,857,656 agreed to <0.1 %.)

* Net = `free × (1 − 1.6/k)` — at the 5× cap that is **0.68 × free liquidity**.
* The **downside is only the skew round-trip** (≈ −$10.9 k), because the pre-held collateral is unaffected by an arb-back. **Risk/reward ≈ 29:1.**
* Requires ≈ 910 NET (≈ 205 wsNET) pre-held — **0.59 % of NET supply / 2.4 % of wsNET supply** — well within reach of an existing holder.

**Arb-back (downside)**: the arb does not merely shrink the borrow — it **pauses the oracle** (`Diverged`, because the spot drops below `0.85 × TWAP` while the TWAP is still elevated). All-in loss −$146,478.75; pre-held loss −$10,878.67.

---

## 7 · Verdict & residual risk

* **Mechanism: CRITICAL and fork-proven.** The `Diverged` guard is one-sided; the upward ceiling is `5 × floor`; a held skew drains the market's entire free liquidity (**$460,865.63** at the pinned block).
* **Realised risk: HIGH.** Net is **+$58.4 k (all-in)** to **+$301.8 k (pre-held)**, gated only by a ~30-minute skew surviving arbitrage. The pair is very illiquid/inactive (see §5), so an unarbed hold is plausible — but ~154 k NET outside the pool is a real arb surface, and **it was not observed live**.
* **Re-arm/trigger monitors:**
  1. **The NET pool's liquidity** — a deepening of the USDG/NET pair (or a second NET venue) raises the arb risk and shrinks the all-in net.
  2. **Any change to the oracle guard/reference** — `DIVERGENCE_BPS`, `PREMIUM_CAP`, `HAIRCUT_BPS`, the treasury floor or the PairOracle window. There is **no owner function** (retuning = a successor market + oracle), so a new market id / new oracle address is the trigger.
  3. **The market's free liquidity** — it is the gross ceiling and it moves fast ($188.9 k → $460.9 k within hours).
  4. **The PairOracle's `lastCheckpointAt`/observation ring** — a stalled keeper makes the TWAP fail closed (`WindowOutOfBand`) and pauses the attack.
* **Blockers / mitigations today: none effective.** The oracle has no owner; `supplyCollateral`/`borrow` are open; the collateral is abandonable; USDG is a plain transferable ERC-20. The **only** thing standing between this and a full drain is the arbitrage bet.

---

## 8 · Methodology, sources, caveats

* **Sources of truth:** Sourcify v2 verified sources (chain 4663): `LoopbackOracle`, `LendingConstants`, `Constants`, `PairOracle`, `Treasury`, `NET`, `StakedNET`, `WrappedStakedNET`, `Staking` (all `exact_match`). Morpho Blue API (GraphQL, `chainId 4663`) for market/oracle enumeration. Live `eth_call`/`eth_getCode` on `https://robinhood.drpc.org` (keyless).
* **Manipulation technique:** the oracle reads only the pair *ratio*, so a `stateDiff` reserve override is oracle-equivalent; the fork PoC uses **real swaps** on the real pair (including the 5 % NET fee-on-transfer), real `Staking.stake`/`wsNET.wrap`, and real `supplyCollateral`/`borrow`.
* **Caveats / limitations:**
  * The free-liquidity ceiling is **point-in-time** and moves within hours; re-read before acting.
  * The **pre-held net** assumes an attacker who already holds ≈ 910 NET and an unarbed 30-minute hold — **not proven live**.
  * The all-in net is capacity-bound and depends on the pool's NET reserve (1,062 NET at the pinned block).
  * `block.number` returned by the fork's EVM is the **L1** block number on this OP-style chain; all citations use the **L2** block from `eth_blockNumber` (`RH_BLOCK`).
  * Robinhood Blockscout is Cloudflare-blocked from the research host; verification used Sourcify + bytecode.
* **No secrets**: no keyed RPC URL, API key or private key is written in this folder; the fork uses keyless public endpoints only.

### Files

```
wsnet-oracle/
├── README.md                      (this file)
├── summary.json                   (machine-readable)
├── analysis/
│   ├── live_snapshot.py           (read-only live-state reader)
│   ├── scan_oracles.py            (every 4663 Morpho market + oracle classifier)
│   ├── net_model.md               (closed-form net model + measured table)
│   ├── oracle_selector_scan.json  (500-oracle bytecode selector scan)
│   ├── guard_direction_test.json  (live stateDiff guard-direction table)
│   ├── oracle_abi.json            (LoopbackOracle ABI)
│   └── src/                       (Sourcify-verified protocol sources)
├── poc/                           (Foundry: foundry.toml, src/, test/, lib/forge-std)
│   └── test/WsnetOracle.t.sol     (7/7 PASS)
├── ci/run.sh                      (RPC pick + RH_BLOCK pin + live snapshot + oracle scan)
├── ci-out/                        (live_state.json, oracle_scan.json)
├── ci-artifacts/                  (downloaded CI artefacts)
├── ci-log.txt / job log           (CI job log)
└── child-verify/                  (independent verifier: report.md, evidence.json)
```

*Prepared 2026-10-25 · read-only · fork-only · evidence above.*
