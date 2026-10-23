# ZH4-PASS5 — RESIDUAL RECONCILIATION (`pass5-recon`)

**Campaign:** 2026-10-23 · **Mode:** READ-ONLY triage (no transactions signed/sent; keyless public RPCs) · **Owner:** ZH4-PASS5 reconciliation subagent
**Mission:** the 20 `zombie-hunt-iv/pass5/*.md` lanes name far more protocols than `zombie-hunt-iv/pass5/README.md` lists. Give **every named candidate across every lane a disposition**, and produce the **OPEN list** (funded + plausible unprivileged path + no verdict anywhere). Triage only — no deep dives, no fork PoCs.

**Deliverables:** this file · `analysis/dispositions.json` (188 machine-readable rows) · `summary.json` · `ci/run.sh` + `ci-out/recon-sanity.json` · CI URL below.

---

## 1. TL;DR

| Metric | Value |
|---|---|
| Lanes read | **20** (+ `pass5/README.md`) |
| Named candidates enumerated | **188** disposition rows (plus grouped families: 83 paymasters, 78 non-EVM screens, ~50 v4 hooks) |
| **README-FINDING** (assigned in pass5) | **15** distinct (9 HIGH + 6 LOW) |
| **README-CLOSED** | **7** distinct (Baseline, Set V3, Kai, RNT, Evro, Maker keepers + the selector sweep) |
| **LANE-CLOSED** (lane itself disproved/closed) | **90** rows |
| **PRIOR-COVERED** (our trackers / pass1-4 / wave1-2) | **30** rows |
| **NOT-A-PROTOCOL** (metric/class/key/supply-chain/synthetic) | **15** rows |
| **OPEN** | **23 rows → 22 distinct** = **5 OPEN-A** (concrete path) + **15 OPEN-B** (unread/unresolved) + 2 dupes |
| New CRITICAL proven by this triage | **0** — honest. This is a reconciliation, not a hunt. |

**Headline:** the README's "verified closed ~20 clusters" is accurate for everything it names, but the lane files contain **~22 funded candidates with no verdict anywhere** — most are *unread/unresolved* (OPEN-B), and **5 carry a concrete, if unproven, unprivileged path** (OPEN-A). The single largest is **Saturn Protocol's sUSDat v2 ($48.1M, live, unaudited v2 surface)**.

---

## 2. Disposition legend

| Code | Meaning |
|---|---|
| **README-FINDING** | assigned in the pass5 README (P5-01…09 / LOW 1–6) |
| **README-CLOSED** | closed by a pass5 verification lane *and* listed in the README closed table |
| **LANE-CLOSED** | the lane itself disproved/closed it (patched, gated, dead, drained, dust, or "not the shape") |
| **PRIOR-COVERED** | closed in `ci/*TRACKER*.md` or the pass1–4 / wave1–2 corpus |
| **NOT-A-PROTOCOL** | metric/address/class/hypothesis row; key/supply-chain/infra; or synthetic teaching repo |
| **OPEN** | funded (≥~$1k) **+** plausible unprivileged path **+** no verdict anywhere |

---

## 3. The OPEN list (ranked by funds × plausibility)

### 3a. OPEN-A — concrete unprivileged path named, no verdict anywhere (5)

| # | Target | Chain | Live funds | Path (why it is not closed) | Blocker / next check | Conf |
|---|---|---|---|---|---|---|
| **A1** | **Saturn Protocol — sUSDat v2** | Ethereum | **$48.13M** (live `totalAssets`; DefiLlama `saturn` $157.5M) | Proxy `0xD166337499E176bbC38a1FBd113Ab144e5bd2Df7` → **new v2 impl `0x2b7074cf6681382b70e239063931ebe83c0f4e0a`** (the v1 `0x2005e0ca…` + `toleranceBps()` are gone). The disclosed v1 bug is superseded, and the **v2 surface (`buy`/`sell`/`migrate`/`migrationToleranceBps`/`strcMirrorModule`/redemption batches) has no verdict anywhere**. | Read v2 impl source + trace `buy`/`sell`/`migrate` and redemption-batch accounting against live state; check the `strcMirrorModule` price path. | low |
| **A2** | **Abracadabra — PurrSwap Balancer Aggregator** | **Hyperliquid** (lane said Berachain — corrected) | not isolated (Abracadabra general TVL $4.81M) | Guardian 2025-03-29: **C-06 "No validation for oracles used in pools" (CRIT, Acknowledged)** + **C-07 "Wrong initial target updates" (CRIT, Acknowledged)**; `Factory`/`Router` accept a deployer-supplied oracle with no validation. | Isolate the live PurrSwap `Factory`/`Router` on Hyperliquid; confirm C-06/C-07 present; note the harm is to **opt-in LPs of a maliciously-created pool** (permissionless pool creation is *by design*, M-03 ack) — **not** a drain of existing funds. | low |
| **A3** | **Unverified delta-returning v4 hooks (3)** | Ethereum, Base | **$1.55M + $1.03M + $0.39M ≈ $2.97M** | ETH `0xfAaad5B731F52cDc9746F2414c823eca9B06E844` (codesize 14,553, aSD); ETH `0xd33398d46cB5749c7319AE1FABC498CdeB0F0FC0` (codesize 176 = **EIP-1967 proxy → impl `0x521553991534f26b9aea7d3ac6d798ade0508fc0`**); Base `0xC90eddF51569270E06270eA98F7EfFF828dDe0CC` (codesize 10,154, bSD+aSD). **Return-delta power + no verified source and no decompile** — a sign/currency bug in the delta is invisible to the lane's source read. | Decompile the 3 impls (heimdall) and diff delta sign/currency handling; fork-sim one swap per live pool. | low |
| **A4** | **Stake DAO — Curator / Morpho-collateral vault** | Ethereum | **$1.008M** (DefiLlama `stake-dao-curator`, confirmed live) | Pashov 2025-07-21 **C-02 "checkpoints almost always outdated due to missing `_update` override" (CRITICAL, Acknowledged)** — `StrategyWrapper` used as Morpho collateral without `_update` → stale checkpoints → liquidator cannot redeem LP; post-liquidation reward claims. (Prior-corpus StakeDAO hit is the *vsdCRV OFT key compromise* — a different component.) | Locate live `StrategyWrapper`/Curator vault, diff vs audited commit; test reward-claim / liquidation for an unprivileged extractor. | low-med |
| **A5** | **MUX Protocol — Pool (signed `makerFee`)** | Arbitrum | **$8.69M** (DefiLlama `mux-protocol`; Pool `0x45de6f4Ddc91B4353e9e0fF5d714bd1F8C113851`, codesize 22,282, live) | `int256 makerFee` / `setLPStableProfit(int256)` — all **setters** are role-gated (source-proven), but the **trade-time application of the signed `makerFee` into the position/order manager (separate, partly-unverified impls) was never traced**; a mis-signed fee could credit a trader. | Trace signed `makerFee` from `Pool` into `PositionManager`/`OrderManager` at trade time; fork-sim a trade if the fee store is reachable. | low-med |

### 3b. OPEN-B — funded but unread/unresolved (15)

| Target | Lane | Chain | Live funds | Why OPEN (no verdict) |
|---|---|---|---|---|
| **Twyne** | new-protocols | Ethereum | $11.2M | credit-delegation on Euler/Aave, 2 audits, growth-only; **not deep-read** |
| **Exponent** | non-evm | Solana | $27.1M | yield tranching, 2 audits; **instruction-level auth not completed** (RPC 429) |
| **Sushi Stellar** | non-evm | Stellar | $15.1M | Soroban UniV2-style AMM; **not reviewed** |
| **Loopscale Curation** | new-protocols | Solana | $7.49M | curator vaults; **withdrawal auth unseen** |
| **Reflect Tranches** | non-evm | Solana | $2.73M | custom RLP+proxy, **0 audits**; role/permission system unanalyzed |
| **3F Labs (grunt)** | advisories-git | EVM | $42.9M | recent #231 "repay bound" fix; **live core not pinned** |
| **DIEM Relay** | advisories-git | Base | $584k | live vault deposit-only; **audited sDIEM/csDIEM set not diffed** |
| **Crossbow / Arrowfarm** | new-protocols | Robinhood Chain | $770k | fresh CL/LM vaults; **vault sources not read** |
| **Prosper Alpha** | new-protocols | Pharos | $505k | launchpad `externalPair` + timelock; adapter-only read |
| **Choice Exchange V1** | new-protocols/non-evm | Injective | $287k | Terraswap-fork CosmWasm; **not read** |
| **Monetrix mxBTC** | new-protocols | HyperEVM | $265k | `BtcAccountant` net-equity; **unread** |
| **ArcX.trade** | non-evm | Starknet | $220k | Cairo vault registry; **not reviewed** |
| **Umbra Privacy V2** | non-evm | Solana | $250k | shielded-pool PDAs; **not reviewed** |
| **GnoSwap** | new-protocols | Gno.land | $318k | fresh CL AMM; **non-EVM, not read** |
| **Paladin — Valkyrie** | contest-audit-gap | unlocated | $0 | Cyfrin High Acknowledged (recursive-liquidity reward drain); **deployment not located** (resolve before funding) |

> OPEN-B is deliberately broad: these are *unread/unresolved*, not confirmed bugs. Rank the top 4–6 (Twyne, Exponent, Sushi Stellar, Loopscale, 3F, DIEM) if agent budget is limited.

---

## 4. Full disposition table (188 rows — grouped where a lane is a uniform family)

Legend in §2. `$` = live funds as stated by the lane (point-in-time 2026-10-22; not re-valued except where noted). Machine-readable: `analysis/dispositions.json`.

### 4.1 `advisories-git.md` (14)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| Ledgity Yield v2 vaults | Base/ETH/Arb/Linea | $2.27M | MED pre-fix / LOW E-U | **README-FINDING** (P5-09) |
| anchor-lang 1.0.0/1.0.1 programs | Solana | 0 | LOW (HIGH class, no victim) | **README-FINDING** (P5-08) |
| CometBFT / cosmos-sdk | Cosmos | 0 | LOW (base-layer) | NOT-A-PROTOCOL |
| ENS DNSSEC oracle | ETH | 0 | CLOSED (patched 2026-03-09) | LANE-CLOSED |
| Firelight | Flare | $67.4M | CLOSED (==HEAD) | PRIOR-COVERED (wave2/v7) |
| Enhanced Finance | ETH | $151k | CLOSED (==HEAD) | LANE-CLOSED |
| Paimon | BSC | $14.1M | CLOSED (fixes present) | LANE-CLOSED |
| Curvance | Monad | $131.8M | CLOSED (~HEAD) | PRIOR-COVERED |
| tiny-secp256k1 consumers | off-chain | 0 | LOW (not on-chain) | NOT-A-PROTOCOL |
| `@openzeppelin Bytes.lastIndexOf` | EVM | 0 | LOW (no caller) | NOT-A-PROTOCOL |
| DIEM Relay | Base | $584k | dead end / follow-up | **OPEN-B** |
| 3F Labs (grunt) | EVM | $42.9M | hardening; core unpinned | **OPEN-B** |
| iAero / PerpBond | Base | 0 | drop | NOT-A-PROTOCOL |
| Sera/Flex/Ripe/Monolith/Twyne/Paimon-dex | EVM | 0 | hardening, not drain recipes | LANE-CLOSED |

### 4.2 `contest-audit-gap.md` (20)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| Baseline (Mercury) | ETH/Base/HyperEVM | $1.34M | HIGH (path+funds) | **README-CLOSED** (baseline.md) |
| Abracadabra — PurrSwap | Hyperliquid | not isolated | MED | **OPEN-A2** |
| Ostium | Arbitrum | $2.09M | MED (superseded impl) | PRIOR-COVERED (row 60 + key compromise) |
| Paladin — Valkyrie | unlocated | 0 | LOW-MED | **OPEN-B** |
| Stake DAO — Curator | ETH | $1.008M | LOW-MED | **OPEN-A4** |
| Suzaku — Balancer Validator | Avax | 0 | LOW (DoS) | LANE-CLOSED |
| Securitize — Solana Bridge v2.1 | EVM→Solana | 0 | LOW (edge) | LANE-CLOSED |
| Remora — Dynamic Tokens | EVM | 0 | LOW (ack) | PRIOR-COVERED (pass4) |
| Bunni v2.1 — FloodPlain | EVM | 0 | CLOSED (product dead) | LANE-CLOSED |
| Bounce | ? | 0 | LOW (DoS) | LANE-CLOSED |
| Bigcoin | ? | 0 | LOW (DoS) | LANE-CLOSED |
| Bracket / BracketFi | ? | 0 | LOW | LANE-CLOSED |
| Baseline — Fixed Supply | ETH | 0 | LOW (DoS) | LANE-CLOSED |
| Flare — Enosys | Flare | 0 | CLOSED | PRIOR-COVERED |
| Infura — DIN AVS | EigenLayer | 0 | CLOSED (privileged) | PRIOR-COVERED |
| Apriori — LockedAprMON | Monad | 0 | CLOSED | LANE-CLOSED |
| Liquity V2 — Governance | ETH | 0 | CLOSED | LANE-CLOSED |
| 0x Settler / Enso CCIP / EF EIPs | multi | 0 | CLOSED | LANE-CLOSED |
| CodeHawks First Flight #52-59 | n/a | 0 | NOT REAL | NOT-A-PROTOCOL |
| CodeHawks 2026-07 BattleChain | BattleChain | 0 | CLOSED | NOT-A-PROTOCOL |

### 4.3 `v4-hooks.md` (56 hooks; 23 disposition rows)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| AGLHook | ETH | $1.43M | unproven (must-not-deploy live) | **README-FINDING** (P5-02) |
| Spot (2 deployments) | Unichain | $4.22M | unproven; ceiling | **README-FINDING** (P5-03) |
| StablePair/VolatilePair (3) | ETH/Arb | $11.71M | unproven; upgrade-key P | **README-FINDING** (P5-04) |
| eth `0xfAaad5B7` (unverified, aSD) | ETH | $1.55M | blind spot | **OPEN-A3** |
| eth `0xd33398d4` proxy | ETH | $1.03M | blind spot | **OPEN-A3** |
| base `0xC90eddF5` (unverified) | Base | $0.39M | blind spot | **OPEN-A3** |
| VirtualLBPStrategyBasic / FullRangeLBP | ETH | $14.5M | $0 E-U (bI only) | LANE-CLOSED |
| Clanker family (×4) | Base | $7.7M | no flaw found | LANE-CLOSED |
| Doppler/Multicurve (×3) | Base | $11.2M | no flaw found | LANE-CLOSED |
| Angstrom | ETH | $5.4M | EXCLUDED (corpus) | PRIOR-COVERED |
| ArrakisPrivateHook | Base/ETH | $2.81M | $0 E-U (no delta) | LANE-CLOSED |
| V4AlphaHook | Base | $2.47M | $0 E-U (no delta) | LANE-CLOSED |
| Zora hooks (×2) | Base | $0.86M | $0 E-U (aI+aS) | LANE-CLOSED |
| LaunchHook (B20) | Base | $0.48M | no flaw found | LANE-CLOSED |
| StockTokenHook | Base | $0.25M | $0 E-U (gated) | LANE-CLOSED |
| VerifiedPoolsBasicHook | Base | $0.68M | $0 E-U (whitelist) | LANE-CLOSED |
| LpGuardHook | Base | $0.80M | $0 E-U (bI only) | LANE-CLOSED |
| V4PermissionedSwaps | BSC | $1.22M | $0 E-U (permissioned) | LANE-CLOSED |
| UniswapV4KEMHook | Arb/Base/ETH | $1.30M | $0 E-U (quote-signer) | LANE-CLOSED |
| UnicredHook + sub-$100k delta hooks | Unichain/OP/… | ~$0.13M | watchlist / dust | LANE-CLOSED |
| Soneium/BNB/Polygon unverified non-delta | Soneium/BSC/Polygon | ~$5M | $0 E-U | LANE-CLOSED |
| UniswapV4Router04 (periphery) | ETH | $5 | live/unpatched, $5 residual | **README-FINDING** (LOW 6) |
| SatoHook/WIN/GULD/GPO/Fables/Kolan/GoldPesa/SpiralCom/Cork | multi | 0 | corpus-closed | PRIOR-COVERED |

### 4.4 `community-leads.md` (15)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| Set Protocol legacy `RebalancingSetTokenV3` | ETH | $118k→$155k | HIGH (lane) → CLOSED | **README-CLOSED** (set-v3.md) |
| MakerDAO legacy keeper class | ETH | $542k taken | MEDIUM → CLOSED | **README-CLOSED** (maker-keepers.md) |
| Evro Finance | Gnosis | $4k | MEDIUM → CLOSED | **README-CLOSED** (evro.md) |
| ERC-4337 paymaster drain class | multi | 0 | LOW (class) | LANE-CLOSED |
| Argent-style smart wallet (unnamed) | ? | 0 | LOW | LANE-CLOSED |
| X7 Finance X7Pioneer | ETH | $16.5k taken | LOW | PRIOR-COVERED (monitor) |
| BitBay `UsdcDaiV4Vault` class | Polygon | $14.8k taken | LOW (template) | PRIOR-COVERED (monitor) |
| Locus Finance v2 | Arbitrum | ~0 | LOW (template) | LANE-CLOSED |
| Chainflip AMM (Tron memo) | Tron | $736k taken | LOW (closed) | LANE-CLOSED |
| Cosmos EVM under-patched chains | Cosmos EVM | 0 | EXCLUDED | PRIOR-COVERED |
| Slice FundsModule | Base | 0 | EXCLUDED | PRIOR-COVERED (pass4) |
| AlpsCon AI Trade Hub | BSC | 0 | EXCLUDED | PRIOR-COVERED (pass4) |
| Papertrade | HyperEVM | 0 | EXCLUDED | PRIOR-COVERED |
| Affluent | TON | 0 | EXCLUDED | PRIOR-COVERED (pass4, false positive) |
| GoldPesa/EtherVista/UNCX V2 | Base/ETH/multi | 0 | EXCLUDED | PRIOR-COVERED |

### 4.5 `new-protocols.md` (36 ≥$250k + 8 growth; 18 rows named)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| RNT Lend (Reental) | Polygon | $0.91M | LOW-MED → CLOSED | **README-CLOSED** (rnt-lend.md) |
| Lucid Labs AssetController | 6 chains | $272k | LOW | LANE-CLOSED |
| Cardboard Trade | Solana | $1.08M | LOW | **README-FINDING** (LOW 2) |
| Shift DeFi | ETH | $1.24M | LOW | LANE-CLOSED |
| Hive Protocol | BSquared | $237.5M (artifact) | NEG | NOT-A-PROTOCOL |
| Hyperliquid Earn | HyperCore | — | LOW (out of scope) | LANE-CLOSED |
| Nonce Capital | ETH/OP | — | LOW (curator) | LANE-CLOSED |
| INFER (imdUSD) | ETH | $400k | NEG (token clean) | LANE-CLOSED |
| Twyne | ETH | $11.2M | LOW (not deep-read) | **OPEN-B** |
| Crossbow / Arrowfarm | Robinhood Chain | $770k | LOW (unread) | **OPEN-B** |
| Faiyah Staking | Xphere | $4.78M | NEG (covered) | PRIOR-COVERED (wave2 v13) |
| Loopscale Curation | Solana | $7.49M | LOW (unread) | **OPEN-B** |
| Prosper Alpha | Pharos | $505k | LOW (unread) | **OPEN-B** |
| Choice Exchange V1 | Injective | $287k | LOW | **OPEN-B** |
| GnoSwap | Gno.land | $318k | LOW | **OPEN-B** |
| Monetrix mxBTC | HyperEVM | $265k | LOW (unread) | **OPEN-B** |
| Forward Industries / Definity SOL | Solana | $320.8M | LOW (unread) | LANE-CLOSED (standard SPL pools) |
| CommunityV3/USD8/Aero + 5 growth (Bucket V2/KTON/SUN.io/Permapod/DiversiFi) | multi | 0 | negatives / pre-covered / unlocated | LANE-CLOSED |

> **Coverage gap:** the lane located contracts for only **~20 of the 36** fresh ≥$250k protocols and 3 of 8 growth rows; the ~19 unnamed fresh protocols were never located (recorded as a gap, not a finding).

### 4.6 `non-evm.md` (78 screened / 4 deep-dives; 19 rows named)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| R25 | Sui | $187.6M | LOW (residual) | LANE-CLOSED |
| Stellar DeFi Hub / Evergreen | Stellar | $95.1M | CLOSED | LANE-CLOSED |
| Exponent | Solana | $27.1M | LOW (unresolved) | **OPEN-B** |
| Pacifica | Solana | 1.44M SOL | MED-HIGH (no E-U) | LANE-CLOSED |
| Haedal Lending Vault | Sui | $6.36M | defect HIGH / exploit LOW | LANE-CLOSED |
| Hermetica hBTC | Stacks | $3.81M | CLOSED | LANE-CLOSED |
| Reflect Tranches | Solana | $2.73M | LOW (unresolved) | **OPEN-B** |
| Cardboard Trade | Solana | $1.08M | LOW-MED | **README-FINDING** (LOW 2) |
| WaterX | Sui | $0.46M | LOW | LANE-CLOSED |
| BitSafe CBTC | BTC/Canton | $3.31M | LOW (off-chain custody) | LANE-CLOSED |
| Circle Bitcoin | Bitcoin | $32M | LOW | LANE-CLOSED |
| Surge Credit | BTC+Base | $1.47M | LOW (indexer) | LANE-CLOSED |
| ArcX.trade | Starknet | $0.22M | LOW | **OPEN-B** |
| Umbra Privacy V2 | Solana | $0.25M | LOW | **OPEN-B** |
| Definity/Raiku/Japan/Forward SOL | Solana | $320.8M | LOW (SPL pools) | LANE-CLOSED |
| Sushi Stellar | Stellar | $15.1M | LOW | **OPEN-B** |
| XOXNO / Extended Spot / Gami Labs | Stellar/Starknet/multi | API-derived | LOW | LANE-CLOSED |
| Upshift / August / Gami Ember | Solana/Sui/Stellar | $375M agg | LOW | LANE-CLOSED |
| 78 fresh non-EVM screens (unnamed remainder) | non-evm | — | 0 E-U proven | LANE-CLOSED (grouped) |

### 4.7 `paymasters-intents.md` (83 paymasters; 11 rows + census)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| Sodium smart-account impl | Arbitrum | $0 (re-arm) | HIGH bug / $0 | **README-FINDING** (P5-01) |
| CoW GPv2Settlement | ETH | $4.9k | LOW (template) | **README-FINDING** (LOW 4) |
| UniswapX V2DutchOrderReactor | ETH | 0 | NEG (false positive) | LANE-CLOSED |
| Coinbase VerifyingPaymaster | Base | 79.05 ETH | clean | LANE-CLOSED |
| Circle SponsorPaymaster / TokenPaymasterV08 | Polygon/Avax/… | ~$87k | clean | LANE-CLOSED |
| Pimlico SingletonPaymaster V6/V7/V8 | 15 chains | — | clean | LANE-CLOSED |
| Notus / ShieldedV6 / OpnVote / sample + 9 probed admin paths | multi | — | clean | LANE-CLOSED |
| NEAR Intents / HOT Bridge | BSC | drained | closed (patched) | LANE-CLOSED |
| Across SpokePool | ETH/OP/Base/Polygon | — | closed (patched) | LANE-CLOSED |
| Across Solana event spoofing | Solana | — | closed (off-chain) | LANE-CLOSED |
| 66 remaining paymasters (83 census) | 18 chains | — | clean | LANE-CLOSED (grouped) |

### 4.8 `shape-sweep.md` (~5,700 tokens / 14k sources; 17 rows)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| AlpsCon V9 | BSC | $8.5k resident | HIGH gate / $0 E-U | **README-FINDING** (P5-06) |
| WAX bridge `eth.token` | WAX | $4,337 EVM-side | HIGH (correction) / $0 | LANE-CLOSED (patched) |
| ether.fi / Veda AtomicQueue | ETH | 0 | HIGH (live) / $0 | PRIOR-COVERED (ZH1 C-07) |
| Nucleus AtomicQueueUCP | ETH | 0 | PATCHED | LANE-CLOSED |
| Kirobo SafeTransfer | ETH | 0.796 ETH | HIGH gate / $0 | LANE-CLOSED |
| AHv2Farmer | Avax | 0 | LOW | LANE-CLOSED |
| WooFi RewardBooster | Arbitrum | 0 | LOW | LANE-CLOSED |
| Polygon FarmNFT | Polygon | 2.66 POL | LOW | LANE-CLOSED |
| 7× partialBurn ERC-20s / PartialBurnVotingFacet | ETH/Polygon | 0 | LOW (not shape) | LANE-CLOSED |
| Symbiosis BridgeV2 | BSC/ETH/RSK | $336k taken | CLOSED | LANE-CLOSED |
| 0xMT PoolHelper | Arbitrum | 0 | MED proven / $0 | LANE-CLOSED |
| MUX Pool | Arbitrum | $8.69M | LOW (gated) | **OPEN-A5** |
| Predy V2 PredyPool | Arbitrum | $12.3k | LOW (unresolved) | **README-FINDING** (LOW 1) |
| Circle CCTP V2 / Across V3 / Snowbridge / StarkGate / GMX / xERC20 / zkBob | multi | — | SAFE | LANE-CLOSED |
| Alien-Worlds teleporteos | WAX | — | SAFE | LANE-CLOSED |
| Celo T1 family | Celo | — | HIGH (gated) | LANE-CLOSED |
| changerio / Grateful / rabbitholegg | multi | — | HIGH (negative) | LANE-CLOSED |

### 4.9 `selector-scan.md` (3,957 contracts / 19,862 selectors; 8 rows + families)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| Benqi `QiErc20Delegate.sweepToken` | Avax | $1.08M at-risk | HIGH-neg ($0 to caller) | LANE-CLOSED |
| `0xd64ef141` sweepProtocolFees | ETH | $80k | HIGH-neg (fork) | LANE-CLOSED |
| `0xb203e117` TUP.upgradeTo | ETH | $105M | HIGH-neg (fork) | LANE-CLOSED |
| `0xef4fb24a` withdrawUnclaimedAffiliateFees | Arbitrum | $500k | HIGH-neg (fork) | LANE-CLOSED |
| `0x724c1cb` withdrawToAllowed | ETH | $7.9M | HIGH-neg (view) | LANE-CLOSED |
| `0x5e023c31` DVF withdrawVmFunds | Avax | $1.47M | HIGH-neg | LANE-CLOSED |
| Lido/EtherDelta/WalletSimple/skim/collectProtocol/emergencyWithdraw/withdrawAll/initialize families (~250 contracts) | multi | 0 to caller | HIGH-neg families | LANE-CLOSED |
| **3,957-contract / 19,862-selector sweep** | multi | 0 | 0 funded drain-shapes | **README-CLOSED** |

### 4.10 `negative-fee.md` (12 rows)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| 0xMT PoolHelper | Arbitrum | 0 | LOW (latent) | LANE-CLOSED |
| MUX Protocol Pool | Arbitrum | $8.69M | MED (gate) | **OPEN-A5** |
| Buffer-style TradePair | Arbitrum | 0 | HIGH (gate) | LANE-CLOSED |
| Predy V2 PredyPool | Arbitrum | $12.3k | LOW (unresolved) | **README-FINDING** (LOW 1) |
| Vela Exchange | Arbitrum | 0 | LOW (dead) | LANE-CLOSED |
| Vertex Endpoint | Arbitrum | $49 | HIGH (dead) | LANE-CLOSED |
| Verus Bridge | ETH | $190 | HIGH (drained) | LANE-CLOSED |
| Adshares wADS | ETH | 0 | HIGH (drained) | LANE-CLOSED |
| DeBridgeGate / RSK BridgeV3 / Union zkgm | multi | — | GATED/SAFE | LANE-CLOSED |
| CCIToken burn / shop transferToSeller | multi | dust | LOW | LANE-CLOSED |

### 4.11 `cross-chain.md` (8 rows)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| BiFi Lending | BSC/Avax/Kaia | $97k BSC | HIGH state / MED timing (paused) | **README-FINDING** (P5-05) |
| Ramses CL-gauge family (Pharaoh/Nile/Nuri/Cleopatra) | Avax/Linea/Scroll/Mantle | $7.0k | HIGH (carry-over) | PRIOR-COVERED (pass3) |
| Balancer V2 ComposableStablePool | multi | ~$0 | MED / $0 | PRIOR-COVERED |
| Mellow Core | multi | 0 | CLOSED | PRIOR-COVERED (pass4) |
| Centrifuge V3 | multi | 0 | CLOSED | PRIOR-COVERED (pass4) |
| Peapods Finance | ETH | 0 | CLOSED | PRIOR-COVERED (pass4) |
| Fluid DEX v2 MM | ETH | 0 | CLOSED | PRIOR-COVERED (pass4) |
| SimpleAccount / Guardian factory | Arbitrum | 0 | HIGH bug / $0 | PRIOR-COVERED (pass3) |

### 4.12 `incidents.md` (16 rows + Atomic Green + patterns)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| Slice | Base | $41k taken | PATCHED+PAUSED | PRIOR-COVERED (pass4) |
| Institutional MORPHO | ETH | $2.3M taken | key/delegation | NOT-A-PROTOCOL |
| NEM / NemTokenV2 | BSC | $1.79k residual | UNPATCHED, tiny | **README-FINDING** (LOW 3) |
| WAX Multi-Chain Bridge | WAX | $1.5k residual | PATCHED | LANE-CLOSED |
| Fearless Wallet extension | Polkadot | $20k | supply-chain | NOT-A-PROTOCOL |
| Swell swETH/rswETH | ETH | ~2,513 ETH at risk | key/upgrade-queue (not E-U) | **README-FINDING** (LOW 5, context) |
| Railway → crypto apps | off-chain | $370k | infra/key | NOT-A-PROTOCOL |
| Multi-wallet drain campaign | ETH/Arb/Solana | ≥6 wallets | key compromise | NOT-A-PROTOCOL |
| Cysic bridge / Pirate Chain | multi | — | prior incident | PRIOR-COVERED |
| Zipcoin / CoinDCX / PHP / LiteLLM / eMudhra TLS | multi | — | closure/CEX/infra/supply-chain | NOT-A-PROTOCOL |
| Drift / Aztec exploiters | ETH | — | laundering | NOT-A-PROTOCOL |
| Atomic Green / AtomicLending | Arbitrum | $105k TVL | HIGH (replay) / MED profit | PRIOR-COVERED (pass3) |
| Patterns A–K | multi | — | hypotheses | NOT-A-PROTOCOL |

### 4.13 `private-disclosures.md` (8 rows + 4 corrections)
| Candidate | Chain | $ | Lane verdict | Disposition |
|---|---|---|---|---|
| 1inch V6 clear-signing descriptors | ETH+12 | user-risk | UNFIXED (needs victim sig) | **README-FINDING** (P5-07) |
| Kai Finance | Sui | $0.896M | LOW-MED → CLOSED | **README-CLOSED** (kai-finance.md) |
| Nethermind CPIMP / Decurity Web2.5 / MoveBit Sui / ToB v4 / SigIntZero / ChainSecurity MPT | multi | — | class-level | NOT-A-PROTOCOL |
| **Saturn Protocol / sUSDat v2** | ETH | **$48.13M** | correction: v2 unaudited | **OPEN-A1** |
| GoonFi | Solana | $5.49M | patched (correction) | PRIOR-COVERED (ZH3) |
| StakeDAO vsdCRV OFT / Ostium | ETH/Arb | — | prior-corpus corrections | PRIOR-COVERED |

### 4.14 Verification lanes (6)
| Candidate | Lane | Disposition |
|---|---|---|
| Baseline (Mercury) — $1.34M | baseline.md | **README-CLOSED** ($0, 6 recipes fork-disproven) |
| Set Protocol V3 — $155k | set-v3.md | **README-CLOSED** (~$0.15 theoretical) |
| Kai Finance — $0.896M | kai-finance.md | **README-CLOSED** ($0, both Criticals non-exploitable) |
| RNT Lend — $0.91M | rnt-lend.md | **README-CLOSED** ($0, 2FA+whitelist gate holds) |
| Evro Finance — $4k | evro.md | **README-CLOSED** ($0, vulnerable build did not ship) |
| Maker keeper family — $0 | maker-keepers.md | **README-CLOSED** ($0, all 6 drained) |

---

## 5. Live sanity checks (this pass, read-only)

Block: ETH **26,253,597** · Arb **517,459,432** · Base **52,974,175**. Full JSON: `ci-out/recon-sanity.json`.

| Target | Check | Result |
|---|---|---|
| Saturn sUSDat proxy `0xD166…Df7` | EIP-1967 impl slot | `0x…2b7074cf6681382b70e239063931ebe83c0f4e0a` (v2) |
| Saturn sUSDat | `totalAssets()` | `48129487909424` (6-dp USDat) = **$48.13M** — **live, large** |
| eth `0xfAaad5B7` | codesize | **14,553** (live contract) |
| eth `0xd33398d4` | codesize / impl slot | **176** (proxy) → impl `0x521553991534f26b9aea7d3ac6d798ade0508fc0` |
| base `0xC90eddF5` | codesize | **10,154** (live contract) |
| MUX Pool `0x45de…3851` | codesize / native | 22,282 / 0 (tokens held, not native) |
| Stake DAO Curator | DefiLlama | $1,007,815 Ethereum — **live** |
| MUX Protocol | DefiLlama | Arbitrum $8,694,601 — **live** |
| Saturn Protocol | DefiLlama | Ethereum $157.5M — **live** |

**Not disproven on-chain:** every OPEN-A target is live and funded as claimed. The lane's *verdicts* (unproven paths) stand; nothing here changes a verdict — it only ranks the residual.

---

## 6. Method, counts, caveats

**Method.** (1) Read `pass5/README.md` + all 20 lanes; extracted every named candidate (table rows *and* prose leads). (2) Diffed against `ci/ZH4P5-RESULTS-TRACKER.md`, `ci/ZH4P4/3/2-RESULTS-TRACKER.md`, `ci/MONITOR-LIST.md`, `zombie-hunt-iv/EXCLUSIONS.md`, `pass4/contest-gap.md` and `zh4-check.sh` to assign PRIOR-COVERED. (3) Classified LANE-CLOSED from the lane's own explicit verdict. (4) For each OPEN, ran a light live sanity check (contract exists? balance? already disproven?).

**Counts (disposition rows, `analysis/dispositions.json`).** 188 rows: README-FINDING **17 rows → 15 distinct**; README-CLOSED **13 rows → 7 distinct**; LANE-CLOSED **90**; PRIOR-COVERED **30**; NOT-A-PROTOCOL **15**; OPEN **23 rows → 22 distinct** (5 OPEN-A + 15 OPEN-B; MUX listed in two lanes). Plus grouped families not row-expanded: 83 paymasters, 78 non-EVM screens, ~50 v4 hooks, ~250 selector families.

**Caveats.**
- **Triage, not verification.** No fork PoC was run; every OPEN-A/B verdict is the lane's own "unproven/unread" status. Ranking is funds × plausibility, not a proof.
- **PurrSwap chain correction:** Guardian's report lists **Hyperliquid**, not Berachain; the "$4.81M" is Abracadabra's general TVL, not PurrSwap pool funds. C-06/C-07 harm **opt-in LPs of a maliciously-created pool** (permissionless creation is by design), so this is weaker than a drain of existing funds.
- **Grouped families** (83 paymasters, 78 non-EVM, sub-$100k hooks, selector families) are dispositioned as a block; individual unnamed members were not re-located.
- **Coverage gaps noted, not converted to findings:** ~19 of 36 fresh ≥$250k protocols unlocated; 5 of 8 growth rows unlocated; Cardboard Trade program id unresolved; Paladin Valkyrie deployment unlocated.
- Point-in-time 2026-10-23; re-read all live state before acting. Nothing here is an instruction to transact.

**CI:** `pass5-recon` job — see `ci-log.txt` and the run URL recorded after dispatch (`ci/run.sh` performs the §5 read-only checks).

---

*Prepared 2026-10-23 · ZH4 pass-5 residual reconciliation · read-only · evidence: `analysis/dispositions.json`, `ci-out/recon-sanity.json`.*
