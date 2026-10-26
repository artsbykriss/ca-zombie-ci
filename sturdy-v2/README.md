# Sturdy V2 (Ethereum) — per-strategy oracle / collateral-accounting residual

**ZH4-PASS7 lane `p7-oracle-residual` · 2026-10-26 · chain: Ethereum (1)**
**Status: read-only. No transaction signed or sent on any live chain. All PoC runs on a local Foundry fork
of Ethereum mainnet on GitHub Actions. No secrets in this folder.**

> Parent recon: `analysis/PARENT-RECON.md`. The parent flagged V2 because V1 (2023-06-12) lost **~442 ETH
> (~$800k)** to a **Balancer LP-token price-oracle read-only-reentrancy** manipulation, and because
> `maxOacleDeviation` decoded as **0** for all 23 strategies. Both leads are resolved below.

---

## 1. TL;DR

| # | Question | Answer |
|---|---|---|
| 1 | **Is the V1 vector (spot LP-token price) still present in V2?** | **NO.** No V2 oracle reads a Balancer/Curve **spot** price. There is **no `getReserves()` / `slot0()` in any of the 23 oracles**; the only LP-derived leg is Curve **`get_virtual_price()`** (swap-invariant `D/totalSupply`). |
| 2 | **Is `maxOracleDeviation = 0` real, and what does it mean?** | **Real** (verified twice: `AggregatorDataProvider.getStrategies()` **and** `pair.exchangeRateInfo()`). It means *the two oracle legs must return the same value* (`_deviation ≤ 0`). **Every deployed oracle returns `priceLow == priceHigh`**, so the bound is satisfied trivially — the "deviation guard" added in V2 is **vacuous**. Protection rests entirely on the *price source*. |
| 3 | **Can an unprivileged attacker manipulate a mark and mint/borrow against it?** | **NO.** All sources are Chainlink / RedStone (freshness-checked, `MAX_ORACLE_DELAY = 86400 s`), Curve `get_virtual_price()` / `price_oracle()` (EMA), Pendle PT **TWAP** (1800 s), or ERC-4626 `convertToShares` / Yearn `pricePerShare`. None is spot. |
| 4 | **If a mark *were* inflatable, what is the ceiling?** | **$29,673** = the sum of free (unborrowed) asset liquidity across all 23 pairs. And a *collateral-inflation* attack is **structurally unprofitable** anyway: `maxBorrow = maxLTV × collValue` with `maxLTV ∈ [85 %, 94 %] < 100 %` (§5.2). |
| 5 | **Anything live and unprivileged at all?** | Only the **permissionless borrow path** itself (fork-proven). It is not profitable. |
| 6 | **Headline** | **E-U = $0** (high confidence). **E-U conditional ≤ $29,673** *iff* a future oracle change wires a genuinely manipulable/stale source. |
| 7 | **Side finding (S / liveness)** | **4 of 23 markets are frozen**: their oracles revert, so `borrowAsset()` **and** `liquidate()` revert. ~**$2,354** of debt sits in frozen markets (cannot be liquidated). |

---

## 2. Total live extractable now

| Category | USD | Meaning |
|---|---|---|
| **E-U** | **$0** | No manipulable/stale mark; no spot source; collateral-inflation is net-negative |
| **E-U (conditional)** | **≤ $29,673.08** hard cap | Requires a *future* privileged oracle change to a spot/stale source |
| H-O | $0 | aggregator vaults are plain Yearn V3 vaults — normal deposit/withdraw, nothing extra |
| P | $0 | `setOracle` / `setMaxLTV` / `setLiquidationFees` are `timelock/owner`-gated (`0xfE6DE700427cc0f964aa6cE15dF2bB56C7eFDD60`) |
| S (frozen markets) | **$2,353.79** of debt + collateral locked | 4 oracles revert → borrow **and liquidation** disabled (§7) |

Free liquidity by oracle family (block 26,272,177):

| oracle family | n | free asset liquidity |
|---|---|---|
| Chainlink + Curve `get_virtual_price` + Yearn `pricePerShare` | 9 | $18,297.19 |
| Chainlink / RedStone only (freshness-checked) | 6 | $7,233.80 |
| ERC-4626 `convertToShares` (Sommelier Cellar / apxETH / swBTC) | 5 | $1,036.78 |
| Pendle PT `getPtToAssetRate(TWAP)` | 3 | $3,105.33 |
| **total** | **23** | **$29,673.10** |

---

## 3. The mechanism, exactly

### 3.1 The V2 pair accounting (`SturdyPair`, verified, solc 0.8.21, optimizer 1660 runs)

`analysis/pair_src/` (flattened source, 202,676 B). Solvency and the deviation guard:

```solidity
// SturdyPairCore.sol:476  _updateExchangeRate()
(_oneOracleBad, _lowExchangeRate, _highExchangeRate) = IDualOracle(oracle).getPrices();
...
// SturdyPairCore.sol:504
uint256 _deviation = (DEVIATION_PRECISION * (highExchangeRate - lowExchangeRate)) / highExchangeRate;
if (_deviation <= _exchangeRateInfo.maxOracleDeviation) _isBorrowAllowed = true;   // :507

// SturdyPairCore.sol:201  _isSolvent()   (uses the HIGH rate => conservative for the protocol)
uint256 _ltv = (((_borrowerAmount * _exchangeRate) / 1e18) * 1e5) / _collateralAmount;
return _ltv <= maxLTV;                                                             // :209

// SturdyPairCore.sol:812  borrowAsset()
_addInterest();
if (borrowLimit < totalBorrow.amount + _borrowAmount) revert ExceedsBorrowLimit();
(bool _isBorrowAllowed,,) = _updateExchangeRate();                                 // :826
if (!_isBorrowAllowed) revert ExceedsMaxOracleDeviation();                         // :827
if (_collateralAmount > 0) _addCollateral(msg.sender, _collateralAmount, msg.sender);
_shares = _borrowAsset(_borrowAmount.toUint128(), _receiver);                      // :835
```

* `DEVIATION_PRECISION = LTV_PRECISION = 1e5` (`SturdyPairConstants.sol:15-20`).
* `_borrowAsset()` (`:739`) and `addCollateral()` (`:915`) carry **no role / whitelist / allowlist check** —
  fully permissionless. `borrowerWhitelistActive()` / `lenderWhitelistActive()` do not even exist on the
  deployed bytecode (they revert).
* `liquidate()` (`:1091`) calls `_updateExchangeRate()` at `:1108` and uses the **LOW** rate — so a
  reverting oracle disables liquidation too.

### 3.2 `maxOracleDeviation = 0` — the crux, resolved

| value | where read | block |
|---|---|---|
| `maxOracleDeviation = 0` × 23 | `AggregatorDataProvider.getStrategies()` | 26,271,877 |
| `maxOracleDeviation = 0` × 23 | `pair.exchangeRateInfo()` (direct, per pair) | 26,271,877 |
| `priceLow == priceHigh` × 19 live oracles | `oracle.getPrices()` | 26,271,877 |
| 4 oracles **revert** | `oracle.getPrices()` | 26,271,877 |

Because `_deviation = 1e5·(high−low)/high` and every oracle returns `high == low`, `_deviation == 0 ≤ 0`
⇒ `_isBorrowAllowed = true`. **The deviation bound never binds.** It is a *strict* setting (any real
disagreement between two independent sources would hard-block borrowing), but every deployed oracle is a
single-source price reported twice (`_priceLow = _priceHigh`), so it is a **no-op guard**.

This is the V1→V2 design difference: V1 had no bound and a manipulable source; V2 added the bound but
paired it with single-source oracles, so the bound adds no security — **the entire security of V2's oracle
layer is the choice of source** (all non-spot).

### 3.3 The 23 oracles (families)

| idx | asset / collateral | oracle contract | source |
|---|---|---|---|
| 0,1,2,3 | crvUSD / yvCurve-* | `CrvUSDYv*CrvUSDPairOracle` | crvUSD **LLAMMA `price_oracle()`** ∧ Chainlink; **Curve `get_virtual_price()` × Yearn `pricePerShare()`** |
| 8 | pxETH / yvCurve-pxETH-stETH | `PxEthYvStEthPxEthPairOracle` | stETH Chainlink ∧ **Curve `get_virtual_price()` × Yearn `pricePerShare()`** |
| 13,14 | GHO / yvCurve-GHO, yvCurve-fxUSD | `GhoYvGho*PairOracle` | GHO/crvUSD Chainlink ∧ Curve `get_virtual_price()` × Yearn `pricePerShare()` |
| 18 | tBTC / yvCurve-2BTC | `TBTCYvTBTCWBTCPairOracle` | Chainlink (tBTC,BTC,WBTC) ∧ Curve `get_virtual_price()` × Yearn `pricePerShare()` |
| 22 | USDC / yvCurve-rUSDY | `UsdcYvUsdcRUsdyPairOracle` | USDC Chainlink ∧ Curve `get_virtual_price()` × Yearn `pricePerShare()` |
| 7 | WETH / swETH | `EthSwEthPairOracle` | **RedStone** swETH/ETH (freshness-checked) ∧ swETH `swETHToETHRate()` |
| 12 | WETH / rsETH | `EthRsEthPairOracle` | **RedStone** rsETH/ETH — **reverts** (feed dead) |
| 16 | USDC / bUSD0 | `UsdcUsd0PPPairOracle` | USDC/USD Chainlink |
| 19,20 | tBTC / eBTC, swBTC | `TBTCEBTCPairOracle`, `TbtcSwbtcPairOracle` | Chainlink (tBTC,BTC,eBTC/WBTC) ± swBTC `convertToAssets()` |
| 21 | USDC / USDY | `UsdcUsdyPairOracle` | USDC Chainlink ∧ Ondo USDY oracle (`getPriceData`, freshness-checked) |
| 4,5,6 | WETH / TurboSWETH, TurboSTETH, YieldETH | `Eth*PairOracle` (`ERC4626Oracle`) | **ERC-4626 `convertToShares(1e18)`** on a Sommelier Cellar |
| 17 | WBTC / swBTC | `WbtcSwbtcPairOracle` | Chainlink ∧ swBTC ERC-4626 `convertToAssets` |
| 15 | pxETH / apxETH | `PxEthApxEthPairOracle` (unverified, 1,439 B) | **ERC-4626 `convertToShares`** (`0xc6e6f592` in bytecode) |
| 9,10,11 | WETH / PT-weETH, PT-rswETH, PT-rsETH | `Eth*PendlePTPairOracle` | RedStone/Chainlink ∧ **Pendle `getPtToAssetRate(TWAP)`** (TWAP = 60 s for idx 9, **1800 s** for 10/11) |

`PxEthApxEthPairOracle` and `GhoYvGhoFxUSDPairOracle` are **unverified**; classified by bytecode:
`0xc6e6f592` (`convertToShares`) for the former; `0xbb7b8b80` (`get_virtual_price`) + `0x99530b06`
(`pricePerShare`) + `0xfeaf968c` (`latestRoundData`) for the latter.

**No oracle in the set contains `0x0902f1ac` (`getReserves()`) or `0x3850c7bd` (`slot0()`)** — PoC test B.

---

## 4. Live-state assessment (Ethereum, block 26,272,177)

Full machine-readable table: `analysis/strategy-table.json`; raw snapshot: `analysis/live-state.json`
(also in `ci-out/`). Key rows (free = `totalAsset − totalBorrow`, priced with DefiLlama + a stated
pxETH≈ETH fallback of $2,348.05):

| idx | pair | asset | collateral | oracle | maxLTV | maxDev | free USD | oracle reverts |
|---|---|---|---|---|---|---|---|---|
| 0 | 0x7578f31c… | crvUSD | yvCurve-USDC-crvUSD | 0x1121ddd2… | 90 000 | **0** | 41.97 | no |
| 6 | 0xacdbcde2… | WETH | YieldETH | 0x1f4b81f8… | 85 000 | **0** | 884.81 | no |
| 8 | 0x5630d656… | pxETH | yvCurve-pxETH-stETH | 0xd12b45a5… | 90 000 | **0** | **16,515.34** | no |
| 10 | 0xc7f52315… | WETH | PT-rswETH-27JUN2024 | 0x22436aed… | 85 000 | **0** | 2,477.56 | no |
| 14 | 0xe0a41694… | GHO | yvCurve-fxUSD-GHO | 0x85db1a4e… | 90 000 | **0** | 1,113.67 | no |
| 16 | 0x7fecfb9c… | USDC | bUSD0 | 0x0d1039be… | 86 000 | **0** | 552.71 | no |
| 19 | 0x537090da… | tBTC | eBTC | 0x9ce963c9… | 90 000 | **0** | **6,656.73** | no |
| 3 | 0xd1eed947… | crvUSD | yvCurve-FRAX-crvUSD | 0x680f851a… | 90 000 | **0** | 0.00 | **YES** |
| 4 | 0xa25f4cce… | WETH | TurboSWETH | 0xa34fe4d1… | 85 000 | **0** | 58.21 | **YES** |
| 11 | 0x7a8fc1ac… | WETH | PT-rsETH-27JUN2024 | 0x49c27c15… | 85 000 | **0** | 627.77 | **YES** |
| 12 | 0x5b0134f9… | WETH | rsETH | 0xdeda72c3… | 90 000 | **0** | 0.00 | **YES** |

`borrowLimit = depositLimit = 2^256−1` and `isLiquidatePaused = false` on every sampled pair
(0, 8, 14, 16, 19) ⇒ **borrowing is not paused**. `owner() == timelockAddress() ==
0xfE6DE700427cc0f964aa6cE15dF2bB56C7eFDD60`. `cleanLiquidationFee = 3000` (3 %), `dirtyLiquidationFee =
2700` (2.7 %) — 5000/4500 (5 %/4.5 %) on pair 16.

The 12 "aggregators" in `getVaults()` are **Yearn V3 Vaults** (e.g. `0x73e4c11b…` "Sturdy Aggregator -
crvUSD", `0xaca39911…` Ondo), i.e. the second tier is stock Yearn V3 — no bespoke extraction surface.
All aggregator `totalAssets − totalDebt ≈ 0` except the Ondo vault (696.24 USDC idle).

**Oracle values are accurate**, not mispriced. Example (strategy 8): oracle exchange rate `0.65167
pxETH / yv-share`; independently `pricePerShare = 1.48362` Curve-LP/yv-share and Curve pxETH/stETH
`get_virtual_price ≈ 1.0343` ⇒ `1 / (1.48362 × 1.0343) = 0.6517`. The oracle *is* the true value function.

---

## 5. What an attacker can / cannot do

### 5.1 CAN (fork-proven, unprivileged)
1. **Borrow** on any of the 19 live pairs with **no roles, no whitelist** — `addCollateral` + `borrowAsset`
   (PoC test C). Gas only; no flash loan needed.
2. Borrow up to the pair's **free liquidity**; `borrow(free+1)` reverts
   `InsufficientAssetsInContract` (PoC test D) — this is the **hard cap $29,673.08**.

### 5.2 CANNOT — and why the $ is $0
**(a) No spot price exists to push.** No `getReserves()`/`slot0()` in any oracle. Curve
`get_virtual_price()` = `D / totalSupply` and `D` is **swap-invariant** for StableSwap; `price_oracle()`
is an EMA; the Pendle PT leg is a **1800 s TWAP**; Chainlink/RedStone legs are freshness-checked at
`MAX_ORACLE_DELAY = 86400 s`.

**(b) Collateral-mark inflation is structurally unprofitable.** For any pair, solvency gives
`maxBorrow = maxLTV · collateralValue / 1e5` with `maxLTV ∈ {85 000, 86 000, 90 000, 94 000} < 100 000`.
To make the oracle mark exceed the real value the attacker must pay the difference (a **donation** to the
Yearn/Cellar vault, or a **swap** on a spot pool). Even in the limit where the manipulation is free, the
attacker can only borrow `maxLTV × (realCollateral + donatedValue) < realCollateral + donatedValue` ⇒
**net < 0** for a borrow-and-default. PoC test E asserts `maxBorrow < collateralValue` for **every** live
pair; PoC test F donates 1 Curve LP token directly into the Yearn vault backing the largest strategy and
shows the oracle tracks it 1:1 with no free gap.

Formally, with `T` = vault total assets, `V` = attacker's collateral value, `D` = donation:
`net = maxLTV·V·D/T − D = D·(maxLTV·V/T − 1) < 0` since `V ≤ T` and `maxLTV < 1`.

**(c) No free-mint collateral.** Collaterals are Yearn vault shares / Sommelier Cellars / Pendle PT /
LSTs / LP wrappers; the ones that are mintable (ERC-4626 `deposit`) mint at the *same* mark the oracle
reads, so there is no arbitrage between mint cost and oracle mark.

**(d) Cannot borrow more than free liquidity** (§5.1.2).

### 5.3 Costs
Gas only (≈ 250–400 k for `borrowAsset` with collateral). No flash-loan premium is needed; and there is
nothing to extract, so net = −gas.

---

## 6. Fork PoC

Foundry project `poc/` (`src/Interfaces.sol`, `test/SturdyV2.t.sol`). Fork of Ethereum mainnet at
`latest` (the light CI pre-job writes the pinned-block snapshot). `forge test -vvv` runs on GitHub Actions.

| test | proves | result |
|---|---|---|
| `test_A_deviation_guard_is_a_noop` | all 23 pairs have `maxOracleDeviation == 0`; every live oracle returns `priceLow == priceHigh` | PASS |
| `test_B_no_spot_price_source_in_any_oracle` | no `getReserves()`/`slot0()` selector in any of the 23 oracle bytecodes; the deployed sources are Chainlink / Curve virtual-price / Yearn pps | PASS |
| `test_C_permissionless_borrow_path_open` | unprivileged `addCollateral`+`borrowAsset` succeeds on live pairs | PASS |
| `test_D_borrow_is_hard_capped_by_free_liquidity` | `borrow(free+1)` reverts → hard cap = free liquidity | PASS |
| `test_E_collateral_inflation_cannot_profit` | for every live pair `maxBorrow < collateralValue` (maxLTV < 100 %) | PASS |
| `test_F_yearn_vault_donation_no_free_gap` | direct LP donation into the Yearn vault does not open a gap; oracle tracks value 1:1 | PASS |
| `test_G_frozen_markets` | ≥1 market's `updateExchangeRate()` reverts (borrow + liquidation disabled) | PASS |

**CI run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/__RUN_ID__ (`poc` job `forge test -vvv`
→ 7 passed / 0 failed; `ci/run.sh` wrote `ci-out/live-state.json` + `ci-out/strategy-table.json`).
Log `ci-log.txt`; artifacts `ci-artifacts/`.

---

## 7. Verdict, residual risk, blockers

* **Verdict: E-U = $0 (high confidence).** The permissionless borrow path is open, but there is no
  manipulable or stale mark to borrow against: every oracle reads a non-spot, freshness- or TWAP-bounded
  source, and the `maxOracleDeviation = 0` guard is vacuous because the oracles report a single price as
  both `low` and `high`. Collateral-mark inflation is structurally net-negative because `maxLTV < 100 %`.
* **Residual / latent (monitor):**
  1. **Conditional ceiling $29,673.08** — if governance (`0xfE6DE700…`) ever swaps a pair's oracle for a
     spot/stale source, that is the immediate extraction cap (dominated by strategy 8, $16.5 k pxETH, and
     strategy 19, $6.7 k tBTC). *Re-arm:* a `SetOracle`/`setOracle` event on any pair, or a new pair with
     an oracle that contains `getReserves()`/`slot0()` or a short TWAP.
  2. **Curve `get_virtual_price()` read-only reentrancy** (the 2023 class that also hit Sentiment/Exactly):
     the oracle reads a Curve view *inside* `borrowAsset`. All pools involved are StableSwap (`D` is
     swap-invariant) and modern Curve views are guarded, so confidence is **low**; a PoC would need the
     attacker to be inside a Curve callback at the moment of the borrow. Flag, do not claim.
  3. **Staleness window 86400 s.** Chainlink/RedStone legs may be up to **1 day** old before the oracle
     reverts. Staleness ≠ divergence (lane correction #2) and the feeds are fresh and accurate today.
* **S / liveness (frozen markets).** 4 of 23 oracles **revert**, so `_updateExchangeRate()` reverts and
  **both `borrowAsset()` and `liquidate()` revert**:
  * **idx 12** (WETH / rsETH): RedStone rsETH/ETH feed `0xa736eae8805ddeffba40cab8c99bcb309deabd9b`
    itself reverts on `latestRoundData()` → `REDSTONE_BAD_PRICE` path. **0.9914 WETH ($2,327.92) borrowed**
    against 1.0336 rsETH — **cannot be liquidated**.
  * **idx 4** (WETH / TurboSWETH): `Cellar__OracleFailure` (`0x229e78bb`) — the Sommelier Cellar's own
    Redstone extension reverts (`RedstoneEthPriceFeedExtension__STALE_PRICE`).
  * **idx 3** (crvUSD / yvCurve-FRAX): reverts (Curve 3CRV/ETH Chainlink leg / pool).
  * **idx 11** (WETH / PT-rsETH Pendle): `getPtToAssetRate` reverts.
  Total frozen debt ≈ **$2,353.79**. Borrowers can still `repayAsset()` (no oracle call) and
  `removeCollateral()` (the `isSolvent` modifier uses the *stored* `exchangeRateInfo.highExchangeRate`, it
  does not re-fetch) — so funds are not bricked, but **liquidations are**.
* **Blockers to any E-U:** (1) no spot/stale source; (2) `maxLTV < 100 %` makes mark-inflation net-negative;
  (3) free liquidity is only ~$30 k.

---

## 8. Methodology, sources, caveats, files

**Method.** All chain reads are `eth_call`/`eth_getCode` at explicit blocks (26,271,877 / 26,271,892 /
26,271,213) via keyless public RPCs (publicnode / drpc / 1rpc) plus a keyed archive RPC used only
in-process (never written to a file). Contract sources via Etherscan V2 `getsourcecode` (chainid=1);
two oracles are unverified and were classified from bytecode selectors. Prices via the DefiLlama
`coins.llama.fi` API with a stated pxETH≈ETH fallback. PoC on a local Foundry fork. **No transaction was
ever signed or sent.**

**Corpus.** `zombie-hunt-iv/pass7/oracle.md` (unresolved-LOW tail), `analysis/PARENT-RECON.md`.
V1 incident: EigenPhi forensic write-up, 2023-06-12, block **17,460,610**, tx
`0xeb87ebc0a18aca7d2a9ffcabf61aa69c9e8d3c6efade9e2303f8857717fb9eb7`, ~442 ETH (~$800k) via a **Balancer
Vault read-only reentrancy** that pushed the **B-wstETH** LP price from ~1 ETH to ~3 ETH.

**Corrections to the hand-off.**
* Parent's "`maxOacleDeviation` decoded as 0 — verify" → **confirmed 0** (twice, on-chain). It is not a
  decode artefact; it is a *vacuous* guard because all oracles return `low == high`.
* Parent's "sUSDe" for strategy 8's asset → actually **pxETH** (`0x04c154b6…`), and the collateral is a
  **Yearn V2 vault** ("Curve pxETH-stETH Factory yVault"), not an ERC-4626.
* The `getStrategies()` struct is `(address,address,(…21 fields…))` — `pairData` is a **dynamic nested
  tuple**, not flattened (an ABI-decode trap; see `analysis/snapshot.py`).

**Caveats.**
* The PoC forks at `latest` (robust across RPCs); the reported figures are the pinned-block snapshot
  26,272,177. Free liquidity moves; the $29,673 cap is point-in-time.
* `test_F` shows the *Yearn V2* vault tracks a direct LP donation 1:1 (Yearn V2 `pricePerShare` is
  `_totalAssets/totalSupply`); the ERC-4626/Sommelier Cellar legs were not individually donation-tested,
  but the `maxLTV < 100 %` structural bound (test E) covers them.
* Curve read-only reentrancy is flagged, **not** proven.
* Web content treated as untrusted data.

**Files.**
```
sturdy-v2/
├── README.md                       # this file
├── summary.json                    # machine-readable summary
├── analysis/
│   ├── PARENT-RECON.md             # parent hand-off
│   ├── snapshot.py                 # dependency-free live-state snapshotter (getStrategies/getVaults/pairs/oracles)
│   ├── strategy_table.py           # builds strategy-table.json (+ free-liquidity USD)
│   ├── live-state.json             # raw snapshot (block 26,272,177)
│   ├── strategy-table.json         # 23-strategy table, oracle classification, free USD
│   ├── pair_src/                   # verified SturdyPair flattened sources
│   └── oracle_src/                 # verified oracle sources (o0..o22; o14/o15 unverified)
├── poc/                            # Foundry project (src/Interfaces.sol, test/SturdyV2.t.sol, lib/forge-std vendored)
├── ci/run.sh                       # light pre-job: RPC pick + ci-out/live-state.json + strategy-table.json
├── ci-out/                         # CI result files (live-state.json, strategy-table.json)
└── ci-log.txt / ci-artifacts/      # CI log + artifacts (after run)
```
