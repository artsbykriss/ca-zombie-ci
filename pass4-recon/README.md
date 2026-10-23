# ZH4-PASS4 — residual reconciliation (every lane candidate dispositioned)

**Date:** 2026-10-23 · **Mode:** read-only; no transactions signed/sent; no keyed RPC URLs or secrets in this folder · **Scope:** every candidate row **and** named prose/negative/watchlist lead in all **16** lane files of `zombie-hunt-iv/pass4/` (`affluent, bmx-deli, contest-gap, gap-chains, hacklab-patterns, incidents, mellow, microcap, off-llama, recall, skim-burn, small-chain-scout, trusted-caller, unverified-impl, verify-bmx-mellow, verify-fluid`).

**Why this pass exists.** The pass4 `README.md` lists ~30 protocols, but the lane files name **>200**. The principal flagged that funded candidates may never have been assigned. This pass gives **every named candidate a disposition** and isolates the residual **OPEN** list (funded + plausible unprivileged path + no verdict anywhere). It does **not** deep-dive them.

## Headline counts

| Metric | Count |
|---|---|
| Named candidates enumerated (rows/groups in the disposition table) | **209** |
| — README-FINDING (pass4 README Tier1/2/3 or carry-over) | **15** |
| — README-CLOSED (pass4 README closed table / closed-list) | **39** |
| — LANE-CLOSED (lane file gives a closing verdict) | **75** |
| — PRIOR-COVERED (verdict in an earlier tracker/pass/folder) | **37** |
| — PRIOR-PARTIAL (same protocol, distinct angle) | **1** |
| — NOT-A-PROTOCOL (metric/address/token/pattern/infra) | **30** |
| — LANE-LEAD (named watchlist lead, not verified — below OPEN bar) | **6** |
| — **OPEN** (funded + plausible unprivileged path + no verdict) | **6** |

No new pass4 finding is created; the pass4 verdicts stand (Affluent withdrawn as a false positive 2026-10-23; Burve/Kuru/Infrared/BTCΞ-NS-DMD/BigShot/Metis all closed). The residual value is the OPEN list below.

*Counting note: the 209 rows include grouped rows (e.g. "11 ETH proxies below $10k") and prior-corpus exclusion lists; the full per-name table is `analysis/ALL-ROWS.md`. A row that names a README item **and** is also prior-covered is counted once (README first).*

## OPEN list — ranked by live funds × plausibility

| # | Target | Chain | Live funds (verified 2026-10-23) | Plausibility / confidence | Path | Next check |
|---|---|---|---|---|---|---|
| 1 | **Cabal LST** | Initia / Cabal / Strat (Move, non-EVM) | **~$2.74M DL** (Initia $2.11M + Cabal $128k + Strat $503k) | **MED** / LOW-MED | Cantina/Code4rena **2025-04-cabal-liquid-staking-token H-01**: LP unstake burns shares but leaves underlying → share/asset ratio distortion. The live Move modules were **never diffed**; the audited code may still be live. | Obtain the deployed Cabal LP-staking + LST Move modules; diff vs the audited commit; test the unstake ratio; confirm whether H-01 was mitigated. |
| 2 | **shMonad** `0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c` (impl `0x8ee4ff5f…`) | Monad (143) | **~$7.27M** (`totalAssets()` 333.8M MON; native only ~$182k) | MED-LOW / LOW | Verified `ShMonad` LST; the lane found "no unguarded value-moving external" but **did not deep-diff** the verified impl (stake/unstake/validator-queue + share accounting unreviewed). A native-balance-only screen badly under-reports (98% is staked/delegated). | Diff live impl vs repo HEAD; read stake/unstake/withdraw + share math + validator-delegation auth; fork-test a round-trip and a donation/first-redeemer case. |
| 3 | **Kipseli** "reserve" `0xbee3211ab312a8d065c4fef0247448e17a8da000` | Base (8453) | **~$694k DL Base**; contract holds **~$440.8k USDC + 31.09 WETH (~$75k)** | LOW-MED / LOW | The Base "reserve" is a **deployed contract** (child A: 2,009 bytes, present) flagged **unverified** — a reserve/revenue wallet holding pooled USDC+WETH. If it exposes an unguarded sweep/release (Slice-class) the whole balance moves. BSC reserve is a Gnosis Safe (P). | Decompile the Base reserve contract; enumerate value-moving selectors and auth; check for a caller-supplied recipient / missing `msg.sender` gate. |
| 4 | **TOPS** `0x842B1bFA…3FD588` (pair `0xBEDeBaC3…eDF29`) | BSC | **~$92k USDT** (lane) | LOW-MED / LOW | NEM-class: token bytecode contains a genuine external `sync()` call; **gate UNRESOLVED** (decompiler could not emit the caller; a fork buy reverted, so no outsider entry via the router was found). Funded, no verdict. | Recover the full token source; identify the function that burns/removes from the pair and its gate; fork-probe from a fresh EOA. |
| 5 | **LVIN** `0x33bc8653…545a8` (pair `0x43365c7b…9dc8b`) | BSC | **~$91k USDT** (lane) | LOW / LOW | NEM-class `recycle(uint256)`; fork call reverts `"recycle fail"` — a **state condition, not clearly a gate**. Funded, no verdict. | Walk the `recycle` state preconditions on a fork; test whether the staking-contract path is reachable unprivileged. |
| 6 | **Metropolis DLMM `VaultFactory`** `0x197d40B36677248E82939f96930bf4E7Fe8aD1c2` | Sonic (146) | no direct custody (factory); owner `0xd1f2823f…` | LOW / LOW | Permissionless `createMarketMakerOracleVault(ILBPair,uint16) external payable`; the **vault-side admin/auth was never read**. A factory-created vault with a mis-scoped admin is a downstream drain; factory itself holds 0. | Read the vault implementation the factory clones; check owner/guardian of created vaults and any unguarded fee/withdraw path. |

### OPEN detail — addresses and blockers

**1. Cabal LST** — Initia / Cabal / Strat (Move)
- Live funds: **~$2.74M DL** (child A: Initia $2,114,327 + Cabal $127,578 + Strat $502,890; latest point 1792734023).
- Addresses: **non-EVM (Initia Move)** — no EVM address; DefiLlama slug `cabal`. Audit: Code4rena `2025-04-cabal-liquid-staking-token` **H-01** ("LP unstake burns shares but leaves underlying → ratio distortion"); no mitigation review in the report.
- Path: an LP-stake/unstake round trip that burns shares without moving the underlying would let a staker extract the value of the un-burned underlying (share/asset ratio inflation). Proven? **Unverified** — the lane never diffed the live Move modules.
- Confidence: LOW-MED · plausibility: MED.
- Next check: fetch the deployed Cabal LST + LP-staking Move modules; diff vs the audited commit; fork/unit-test the unstake ratio.

**2. shMonad** — Monad
- Live funds: **~$7.27M** (`totalAssets()` 333,812,435 MON ≈ $7.27M; `totalSupply()` 203.4M shMON; native balance 8.37M MON ≈ $182k). Block 115,828,947.
- Addresses: proxy `0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c` → EIP-1967 impl `0x8ee4ff5fF50198dcbb7b882a0781f42724DD095f`.
- Path: verified LST; the lane's "no unguarded value-moving external found" was a surface scan, **not a diff** — stake/unstake/validator-queue/share-accounting were not read line-by-line.
- Confidence: LOW · plausibility: MED-LOW.
- Next check: diff live impl vs `ShMonad` repo HEAD; read share math + delegation auth; fork round-trip + donation test.

**3. Kipseli** — Base (BSC leg is a Gnosis Safe)
- Live funds: DefiLlama `kipseli` Base **$694,460** (+ Robinhood Chain $299,284 + Binance $395,648 ≈ $1.39M). Child A (block 52,974,224): Base "reserve" holds **440,831.23 USDC (~$440.6k) + 31.0887 WETH (~$74.7k)**; `eth_getCode` present (2,009 bytes), **unverified**.
- Addresses: Base `0xbee3211ab312a8d065c4fef0247448e17a8da000` (unverified contract); BSC `0xbee1aa51dce11faa5bfc6c56dbfa5b95d4dfc000` (Gnosis Safe, P-class).
- Path: if the unverified Base reserve exposes a permissionless sweep/release to a caller-supplied recipient (Slice-class), the ~$515k moves in one tx. Not yet decompiled.
- Confidence: LOW · plausibility: LOW-MED.
- Next check: decompile the Base reserve; enumerate non-view selectors and auth; `eth_call` from a random EOA.

**4–5. TOPS / LVIN** — BSC
- Live funds: ~$92k / ~$91k USDT in the PancakeV2 pairs (lane, 2026-10-22).
- Addresses: TOPS `0x842B1bFA…3FD588` / pair `0xBEDeBaC3…eDF29`; LVIN `0x33bc8653…545a8` / pair `0x43365c7b…9dc8b` (addresses truncated in the lane file — recover in full from the token list before acting).
- Path: NEM-class burn-from-pair + `sync()`; both gates **unresolved** (TOPS buy reverted; LVIN `"recycle fail"`). Funded, no verdict anywhere.
- Confidence: LOW · plausibility: LOW.
- Next check: full source + fork probe from a fresh EOA.

**6. Metropolis DLMM VaultFactory** — Sonic
- Live funds: none at the factory (child A: code present, native 0; owner `0xd1f2823f3aBF4b8c7Ad1B6629421b2618a5e28aF`).
- Path: permissionless vault creation; **vault-side admin not read**.
- Confidence: LOW · plausibility: LOW.

## UNVERIFIED WATCHLIST RESIDUAL (funded leads with **no** confirmed custody/path — not OPEN)

Named watchlist leads that are funded-by-DefiLlama but whose custody contract was never pulled (lane explicitly "not yet verified on-chain"). Listed so they are not lost; they do **not** meet the OPEN bar (no confirmed custody, no plausible path yet).

| Lead | Chain | DL TVL | Prior coverage | Disposition |
|---|---|---|---|---|
| Vectis Finance | Solana/Eth | $5.14M | none | LANE-LEAD |
| LiquidLoans | Pulse | $2.83M | pass2 collapses (note only) | LANE-LEAD |
| Pay Protocol | Tron/BSC/ETH | $1.92M | none | LANE-LEAD |
| Trevee Earn | Sonic | $930k | pass3 lane-yield ("not reached") | LANE-LEAD |
| Unlink | Monad | n/a | none | LANE-LEAD |
| Lagoon v0.5.2 `syncDeposit` (RockSolid family) | — | — | none | LANE-LEAD |

*(The microcap 120-protocol watchlist also named Adrastea, Hylo, Raiku, CatFee, Kyros, StakePoint, SunPump, Magma, Bio Protocol — all **PRIOR-COVERED** in pass3 lanes / zombie_hunt; see `analysis/ALL-ROWS.md`.)*

## Disposition of the specific candidates the principal flagged

| Item | Disposition |
|---|---|
| Affluent / Factorial (TON) | **README-FINDING (P4-01) — withdrawn as FALSE POSITIVE 2026-10-23** (all backing drained to 0); PRIOR-COVERED (P4, MON). |
| Burve | **README-FINDING (P4-02)** → removed ($0; product conflation); PRIOR-COVERED (P4). |
| Kuru | **README-FINDING (P4-03)** → removed (OZ EIP-1967 proxies; gate + formal proof). |
| Infrared | **README-FINDING (P4-04)** → removed (verified iBERA LST). |
| BTCΞ / NS / DMD | **README-FINDING (Tier3 #3)** → removed ($0; gates resolved). |
| BigShot | **README-FINDING (Tier3 #1)** → monitor ($0, fork-proven). |
| Metis Multicall3Router | **README-FINDING (Tier3 #2)** → monitor ($0, 34 chains). |
| BiFi / AlpsCon / Pharaoh / Radworks | **PRIOR-COVERED** carry-overs (pass3 / pass3 / pass3 / pass2). |
| AtomicQueue | **README-FINDING (Tier3 #4)** + PRIOR-COVERED (ZH1 C-07). |
| GaslessReservoirEnabler | **README-FINDING (Tier3 #5)** + PRIOR-COVERED (ZH2-excluded). |
| Nile / Nuri / Cleopatra gauges | **README-FINDING (Tier3 #6)**; PRIOR-COVERED (pass3/ZH2). |
| **Cabal LST** | **OPEN #1** — never in the README; funded $2.74M; published H-01 un-diffed. |
| **shMonad** | **OPEN #2** — never in the README; $7.27M; only surface-scanned. |
| **Kipseli** | **OPEN #3** — never in the README; $694k Base unverified reserve contract. |
| **TOPS / LVIN** | **OPEN #4/#5** — never in the README; ~$92k/$91k NEM-class, gates unresolved. |
| **Metropolis DLMM VaultFactory** | **OPEN #6** — never in the README; vault-side auth unread. |

## Full disposition table

The complete per-lane table (all 209 rows, with the lane's verdict and the prior-source citation) is in **`analysis/ALL-ROWS.md`**. Per-lane summaries:

- **affluent.md** — 3 rows: Affluent (README-FINDING/FP), pool sub-instances + strategy vaults (NOT-A-PROTOCOL).
- **bmx-deli.md** (+ verify-bmx-mellow A) — 4 rows: BMX Deli + frozen Voter (README-CLOSED), abandoned deploy + BMX Freestyle (NOT-A-PROTOCOL).
- **contest-gap.md** — 28 rows: 7 README-CLOSED contest Highs, Burve (README-FINDING), **Cabal LST (OPEN)**, Virtuals/Gamma/BattleChain/Liquid Ron/IQ AI/Thorwallet/Next Generation/Garden-Brix-Covenant-Upside-BitVault (LANE-CLOSED), RAAC/Zaros/Curve/Notional/Malda/Ammplify/Dango (README-CLOSED), infra/private-contest/Immunefi/Cantina (NOT-A-PROTOCOL).
- **gap-chains.md** — 21 rows: Burve/Kuru/Infrared (README-FINDING), **shMonad + Metropolis (OPEN)**, D2 Finance (README-CLOSED), Kinetiq/Hyperbeat/Yuzu (PRIOR-COVERED), Sonic Market/Sturdy/Reservoir/Silo/BoringVault-family + negatives (LANE-CLOSED / PRIOR-PARTIAL).
- **hacklab-patterns.md** — 20 rows: AtomicQueue + Reservoir enabler (README-FINDING + PRIOR-COVERED), 12 prior-covered pattern instances, 5 lane-closed empties, the AtomicQueue fork template (PRIOR-COVERED), the 15-pattern map (NOT-A-PROTOCOL).
- **incidents.md** — 17 rows: Slice + NEM + BiFi (README), MORPHO/Drift/Aztec (NOT-A-PROTOCOL), Argent/AlpsCon/UNCX/EtherVista/Qubic/Cysic/Kolan/THEO/Atomic Green (PRIOR-COVERED), Lagoon + SafeTransfer (LANE-LEAD/CLOSED), patterns A–F (NOT-A-PROTOCOL).
- **mellow.md** (+ verify-bmx-mellow B) — 3 rows: all README-CLOSED / LANE-CLOSED.
- **microcap.md** — 34 rows: Affluent/RouterDrain/Umia/Slice (README), **Kipseli (OPEN)**, TIPMine (PRIOR-COVERED), 13 watchlist leads (mostly PRIOR-COVERED; Vectis/LiquidLoans/Pay Protocol/Trevee → LANE-LEAD), and the negatives (LANE-CLOSED / NOT-A-PROTOCOL / PRIOR-COVERED).
- **off-llama.md** — 16 rows: USDSM/Startale USD/MokuVaultV2 (README-CLOSED), Morpho VaultV2 World (LANE-CLOSED), tokens/treasury/screener-artifacts (NOT-A-PROTOCOL), Firelight (PRIOR-COVERED), Unlink (LANE-LEAD).
- **recall.md** — 3 rows: README-CLOSED + testnet-only (NOT-A-PROTOCOL).
- **skim-burn.md** — 16 rows: BTCΞ/NS/DMD (README-FINDING), **TOPS/LVIN (OPEN)**, 8 fork-proven-gated pairs (LANE-CLOSED), drained pattern family (PRIOR-COVERED/LANE-CLOSED), cross-chain dust (LANE-CLOSED).
- **small-chain-scout.md** — 18 rows: Multicall3Router (README-FINDING), CIAN/MokuVaultV2 (README-CLOSED), 14 role-gated/self-scoped contracts (LANE-CLOSED), Flare un-covered (PRIOR-COVERED).
- **trusted-caller.md** — 9 rows: BigShot (README-FINDING), Slice (README-CLOSED), 7 closed/safe (LANE-CLOSED).
- **unverified-impl.md** — 8 rows: 22 funded unverified-impl proxies (README-CLOSED), medium-freq impls (NOT-A-PROTOCOL).
- **verify-fluid.md** — 3 rows: Fluid H-1 (README-CLOSED), stale vulnerable modules (LANE-CLOSED), Fluid V1 TVL (NOT-A-PROTOCOL context).

## Method

1. Read the pass4 README + all 16 lane files in full; extracted every named candidate from ranked tables **and** prose/negative/dead-end/watchlist sections.
2. Ran `zh4-check.sh` and targeted greps over the prior corpus — `ci/ZH4P5/P4/P3/P2/P1/ZH3/ZH2B*-RESULTS-TRACKER.md`, `ci/L2-*`, `ci/TIER3-LOW-TRACKER.md`, `ci/MONITOR-LIST.md`, `zombie_hunt/`, `zombie-deep/`, `zombie-hunt-iv/pass2|3|5/`, `wave1|2/`, and the root protocol folders (`ls -d */`). DefiLlama data dumps (`llama_*`, `lane_*.tsv`, `gov/*`) were **not** counted as coverage (they are data, not verdicts).
3. Dispositioned each: README-FINDING / README-CLOSED / LANE-CLOSED (line cited) / PRIOR-COVERED / PRIOR-PARTIAL / NOT-A-PROTOCOL / OPEN / LANE-LEAD.
4. For each OPEN: a quick live sanity check (contract exists? balance? already disproven?) via public RPCs + DefiLlama (child A) to rank.
5. No deep-dive. `analysis/childA-live.md` (live reads) and `analysis/childB-enum.md` (independent enumeration cross-check) hold the raw evidence.

## CI

- Run: see `ci-out/` and the URL printed by `ci/ci-run.sh`. The job (`ci/check.py`) re-parses `analysis/ALL-ROWS.md`, recomputes the disposition counts, compares them to `summary.json`, scans the folder for keyed-URL/secret patterns (expect 0), and re-reads the OPEN-list funds at public RPCs.
- Results: `ci-out/validation.json`, `ci-out/live_checks.json`.

## Caveats

- **OPEN is a triage label, not a proven bug.** Confidence/plausibility are explicit per row.
- Point-in-time reads **2026-10-23** (blocks: Monad 115,828,947 · Base 52,974,224 · Sonic 81,493,855 · World 36,701,092 · Mantle 102,303,744). Re-read balances/prices before acting.
- TOPS/LVIN addresses are **truncated in the source lane**; recover them in full before any work.
- Cabal is **non-EVM (Initia Move)** — no EVM RPC applies; the audit + DL TVL are the only current handles.
- The World Chain "Morpho VaultV2" resolves on-chain to **"AgentBank Deposit Vault" holding WLD** (~$235k) — the label may be wrong; treat as curator-gated either way.
- Nothing here is an instruction to transact; interacting with any listed contract may be illegal in the reader's jurisdiction.
