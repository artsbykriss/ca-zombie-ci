# Z3-H17 · Longbow (Robinhood Chain, chain id 4663) — Morpho market oracle / LLTV screen

**Date:** 2026-10-16 · **Chain:** Robinhood Chain (4663) · **Status:** read-only; PoC fork-verified only; no mainnet transactions
**Scope:** Morpho Blue singleton `0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010` (verified, standard Morpho) · all **55** Longbow-curated markets (ids from `analysis/cluster/dl-adapters/longbow.js`) · 54 distinct oracle contracts · 53 price feeds · the "Loopback" oracle `0xCDE9599059f8Ae6D6B9F33A0aF7877827ec75F16` (WSNET markets).
**Method:** full on-chain market/oracle/feed enumeration (keyless public RPC + Etherscan V2 chainid 4663), verified-source review (MorphoChainlinkOracleV2, LoopbackOracle, EACAggregatorProxy, DualAggregator), **heimdall decompilation** of the unverified pool feeds, and 7 fork tests against live state (Foundry).

---

## 1. TL;DR

| target | live extractable (unprivileged) | why closed / open | latent risk |
|---|---|---|---|
| **EACAggregatorProxy "DON" feeds** (RHNVDA/USD, USDG/USD, WETH/USD, …; 8 dp; backing aggregators `DualAggregator` owner `0xeE27D5Ae…`) — used by 37 markets incl. all equity majors | **$0** | no attacker-reachable update path; `latestRoundData()` fresh (0.1–9.5 h at read time); feeds are immutable (verified 27 KB proxy bundles) | operator/composition trust is off-chain (P); staleness is *never* checked (see below) |
| **"Uniswap V3 Pool Price in USD" feeds** (18 dp; one per meme/mid-cap market: PONS, AI, INDEX, STONKBROKER, WSNET(logic), NOTHING, GLD, NFLX, MRNA, RBLX, RIVN, HIMS, COST, DJT, TTWO, RDDT, CASHCAT) | **$0 material (best arithmetic EV ≈ +$0.5–0.7 k on STONKBROKER; likely negative after hold risk)** | **not spot readers**: decompiled = `observe([300,0])` **300-second Uniswap V3 TWAP** × `quoteChainlinkFeed` (WETH/USD DON). Fork-proven: dumping **40 % of the pool’s base token in one tx moves `slot0` by +54 % while the feed does not move a single basis point** (T2). Moving the TWAP needs the pool distorted for ≥5 min; round-trip pool fees (0.3–1 %/leg) plus the attacker’s collateral cost consume the entire extraction, which is hard-capped by each market’s idle loan liquidity (PONS $22.9 k on a $3.2 M-deep pool: fees alone ≈ $23.5 k → EV negative; STONKBROKER $996 idle: theoretical +$0.65 k before 5-min hold risk/gas) | if any such market grows (deeper idle USDG) **without** deepening its pool, the EV flips positive; re-run this screen per market on every listing/liquidity milestone |
| **LoopbackOracle** (WSNET `0xf47c…` and WSNET_NN `0xaa58…` markets; biggest live exposure: **$952 k supplied / $922 k borrowed**) | **$0 today** | verified formula **`price = clamp(0.9×TWAP, floor, 5×floor) × sNET.index × 1e6`**; fork-verified to the wei (T5). Downside: TWAP cannot push the price below `treasury.backingPerToken()` (floor); upside: capped at 5×floor; both inputs (treasury RFV, sNET rebase index) are non-manipulable by an outsider (no owner fns; mint/rebase are role-gated); a ≥15 % spot-vs-TWAP downside divergence **fails closed** (reverts) | fail-closed guard means a real NET crash can *freeze liquidations* for up to the 4 h TWAP band (liveness, not theft); floor/index drift is the systemic watch item |
| **Liquidation-MEV via oracle manipulation** (no. 1 live borrower: PONS `0x5526fDEb…`, $15.0 k debt vs $54.6 k collateral, LTV 27.5 %) | **$0** | needs a **−28.6 %** oracle crash held long enough to move the 300 s TWAP; required ~864 k PONS (~$289 k) dump into a $3.2 M-deep **1 %-fee** pool → round-trip fees ≈ $5–9 k ≈ gross liquidation bonus ($8–15 k); same-tx manipulation is impossible (T2/T7) | same scaling caveat as above |
| `maxLtv`/LLTV configs (0.385–0.86), `idToMarketParams` | **$0** | configs read live per market; no "unusually high LLTV × manipulable feed" pairing found: SGOV (LLTV 86 %) is on a DON feed and has $111 liquidity; every spot-family market has LLTV ≤ 38.5–62.5 % | SGOV LLTV 86 % is aggressive if its DON feed ever stalls |
| total system liquidity check | **$0** | singleton holds only **$52.6 k USDG**; total market supply ≈ **$1.09 M**, total borrows ≈ **$987 k**; idle (borrowable) liquidity ≈ **$115 k** (WSNET_NN $29.7 k, ETH $34.1 k, PONS $22.9 k, rest ≤ $6.6 k per market) — this caps *any* borrow-side attack even if an oracle were manipulable | — |

**Total live extractable now: $0.00 material** — confidence **high** for the mechanism/family classification (fork-proven same-tx resilience; verified Oracle math), **medium** that some low-value multi-market path nets < $1 k (arithmetic EV on STONKBROKER slightly positive before hold risk; not executed end-to-end).

## 2. The mechanism, in exact terms

1. **Morpho Blue singleton** — battle-tested code; the risk lives in market configs. All 55 markets were enumerated live: 53 use **USDG** (6 dp) as loan token, 2 use **WETH** (SPY_WETH, NVDA_WETH); collateral = tokenized equities (`RHNVDA`, `RHAAPL`, …), ETFs, commodities, memes; LLTVs 38.5 % / 62.5 % / 77 % (ETH) / 86 % (SGOV).
2. **`MorphoChainlinkOracleV2`** (standard Morpho oracle, verified): `price = SCALE_FACTOR × baseFeed1 × baseFeed2 / (quoteFeed1 × quoteFeed2)`; `ChainlinkDataFeedLib.getPrice` reads `latestRoundData()` and only checks `answer ≥ 0` — **no staleness check** (Morpho’s documented assumption: "the Chainlink feed keeps its promises"). Consequence: freshness is 100 % delegated to the feeds.
3. **Feed families (verified/decompiled):**
   - **EACAggregatorProxy** (53 feeds; 8 dp): scoring style proxies over **`DualAggregator`** contracts (e.g. `RHNVDA / USD`, `USDG / USD`, owner `0xeE27D5Ae…`). Fresh updates observed (0.1–12.3 h). WETH/USD `0x78F3556b…` also used as the quote leg of pool feeds.
   - **"Uniswap V3 Pool Price in USD"** (16 feeds, 18 dp, unverified 5.2 KB, decompiled with heimdall): immutables `pool`, `baseToken`, `quoteToken` (WETH), `quoteChainlinkFeed` (= WETH/USD proxy), `decimals = 18`; `latestRoundData()` statically calls the pool’s `observe(uint32[])` (`0x883bdbfd`) with a 300-second window and converts via the quote feed — a **5-minute TWAP**, not a spot read.
   - **`LoopbackOracle`** (WSNET/WSNET_NN, verified): a purpose-built floor/cap TWAP oracle (`src/lending/LoopbackOracle.sol`), quoted at 1e36 per Morpho convention.

## 3. Live-state assessment (2026-10-16; fork blocks 89.79 M `eth_blockNumber` space / 26,202,6xx header space)

- **Morpho singleton** `0x9D53d5E3…`: USDG balance **$52,553.18**; RHNVDA balance **7,146.52** (≈$1.557 M at the $217.85 feed price).
- **Markets with liquidity** (supply / borrow, USD): WSNET_NN 952,185.41 / 922,443.35 · ETH 52,873.31 / 18,811.63 · PONS 51,104.51 / 28,247.72 · SPY 11,128.07 / 6,327.71 · NVDA 6,603.77 / 100.26 · TSLA 6,559.63 / 12.44 · AI 6,100.54 / 178.15 · INDEX 1,816.81 / 1,730.56 · WSNET 1,602.12 / 130.37 · STONKBROKER 996.22 / 0 · NOTHING 226.83 / 123.87 · USAR/CRWV/NBIS ~125 each · SGOV 110.98 · plus ~25 seeded markets at ≤ $110. **Total supply ≈ $1.09 M; borrows ≈ $987 k.**
- **Top positions:** PONS `0x5526fDEb…` 163,051.41 PONS collateral / $15.0 k debt (LTV 27.5 %; −28.6 % needed to liquidate) · PONS `0x668f37ed…` 240,160.8 / $10.0 k (LTV 12.5 %) · NVDA collateral `0x46386178…` etc. — 7,146 RHNVDA vs $100 debt.
- **Loopback market reads:** `price()` 7.479e26 ($747.9/wsNET) = clamp(0.9×187.77, 162.77, 813.84)×4,424,337,177/1e9×1e6 — exact (T5). TWAP window params 1,800–14,400 s; treasury RFV $25.2 M (liquid $7.71 M + Morpho $17.82 M), backing $162.77/NET, index 4.424×.
- **Pool depths (manipulation cost driver):** PONS/WETH 667.4 WETH + 4.72 M PONS ($1.6 M/side, fee 1 %) · AI/WETH 110.1 WETH (fee 1 %) · INDEX/WETH 48.5 WETH (fee 1 %) · STONKBROKER/WETH 8.0 WETH (fee 0.3 %) · GLD/USDG 0 USDG + 29.76 GLD (degenerate, market idle $111).
- **Feed freshness sample:** DON equity feeds 0.1–9.5 h old; **USDG/USD (the quote leg of 49 markets) was 12.3 h old at read** — benign for a peg, but shows the heartbeat is loose.

## 4. What an attacker can / cannot do (exact paths)

Can (all fork-proven, none profitable):

- Swap a huge amount inside a pool feed market in one transaction and watch the oracle (`test_T2`): `slot0` moved 5.246e31 → 8.076e31 (+54 %), **feed delta 0 bp** — the 300 s TWAP cannot be moved in the same block. (`observe([300,0])` is answerable — T3.)
- Repay/flash and borrow against the same collateral base — the borrow is priced by the **unchanged** TWAP, so no undercollateralized borrow (T2/T3).
- Attempt liquidation of the top PONS borrower only after a ≥ 28.6 % TWAP crash, which requires holding ~864 k PONS (~$289 k) distorted for ≥ 5 min in a 1 %-fee pool (T7) — fees ≈ bonus.

Cannot:

- Move any DON-backed feed (all equity majors, USDG): no update path exists for outsiders; the aggregators are operator-driven (P-class trust).
- Move the Loopback price below its floor or above 5× floor (clamped; fork-verified against live values), or push the floor (treasury RFV is not donation-manipulable: POL RFV = 2√(xy) only rises if *someone donates* liquidity — which raises the *borrower-safe* floor, not the attacker's profit) or the index (rebase is role-gated).
- Profit from the same-transaction "flash manipulation" class that drains spot-oracle lending markets.

## 5. PoC / fork verification

- `poc/test/Longbow.t.sol` — contract `LongbowH17Test`; forks live Robinhood Chain via keyless public RPCs (`rpc.mainnet.chain.robinhood.com`, publicnode, drpc; env override `RHO_RPC`). `ForkHelper.sol` is not compilable as vendored (parent-owned; solc 9097) — same inline-fork pattern as the Fang/HertzFlow children.
- Local run: **7/7 PASS** (`forge test --match-path 'test/Longbow.t.sol' --skip 'src/ForkHelper.sol'`), fork block 89,790,429 `eth_blockNumber` space.
- Key numbers: T2 slot0 +54 % vs feed delta **0 bp**; T4 EV: PONS idle $22,856 vs fees $23,451 → EV **$0**; STONKBROKER idle $996 vs coll cost $258 + fees $248 → arithmetic EV **$654** (before 5-min hold risk/gas → immaterial); T5 Loopback reconstruction exact; T6 NVDA collateral 7,146.52 behind an 8 dp aggregator proxy; T7 required dump 863.8 k PONS with pool depth 667.4 WETH.

## 6. Verdict and residual risk

- **E-U (external unprivileged, live): $0.00 — high confidence** for anything material. The two feed families that could be attacker-influenced are (a) 300 s TWAPs whose manipulation costs exceed every market’s idle liquidity and (b) a floor/cap TWAP oracle whose clamp makes directional gain impossible; all major positions sit behind operator-driven Chainlink-proxy feeds.
- **E-U-conditional (scaling trigger):** any Longbow market whose **idle loan liquidity** exceeds the manipulation cost of its collateral pool. Quantified monitors: for each "Uniswap V3 Pool Price in USD" market compute `EV = idle − idle/(LLTV×F) − 2×fee×notional(F)`; alert if positive at a feasible F (the STONKBROKER arithmetic was +$654 at F=10 — a 3× size increase would make it >$1 k and, with a 0.3 % pool, still cheap). Second monitor: **feed heartbeat** — a stale DON feed (no `updatedAt` bound enforced anywhere in Morpho or the oracle wrappers) lets borrowers/liquidators act on old prices; watch the USDG/USD and equity feet for > 24 h gaps.
- **H-O:** ~$1.09 M supplied (self-service via Morpho). **P:** feed operators (`0xeE27D5Ae…` DualAggregator owner), treasury role-gated minters/spenders, herd of curators; DON trust is the systemic reliance. **S:** none material (dead GLD/USDG pool is inert).
- **Blockers/caveats:** the pool-feed contracts are unverified — mechanism established by heimdall decompilation + live structural reads (immutables, `observe` semantics), not source; TWAP mis-measurement on sparse observations (if a pool lacks observations near 300 s, `observe` can revert → feed fails, blocking borrows/liquidations rather than mispricing); concentrated-liquidity depth was approximated by reserve-side notional for the EV math (documented; direction of the inequality is robust); the DL adapter's $3.25 M TVL includes ~$1.56 M RHNVDA collateral + ~$1.09 M supply — the *borrowable* half is what attacks can reach.

## 7. Methodology & sources

Read-only: live `eth_call` enumeration of all 55 `idToMarketParams`/`market`/`position`, 54 oracle configs, 53 feeds (round data, decimals, aggregator), pool depths and fee tiers; verified sources from Etherscan V2 (chain 4663): Morpho singleton, `MorphoChainlinkOracleV2`, `LoopbackOracle` (+constants/interfaces), `EACAggregatorProxy`, `DualAggregator`; heimdall-rs decompilation of the unverified pool feed (selector map: `pool() 0x16f0115b`, `quoteToken() 0x217a4b70`, `quoteChainlinkFeed() 0x9414d92b`, `baseToken() 0xc55dae63`, `observe(uint32[]) 0x883bdbfd`, window constant `0x012c` = 300 s); 7 fork tests. No transactions sent; no keyed URLs stored.

**Files:** `README.md` · `summary.json` · `market_params.json`, `oracle_configs.json`, `feed_state.json`, `market_states.json`, `markets.json`, `market_params_raw.json`, `MorphoChainlinkOracleV2_impl.sol`, `loopback_*.sol`, `oracle_src_*.json`, `feed_src_*.json`, `src_*.json`, `stk_feed.bin` · `poc/test/Longbow.t.sol`.
