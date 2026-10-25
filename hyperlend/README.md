# HyperLend core pool — stock `AaveOracle` with **no staleness check** (HyperEVM 999) — P7-03

**Date:** 2026-10-25 · **Chain:** HyperEVM (999) · **Status:** read-only research; PoC **fork-verified only** (GitHub Actions, public keyless RPC); **no mainnet transaction was ever signed or sent**. This folder is self-contained.
**Live state read at HyperEVM block ≈ 49,509,633 (2026-10-25 ~18:15 UTC); PoC fork head 49,512,244.**

Targets: core Pool `0x00A89d7a5A02160f20150EbEA7a2b5E4879A1A8b` (proxy → impl `0xbebb62c7ff8b96db4325d9481c44e09a92d49b06`, `PoolInstance` aave-v3-origin v3.4) · Oracle `0xC9Fb4fbE842d57EAc1dF3e641a281827493A630e` (`AaveOracle`).

---

## 1. TL;DR

| Target | Live extractable (external, unprivileged) | Why closed | Latent risk / trigger |
|---|---|---|---|
| **USDHL** reserve `0xb50A9625…` (dead feed **60.1 d**) | **$0** | oracle is **accurate** (oracle $0.99779574 vs real $0.99956 → *understates* 0.18 %); reserve is **soft-delisted** — `supplyCap=1` **and** `borrowCap=1` (already exceeded: 7,696 supplied / 3,778 borrowed) so `supply()`/`borrow()` **revert**; `LTV=0` so it can never be collateral | feed gains a real LTV **+** an open cap **+** a >30 % USDHL depeg while the Pyth feed stays frozen |
| **PT-sUSDe-25SEP2025** `0xb7379d39…` (dead feed **127.3 d**) | **$0** | oracle is **accurate/conservative** (oracle $0.99904247 vs true ~$1.00 → *understates* ~0.1 %); `supplyCap=1`/`borrowCap=1` already exceeded → `supply()` **reverts**; `borrowingEnabled=false` | e-mode cat 3 gives it **75 % LTV**, so an open cap + a USDe depeg < ~$0.748 while the frozen feed still reports $0.999 would re-arm it |
| 4 **isolated pairs** (`HyperlendPair`, Curvance-style) | **$0** | ~$110 k total; `OracleChainlink` **does** check `maxOracleDelay` (reverts `"invalid oracle price"` when stale) — one oracle (`0xd8adb328`, 7 d) **is** stale but its pair holds ~$1 | an open/older pair whose Chainlink leg dies |

**Total live extractable now: $0.00 (E-U). Confidence: HIGH.** H-O / P / S = $0.

The flaw is **real and live** (a stock `AaveOracle` that reads `latestAnswer()` with no `updatedAt`/heartbeat check, on a $467.7 M-supplied / $162.4 M-borrowed pool, with two feeds genuinely dead for 60 d / 127 d) — but **every permissionless path today is gated three ways**: the dead feeds are *accurate*, the two dead-feed reserves are *soft-delisted* (`supplyCap=1` & `borrowCap=1`, already exceeded), and neither can be collateral in its own config (USDHL `LTV=0`). The two re-arm triggers are quantified in §6.

---

## 2. The bug, in exact terms

`AaveOracle` (`0xC9Fb4fbE…`) is the **stock Aave contract** (verified source, solc 0.8.20, `contracts/misc/AaveOracle.sol`). Its only price path is:

```solidity
function getAssetPrice(address asset) public view override returns (uint256) {
    AggregatorInterface source = assetsSources[asset];
    if (asset == BASE_CURRENCY)      return BASE_CURRENCY_UNIT;              // 1e8 (USD)
    else if (address(source)==address(0)) return _fallbackOracle.getAssetPrice(asset);
    else { int256 price = source.latestAnswer();                             // <-- no updatedAt
           if (price > 0) return uint256(price);
           else return _fallbackOracle.getAssetPrice(asset); } }
```

- **No `latestRoundData()`, no `updatedAt`, no heartbeat, no min/max bound** — the *only* validation is `price > 0`. A feed that stopped publishing 127 days ago is accepted verbatim.
- The two dead feeds are themselves *pull/push adapters that also skip staleness*:
  - USDHL → `PythOracleAdapter 0xa19b7fE6FFd492dd84ADF38D37B974Cb52f40267` (`"Pyth-USDHL/USD"`), which calls **`pyth.getPriceUnsafe(priceFeedId)`** — Pyth's explicitly-unsafe accessor that omits the `publishTime` check.
  - PT-sUSDe-25SEP2025 → `PendlePriceCapAdapter 0x8514D528275025AD9bE6019e6e189DFeF1Db6c5e` (`"PT Capped sUSDe/USD linear discount 25SEP2025"`). For a **matured** PT `getCurrentDiscount()==0`, so it returns its underlying aggregator verbatim: `SingleFeedProvider 0x6926d2C4f5aecD82192A9faf7B8e09A1d103bf23` → `ChainlinkConsumer` (Chainlink **Data Streams**), whose stored `USDe/USD` report is frozen 127 d at `$0.99904247`. The consumer itself *does* enforce monotonic timestamps (`OldData`), so the value cannot be replayed backwards — it is simply **not being pushed**.

**Live staleness (fork-verified):** USDHL feed `updatedAt` = `1787759670` → **60.1 d** old, still returns `99779574`. PT feed `updatedAt` = `1781949599` → **127.3 d** old, still returns `99904247`. Every reserve with a *live* LTV has a fresh feed (≤ 0.05 d) — 18/18 scanned.

### 2.1 Correction to pass-7 — the dead-feed reserves are *also* soft-delisted, and e-mode matters
Pass-7 flagged only `LTV 0 % / 0.1 %`. Two further gates (both verified on-chain + fork) matter:

1. **`supplyCap = 1` and `borrowCap = 1` (whole tokens) on both reserves, already exceeded** → `supply()` reverts `SupplyCapExceeded`, `borrow()` reverts `BorrowCapExceeded`. This is a soft delisting that closes the path *independently* of LTV. (Also true for `USDH` and the `PT-kHYPE-13NOV/19MAR` reserves.)
2. **e-mode is broader than the per-reserve LTV suggests.** Reading the *real* v3.4 `EModeCategory` struct from Pool storage (slot 55; `getEModeCategoryData()` returns only the *legacy* struct and hides the bitmaps):

| cat | label | LTV | collateralBitmap | borrowableBitmap |
|---|---|---|---|---|
| 1 | HYPE correlated | 8270 | WHYPE, wstHYPE, kHYPE | WHYPE, wstHYPE, kHYPE |
| 2 | PT-kHYPE-13NOV2025 / HYPE | 8000 | PT-kHYPE-13NOV2025 | WHYPE |
| **3** | **PT-sUSDe / stablecoins** | **7500** | **PT-sUSDe-25SEP2025** | USDe, USDT0 |
| 4 | PT-kHYPE-19MAR2026 / HYPE | 8000 | PT-kHYPE-13NOV2025, PT-kHYPE-19MAR2026 | WHYPE |
| 5 | kHYPE / HYPE | 8713 | kHYPE, PT-kHYPE-13NOV2025, PT-kHYPE-19MAR2026 | WHYPE |
| 6 | PT-kHYPE-24SEP2026 / HYPE | 8000 | PT-kHYPE-13NOV2025, PT-kHYPE-19MAR2026 | WHYPE |

So the **stale-feed PT is e-mode collateral at 75 %** (`getUserReserveLtv` returns the category LTV, overriding the reserve's 5 bps). It is inert *only* because the reserve's `supplyCap=1` is already exceeded — a **cap**, not the oracle. (The `0x800` bit is fork-confirmed; labels 4/6 do not match their bitmaps.)

---

## 3. Live-state assessment (addresses · blocks · calls)

All reads at HyperEVM block ≈ **49,509,633** unless noted. Full dumps: `analysis/reserves_scan.json`, `analysis/reserve_configs_decoded.txt`, `analysis/reserve_totals.txt`, `analysis/emode_storage.txt`.

| Item | Value |
|---|---|
| Pool proxy / impl | `0x00A89d7a5A02160f20150EbEA7a2b5E4879A1A8b` → EIP-1967 `0xbebb62c7ff8b96db4325d9481c44e09a92d49b06` (`PoolInstance`, solc 0.8.27) |
| Oracle / base | `0xC9Fb4fbE842d57EAc1dF3e641a281827493A630e`; `BASE_CURRENCY=0x0`, `BASE_CURRENCY_UNIT=1e8` |
| Reserves | **18** (`getReservesList()`) |
| Pool size | **$467.7 M supplied / $162.4 M borrowed** (Σ aToken / variableDebtToken totalSupply × oracle prices) |
| `USDHL` cfg | LTV **0**, liqThr 0, **supplyCap 1**, **borrowCap 1**, borrowing=1, active=1, frozen=0, paused=0 |
| `USDHL` supply/borrow | 7,696.47 supplied / 3,778.19 borrowed → **both caps already exceeded** |
| `USDHL` oracle / real | **$0.99779574** (feed, 60.1 d) vs **$0.99956** (DefiLlama) → oracle **LOW 0.18 %** |
| `PT-sUSDe-25SEP2025` cfg | LTV **5**, liqThr 10, **supplyCap 1**, **borrowCap 1**, **borrowing=0**, active=1 |
| `PT-sUSDe` supply/borrow | 1.4511 supplied / 0 borrowed → **supply cap already exceeded** |
| `PT-sUSDe` oracle / true | **$0.99904247** (feed, 127.3 d) vs **~$1.00** (0.79692–0.79831 sUSDe/PT × $1.2544; empirically redeemed 2026-10-11) → oracle **LOW ~0.1 %** |
| ACL | `ADDRESSES_PROVIDER 0x72c98246a98bFe64022a3190e7710E157497170C`; `ACL_ADMIN 0xaAaaaAAAa810beD1EDA93A18FEC940857ED17879`; `POOL_CONFIGURATOR 0x8CB4310dD38F6fD59388C9DE225f328092bdC379` |
| Isolated pairs | registry `0xf55AF86c9EC3a7d5fa6367c00a120E6B262f718d` (4 pairs): `0x06Fd…` (USDT0/WHLP, ~$71 k, oracle fresh), `0xb8fE…` (USDT0/xHYPE, ~$1, oracle **stale→revert**), `0x78DD…` (USDC/xHYPE, ~$22 k, fresh), `0x9465…` (WHYPE/kmHYPE, ~$15 k, fresh). `OracleChainlink.maxOracleDelay` = 7 d (3 pairs) / 70 d (1) and **enforces it** (`revert "invalid oracle price"`). |

**Negative results (do not re-check):** USDHL is in **no** e-mode collateralBitmap; `setUserUseReserveAsCollateral(USDHL,true)` reverts `UserInIsolationModeOrLtvZero` (LTV 0). No `MorphoPythOracle`-style ERC-4626 donation leg is used by the core pool. The `PythOracleAdapter`'s price can only be moved by a **signed** Pyth update (real data), and `ChainlinkConsumer` rejects older timestamps (`OldData`), so neither dead feed is manipulable — only *stale*.

---

## 4. What an attacker can / cannot do

**Cannot (all fork-verified, `test_03`–`test_05`):**
- `supply(USDHL, …)` → reverts (`supplyCap=1`, 7,696 already supplied).
- `borrow(USDHL, …)` against a live-LTV collateral (USDC) → reverts (`borrowCap=1`, 3,778 already borrowed).
- `setUserUseReserveAsCollateral(USDHL,true)` → reverts (LTV 0; USDHL is in no e-mode bitmap).
- `supply(PT-sUSDe, …)` even in e-mode cat 3 → reverts (`supplyCap=1`, 1.4511 already supplied).
- `getAssetPrice()` is unvalidated beyond `>0` (`test_02`: a mocked divergent `latestAnswer` of $2.00 for the USDC feed is returned verbatim; a `0` answer falls to a **null** fallback oracle and reverts).

**Could, if the gates were removed (`test_06`/`test_07` = the *trigger* demonstrations):**
- With USDHL at `LTV 70 %`/`liqThr 75 %` + open caps, 1,000,000 USDHL of dead-feed collateral yields **`availableBorrowsBase = $698,457.02`** (0.698457 USDHL) → an attacker borrows USDC up to that. Fork-proven: `borrow(USDC, 100,000e6)` **succeeds** (status 1) against the frozen $0.9978 price.
- With the PT supply cap opened, 100,000 PT in e-mode 3 yields **`availableBorrowsBase = $74,928.19`** (0.749282 PT) → `borrow(USDT0, 50,000e6)` **succeeds**.
- Ceiling of any such path = the pool's *available* borrowable liquidity (USDC **4,706,779**, USDT0 **1,144,306**, WHYPE **362,414 ≈ $27.9 M**, USDe 58,415, …), not the $467 M TVL.

---

## 5. PoC / fork-verification

`poc/` (Foundry 1.8.6, solc 0.8.24) forks live HyperEVM via `https://rpc.hyperliquid.xyz/evm` (keyless) and runs 7 tests — **7/7 PASS**.

```
[PASS] test_01_oracle_dead_feeds_still_answer            (60.1d / 127.3d stale, prices > 0)
[PASS] test_02_oracle_ignores_staleness_and_divergence   (mocked $2.00 answer accepted; 0 -> revert)
[PASS] test_03_usdhl_soft_delisted_and_not_collateral     (LTV 0, supplyCap 1, borrowCap 1, supply reverts)
[PASS] test_04_usdhl_borrow_reverts_over_cap              (borrow USDHL reverts)
[PASS] test_05_pt_emode_collateral_but_supply_capped      (e-mode 3 set; supply(PT) reverts)
[PASS] test_06_trigger_dead_feed_with_real_ltv_drains     (LTV70 -> borrows; $698,457/1M USDHL)
[PASS] test_07_trigger_pt_emode_with_open_cap             (e-mode75 -> borrows; $74,928/100k PT)
```

- **CI run:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40227781920 (7 passed, 0 failed; artifact `result-hyperlend` → `ci-out/live_state.txt`). Full log `ci-log.txt`.
- The trigger tests use `vm.store` on the Pool's `_reserves` mapping (slot **52**, located empirically by matching the WHYPE config word) to open the caps / raise LTV — the oracle is left untouched (still the dead price). This is the honest "conditional" measurement: it proves the *mechanism* and its ceiling, and it shows the caps/LTV are the only thing standing between the flaw and a drain.

---

## 6. Verdict, residual risk, and the exact triggers

**Verdict: E-U $0.00, HIGH confidence.** The no-staleness-check flaw is live and general (any of the 18 feeds could die), but the two dead feeds are *accurate* (oracle ≤ real), and both dead-feed reserves are soft-delisted (caps=1, exceeded) and non-collateral in their own config. There is no permissionless path today.

**Re-arm triggers (monitor):**
1. **A dead feed gains a real LTV + an open cap.** Specifically: `USDHL` `LTV > 10 %` **and** `supplyCap`/`borrowCap` raised above current supply/borrow. Then a **>30 % USDHL depeg** while the Pyth feed stays frozen (it is already 60 d frozen) makes `supply(USDHL)+borrow(USDC)` net-positive (fork: borrow power 0.6985 USDHL; profit iff real price < $0.6985). Watch `PoolConfigurator` `CollateralConfigurationChanged`/`SupplyCapChanged`/`BorrowCapChanged`.
2. **A live-LTV feed dies while its market moves.** Every *live*-LTV asset is fresh today, but HyperLend already demonstrates the failure mode: the sUSDe PT feed went stale after maturity while the kHYPE PT feeds stayed fresh. If e.g. `kHYPE` (LTV 59 %) or a PT feed freezes, the pool misprices with **no** check. Trigger: `updatedAt` age > feed heartbeat on any reserve with LTV > 0 **and** a price divergence > `1/LTV − 1`.
3. **PT-sUSDe e-mode path:** opening `supplyCap` on the PT reserve re-enables a 75 %-LTV borrow against a **frozen $0.999** price; it becomes profitable only if the true PT value falls below **$0.7493** (e.g. a USDe depeg below ~$0.748) while the Chainlink Data Streams feed stays unpushed.

**Blocker caveat:** none of these is under attacker control — all three require a governance/config change or a stablecoin depeg; that is precisely why the honest E-U is $0.

---

## 7. Methodology, caveats, files

**Method.** Verified sources pulled from Etherscan V2 (chainid 999): `AaveOracle`, `PoolInstance` (aave-v3-origin v3.4), `PythOracleAdapter`, `PendlePriceCapAdapter`, `SingleFeedProvider`/`ChainlinkConsumer`, `HyperlendPair`, `OracleChainlink`. Full 18-reserve scan (`getConfiguration` bit-decoded with the exact v3.4 masks, `getAssetPrice`, `getSourceOfAsset`, `latestRoundData`/`latestTimestamp`); aToken/debtToken totals; e-mode read from raw Pool storage (slot 55) after finding `getEModeCategoryData()` returns only the legacy struct; real prices from DefiLlama; PT economics independently resolved (`analysis/ptsusde_value.md`, redemption tx `0x678b7b63…` at block 48,342,068). PoC runs in CI on a live fork.

**Caveats.** (i) Point-in-time 2026-10-25 — caps/LTV/feeds can change; re-read before acting. (ii) `getEModeCategoryData()` is the legacy struct — bitmaps must be read from storage slot 55. (iii) The trigger tests use state overrides; they measure the *mechanism/ceiling*, not a live drain. (iv) The oracle is USD-based (`1e8`); USD values for non-USD assets use the pool's own oracle. (v) Isolated-pair impact is bounded (~$110 k) and one stale oracle sits on a ~$1 pair.

**Files.** `README.md`, `summary.json`, `analysis/` (scan scripts + JSON/CSV + `ptsusde_value.md` + verified sources under `analysis/src/`), `poc/` (Foundry; `test/HyperLend.t.sol`), `ci/run.sh`, `ci-out/live_state.txt`, `ci-log.txt`, `ci-artifacts/`.

*Read-only. Nothing here is an instruction to transact. Prices: USDHL $0.99956, sUSDe $1.2544, USDe ~$0.9990 (DefiLlama/on-chain, 2026-10-25).*
