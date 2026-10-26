# LayerBank (Robinhood Chain 4663) — stock `AaveOracle` with **no staleness check**

**ZH4-PASS7 TIER 3 deep dive · TARGET 2 · 2026-10-25 · chain: Robinhood Chain (id 4663)**
**Status: read-only. No transaction was signed or sent on any live network. All PoC execution is on a local Foundry fork of chain 4663, run on GitHub Actions. No secrets / keyed RPC URLs in this folder.**

---

## 1. TL;DR

| # | Question | Answer |
|---|---|---|
| 1 | **Is the flaw real?** | **YES.** The price oracle `0x0e1289335E72a9e1799D691Fc618656FA69F2ca1` is a **stock Aave `AaveOracle`**: `getAssetPrice(asset)` returns `source.latestAnswer()` verbatim. Its bytecode contains `latestAnswer()` (`0x50d25bcd`) and **not** `latestRoundData()` (`0xfeaf968c`) — so **`updatedAt` is never read**. There is **no heartbeat, no staleness bound, no fallback, no deviation check**. |
| 2 | **Are the feeds actually stale?** | **YES — a 46.9–63.7 h weekend freeze was observed.** At block **97,805,494** (2026-10-25 18:48:43 UTC) the tokenized-equity feeds were frozen at Friday's close: **NVDA 46.9 h, SPY 48.8 h, QQQ 52.2 h, SGOV 63.7 h**. The freeze has since **closed** — at block 97,990,305 (2026-10-26 00:09 UTC) all four refreshed ~8 min earlier. (GLD, cbBTC, USDG, WETH are slower/live.) |
| 3 | **Are the feeds manipulable?** | **NO.** All 8 sources are **Chainlink `EACAggregatorProxy`** contracts (`aggregator()` present) fronting 23,186-byte OCR aggregators; the proxy owner is `0xeE27D5Ae494300902D90454e8630A3F1C68c9C52`. An unprivileged attacker cannot push a price. |
| 4 | **Is the borrow path open?** | **YES, permissionless.** `supply()` + `borrow()` are ungated (no whitelist selectors in the Pool impl). Fork-proven: a fresh EOA with no roles supplies equity collateral and borrows USDG. |
| 5 | **Is there money in it today?** | **NO — $0.** The stale prints were *accurate*: max oracle-vs-real gap = **0.71 %** (SGOV). Profit needs a **42.9 %–100 %** stale-vs-real gap (1/LTV − 1). |
| 6 | **What is the conditional ceiling?** | **$1,536,666** — the hard cap is the free liquidity of the only two **borrowable** reserves (USDG **$463,125.55** + WETH **462.66 = $1,073,540**), read at block 97,990,305. At a realistic 100 % gap ≈ **$439,047**; at 150 % ≈ **$658,571**. *(At the weekend snapshot, block 97,805,494, the same cap was $1,661,064.)* |
| 7 | **Trigger** | Any equity/LST feed **frozen** while the real price gaps more than `1/LTV − 1` (42.9 % for SGOV/WETH/cbBTC, 66.7 % SPY/GLD, 81.8 % NVDA, 100 % QQQ, 25 % USDG). Weekends already give a **46–64 h** freeze window; a permanently dead aggregator gives an unbounded window. |
| 8 | **Category** | **E-U (conditional)** — extractable by an external unprivileged attacker *only* when the gap appears. Today: **$0**. |
| 9 | **Confidence** | Mechanism **high** (fork-proven, bytecode-verified). Today's **$0 high** (gap is 0.71 % vs a 42.9 % threshold — a 60× margin). Gap scenario **medium**. |

**Correction to the pass-7 note:** pass-7 quoted "NVDA LTV 55 % → needs O > 1.82·R; SPY 60 % → O > 1.67·R". That is correct *per-reserve*, but the **cheapest** collateral to attack is **SGOV / cbBTC / WETH at LTV 70 % → O > 1.43·R (a 42.9 % gap)**, and if the *USDG* feed (LTV 80 %) is the one that freezes the threshold drops to **25 %**. The binding constraint is not NVDA's 82 %.

---

## 2. Total live extractable now

| Category | USD | Meaning |
|---|---|---|
| **E-U** | **$0.00** | No stale-vs-real gap today (max 0.71 %, oracle both high and low across reserves) |
| **E-U (conditional)** | **≤ $1,536,665.87** hard cap; **~$439,047** at a 100 % gap; **~$658,571** at 150 % | Needs a feed frozen through a > 42.9 % real move |
| **H-O** | $0.00 | — (all withdrawals are the normal permissionless `withdraw`) |
| **P** | **≤ $5,162,800.51** | The whole pool is admin-controlled by a **single EOA** `0x514C5684B2fc3eD66A492cf378EB227947C91161` (ACL admin + provider owner) via `AaveOracle.setAssetSources` |
| **S** | $0.00 | — |

**Headline: external unprivileged attacker extractable today = $0.00 (high confidence).**

---

## 3. The mechanism, exactly

### 3.1 The oracle is a stock `AaveOracle` — no freshness check

Deployed at `0x0e1289335E72a9e1799D691Fc618656FA69F2ca1` (2,607 bytes, **not** a proxy — EIP-1967 impl slot = 0). Dispatcher exposes `getAssetPrice` (`0xb3596f07`), `getSourceOfAsset` (`0x92bf2be0`), `getAssetsPrices` (`0x9d23d9f2`), `setAssetSources` (`0xabfd5310`), `BASE_CURRENCY` (`0xe19f4700`), `BASE_CURRENCY_UNIT` (`0x8c89b64f` = `1e8`).

```solidity
// Aave v3 AaveOracle (verbatim shape)
function getAssetPrice(address asset) public view override returns (uint256) {
    AggregatorInterface source = assetsSources[asset];
    if (asset == BASE_CURRENCY) return BASE_CURRENCY_UNIT;
    else if (address(source) == address(0)) return 0;
    else return uint256(source.latestAnswer());   // <-- updatedAt is NEVER read
}
```

Proof (bytecode, no source needed): the oracle code contains the `latestAnswer()` selector **`50d25bcd`** and does **not** contain `latestRoundData()` **`feaf968c`**. Fork test `test_A3` asserts exactly this.

`getAssetPrice(NVDA)` returns `21116355858` = **`RHNVDA/USD.latestAnswer()`** bit-for-bit (`test_A`). There is no second source, no TWAP, no circuit breaker.

### 3.2 The feeds are Chainlink OCR push feeds (not manipulable)

| reserve | source (feed proxy) | description | aggregator | code (B) |
|---|---|---|---|---|
| NVDA | `0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15` | `RHNVDA / USD` | `0xC9d16E4f2569b9E3ea0468fD85844953713DC2a2` | 23,186 |
| SPY | `0x319724394D3A0e3669269846abE664Cd621f9f6A` | `RHSPY / USD` | `0x78BCB218fA04B9b3a278eBc865Ed320BF8DEFBAc` | 23,186 |
| QQQ | `0x80901d846d5d7b030f26b480776ee3b29374c2ae` | `Robinhood QQQ / USD` | — | 23,186 |
| SGOV | `0xa0df4ee0fff975306345875e3548fcc519577a11` | `Robinhood SGOV-USD` | — | 23,186 |
| GLD | `0x470a51258068043bd43dc0a56245625c9fe86eb0` | `GLD / USD` | — | 23,186 |
| cbBTC | `0x0009cd492adf8167f9eebf1293556a673530a21a` | `CBBTC / USD` | — | 23,186 |
| USDG | `0x61b7e5650328764b076a108eff5fa7282a1b9ad2` | `USDG / USD` | — | 23,186 |
| WETH | `0x78f3556b67e17df817d51ef5a990cdaf09e8d3a9` | `ETH / USD` | — | 23,186 |

Every feed is an `EACAggregatorProxy` (`aggregator()` returns a distinct 23,186-byte `AccessControlledOffchainAggregator`), all owned by `0xeE27D5Ae494300902D90454e8630A3F1C68c9C52`. **An unprivileged attacker has no way to move these prices** — the only lever is the aggregator owner (P) or a genuine market move while the feed is frozen.

### 3.3 The permissionless borrow path (Aave v3, unchanged)

`supply(asset, amount, onBehalfOf, referralCode)` and `borrow(asset, amount, interestRateMode, referralCode, onBehalfOf)` on the Pool proxy `0x433e21dC2BF027910B1635653c2Eb630bC7dAD43` (impl `0xb8ea4704fe518c5ccbf429fc6db1b2c4c4ca7193`, 42,835 B) carry **no role, whitelist or authorization** check (no `isWhitelisted`/`setWhitelist` selectors exist in the impl). Fork-proven in `test_B`.

### 3.4 The attack (borrow against a stale-high mark, then default)

Let `O` = stale oracle price, `R` = real tradeable price, `L` = LTV of the collateral reserve:

```
buy Q of the collateral at R, supply it, borrow L·O·Q of USDG/WETH, abandon the collateral
net = L·O·Q − R·Q  > 0   ⟺   O/R > 1/L   ⟺   stale-vs-real gap g > 1/L − 1
```

The attacker's net, capped by the free liquidity `F` of the borrowable reserve, is
`net(g) = F · (1 − 1/(L·(1+g)))`.

Break-even gap per collateral reserve (exact, on-chain LTV):

| collateral | LTV | break-even gap `1/L−1` | stale today |
|---|---|---|---|
| NVDA | 55 % | **81.8 %** | 46.9 h |
| SPY | 60 % | **66.7 %** | 48.8 h |
| GLD | 60 % | **66.7 %** | 4.3 h |
| SGOV | 70 % | **42.9 %** | 63.7 h |
| cbBTC | 70 % | **42.9 %** | 6.9 h |
| WETH | 70 % | **42.9 %** | 1.4 h |
| USDG | 80 % | **25.0 %** | 3.0 h |
| QQQ | 50 % | **100 %** | 52.2 h |

Conditional net (best equity collateral, L = 0.70, `F` = USDG + WETH free liquidity at block 97,990,305):

| gap g | net (borrow USDG) | net (borrow WETH) | **net total** |
|---|---|---|---|
| 42.9 % (break-even) | $139 | $322 | **$461** |
| 60 % | $49,621 | $115,022 | **$164,643** |
| 80 % | $95,566 | $221,524 | **$317,090** |
| **100 %** | $132,322 | $306,726 | **$439,047** |
| **150 % (a 60 % crash)** | $198,482 | $460,089 | **$658,571** |
| 300 % | $297,724 | $690,133 | $987,857 |
| → ∞ | — | — | **$1,536,666 (hard cap)** |

*(`analysis/divergence.py`, machine-readable in `analysis/divergence.json`. At the weekend snapshot block 97,805,494 — free USDG $568,926.52 — the 100 %/150 %/ceiling figures were $474,590 / $711,884 / $1,661,064.)*

---

## 4. Live-state assessment (chain 4663)

**Block 97,805,494 · 2026-10-25 18:48:43 UTC.** Pool `0x433e21dC2BF027910B1635653c2Eb630bC7dAD43` (proxy, impl `0xb8ea4704fe518c5ccbf429fc6db1b2c4c4ca7193`), Oracle `0x0e1289335E72a9e1799D691Fc618656FA69F2ca1`, Provider `0x6758Efc446EE8BDE7670b93a6Df799dFfE8F8969`.

### 4.1 Reserves (8) — `getReservesList()`, `getReserveData()`, `getAssetPrice()`, `getSourceOfAsset()`

| reserve | token | LTV | liq.thr | bonus | dec | borrowable | oracle price | source |
|---|---|---|---|---|---|---|---|---|
| NVDA | `0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC` | 55 % | 60 % | 8 % | 18 | **no** | $211.1636 | `0x379EC4f7…` |
| SPY | `0x117cc2133c37B721F49dE2A7a74833232B3B4C0C` | 60 % | 65 % | 8 % | 18 | **no** | $762.2613 | `0x31972439…` |
| USDG | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` | 80 % | 85 % | 8 % | 6 | **YES** | $0.99992 | `0x61b7e565…` |
| WETH | `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73` | 70 % | 75 % | 8 % | 18 | **YES** | $2,360.5609 | `0x78f3556b…` |
| cbBTC | `0xCEC185eB182c47d1bA1EFc84e6959e18cd620Be4` | 70 % | 75 % | 8 % | 8 | no | $80,511.9062 | `0x0009cd49…` |
| QQQ | `0xD5f3879160bc7c32ebb4dC785F8a4F505888de68` | 50 % | 55 % | 8 % | 18 | no | $707.2803 | `0x80901d84…` |
| SGOV | `0x92FD66527192E3e61d4DDd13322Aa222DE86F9B5` | 70 % | 75 % | 8 % | 18 | no | $101.3784 | `0xa0df4ee0…` |
| GLD | `0xC9a981FEE1F9DEc688bb123ccDeCc63D0deBFC4e` | 60 % | 65 % | 8 % | 18 | no | $365.6246 | `0x470a5125…` |

**Only USDG and WETH are borrowable** (`borrowingEnabled=true`); all 6 equities/metals are collateral-only. All reserves `isActive`, not frozen, not paused.

### 4.2 Feed staleness + divergence at that block

| reserve | `updatedAt` | age | oracle | DefiLlama real | **oracle-vs-real gap** | needs |
|---|---|---|---|---|---|---|
| NVDA | 1792785331 | **46.89 h** | $211.1636 | $212.155 | **−0.47 %** | 81.8 % |
| SPY | 1792778536 | **48.77 h** | $762.2613 | $760.795 | **+0.19 %** | 66.7 % |
| QQQ | 1792766392 | **52.15 h** | $707.2803 | $705.435 | **+0.26 %** | 100 % |
| SGOV | 1792724929 | **63.66 h** | $101.3784 | $100.665 | **+0.71 %** | 42.9 % |
| GLD | 1792938527 | 4.33 h | $365.6246 | $366.175 | −0.15 % | 66.7 % |
| cbBTC | 1792929257 | 6.91 h | $80,511.9062 | $80,467.09 | +0.06 % | 42.9 % |
| USDG | 1792943201 | 3.03 h | $0.99992 | $1.00004 | −0.01 % | 25.0 % |
| WETH | 1792948927 | 1.44 h | $2,360.5609 | $2,349.279 | +0.48 % | 42.9 % |

The equity feeds froze at the **Friday 2026-10-23 US close** (NVDA `updatedAt` = 2026-10-23 19:55 UTC); the weekend freeze was 46.9–63.7 h. **The frozen prints were essentially correct** (max 0.71 %, and the two largest by exposure — USDG and WETH — were live). **No exploitable divergence existed.**

**The freeze has since closed.** At block **97,990,305** (2026-10-26 00:09:32 UTC) every equity feed had refreshed ~8–9 min earlier (NVDA 523 s, SPY 535 s, QQQ 531 s, SGOV 544 s) and the gaps were unchanged: NVDA −0.014 %, SPY +0.204 %, QQQ +0.101 %, SGOV +0.709 %, GLD +0.083 %, cbBTC +0.173 %, USDG −0.011 %, WETH −0.105 %. The whole window produced a maximum divergence of **0.71 %** — 60× below the 42.9 % break-even floor.

### 4.3 Liquidity surface

| reserve | supplied | borrowed | **free liquidity** |
|---|---|---|---|
| USDG | $2,652,557.66 | $2,088,925 | **$568,926.52 → $463,125.55 (current)** |
| WETH | $2,319,379.97 (982.555 WETH) | 520.46 WETH ($1,228,570) | **462.66 WETH ($1,092,138)** |
| NVDA | $18,052.09 (85.49) | 0 | 85.49 NVDA |
| SPY | $53,997.81 (70.84) | 0 | 70.84 SPY |
| cbBTC | $54,671.92 (0.679) | 0 | 0.679 cbBTC |
| SGOV | $33,349.95 (328.97) | 0 | 328.97 SGOV |
| GLD | $20,210.93 (55.28) | 0 | 55.28 GLD |
| QQQ | $10,580.17 (14.96) | 0 | 14.96 QQQ |
| **total** | **$5,162,800.51** | **$3,317,495** | **$1,536,666 (USDG+WETH, current)** |

*(Free USDG fell from $568,926.52 at the weekend snapshot to $463,125.55 by block 97,990,305 — liquidity moves; the ceiling is always the live free liquidity of the two borrowable reserves.)*

### 4.4 Borrowers (41) — no liquidatable position, and the book is a stablecoin carry trade

From `Borrow` logs (topic0 `0xb3d084820fb1a9decffb176436bd02558d15fac9b0ddfed8c465bc7359d7dce0`) over blocks 60,085,704–97,813,532 → **41 unique borrowers**; `getUserAccountData` at ~97,805,494 (`analysis/borrowers.json`):

| borrower | collateral | debt | LT | **HF** |
|---|---|---|---|---|
| `0x234888e6dafdd64a3890bd2cd8e5558ce81a8e37` | $1,090,851 (836,727 USDG + 108.3 WETH) | $835,793 | 82.66 % | **1.079** |
| `0x1e702475632a838dbdfa3ea455e30f66aa88a9c0` | $696,446 (696,506 USDG) | $544,786 | 85.00 % | **1.087** |
| `0xe647df965dc7ebee27fdd8840a7fc907540eb3d3` | $434,287 (180.1 WETH + 1,629 USDG + 12.9 SPY) | $281,966 | 74.81 % | 1.152 |
| `0xc65c762fc8a7e1618529c1e49ea3fe572dbdc40b` | $251,068 (94.2 WETH + 29,975 USDG) | $150,695 | 76.19 % | 1.269 |
| `0x92e0a48ec97f251c3cbf82e40a8f8d1b33367aee` | $197,240 (83.9 WETH + 339 USDG) | $137,789 | 75.01 % | **1.074** |
| … 36 more (all HF ≥ 1.10) | | | | |

- **Min HF = 1.0737** → **nothing is liquidatable**, and a **frozen oracle holds HF constant**, so staleness can *never* trigger a liquidation (it can only delay one).
- **The large positions are USDG↔WETH carry trades** (USDG collateral → WETH borrow, WETH collateral → USDG borrow). Total **equity collateral ≈ $136 k** (NVDA 18 k + SPY 54 k + SGOV 33 k + GLD 20 k + QQQ 11 k), mostly on **debt-free** accounts. The equity-staleness flaw therefore touches only a small slice of the book — the *attacker* must bring their own collateral, which is why the ceiling is the free liquidity, not the existing debt.

### 4.5 Admin / roles (P-class)

| role | address | power |
|---|---|---|
| Provider `owner()` | `0x514C5684B2fc3eD66A492cf378EB227947C91161` (**single EOA**) | `setPriceOracle`, pool configurator, ACL |
| `getACLAdmin()` | `0x514C5684B2fc3eD66A492cf378EB227947C91161` (**same EOA**) | `isPoolAdmin == true` |
| ACL manager | `0x569C94DD0e1c6Ec6E52B758054fE042C2623BE4E` | `ADMIN` role holder = the EOA |
| Pool configurator | `0x4FEf45041bE6ce7cdAae216B13b84B69F25ec70f` | LTV / freeze / pause |

`AaveOracle.setAssetSources(address[],address[])` (`0xabfd5310`) is gated on `isPoolAdmin`. Read-only `eth_call` proof: **from `0x…dEaD` it reverts (`"5"`); from `0x514C5684…` it returns `0x` (success)**. So a **single EOA key** can repoint any reserve's oracle to an arbitrary feed, set a fake price and drain the whole **$5,162,800.51** supplied. That is **P-class** (requires the key), not E-U — but it is the largest single-key exposure on this protocol.

---

## 5. What an attacker can / cannot do (net of costs)

**CAN (conditional only):** acquire a collateral token at its real price `R`, `supply()` it, `borrow()` USDG/WETH at the frozen mark `O` up to that reserve's free liquidity, then abandon the collateral. Works only if `O > R/L`.

**CANNOT:**
1. **Manipulate the oracle.** All 8 sources are Chainlink OCR push feeds (23,186-byte aggregators behind `EACAggregatorProxy`). No spot DEX read anywhere. (Contrast: the *other* Robinhood-Chain finding, wsNET/Morpho, is a UniV2 `getReserves()` spot oracle — a different contract, different bug.)
2. **Profit today.** Max gap 0.71 % vs a 42.9 % floor.
3. **Borrow more than free liquidity.** `borrow(avail+1)` reverts (fork-proven `test_D`). Supplying USDG first to "create" liquidity only re-lends the attacker's own money.
4. **Liquidate anyone via the stale feed.** Frozen oracle ⇒ HF frozen; min HF 1.0737; no position is liquidatable.
5. **Free-mint the collateral.** The equity tokens are ERC-1967 **beacon proxies** (`0xe10b6f6b275de231345c20d14ab812db62151b00`) with role-gated mint (`Stock.sol`).
6. **Cause the divergence.** The feed update cadence is controlled by the Chainlink OCR aggregator owner, not by any unprivileged caller.

**Costs:** gas only — the attack needs **no flash loan** (the capital is the collateral purchase itself). If the collateral is bought on-chain, DEX depth/slippage on the buy leg reduces the net; the buy leg is modelled at `R`.

---

## 6. PoC / fork verification

Foundry project `poc/` — local fork of chain 4663 (`RH_RPC_URL`, keyless `https://4663.rpc.thirdweb.com` / `https://robinhood.drpc.org`). `forge test -vvv` runs on GitHub Actions; `ci/run.sh` writes a live-state snapshot to `ci-out/live-state.json`.

| test | proves | result |
|---|---|---|
| `test_A_oracle_is_stock_aaveoracle_passthrough` | `getAssetPrice(NVDA/SPY) == source.latestAnswer()`; `BASE_CURRENCY_UNIT = 1e8`; oracle-vs-real gap < 5 % | PASS |
| `test_A1_historical_weekend_freeze_block_97805494` | **pinned fork** at the weekend block: NVDA feed age **46.9 h**, oracle returns the frozen print, frozen print within 5 % of real | PASS |
| `test_A2_no_staleness_check_warp_one_year` | `vm.warp(+365 days)` → **identical** price ⇒ no freshness check | PASS |
| `test_A3_oracle_bytecode_uses_latestAnswer_only` | oracle bytecode has `latestAnswer` (`50d25bcd`), lacks `latestRoundData` (`feaf968c`); feed is a Chainlink proxy (`245a7bfc`) | PASS |
| `test_B_permissionless_supply_borrow_equity_collateral` | fresh EOA (no ACL role) supplies 100 NVDA and borrows 1,000 USDG | PASS |
| `test_C1_real_feed_borrow_over_ltv_reverts` | at the **real** feed, borrowing 20,000 USDG against 100 NVDA **reverts** | PASS |
| `test_C2_divergent_feed_extracts_free_liquidity` | feed mocked to `2.5×` (+150 % gap) ⇒ supply NVDA, borrow the whole **free USDG liquidity**, net > 0 | PASS |
| `test_D_borrow_capped_by_free_liquidity` | `borrow(free+1)` reverts ⇒ hard liquidity cap | PASS |
| `test_E_break_even_gap_per_reserve` | exact break-even gaps 81.8 / 66.7 / 42.9 / 25.0 / 100 % | PASS |

**CI run (all 9 tests PASS):** `<CI_RUN_URL>`
*(Run history: dispatch 1 — 7/8, `test_C2` tripped a hard-coded `>500k` assertion because free USDG had fallen to $463 k at the fork block; the mechanism itself succeeded — **net $126,306.97 at a 150 % gap**, `borrowed = 463,125,547,664` = the entire free USDG liquidity. Dispatch 2 — 7/8, `test_A` tripped a time-dependent `>6 h stale` assertion after the weekend freeze closed; replaced with the pinned-block `test_A1`.)*
`ci/run.sh` job writes `ci-out/live-state.json` (snapshot block + per-reserve LTV/free-liquidity + per-feed `updatedAt`/age + DefiLlama divergence). Log `ci-log.txt`; artifacts `ci-artifacts/result-layerbank/`.

**Note on the divergence injection.** Because the feeds are Chainlink OCR (not manipulable on-chain), `test_C2` injects the divergence at the *feed* with `vm.mockCall(feed, latestAnswer, 2.5·R)` — which is **exactly what a frozen/dead feed produces over time** (the oracle keeps returning the last answer while the real price moves). The test therefore proves the *mechanism and the conditional ceiling*, not a live exploit.

---

## 7. Verdict, residual risk, blockers

- **Verdict: E-U (conditional).** Live extractable **$0.00** today, **high confidence**. A **proven, permissionless** mechanism sits behind a **> 42.9 %** stale-vs-real gap; when that gap occurs the attacker nets up to **$1,536,666** (hard free-liquidity cap), realistically **~$439,047** at a 100 % gap and **~$658,571** at 150 %.
- **Residual / latent risk.** The freeze window is **already 46–64 h every weekend** and is **unbounded** if an aggregator dies (the oracle never notices). Any of the following turns this into a live E-U: (i) a feed that stops updating while the real price moves > 42.9 % (equity crash, trading halt, delisting, corporate action); (ii) any new reserve listed with a high LTV on a feed that then freezes; (iii) a USDG depeg > 25 % while the USDG feed is frozen (LTV 80 %).
- **Monitor / re-arm (exact):** for any collateral reserve, if `now − source.latestRoundData().updatedAt > 12 h` **and** `|real/oracle − 1| > 1/LTV − 1` **and** the borrowable free liquidity > $10 k → `net ≈ F·(1 − 1/(L·(1+g)))`. Watch the Robinhood equity feed cadence (US market hours), the SGOV/QQQ feeds (longest freezes), and any `AggregatorUpdated`/`proposeAggregator` on the 8 proxies.
- **Blockers to the exploit today:** (1) the frozen prints are accurate (≤ 0.71 % off); (2) the only borrowable assets (USDG, WETH) have **live** feeds; (3) the feeds are not manipulable; (4) the equity tokens are not free-mintable; (5) the equity collateral on the book is only ~$136 k and mostly debt-free — an attacker must bring their own collateral.
- **P-class (separate):** a **single EOA** `0x514C5684B2fc3eD66A492cf378EB227947C91161` is provider owner + ACL admin and can `setAssetSources` to a fake feed → drain up to **$5,162,800.51**. Key-compromise only.

---

## 8. Methodology, sources, caveats, files

**Method.** Chain-4663 reads via keyless `https://4663.rpc.thirdweb.com` / `https://robinhood.drpc.org` + Alchemy (`robinhood-mainnet`) at explicit blocks; `eth_getCode`, `eth_call`, `eth_getStorageAt`, `eth_getLogs` (Borrow/Supply/LiquidationCall topics). Oracle/feed source from bytecode selector analysis + `getSourceOfAsset` (Blockscout for 4663 is Cloudflare-blocked from this host; the oracle is **unverified**, so all claims are from live `eth_call`/bytecode). Reference prices from DefiLlama `coins.llama.fi` (`robinhood:<token>`, 2026-10-25 ~18:54 UTC). All PoC on a local fork.

**Caveats / limitations.**
- The oracle and Pool are **unverified** on any reachable explorer; the `AaveOracle`/`ReserveData` layouts were pinned by on-chain probing (`getReserveData` returns a 15-word struct; LTV/LT/bonus/decimals decoded from the config word and cross-checked against `getUserAccountData` liquidation thresholds).
- The borrower enumeration is 41 of an estimated ~45 addresses (a few Alchemy `eth_getLogs` windows were rate-limited); the observed total debt $2.37 M of the $3.32 M pool debt. The missing windows contain no equity-heavy position (checked the top-13 by collateral).
- The "real price" is DefiLlama's Robinhood-token print, not a full on-chain order book; the buy leg is modelled at `R` with no slippage. SGOV/GLD carry `confidence` 0.9 on DefiLlama.
- Free liquidity is a snapshot at block 97,805,494 and moves.
- **Point-in-time 2026-10-25.** Re-read all live state (and the feed ages) before acting.

**Files.**
```
layerbank/
├── README.md                       # this file
├── summary.json                    # machine-readable summary
├── analysis/
│   ├── live_state.json             # full snapshot (reserves/feeds/free-liq/DefiLlama)
│   ├── current_state.json          # current snapshot (block 97990305): prices/ages/free-liquidity
│   ├── snapshot.py                 # live-state snapshotter (used by ci/run.sh)
│   ├── feeds_at_block.json         # per-feed latestRoundData + age at block 97,805,494
│   ├── divergence.py / divergence.json  # gap table + conditional-net table
│   ├── reserves.json / tokens.json # reserve config + aToken/debt addresses + balances
│   ├── borrowers.json / positions.json  # 41 borrowers, HF, collateral composition
│   ├── user_collateral.json        # per-borrower aToken/varDebt composition
│   └── decode.py                   # getReserveData config decoder
├── poc/                            # Foundry project (src/Interfaces.sol, test/LayerBankOracle.t.sol, lib/forge-std)
├── ci/run.sh                       # light pre-job: RPC pick + ci-out/live-state.json
├── ci-out/live-state.json          # CI live-state snapshot
├── ci-log.txt / ci-artifacts/      # CI log + artifacts
└── summary.json
```
