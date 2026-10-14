# Orbit Protocol (Blast) — L2 Phase-2 deep dive

**Date:** 2026-10-14 · **Chain:** Blast (81457) · **Targets:** 4 Orbit comptrollers ("Orbit Space Station V4") + 21 oToken markets
**Status:** read-only; PoC fork-verified only (GitHub Actions, local forks); **no mainnet transactions, no secrets**.

Comptrollers: `0x1E18C3cb…` (c1), `0x273683CA…` (c2), `0xe9266ae9…` (c3), `0xfFF8Fc17…` (c4).
Impl: `OrbitSpaceStationV4` (Compound v2 Comptroller fork + ORB rewards). Markets: `OErc20Delegator`→`OErc20DelegateV2` (V2) and `OEther2` (native ETH).

---

## 1. TL;DR

| Target | Live value (USD) | Category | Why |
|---|---|---|---|
| **Live custody (cash in 21 markets)** | **$612,954** | H-O | Suppliers' pro-rata claims; redeemable while cash lasts (no oracle needed for debt-free suppliers). |
| c1: USDB 63,723.6 ($63,360) + oETH 53.83 ($134,895) + oETHV2 143.47 ($359,565) + small ($408) | $558,228 | H-O | Cash is owned by oToken holders. |
| c2: oETHV2 9.175 ETH ($22,994) + ezETH 8.220 ($22,339) + dust | $45,334 | H-O | idem. |
| c3: wrsETH 1.266 ($3,322) + USDe 1,234 ($1,234) + USDB 1,892 ($1,881) + DETH 0.285 ($714) + weETH $69 + RESC (unpriced) + dust | $7,220 | H-O/S | Mostly suppliers' claims; DETH/USDB/DUSD claims are ~100% bad debt. |
| c4: oETHV2 0.538 ETH ($1,350) + weETH 0.207 ($571) + DETH 0.1 ($250) | $2,171 | H-O | idem. |
| Blast native yield on oEther markets | **~$20,200** (8.06 ETH) | **P** | `_blastClaimYield` is `msg.sender == admin` only (fork-verified revert). |
| Mispriced collateral: RESC priced at ETH/USD | **$0** | E-U (closed) | c3 RESC market maps to the **ETH/USD Pyth feed** (CF 0.8, mint+borrow open), but 990,000 of the 1,000,000 RESC supply is held by the team admin address and there is no market/venue to obtain RESC — not an unprivileged path. |
| Liquidation of underwater accounts | **$0 today; ≤ $12.50 conditional** | E-U | 4,042 borrowers scanned: 65 underwater, **1** with profitable collateral ($250 USDe → 5% = $12.50), and liquidations are **currently blocked** because every Pyth feed reverts `StalePrice` (fork-verified). Needs a Pyth API key to refresh. |
| Bad debt (c3 DETH/USDB/DUSD) | $457.8M nominal shortfall | **S** | Uncollectible; claims inflated by interest on defaulted borrows; nobody can realize it. |

### Total live extractable now: **$0.00 (E-U)** — confidence **high**

The $612,954 of live cash is **supplier-owned (H-O)**; the $20.2k of Blast yield is **admin-gated (P)**; the ~$458M of nominal bad debt is **unrealizable (S)**. The only theoretical unprivileged profits are (a) one underwater account worth **$12.50** of liquidation profit and (b) the RESC-collateral borrow (**$0**, token unobtainable) — and both require the Pyth price feeds to be refreshed first, which today is impossible without a Pyth API key (the reason the protocol is frozen).

---

## 2. What the protocol is / incident history

- Orbit Protocol was a Blast-native Compound-v2 fork (launched Feb–Mar 2024, "Orbit Space Station"), with 4 isolated comptrollers and an ORB reward token. It was one of the largest Blast lending protocols in 2024.
- The protocol is now **dormant**: last meaningful activity is old; DefiLlama flags the markets insolvent and shows TVL $612.8k (cash), which our on-chain reads reproduce ($612,954 at 2026-10-14).
- Bad debt: c3 markets show enormous nominal borrows (181,183 DETH, 5,745,413 USDB, 7,327,274 DUSD) against ~$7.2k of cash — accumulated interest on defaulted loans in deprecated markets.
- Oracle infrastructure has **decayed**: c1's USDB market uses a Redstone push oracle last updated 2026-02-19 (~8 months ago); c1's oETHV2 market uses an API3 dAPI proxy that reverts `dAPI name not set`; all Pyth feeds were last updated ~23 days ago (2026-09-20) — right after Pyth's Hermes API-key migration (2026-08-26), suggesting the keepers stopped running.

---

## 3. Live-state assessment (all reads at Blast blocks ~41.56M–41.57M; 2026-10-14)

| Item | Value | Evidence |
|---|---|---|
| Comptrollers | 4 Unitrollers, impl `OrbitSpaceStationV4` (verified) | `eth_getCode`, Etherscan V2 81457 |
| c1 admin | `0x154D8e44d88A061908aA9b3A4f8609bD72B19886` | `admin()` |
| c2/c3/c4 admin | `0x6315F65843e7582508e4F0aAC20a7203E7B09F02` | `admin()` |
| pendingAdmin / pendingComptrollerImplementation | `0x0` everywhere | `pendingAdmin()`, `pendingComptrollerImplementation()` |
| closeFactor / liqIncentive | 0.5 / 1.05 (all) | `closeFactorMantissa()`, `liquidationIncentiveMantissa()` |
| pauseGuardian | `0x0` everywhere; transferPaused/seizePaused = false | getters |
| Market gate map | c1: oETH#1 borrow-paused, others open (caps=0=unlimited). c2: all open (ezETH borrowCap=1). c3: **all mint+borrow paused** except DETH (borrow open, cap 0) and RESC (mint+borrow open, cap 0). c4: open (weETH cap 1) | `mintGuardianPaused`/`borrowGuardianPaused`/`borrowCaps` |
| Oracles | c1 = `OracleRouter` → per-market: Pyth (oETH#1/#2, small), Redstone (USDB), API3 (oETHV2). c2/c3/c4 = `PythOracleProxy` | `oracle()`, router map, verified sources |
| Pyth contract | `0xA2aa501b19aff244D90cc15a4Cf739D2725B5729` (canonical), validTimePeriod 60s | `pyth()`, `getValidTimePeriod()` |
| Pyth feeds | **stale ~23 days** (`StalePrice` revert; ETH/USD stored publishTime 1789936627, price $2,631.98@expo-8) | `getPriceNoOlderThan` → revert `0x19abf40e` |
| Redstone USDB | adapter `0x3a236f67…`, roundId 3506, answer 99,797,441 (8 dec = $0.99797), updatedAt 1771528225 = **2026-02-19** → `OraclePriceExpired` | `latestRoundData()` |
| API3 oETHV2 | `getUnderlyingPrice` reverts `dAPI name not set` | call trace |
| RESC feed | `addressToPriceFeedID[RESC] = 0xff61491a…` = **ETH/USD feed** (RESC has no market value) | `addressToPriceFeedID()` |
| Live cash | **$612,954** (see table in §1; per-market detail `analysis/custody_table.json`) | `getCash` + CoinGecko/DefiLlama prices |
| Blast claimable yield | c1 oETHV2 4.715 ETH, c2 oETHV2 2.925 ETH, c4 oETHV2 0.420 ETH (+dust) ≈ $20.2k | `IBlast.readClaimableYield` |
| ORB token | `0x42e12d42b3d6c4a74a88a61063856756ea2db357`; comptroller balance ~0.00065 ORB | `getTokenAddress()`, `balanceOf` |
| Comptroller ORB accruals | compRate = 0; no active reward speeds | `compRate()`, `_setOrbSpeeds` admin-gated |

---

## 4. The code — what an attacker actually faces

- **Comptroller** (`SpaceStationV4.sol`): Compound v2 Comptroller with ORB rewards. `borrowAllowed` reverts on `borrowGuardianPaused`, enforces caps (0 = unlimited), then `getHypotheticalAccountLiquidityInternal`. `liquidateBorrowAllowed` = standard (isListed + shortfall + closeFactor 0.5). `seizeAllowed` only checks `seizeGuardianPaused` + listing. `_become` requires unitroller admin. All config functions admin-gated (some return `fail()` codes instead of reverting — verified no state change).
- **cTokens** (`OTokenV2`/`OErc20DelegateV2`/`OEther2`): standard Compound v2 + Blast yield config. `initialize()` is `msg.sender == admin` + one-time. `_blastClaimYield`/`_blastClaimYieldAll`/`_blastConfigureYield` are admin-only. `sweepToken` admin-only. `_reduceReserves` admin-only. `_setImplementation` admin-only. Fallback delegatecall standard.
- **Unitrollers**: `comptrollerImplementation` set; `pendingComptrollerImplementation == 0` (no takeover path). `_acceptImplementation` requires `msg.sender == pendingImplementation`.
- **Oracles**: all three proxies have staleness checks (Pyth 3600s, Redstone 86400s, API3 86400s) and revert on stale/negative prices; feeds are off-chain-signed (not spot-DEX), so no flash-loan manipulation.
- **RESC mispricing**: the c3 `PythOracleProxy.addressToPriceFeedID[RESC]` entry is the ETH/USD feed — a configuration error. Since c3 borrows are paused everywhere except DETH and RESC, this is capped at the DETH cash (0.285 ETH) and requires obtaining RESC tokens (not obtainable on-chain today: no DEX pool found; the only transfers are dust between the market and a handful of addresses; total supply 1,000,000, 18 dec, unverified contract "RescueFunds").

---

## 5. What an attacker can / cannot do (exact paths)

| Path | Verdict | Evidence |
|---|---|---|
| Admin takeover (`_become`, `_setPriceOracle`, `_setCloseFactor`, `_setMintPaused`) | **No** | fork test `test_03` (all fail/revert; oracle unchanged) |
| `_reduceReserves` / `sweepToken` / `_blastClaimYield` | **No** — admin-only | fork test `test_03`, source |
| Empty-market donation (totalSupply==0 && cash>0) | **No candidates** | fork tests `test_04` (0 candidates), `test_05` (all cash-bearing oEther markets have supply>0) |
| Borrow cash against fair collateral | **No profit** (must repay; CF 0.6–0.8 < 1) | math + gate map |
| Borrow cash with mispriced collateral (RESC→ETH feed) | **$0** | 990k/1M RESC held by team admin `0x6315F658…`; no DEX/venue; only 13.8 RESC outside team+market |
| Liquidation of underwater accounts | **$0 today; ≤ $12.50 conditional** | 4,042 borrowers scanned (`positions2.py`, CI): 65 underwater, 1 with profitable collateral; `test_08` shows every probed liquidation reverts `StalePrice` (0x19abf40e) |
| Redeem cTokens (suppliers) | **Allowed** (H-O) — limited by market cash | `redeemAllowed` skips oracle check for debt-free accounts |
| Oracle manipulation (flash loans) | **No** — signed off-chain feeds + staleness checks | source |
| Stale-price window abuse (push old VAA) | **No** — 3600s freshness window blocks >~1% deviation; CF < 1 | `PythOracleProxy` source |
| Refresh Pyth prices | **Possible only with a Pyth API key** (Hermes requires auth since 2026-08-26); not needed for the protocol's own keepers — they stopped 23 days ago | `hermes.pyth.network` → unauthorized; Pyth docs |
| Blast yield claim | **No** — admin-only (P) | fork test `test_03` |
| Redstone USDB feed refresh | **No** — `requireAuthorisedUpdater` + signed data packages | `MergedAdapterWithRoundsUsdbV1` source |
| Frozen accounts (oETHV2/USDB collateral with dead oracles) | **S** | `getAccountLiquidity` reverts for accounts holding those markets |

---

## 6. PoC / fork verification

Foundry project `poc/` (fork of Blast mainnet, keyless public RPC). **9/9 tests passing** (CI re-run):

- `test_00_live_state` — snapshot of all 4 comptrollers + 21 markets (cash/borrows/supply/reserves/exchangeRate).
- `test_01_oracle_prices` — per-market `getUnderlyingPrice` (revert reasons for stale/dead feeds).
- `test_02_pyth_refresh` — Pyth staleness proof (ETH/USD stored `publishTime` 2026-09-20; `getPriceNoOlderThan(3600)` reverts `StalePrice`); optional refresh with a Hermes VAA when available (CI env `PYTH_VAA_*`; Hermes now requires an API key → CI reports "no VAA", which is itself the finding).
- `test_03_admin_gates` — fresh address cannot change oracle, close factor, implementation, reserves, sweep tokens, pause states, or claim Blast yield (all fail/revert; oracle unchanged).
- `test_04_donation_check` — **0** zero-supply cash-bearing markets.
- `test_05_ether_donation_check` — no CEther donation path.
- `test_06_borrow_probe` — fresh borrower without collateral cannot borrow (reverts).
- `test_07_liquidation_probe` — env-provided pairs.
- `test_08_targeted_liquidation` — the 4 largest underwater accounts all revert `0x19abf40e` (`StalePrice`) on `getAccountLiquidity` → **liquidations are impossible today**.

The full borrower scan (4,042 candidate pairs from 30,592 on-chain `Borrow` events) runs off-chain in `analysis/positions2.py` (CI step) because it needs ~10k `eth_call`s; results in `ci-artifacts/…/ci-out/positions2.json` and `analysis/liquidation_profit.json`:
- 4,042 scanned, 65 underwater (nominal shortfall $457.8M), **1** with collateral in a market whose cash ratio > 0.9524 (`0xD89b1b88…`, $249.90 of USDe) → **max liquidation profit $12.50** — and only after a Pyth refresh.

CI run: see `summary.json` → `poc.ci_run_urls` and `ci-log.txt` / `ci-artifacts/`.

---

## 7. Verdict, residual & latent risk

- **E-U = $0.00 today (high confidence).** Every unprivileged path to the $612,954 of live cash is closed by code (admin gates), state (all markets funded with supply>0; borrow/mint pauses; dead oracles), or economics (CF<1, 5% liquidation bonus vs cash ratios of 0.0002–1.0).
- **Conditional E-U = $12.50** (one underwater account `0xD89b1b88…`: repay ~$238 of DETH, seize $250 of USDe oTokens, redeem; 5% bonus) — executable only after someone obtains a Pyth API key and refreshes the ETH/USD + USDC/USD feeds. The RESC-collateral path is worth $0 (token unobtainable).
- **H-O = $612,954**: suppliers can redeem pro-rata while cash lasts; debt-free suppliers don't need oracles. Individual accounts holding dead-oracle markets (c1 USDB, c1 oETHV2) as collateral *and* carrying debt are frozen (can't redeem/borrow/liquidate) — a subset of the cash is in those markets (c1 USDB $63.4k, c1 oETHV2 $359.6k).
- **P = ~$20.2k** Blast yield (admin-only) + market reserves (admin `_reduceReserves`; reserves are largely unbacked in the bad-debt markets).
- **S = $457.8M nominal** bad debt (65 underwater accounts; c3 DETH/USDB/DUSD) + frozen accounts — uncollectible/immovable by anyone.
- **Latent risk:** (1) the RESC→ETH/USD feed misconfiguration is a real bug: if RESC were ever distributed/listed, a holder could borrow up to ~$714 against worthless collateral; (2) if a Pyth API key is used to refresh feeds, the $12.50 liquidation becomes live and bots may cascade to seize remaining realizable collateral; (3) if the admin keys are lost, the $20.2k Blast yield becomes S.

**Blockers/caveats:**
- Blast wind-down (announced 2026-10-02): withdrawals through the Blast interface until 2026-10-26, then via L1 bridge contracts; assets remain withdrawable.
- Pyth feed refresh requires an API key (Hermes auth change, Aug 2026) — the reason the protocol is frozen; the protocol's own keepers appear to have stopped running.
- The liquidation scan uses true market prices (CoinGecko/DefiLlama) as a proxy for refreshed Pyth prices; Pyth would return its own prices within ±1%.
- RESC's true value is unobservable (no market); assumed $0.
- DETH/wrsETH/weETH/ezETH are priced by the protocol's oracle at their Pyth/ETH values; DEX liquidity for DETH was not verified — if DETH is untradable, the $12.50 liquidation is also not executable (the liquidator must repay in DETH).

---

## 8. Methodology & sources

1. Enumerated all 4 comptrollers + 21 markets from on-chain `getAllMarkets`; verified code/sources via Etherscan V2 (chainid 81457).
2. Read market state (`getCash`/`totalBorrows`/`totalSupply`/`totalReserves`/`exchangeRate`) and comptroller config (`admin`, `oracle`, `closeFactor`, `liquidationIncentive`, pause flags, caps) at pinned blocks.
3. Read oracle configuration (router maps, Pyth feed IDs, Redstone adapter, API3 dAPI) and current values; proved staleness.
4. Pulled all `Borrow` events (30,592) via Etherscan V2 logs; built 4,042 unique borrower-market candidate pairs.
5. Scanned every candidate: `getAssetsIn` + `getAccountSnapshot`, computed Compound account liquidity with true prices, plus cash-realizable collateral values.
6. Fork tests for every candidate extraction path (admin gates, donation, borrow, liquidation scan).
7. Prices: CoinGecko (ETH) + DefiLlama `coins.llama.fi` (tokens).

**Files:** `analysis/` (state JSONs, scripts, sources under `analysis/src/`, custody table), `poc/` (Foundry), `ci/`, `ci-out/`, `ci-log.txt`.
