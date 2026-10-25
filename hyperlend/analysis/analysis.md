# HyperLend core pool — evidence trail & corrections (P7-03)

Companion to `../README.md`. All reads HyperEVM (999), block ≈ 49,509,633 (2026-10-25 ~18:15 UTC), keyless `https://rpc.hyperliquid.xyz/evm`.

## A. The oracle flaw (verified source)

`AaveOracle 0xC9Fb4fbE842d57EAc1dF3e641a281827493A630e` — stock Aave contract (solc 0.8.20, `contracts/misc/AaveOracle.sol`).
`getAssetPrice(asset)` = `assetsSources[asset].latestAnswer()` with the single check `price > 0`. **No `latestRoundData()`, no `updatedAt`, no heartbeat, no bounds.** (Source in `src/AaveOracle/`.)

Both dead feeds are themselves staleness-agnostic adapters:
- `PythOracleAdapter 0xa19b7fE6FFd492dd84ADF38D37B974Cb52f40267` (`"Pyth-USDHL/USD"`) → `pyth.getPriceUnsafe(feedId)` (explicitly unsafe accessor).
- `PendlePriceCapAdapter 0x8514D528275025AD9bE6019e6e189DFeF1Db6c5e` (`"PT Capped sUSDe/USD linear discount 25SEP2025"`) → underlying aggregator `SingleFeedProvider 0x6926d2C4f5aecD82192A9faf7B8e09A1d103bf23` → `ChainlinkConsumer` (Chainlink Data Streams). `ChainlinkConsumer.verifyReport` **does** enforce monotonic timestamps (`revert OldData`) — so the frozen value cannot be replayed *backwards*; it is simply not being pushed. `SingleFeedProvider` / `ChainlinkConsumer` sources in `src/SingleFeedProvider/`.

## B. Staleness measured on-chain

| reserve | feed | updatedAt | age | price (1e8) | live LTV |
|---|---|---|---|---|---|
| USDHL `0xb50A9625…` | `0xa19b7fE6…` | 1787759670 | **60.1 d** | 0.99779574 | 0 |
| PT-sUSDe-25SEP2025 `0xb7379d39…` | `0x8514D528…` | 1781949599 | **127.3 d** | 0.99904247 | 5 bps (reserve) / **7500 e-mode cat 3** |
| all other 16 reserves | — | — | ≤ 0.05 d | — | as scanned |

(`analysis/reserves_scan.json`, `analysis/reserve_details.txt`.)

## C. Corrections to pass-7

1. **`getConfiguration` caps (v3.4 masks).** USDHL: `LTV 0`, **`supplyCap 1`**, **`borrowCap 1`**, borrowing=1, active=1, not frozen, not paused. PT-sUSDe: `LTV 5`, **`supplyCap 1`**, **`borrowCap 1`**, borrowing=0. Both caps are **already exceeded** (USDHL 7,696 supplied / 3,778 borrowed; PT 1.4511 supplied) → `supply()`/`borrow()` revert. This is a soft-delisting gate pass-7 did not report. Decoded with the exact v3.4 masks parsed from `ReserveConfiguration.sol` (`analysis/reserve_configs_decoded.txt`).
2. **e-mode bitmaps.** `Pool.getEModeCategoryData()` returns only `EModeCategoryLegacy` `(ltv,liqThr,liqBonus,priceSource,label)` — it hides the v3.4 `collateralBitmap`/`borrowableBitmap`/`ltvzeroBitmap`. Read them from **Pool storage slot 55** (`_eModeCategories` mapping; located by matching cat-1's packed word `0x…010329042328204e`). Result: **cat 3 ("PT-sUSDe / stablecoins", LTV 7500) has `collateralBitmap = 0x800` = PT-sUSDe-25SEP2025** → the stale PT is e-mode collateral at **75 %**, overriding its 5 bps reserve LTV. Cat 2/4/5/6 make the `PT-kHYPE-*` tokens 80–87 % e-mode collateral. (`analysis/emode_storage.txt`, `emode_decode.py`.)
3. **The dead feeds are accurate, not diverged.** USDHL oracle 0.99779574 vs real 0.99956 (DefiLlama) → **understates 0.18 %**. PT oracle 0.99904247 vs true ≈ $1.00 (0.79692–0.79831 sUSDe/PT × $1.2544; empirical redemption tx `0x678b7b63…` at block 48,342,068, 2026-10-11) → **understates ~0.1 %**. Staleness ≠ divergence. (`analysis/ptsusde_value.md`.)
4. **Isolated pairs use a staleness-checking oracle.** `OracleChainlink` reverts `"invalid oracle price"` when `block.timestamp - updatedAt > maxOracleDelay`. Live: `0x70f27F1a` fresh, `0xd8adb328` **STALE→revert** (7 d; its pair `0xb8fE…` holds ~1 USDT0), `0x896970EB` fresh (70 d tolerance), `0x8CBa4384` fresh. `maxOracleDelay` = 604800 (7 d) ×3 / 6048000 (70 d) ×1. Pass-7's "all feeds fresh ~18 min" is now wrong for one oracle — but its pair is ~$1.

## D. Fork PoC results (CI)

`poc/test/HyperLend.t.sol`, 7/7 PASS — https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40227781920

| test | result | key number |
|---|---|---|
| 01 dead feeds still answer | PASS | ages 60.1 d / 127.3 d; prices > 0 |
| 02 no staleness/divergence check | PASS | mocked USDC `latestAnswer()=$2.00` accepted verbatim; `0` → revert (null fallback) |
| 03 USDHL soft-delisted | PASS | LTV 0, supplyCap 1, borrowCap 1; `supply(USDHL)` reverts |
| 04 USDHL borrow over cap | PASS | `borrow(USDHL)` reverts |
| 05 PT e-mode collateral, supply capped | PASS | e-mode 3 set; `supply(PT)` reverts |
| 06 trigger: USDHL LTV 70 % + open cap | PASS | 1,000,000 USDHL → collateralBase $997,795.74, **availableBorrows $698,457.02**; `borrow(USDC,100000e6)` succeeds |
| 07 trigger: PT e-mode + open cap | PASS | 100,000 PT → collateralBase $99,904.25, **availableBorrows $74,928.19**; `borrow(USDT0,50000e6)` succeeds |

`_reserves` mapping slot = **52** (located empirically: `keccak256(abi.encode(WHYPE,52))` holds the WHYPE config word). Trigger tests `vm.store` the config there; the oracle is untouched (still the dead price).

## E. Negatives (do not re-check)

- USDHL is in **no** e-mode collateralBitmap; `setUserUseReserveAsCollateral(USDHL,true)` reverts `UserInIsolationModeOrLtvZero`.
- No `MorphoPythOracle`/ERC-4626-donation leg in the core pool.
- Neither dead feed is manipulable: Pyth needs a signed update; `ChainlinkConsumer` rejects older timestamps.
- `USR` (frozen, caps 1, price $0.50) and `USDH` (LTV 62 % but caps 1, already exceeded) are also inert.
- `USDe` has LTV 0 (borrowable only); `sUSDe` has borrowing disabled.
- All reserves with an **open** supply cap and a real LTV have **fresh** feeds (≤ 0.05 d).

## F. Files

- Scans: `reserves_scan.py`/`reserves_scan.json`, `emode_scan.py`, `emode_decode.py`, `emode_storage.txt`, `reserve_configs_decoded.txt`, `reserve_totals.py`/`reserve_totals.txt`, `probe_reserves.sh`/`reserve_details.txt`, `pr_abi.json`.
- Sources (Etherscan V2 chainid 999): `fetch_src.sh`, `extract_src.py`, `src/{AaveOracle,PythOracleAdapter,PendlePriceCapAdapter,SingleFeedProvider,PoolInstance,HyperlendPair,OracleChainlink}/`.
- PT economics: `ptsusde_value.md`.
- PoC: `../poc/test/HyperLend.t.sol`.
