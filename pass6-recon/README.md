# ZH4-PASS6 — RESIDUAL RECONCILIATION (pass6-recon)

**Date:** 2026-10-24 · **Mode:** READ-ONLY (no tx signed/sent; `eth_call`/`eth_getBalance`/explorer reads only) · **Deliverable:** this file + `summary.json` + `analysis/` + `ci-out/`
**Mandate (principal):** give **every named candidate across every pass6 lane a disposition** and produce the **OPEN list** (funded + plausible unprivileged path + no verdict anywhere). Do not deep-dive; for each OPEN a quick live sanity check.

---

## 0. TL;DR

pass6 named **177 protocol-level candidates** across its 20 lanes (the board rows 6–19, every lane table row and prose lead, and the lane-level aggregates). Each is dispositioned below. **Nothing was left without a disposition.**

| Disposition | n |
|---|---|
| README-FINDING (pass6 README headline/board) | **1** |
| README-CLOSED (pass6 README §5) | **30** |
| LANE-CLOSED (closed inside its lane) | **49** |
| PRIOR-COVERED (closed by an earlier pass) | **34** |
| PRIOR-PARTIAL (same protocol, different angle) | **2** |
| NOT-A-PROTOCOL (off-chain / key / CEX / chain / non-EVM) | **21** |
| ASSIGNED (handled by another pass6 agent) | **18** |
| PARKED (funded but unlocated / trigger-only) | **1** |
| **OPEN** | **21** |

**Bottom line.** External-unprivileged extractable **today = $0** (unchanged from pass6's honest 0-new-CRITICAL result). The residual value is in **21 OPEN** candidates — funded surfaces whose lane flagged an *unread / unverified / untested* path and that **no pass has closed**. Two of them were **materially under-measured by their own lane** (the lanes checked only native balances / probed selectors):

- **ETH `0x278d858f…` whitelist-router family** — holds **≈$399k in tokens** on Ethereum alone (73,386.89 USDT + 87,134.14 USDC + **102.279 WETH**), not the "$0.0006 ETH dust" the lane reported. Lane family claim: $6.9M / 12 chains.
- **BSC `0x6aba0315…` proxy** — holds **≈$3.28M on BSC** (741,702.22 USDT + 3,476.04 BNB) at 155.9M txs. Lane family claim: $8.63M / 5 chains.

Neither is proven exploitable (both revert for a stranger; the router's whitelist check works). They rank top of the OPEN list on funds×plausibility.

**Status line:** read-only; no mainnet transactions; no secrets in this folder.

---

## 1. Method

1. **Extract every named candidate** from `pass6/README.md` + all 20 lane files (`zombie-hunt-iv/pass6/*.md`) — table rows *and* prose. → 177 rows (`analysis/rows.json`, full table in `analysis/DISPOSITIONS.md`).
2. **Disposition** each against the prior-coverage sources: our trackers `ci/ZH4P5 → ZH4P4 → ZH4P3 → ZH4P2 → ZH4 → ZH3 → ZH2B*`, `ci/L2-*`, `ci/TIER3-LOW-TRACKER.md`, `ci/MONITOR-LIST.md`, the kept/verified root folders (`ls -d */`, incl. `residual-recon/`), `bash zombie-hunt-iv/zh4-check.sh "<name>"`, and the pass1–5 README closed lists. Same protocol / different angle → **PRIOR-PARTIAL**.
3. **Known pass6 items already handled** are not re-listed as OPEN: Robinhood oracle, Ascend, INFER, JPY DeFi, The Moats, Exceed, Kolan ×14 hooks, BSC V4-hook bank (all **ASSIGNED**); Sodium/AGLHook/Spot/StablePair/BiFi (**closed by us**); Cardboard/Monetrix/Kestrel/Tessera/Secured-Finance/BPool/Swaap/Pacifica/StonkBrokers/VETRO/Arcus/Popdex/HoodLock/JUSD/Fake-World/CommunityV3/Bebop/Aero (**README-CLOSED**); NEM (pass4), UniswapV4Router04 (kept dust).
4. **For each OPEN, a live sanity check** (exists? balance? already disproven?) at public RPCs — see §3 and `ci-out/live_checks.json`.

---

## 2. FULL DISPOSITION TABLE (177 named candidates)

Full table: `analysis/DISPOSITIONS.md` (same rows, same order). Reproduced here:

| # | Lane | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|---|
| 1 | next-hack | Cardboard Trade (perp DEX) | Solana | $1.08M | row1 / P6 CLOSED | **README-CLOSED** | pass6 README §5; cardboard.md |
| 2 | next-hack | Monetrix (USDM/mxHYPE/mxBTC) | HyperEVM 999 | ~$4.9M | row2 / P6 CLOSED | **README-CLOSED** | pass6 README §5; monetrix.md |
| 3 | next-hack | INFER / imdUSD | Ethereum | <=$340k | row3 LOW-MED | **ASSIGNED** | ZH4P6 tracker (infer-imdusd/) |
| 4 | next-hack | Robinhood-Chain Morpho x tokenized equities | Robinhood 4663 | $3.4M+ | row4 / P6-01 PROVEN-armed | **ASSIGNED** | ZH4P6 tracker (robinhood-oracle/) |
| 5 | next-hack | Arcus pTokens (17) | Robinhood 4663 | ~$720k | row5 MED | **README-CLOSED** | pass6 README §5; arcus-ptokens.md (dup Z3-H12) |
| 6 | next-hack | VETRO | Ethereum | ~$906k | row6 LOW-MED | **README-CLOSED** | pass6 README §5; vetro.md |
| 7 | next-hack | StonkBrokers | Robinhood 4663 | $1.16M | row7 LOW-MED | **README-CLOSED** | pass6 README §5; stonkbrokers.md |
| 8 | next-hack | Pacifica Bridge | Solana | $24.16M (artifact) | row8 LOW-MED | **README-CLOSED** | pass6 README §5; pacifica-bridge.md |
| 9 | next-hack | Ascend | 0G 16661 | ~$3.4M | row9 / P6-02 | **ASSIGNED** | ZH4P6 tracker (ascend-0g/) |
| 10 | next-hack | URM Fortress | Base | $69k CDP | row10 LOW | **PARKED** | next-hack.md row10; no address published |
| 11 | next-hack | JPY DeFi (Liquity-v2 fork) | Ethereum | $840k | row11 LOW-MED | **ASSIGNED** | ZH4P6 tracker (jpy-defi/); PRIOR-PARTIAL = JPYdf closed ZH4 |
| 12 | next-hack | The Moats | Avax/RH/Monad/BSC/Base | $1.4M | row12 LOW | **ASSIGNED** | ZH4P6 tracker (moats/) |
| 13 | next-hack | Exceed Finance (exUSDC/exSOL/exBTC) | Solana | $704k | row13 LOW | **ASSIGNED** | ZH4P6 tracker (exceed-finance/) |
| 14 | next-hack | JUSD Finance | Ethereum+Arbitrum | $25.0M | row14 P | **README-CLOSED** | pass6 README §5 |
| 15 | next-hack | Fake World Assets V2 | Ethereum | ~$1.57M | row15 no-path | **README-CLOSED** | pass6 README §5 |
| 16 | next-hack | CommunityV3 | Ethereum | $6.3M | row16 no-path | **README-CLOSED** | pass6 README §5 |
| 17 | next-hack | Bebop bopAMM | Ethereum | ~$0 | row17 no-path | **README-CLOSED** | pass6 README §5 |
| 18 | next-hack | Aero Basic / Aero Slipstream | Base+6 | $48M/$79M | row18 not-a-fork | **README-CLOSED** | pass6 README §5 (Dromos merger) |
| 19 | next-hack | Choice Exchange V1 | Injective | $283k | row19 privileged | **NOT-A-PROTOCOL** | next-hack.md §5 (CosmWasm, multisig admin) |
| 20 | next-hack | Nova Perps | ? | $208k | Gains 1:1 fork | **LANE-CLOSED** | next-hack.md §5 (Safe+timelocks) |
| 21 | next-hack | Hyperliquid Earn | HyperCore | $1.43B | native primitive | **NOT-A-PROTOCOL** | next-hack.md §5 |
| 22 | next-hack | Strat Perps | Initia Move | - | non-EVM, 2x Zellic | **NOT-A-PROTOCOL** | next-hack.md §5 |
| 23 | next-hack | Solana fresh-LST cluster (Forward/Definity/Raiku/Japan) | Solana | $254-350M | privileged manager | **README-CLOSED** | pass6 README §5 |
| 24 | next-hack | HoodLock | - | - | no E-U | **README-CLOSED** | pass6 README §5 |
| 25 | next-hack | Popdex Bridge | Arbitrum | $73.3M | ZH4-internal repeat | **PRIOR-COVERED** | v14-popdex.md |
| 26 | next-hack | STRATO Bridge | - | $16.19M | H2-05 closed | **PRIOR-COVERED** | H2-05 |
| 27 | next-hack | Lucid Labs | - | - | pass5 closed | **PRIOR-COVERED** | pass5 |
| 28 | next-hack | SundaeSwap V4 | Cardano | - | not verifiable | **LANE-CLOSED** | next-hack.md §5 |
| 29 | next-hack | xALPH | Alephium | - | no external path | **LANE-CLOSED** | next-hack.md §5 |
| 30 | next-hack | Robinhood tail (Ouro/Raphael/Goo/Titan/Arrowfarm/Crossbow/Abyss) | Robinhood 4663 | $84-444k | UniV2/V3 forks | **LANE-CLOSED** | next-hack.md §5 |
| 31 | next-hack | Prosper Alpha | - | - | kept on board, no lead | **LANE-CLOSED** | next-hack.md §5 |
| 32 | next-hack | Forest Road Vault | Ethereum | - | role/KYC gated | **LANE-CLOSED** | next-hack.md §5 |
| 33 | next-hack | NEMO Trading | - | - | ifSenderWhitelisted | **LANE-CLOSED** | next-hack.md §5 |
| 34 | next-hack | Hub Capital / Odyssey Digital AM / DeTrade | - | - | Lagoon curator-gated | **LANE-CLOSED** | next-hack.md §5 |
| 35 | next-hack | Ditto Earn | Ethereum | $45.88 | dust | **LANE-CLOSED** | next-hack.md §5 |
| 36 | next-hack | Excluded repeats (FermiSwap/Kipseli/HertzFlow/LevrBet/Kamui/Longbow/Phase/GoonFi/Scorch/BisonFi/TONCO/Reflect/BDEX/Waterline/Architect/LibertySwap/MetricV1/RNTLend/Faiyah/Papertrade/JustLend sTRX) | multi | - | zh4-check EXCLUDE | **PRIOR-COVERED** | next-hack.md §5 (24 names) |
| 37 | next-hack | Carry-over monitors (Radworks/HAI/CL-gauge/Startale/Shibarium WBONE/Affluent/Burve/Kuru/Infrared) | multi | - | monitor | **PRIOR-COVERED** | next-hack.md §6; MONITOR-LIST.md |
| 38 | arcus-ptokens | Arcus pToken factory + 17 BeaconProxy vaults | Robinhood 4663 | $693,796 | CLOSED E-U $0 | **README-CLOSED** | arcus-ptokens.md (dup Z3-H12) |
| 39 | base-bsc-fresh | Wager Predict (SpotEngine/Vault/USDW) | BSC | $173.7k | MED lead; no cheap drain; USDW impl unread | **OPEN** | base-bsc-fresh.md row1 |
| 40 | base-bsc-fresh | Tapir Protocol (DepegPool/AMM) | Base | $55k | MED unread | **OPEN** | base-bsc-fresh.md row2 |
| 41 | base-bsc-fresh | Prodigy.Fi V2 (PositionManager, unverified impl) | Base | $68.9k DL | MED opaque core | **OPEN** | base-bsc-fresh.md row3 |
| 42 | base-bsc-fresh | Nullmask (ZK privacy pool) | Base(+BSC) | 12.50 ETH ~$28.9k | MED unread; prior PARKED | **OPEN** | base-bsc-fresh.md row4; residual-recon PARKED |
| 43 | base-bsc-fresh | Primus Confidential Vault (FHE) | BSC | reported >$1M / backend $38.6M | MED-HIGH address-thin | **OPEN** | base-bsc-fresh.md row5 (addresses unresolved) |
| 44 | base-bsc-fresh | Doppler Finance XDP Staking | Base | $560k staked | NEG inert (0 reward periods) | **LANE-CLOSED** | base-bsc-fresh.md row6 (monitor first addRewardPeriod) |
| 45 | base-bsc-fresh | ArexAIStaking | BSC | 115M ARXAI ($0 realizable) | LOW no drain | **LANE-CLOSED** | base-bsc-fresh.md row7 |
| 46 | base-bsc-fresh | StakedVault + CooldownSilo | Base | $0 | NEG | **LANE-CLOSED** | base-bsc-fresh.md row7 |
| 47 | base-bsc-fresh | PhoenixCo | BSC | ~$3k | LOW | **LANE-CLOSED** | base-bsc-fresh.md row8 |
| 48 | base-bsc-fresh | Berry Finance / Berry Juicer | Base | small | LOW unverified EIP-1167 | **LANE-CLOSED** | base-bsc-fresh.md row9 |
| 49 | base-bsc-fresh | BASE STREET presale | Base | ~$25k | NEG treasury EOA | **NOT-A-PROTOCOL** | base-bsc-fresh.md row10 |
| 50 | base-bsc-fresh | Based Eggman | Base | $0 | NEG | **NOT-A-PROTOCOL** | base-bsc-fresh.md row11 |
| 51 | base-bsc-fresh | ZiG / ZAOIN | Base | $0 | NEG honeypot/1155 | **NOT-A-PROTOCOL** | base-bsc-fresh.md row12 |
| 52 | base-bsc-fresh | Today's fresh-verified Base/BSC (50) | Base+BSC | 0 native | NEG | **LANE-CLOSED** | base-bsc-fresh.md row13 |
| 53 | base-bsc-fresh | Fresh DEX tokens (212) | Base+BSC | 0 native | NEG | **LANE-CLOSED** | base-bsc-fresh.md row14 |
| 54 | base-bsc-fresh | AXIS Robotics | Base | $2.47M pool | no custody contract yet | **LANE-CLOSED** | base-bsc-fresh.md negatives |
| 55 | base-bsc-fresh | Concrete (CT) | BSC | - | out-of-lane | **PRIOR-COVERED** | base-bsc-fresh.md negatives |
| 56 | base-bsc-fresh | Nesa | BSC | - | prior-covered | **PRIOR-COVERED** | base-bsc-fresh.md negatives |
| 57 | base-bsc-fresh | Paimon/pPOLY | BSC | - | prior-covered pass5 | **PRIOR-COVERED** | base-bsc-fresh.md negatives |
| 58 | base-bsc-fresh | Fake-liquidity cluster (USDB/ATC/GALABET/etc) | Base+BSC | artifact | NEG | **NOT-A-PROTOCOL** | base-bsc-fresh.md negatives |
| 59 | base-bsc-fresh | CEX/MM wallets (0x28e2ea09/0x8a08d98c/0x6aba0315) | BSC | - | NEG exchange wallets | **NOT-A-PROTOCOL** | base-bsc-fresh.md negatives |
| 60 | base-bsc-fresh | 0xD189 vault | Base | $6M | prior-corpus, not E-U | **PRIOR-COVERED** | ZOMBIE-HUNT-II.md |
| 61 | base-bsc-fresh | UNCX/Slice/NEM/AlpsCon/Umia/RouterDrain | multi | - | corpus-closed | **PRIOR-COVERED** | base-bsc-fresh.md negatives |
| 62 | bpool-forks | Balancer V1 BPool fork census (6,538 pools / 9 chains) | multi | net $0 | CLOSED | **README-CLOSED** | pass6 README §5; bpool-forks.md |
| 63 | bpool-forks | Canonical OCEAN/USDC pool 0x9a16bddf | Ethereum | $135k | value token frozen | **LANE-CLOSED** | bpool-forks.md §3 |
| 64 | bpool-forks | Swaap Finance Pool 0x7f5f7411 | Polygon | $107k | different math, closed | **README-CLOSED** | swaap.md |
| 65 | bpool-forks | Base/Arb BCoWPool families | Base+Arb | - | functions removed | **LANE-CLOSED** | bpool-forks.md |
| 66 | cardboard | Cardboard Trade oracle/settle | Solana | $1.08M | CLOSED E-U $0 | **README-CLOSED** | cardboard.md |
| 67 | deployer-lineage | LauncherV2 proxy 0xe1795625 | Arbitrum | $125.7k | funded, NOT extractable | **LANE-CLOSED** | deployer-lineage.md #1 |
| 68 | deployer-lineage | CrowdRingCircle 6-token sell-destroy family | BSC | $0 | template, unfunded | **LANE-CLOSED** | deployer-lineage.md #2 |
| 69 | deployer-lineage | BitBay/StableVault ~25-vault family | Polygon | $0 | template, unfunded | **LANE-CLOSED** | deployer-lineage.md #3 |
| 70 | deployer-lineage | UNCX VestingManager lineage (75 contracts) | ETH/ARB/Poly | $4.18M nominal | no new sibling | **PRIOR-COVERED** | deployer-lineage.md #4; pass2 |
| 71 | deployer-lineage | KolanHook deployer lineage | Ethereum | $0 | no second hook | **ASSIGNED** | deployer-lineage.md #5 (kolan-hooks/) |
| 72 | deployer-lineage | GoldPesa GPXHooks | Base | $0 | drained | **PRIOR-COVERED** | ZH3-H5 monitor |
| 73 | deployer-lineage | ether.fi AtomicQueue | Ethereum | $0 | one instance; forks unresolved | **PRIOR-COVERED** | ZH1 C-07 / pass4 |
| 74 | deployer-lineage | FlashLoopAdapter + 30 same-deployer modules | Ethereum | $0 | possible self-attestation in siblings (unread) | **PRIOR-PARTIAL** | ZOMBIE-HUNT-II.md (closed) + sibling tail unread |
| 75 | deployer-lineage | MOKE / MokeRelease family | BSC | $0 | paused | **LANE-CLOSED** | deployer-lineage.md #9 |
| 76 | deployer-lineage | AlpsCon V6-V9 lineage | BSC | $8,333 | known, whitelist re-arm | **PRIOR-COVERED** | pass5 |
| 77 | deployer-lineage | EtherVista factory lineage | Ethereum | $0 | router-gated (privileged) | **PRIOR-COVERED** | pass2/3 |
| 78 | deployer-lineage | BiFi TokenHandler lineage (89) | Ethereum | dust | known, paused | **PRIOR-COVERED** | pass3/5 |
| 79 | deployer-lineage | Arrakis G-UNI lineage | Ethereum | $0 | - | **LANE-CLOSED** | deployer-lineage.md #13 |
| 80 | deployer-lineage | USM lineage | Ethereum | small | - | **LANE-CLOSED** | deployer-lineage.md #14 |
| 81 | deployer-lineage | Float Protocol lineage | Ethereum | $0 | - | **LANE-CLOSED** | deployer-lineage.md #15 |
| 82 | deployer-lineage | Balancer V1 BPool deployer | Ethereum | $0 | - | **README-CLOSED** | deployer-lineage.md #16 |
| 83 | deployer-lineage | MALT sLP | Polygon | $0 | - | **PRIOR-COVERED** | deployer-lineage.md #17 |
| 84 | deployer-lineage | BigShot | Optimism | $0 | pass4 | **PRIOR-COVERED** | pass4 |
| 85 | deployer-lineage | Allbridge CCTP | Base | $0 | - | **LANE-CLOSED** | deployer-lineage.md #19 |
| 86 | deployer-lineage | SandboxOFT | Base | $0 | - | **LANE-CLOSED** | deployer-lineage.md #20 |
| 87 | deployer-lineage | Perpetual Protocol v2 Curie OrderBooks | Optimism | $0 ($435k patched) | live bug, empty/patched | **LANE-CLOSED** | deployer-lineage.md #21; child C |
| 88 | deployer-lineage | Sodium smart-account lineage (479 contracts) | Arbitrum | $0 | no clone references impl | **PRIOR-COVERED** | carry-over (sodium/ kept) |
| 89 | fresh-deploy-sweep | Fresh-verified contracts (10,566 / 21 chains) | multi | 714 funded | 0 drains | **LANE-CLOSED** | fresh-deploy-sweep.md §0 |
| 90 | fresh-deploy-sweep | Funded fresh table rows 1-30 (Safes/UniV2V3/Pendle/ERC-4626/ApeChain dapps) | multi | $5.0M+ | all guarded-by-design | **LANE-CLOSED** | fresh-deploy-sweep.md §2 |
| 91 | fresh-deploy-sweep | P6-01 ChimeraQuoteHook404 (v4 hook + ERC-404 launchpad) | Ink | fees in per-pool vaults | LOW unproven | **OPEN** | fresh-deploy-sweep.md §3 |
| 92 | fresh-deploy-sweep | P6-02 BondingCurveManager | Ronin | 190 ERC-20s | LOW unproven | **OPEN** | fresh-deploy-sweep.md §3 |
| 93 | fresh-deploy-sweep | P6-03 Unichain ImmutableProxy family (~130 clones) | Unichain | ~$130k | LOW unproven (probe reverts) | **OPEN** | fresh-deploy-sweep.md §3 |
| 94 | fresh-deploy-sweep | zksync fresh-verified feed | zkSync | - | not covered (0 rows) | **LANE-CLOSED** | fresh-deploy-sweep.md §4 |
| 95 | incidents-siblings | WAX Multi-Chain Bridge | WAX | ~$1.5k residual | PATCHED | **LANE-CLOSED** | incidents-siblings.md #1 |
| 96 | incidents-siblings | Arkadiko (USDA CDP) | Stacks | TVL $138k | governance, non-EVM | **NOT-A-PROTOCOL** | incidents-siblings.md #2 |
| 97 | incidents-siblings | Swell (swETH/rswETH) | Ethereum | ~2,500 ETH exposure | key/upgrade | **NOT-A-PROTOCOL** | incidents-siblings.md #3 |
| 98 | incidents-siblings | Balancer V1 BPool (DPI) | Ethereum | $234k | immutable, forks $0 | **README-CLOSED** | incidents-siblings.md #4 |
| 99 | incidents-siblings | Cysic bridge | BSC | $744k moved | off-chain/halted | **NOT-A-PROTOCOL** | incidents-siblings.md #5 |
| 100 | incidents-siblings | CoinDCX | multi | $16M flagged | CEX cleanup | **NOT-A-PROTOCOL** | incidents-siblings.md #6 |
| 101 | incidents-siblings | Ngrave wallet | multi | $2.65M | phishing | **NOT-A-PROTOCOL** | incidents-siblings.md #7 |
| 102 | incidents-siblings | Drift exploiter laundering | Ethereum | $122.3M | not an exploit | **PRIOR-COVERED** | incidents-siblings.md #8 |
| 103 | incidents-siblings | PHP/LiteLLM/eMudhra | off-chain | - | infra | **NOT-A-PROTOCOL** | incidents-siblings.md #9 |
| 104 | incidents-siblings | UNCX VestingManager siblings (17/8 chains) | multi | dust; RH $658k locked | flatFee=uint256.max | **PRIOR-COVERED** | incidents-siblings.md §2 #1 |
| 105 | incidents-siblings | KolanHook + launchpad 14 hooks | Ethereum | $0 | code-identical, $0 | **ASSIGNED** | incidents-siblings.md §2 #2 |
| 106 | incidents-siblings | TIP/TIPMine | BSC | $0 | pool drained; clone uninitialized | **LANE-CLOSED** | incidents-siblings.md §2 #3 |
| 107 | incidents-siblings | NEM/NemTokenV2 | BSC | $1.79k | prior-covered | **PRIOR-COVERED** | incidents-siblings.md §2 #4 |
| 108 | incidents-siblings | CrowdRingCircle (CRC) | BSC | $0 | 0/301k pairs | **LANE-CLOSED** | incidents-siblings.md §2 #5 |
| 109 | incidents-siblings | MOKE | BSC | $0 | claim paused | **LANE-CLOSED** | incidents-siblings.md §2 #6 |
| 110 | incidents-siblings | Perpetual Protocol v2 | Optimism | $0 | empty/patched | **LANE-CLOSED** | incidents-siblings.md §2 #7 |
| 111 | incidents-siblings | AlpsCon V7/V8/V9 | Ethereum | $8,333 | V9 no code | **PRIOR-COVERED** | incidents-siblings.md §2 #9 |
| 112 | incidents-siblings | BiFi Lending | BSC/AVAX/Kaia | ~$97k BSC | paused | **PRIOR-COVERED** | carry-over closed by us |
| 113 | incidents-siblings | EtherVista | Ethereum | ~$291k WETH | router-gated | **PRIOR-COVERED** | incidents-siblings.md §2 #11 |
| 114 | incidents-siblings | Argent-style smart wallet | Ethereum | ~24-28 ETH nominal | $0 affordable payload | **PRIOR-COVERED** | incidents-siblings.md §2 #12 |
| 115 | incidents-siblings | Slice FundsModule | Base | $0 | patched/paused | **PRIOR-COVERED** | incidents-siblings.md §2 #13 |
| 116 | incidents-siblings | MORPHO EIP-7702 | Ethereum | $2.3M | key/delegation | **NOT-A-PROTOCOL** | incidents-siblings.md #16 |
| 117 | incidents-siblings | X7 Finance (X7Pioneer) | Ethereum | $52 | drained | **LANE-CLOSED** | incidents-siblings.md #18 |
| 118 | incidents-siblings | MALT (Malt Stablecoin) | Ethereum | 8,658 DAI | prior-corpus | **PRIOR-COVERED** | incidents-siblings.md #19 |
| 119 | incidents-siblings | Pirate Chain (ARRR) | Pirate L1 | 79.8M ARRR forged | chain consensus | **NOT-A-PROTOCOL** | incidents-siblings.md #20 |
| 120 | incidents-siblings | Qubic | - | ~$1.13M frozen | wallet-side | **NOT-A-PROTOCOL** | incidents-siblings.md #21 |
| 121 | incidents-siblings | Gamdom/Fearless/Ngrave/Ledger | - | - | key/supply-chain | **NOT-A-PROTOCOL** | incidents-siblings.md #23 |
| 122 | incidents-siblings | Affluent (TON) / Coffer (Solana) | TON/Solana | $1.05M / $0.70 | drained/dust | **PRIOR-COVERED** | incidents-siblings.md #24 |
| 123 | incidents-siblings | Secured Finance (ETH/FIL/ARB) | multi | $168.7k | CLOSED $0 (re-open refuted) | **README-CLOSED** | secured-finance.md |
| 124 | kestrel | Kestrel Long Yield Carry | Solana | $441.6k | CLOSED E-U $0 | **README-CLOSED** | kestrel.md |
| 125 | monetrix | Monetrix (USDM/mxHYPE/mxBTC) | HyperEVM 999 | ~$4.75M | CLOSED E-U $0 | **README-CLOSED** | monetrix.md |
| 126 | pacifica-bridge | Pacifica Bridge (PCFA + sol-bridge) | Solana | $24.33M (P-class) | CLOSED E-U $0 | **README-CLOSED** | pacifica-bridge.md |
| 127 | probed-protocols | BSC 0x16ceff8d V4-hook 'bank' (54.5 BNB) | BSC | 64.2 BNB + USDT | probed; no unguarded path | **ASSIGNED** | bsc-v4-hook-bank/ |
| 128 | probed-protocols | BSC 0x6aba0315 proxy ($8.63M / 155.9M txs) | BSC+4 | ~$3.28M BSC verified | reverts for stranger; unverified | **OPEN** | probed-protocols.md #2 |
| 129 | probed-protocols | ETH 0x278d858f + BSC 0xa9010523 whitelist-router family | ETH+BSC+12 | ~$400k ETH verified; $6.9M family | whitelist works; unverified/obfuscated | **OPEN** | probed-protocols.md #3 |
| 130 | probed-protocols | Uniswap Continuous Clearing Auction 0xa93807cd | Ethereum | 5.17 ETH | LOW | **LANE-CLOSED** | probed-protocols.md #4 |
| 131 | probed-protocols | Axiom Uniswap-V4 hook 0x9689992f | Ethereum | $0 | LOW | **LANE-CLOSED** | probed-protocols.md #5 |
| 132 | probed-protocols | Cross-chain swap 0x8ea5ad2a / 0x86d5db2a | Base+BSC | ~0.067 ETH | LOW | **LANE-CLOSED** | probed-protocols.md #6 |
| 133 | probed-protocols | Hatchlings mintFree | Ethereum | - | sold out, not E-U | **NOT-A-PROTOCOL** | probed-protocols.md #7 |
| 134 | probed-protocols | Packed-command contracts (0xae629bf1/0x29be31e7/0x56320386) | Base+BSC | spam tokens | LOW reverts | **LANE-CLOSED** | probed-protocols.md #8-10 |
| 135 | probed-protocols | getRich honeypot 0x913b87c7 | Base | - | LOW | **NOT-A-PROTOCOL** | probed-protocols.md #11 |
| 136 | probed-protocols | executeProgram proxy 0x774c69ab | Base | - | LOW | **LANE-CLOSED** | probed-protocols.md #12 |
| 137 | probed-protocols | EIP-2535 Diamond 0xb44446b0 | Ethereum | - | LOW | **LANE-CLOSED** | probed-protocols.md #13 |
| 138 | probed-protocols | OptimizedBatchClaimer 0xd6510531 | Ethereum | $0 | LOW | **LANE-CLOSED** | probed-protocols.md #14 |
| 139 | probed-protocols | Fresh-EOA one-offs (0x26ff4608/0xfdf682f5) | Base | - | LOW | **LANE-CLOSED** | probed-protocols.md #15 |
| 140 | probed-protocols | 169-ETH Base tag-dispatch contract 0x08fb3354 | Base | 169.39 ETH | prior-covered pass5 row15 | **PRIOR-COVERED** | probed-protocols.md #16 (monitor) |
| 141 | probed-protocols | OKX/Across/UniversalRouter/1inch/Seaport/UniswapV4Router04 | multi | dust | legit infra | **LANE-CLOSED** | probed-protocols.md negatives |
| 142 | probed-protocols | EIP-7702 delegation designators | Base+ETH | - | MEV bots | **PRIOR-COVERED** | ZH4 monitor |
| 143 | robinhood-oracle | Robinhood-Chain Morpho equity oracle staleness | Robinhood 4663 | $1.69M debt; $215.5k free | LOW, armed; mechanism proven | **README-FINDING** | pass6 P6-01; robinhood-oracle.md |
| 144 | robinhood-oracle | Robinhood mock oracle 0x20925300 unprotected setPrice | Robinhood 4663 | $0 | mock markets only | **LANE-CLOSED** | robinhood-oracle.md §7 |
| 145 | solana-fresh | Kestrel Long Yield Carry | Solana | $440k | CLOSED | **README-CLOSED** | kestrel.md |
| 146 | solana-fresh | Tessera V | Solana | $9.18M | LOW (router-proxy untested) | **README-CLOSED** | tessera.md |
| 147 | solana-fresh | AlphaQ prop-AMM | Solana | ~$1.0M | LOW; admin gated; swap unresolved | **OPEN** | solana-fresh.md #3 |
| 148 | solana-fresh | Exceed Finance | Solana | $704k | LOW-MED; update_pair_limits gated | **ASSIGNED** | exceed-finance/ |
| 149 | solana-fresh | DiversiFi index vaults | Solana | $745k | LOW; rebalance untested | **OPEN** | solana-fresh.md #5 |
| 150 | solana-fresh | Flipcash bonding-curve launchpad | Solana | $415k | LOW immutable | **PRIOR-PARTIAL** | residual-recon r4:53 (immutable+audited) |
| 151 | solana-fresh | Overpass wrapper factory | Solana | $141k | LOW unread | **OPEN** | solana-fresh.md #7 |
| 152 | solana-fresh | Zodial (marginfi fork) | Solana | $201k | LOW fork-drift | **OPEN** | solana-fresh.md #8 |
| 153 | solana-fresh | Umbra Privacy V2 | Solana | $252k | P5 OPEN-B tail | **PRIOR-COVERED** | solana-fresh.md #9 |
| 154 | solana-fresh | Sat Rush | Solana | $847k | LOW unlocated | **OPEN** | solana-fresh.md #10 |
| 155 | solana-fresh | Loyal Earn | Solana | $393k | LOW unlocated | **OPEN** | solana-fresh.md #11 |
| 156 | solana-fresh | TRUE DEX | Solana | $281k | LOW unlocated | **OPEN** | solana-fresh.md #12 |
| 157 | solana-fresh | Pascal | Solana | $2.24M | LOW unlocated | **OPEN** | solana-fresh.md #13 |
| 158 | solana-fresh | N1 Exchange Bridge | Solana | $1.37M | LOW unlocated | **OPEN** | solana-fresh.md #14 |
| 159 | solana-fresh | Byzanlink RWA Markets | Solana | $2.09M | LOW unlocated | **OPEN** | solana-fresh.md #15 |
| 160 | solana-fresh | Webot | Solana | $3.59M | CEX off-chain | **NOT-A-PROTOCOL** | solana-fresh.md #16 |
| 161 | solana-fresh | Definity/Raiku/Japan/Forward-Industries SOL | Solana | $293M | SPL stake pools | **README-CLOSED** | solana-fresh.md #17 |
| 162 | solana-fresh | Prior-corpus repeats (BisonFi/GoonFi/Aquifer/Phase/Scorch/Loopscale/Reflect/Pacifica/Exponent/Save/marginfi/Drift/DefiTuna/Jupiter Offerbook/Bordrless/DeepSwap) | Solana | - | excluded | **PRIOR-COVERED** | solana-fresh.md negatives |
| 163 | stonkbrokers | StonkBrokers lockers + TokenEscrowReserve | Robinhood 4663 | $1.01M + $7.07M reserve | CLOSED E-U $0 | **README-CLOSED** | stonkbrokers.md |
| 164 | swaap | Swaap Finance Pool 0x7f5f7411 | Polygon | $107k | CLOSED E-U $0 | **README-CLOSED** | swaap.md |
| 165 | swaap | Swaap Maker V2 (SafeguardPool) | multi (11) | $454k | out-of-scope flag, unread | **OPEN** | swaap.md §4 out-of-scope |
| 166 | tessera | Tessera V (Wintermute prop-AMM) | Solana | $8.5M | LOW; whitelist+operator gates | **README-CLOSED** | tessera.md |
| 167 | vetro | VETRO (VUSD/vetBTC) | Ethereum | $906k | CLOSED E-U $0 | **README-CLOSED** | vetro.md |
| 168 | vetro | VETRO VUSD LayerZero OFT lockbox | Ethereum | 230,820 VUSD | correctly configured; monitor | **LANE-CLOSED** | vetro.md §5.7 |
| 169 | assignments | Robinhood oracle (P6-01) | Robinhood 4663 | $0.3-1.5M | assigned | **ASSIGNED** | ZH4P6 tracker |
| 170 | assignments | Ascend (P6-02) | 0G | <=$3.4M | assigned | **ASSIGNED** | ZH4P6 tracker |
| 171 | assignments | INFER/imdUSD | Ethereum | <=$340k | assigned | **ASSIGNED** | ZH4P6 tracker |
| 172 | assignments | JPY DeFi | Ethereum | <=$840k | assigned | **ASSIGNED** | ZH4P6 tracker |
| 173 | assignments | The Moats | multi | <=$1.4M | assigned | **ASSIGNED** | ZH4P6 tracker |
| 174 | assignments | Exceed Finance | Solana | <=$704k | assigned | **ASSIGNED** | ZH4P6 tracker |
| 175 | assignments | Kolan launchpad x14 hooks | Ethereum | $0 re-arm | assigned | **ASSIGNED** | ZH4P6 tracker |
| 176 | assignments | BSC V4-hook bank (54.5 BNB) | BSC | 64.2 BNB | assigned | **ASSIGNED** | ZH4P6 tracker |
| 177 | assignments | Sodium/AGLHook/Spot/StablePair/BiFi (carry-overs) | multi | - | closed by us | **PRIOR-COVERED** | ZH4P6 tracker; pass5 |

---

## 3. THE OPEN LIST (ranked by funds × plausibility)

`OPEN` = funded + a plausible unprivileged path that no pass has closed. Plausibility is explicit; **none is a proven drain**. Live checks at public RPCs 2026-10-24 (`ci-out/live_checks.json`).

| # | Candidate | Chain | Live funds (verified now) | Lane's unclosed path | Plausibility | Next check |
|---|---|---|---|---|---|---|
| O1 | **ETH `0x278d858f…` + BSC `0xa9010523…` whitelist-router family** | ETH/BSC(+12) | **≈$399,327 ETH leg**: 73,386.89 USDT + 87,134.14 USDC + **102.279 WETH** + 0.000616 ETH; lane: $6.9M/12 chains | unverified/obfuscated multi-DEX router with `WHITELIST_MANAGER 0x4a46ef9A…`, 4 swap callbacks + V4 `unlockCallback`; whitelist-bypass via a spoofed pool / missing callback caller-check | **LOW-MED** | decompile the impl (non-EIP-1967, bespoke); test a malicious pool + direct `uniswapV3SwapCallback`/`unlockCallback`; confirm `WHITELIST_MANAGER` gate on each of the 4 probed selectors |
| O2 | **BSC `0x6aba0315…` proxy ($8.63M / 155.9M txs)** | BSC(+4) | **≈$3.28M BSC leg**: 741,702.22 USDT + **3,476.04 BNB**; lane: $8.63M/5 chains | unverified impl `0xb66a5adf…` (AccessControl+UUPS+Pausable+ERC-1271); USDT-settlement fn `0x25356bc7` reverts for *everyone*; a role/validation gap on a sibling path = $8M drain | **LOW-MED** (blocker: may be a CEX/omnibus) | decompile `0xb66a5adf…`; diff the 51-selector set for missing role checks; enumerate USDT approvals; classify CEX vs protocol |
| O3 | **Primus Confidential Vault (FHE)** | BSC | reported >$1M user deposits; backend `StakedUSDuV2 0x385C2794…` $38.6M | FHE vault + 8-h batch settlement + encrypted shares (`esUSDu`); **addresses unresolved** | **MED-HIGH $ / address-thin** | resolve the FHE contracts from `dapp.primuslabs.xyz`; then read the encrypted-share mint/redeem + batch settle |
| O4 | **Prodigy.Fi V2 (PositionManager)** | Base | $68.9k DL; proxy `0x50aB3FE7…` → **unverified impl `0xb1522e35…`** (code present, ~14.5 KB), 1,674 vaults | F1: options-vault share/NAV + settlement behind unread code | **MED** | decompile impl, enumerate value-moving selectors, probe auth from a fresh EOA (pass4's "22 unverified-impl proxies" method) |
| O5 | **Wager Predict** | BSC | **$173,362.94 USDW** in `SpotEngine 0x76b91e83…` (USDW 6dp, totalSupply 202,545.41) | fresh custom LMSR prediction market + LP Vault + **USDW wrapper impl `0x7169d192…` unread**; backing is $204k in an off-protocol issuer wallet `0x255e92b8…` | **LOW-MED** | read USDW impl mint/redeem + who can pull the backing; fork a `buy→sell` round-trip for fixed-point overshoot |
| O6 | **Nullmask** | Base | **12.377 ETH ≈ $28,898** (native; WETH bal 0) | fresh ZK privacy pool (Tornado-lineage): deposit Guard/relayer fee accounting + nullifier/verifier wiring; **prior PARKED (addresses then unresolved)** | **LOW-MED** | read pool impl `0xc763e821…` / `AdminUpgradeController 0xcD12496c…` / Guard `0x0558E584…` |
| O7 | **Tapir Protocol** | Base | **$55k** (52,601 zvUSDC in `DepegPool 0x195F79D6…`) | fresh "Depeg Protected / Yield Boosted" split AMM + redemption-price oracle + 22 bp fee; settlement math unread | **LOW-MED** | source-read `DepegPool` + oracle `0x776e69E1…`; fork a depeg/resolve transition |
| O8 | **Unichain `ImmutableProxy` family (~130 clones)** | Unichain | ~$130k across ~130 clones (~$1k each) | all delegatecall an **unverified impl `0x9f70b0c8…`**; `withdraw/refund/recover` revert for a random EOA (`0x407c71ac`) but not fully decompiled | **LOW** | decompile `0x9f70b0c8…`; look for any clone whose `withdraw`/`refund` returns success from a random EOA |
| O9 | **Swaap Maker V2 (`SafeguardPool`)** | multi (11) | ~$454k | distinct Balancer-V2 codebase (ChainSecurity-audited) flagged out-of-scope by `swaap.md`; **never read** | **LOW** | source-read `SafeguardPool` + its oracle guard on a funded instance |
| O10 | **AlphaQ** | Solana | ~$1.0M on-chain (41 markets / 46 vaults) | `update_price` **proven gated**; the `swap`/`swap_with_sig` payout math + secp256k1 path **unresolved** | **LOW** | build a Jupiter/OKX-router proxy-swap with attacker-chosen accounts (same test Tessera needs) |
| O11 | **ChimeraQuoteHook404** | Ink | fees in per-pool `ChimeraFeeVault404` clones | fresh v4 hook (`beforeSwap/afterSwapReturnDelta`, transient storage); creator-exemption via `IChimeraQuoteRouterContext(router).actor()==creator`; `distributeQuotrons` permissionless | **LOW** | fork Ink; drive `Router404.swapPath` through a live Chimera pool; test non-creator exemption reachability + `_charge` rounding |
| O12 | **BondingCurveManager** | Ronin | 190 ERC-20s (all launches it manages) | fresh bonding-curve launchpad; `mulDiv` rounding + auto-graduation; `Ceil` fallback branch | **LOW** | fork Ronin; fuzz `quoteBuy` vs `quoteSell` for a wei-positive round trip; test `liveTarget` manipulation |
| O13 | **DiversiFi** | Solana | $745k | `7029d112…` **proven gated**; `rebalance`/`update_weights` untested; vaults are user-creatable | **LOW** | simulate `rebalance`/`update_weights` with attacker signer |
| O14 | **Overpass** | Solana | $141k | wrapper factory over Lulo/Kamino/kvault/marginfi/save; user-creatable wrappers + creator fee = PDA-binding surface | **LOW** | simulate `Create*Wrapper` + `UpdateCreatorFee`/`ClaimCreatorFees` |
| O15 | **Zodial** | Solana | $201k | **marginfi fork** — fork-drift risk on an audited base | **LOW** | diff the marginfi ix set against upstream; probe admin paths |
| O16 | **Sat Rush** | Solana | $847k DL | "gamified mining" points portal; program ID **unresolved** | **LOW** | resolve program from the DL adapter; read token-account custody |
| O17 | **Loyal Earn** | Solana | $393k DL | yield aggregator; Token-2022 mint; program ID **unresolved** | **LOW** | resolve program ID; read vault custody |
| O18 | **TRUE DEX** | Solana | $281k DL | derivatives, 0 audits; program ID **unresolved** | **LOW** | resolve program ID |
| O19 | **Pascal** | Solana | $2.24M DL | prediction market, 0 audits; program ID **unresolved** | **LOW** | resolve program ID |
| O20 | **N1 Exchange Bridge** | Solana | $1.37M DL | bridge, 0 audits; program ID **unresolved** | **LOW** | resolve program ID; check message verification |
| O21 | **Byzanlink RWA Markets** | Solana | $2.09M DL | RWA market, 2 audits; program ID **unresolved** | **LOW** | resolve program ID |

**Ranking rationale.** O1–O2 top the list because their *verified* token balances are 5–10× what their lane measured, and the code is unverified/obfuscated (the Slice/Drift pre-condition). O3 is high-$ but address-thin. O4–O7 are fresh, funded, with an unread/unverified value path and a concrete next step. O8–O15 are lower-value or probe-negative-but-not-fully-excluded. O16–O21 are DL-funded Solana protocols with no resolved program ID (unlocated).

**Deliberately NOT OPEN** (to avoid re-listing handled/closed items): the 18 ASSIGNED pass6 items; the 20 pass6 README-closed clusters; NEM and UniswapV4Router04 (prior-covered / kept dust); URM Fortress (PARKED — board row 10, no address published anywhere); JPY DeFi (ASSIGNED, and PRIOR-PARTIAL vs the ZH4-closed JPYdf); FlashLoopAdapter (PRIOR-PARTIAL — the module is in the ZH2 negative list; only its 30 same-deployer siblings are unread).

---

## 4. Live sanity checks (read-only, 2026-10-24)

Blocks at read: Ethereum 26,265,167 · Base 53,043,770 · BSC 129,584,923 · Unichain 62,128,529 · Ink 59,378,479 · Ronin 62,704,051. Prices: ETH $2,334.84 · BNB $731.79 · SOL $101.21 (DefiLlama).

| Target | Exists? | Live balance now | Already disproven? |
|---|---|---|---|
| ETH `0x278d858f` (O1) | yes (unverified, bespoke) | 73,386.89 USDT + 87,134.14 USDC + 102.279 WETH + 0.000616 ETH ≈ **$399.3k** | no — lane only checked native ETH |
| BSC `0xa9010523` (O1) | yes | 0 USDT-BSC, 0 native | sibling; value is on ETH |
| BSC `0x6aba0315` (O2) | yes (unverified impl) | 741,702.22 USDT-BSC + 3,476.04 BNB ≈ **$3.28M** | no — reverts for stranger only |
| Base Prodigy `0x50aB3FE7` (O4) | yes; impl code present (14.5 KB) | native 0 (funds in vaults) | no |
| BSC Wager `0x76b91e83` (O5) | yes | 173,362.94 USDW ≈ **$173.4k** | no |
| Base Nullmask `0xd64EF141` (O6) | yes | 12.377 ETH ≈ **$28.9k** | no |
| Base Tapir `0x195F79D6` (O7) | yes | native 0 (holds zvUSDC) | no |
| Unichain `0x966107c4` (O8) | yes | native 0 | probe reverts (guard present) |
| Ink `0xD723B53D` (O11) | yes | native 0 (fees in vaults) | no |
| Ronin `0xCF6Aa3d8` (O12) | yes | native 0 (holds ERC-20s) | no |
| Base Doppler `0x27ad92D4` (monitor) | yes | native 0 (31.2M XDP staked) | inert until first `addRewardPeriod` |
| Solana programs LYC8…/ALPHAQ…/par1ty…/3vyr9…/ccJYP…/WRAPd…/zod11…/TessV… | **all exist, executable** (BPFLoaderUpgradeable) | custody per lane | Kestrel/Tessera closed; others unresolved |

---

## 5. Confidence & blockers

- **Confidence in the dispositions: HIGH.** Every pass6 README-closed item is corroborated by its own lane file; every PRIOR-COVERED item was matched to a specific tracker/README line; every ASSIGNED item matches the `ci/ZH4P6-RESULTS-TRACKER.md` wave table.
- **Confidence in the OPEN list: MEDIUM.** `OPEN` is a triage label, not a bug. Plausibility is mostly LOW-MED; the top two rest on *unverified/obfuscated* code that the lanes could not name on any free source.
- **Blockers / caveats.**
  1. **`0x6aba0315` (O2)** has 155.9M txs and 5-chain custody — it may be a **CEX/omnibus**, not a protocol (the same blocker as pass5-recon's zkSync vault OPEN). Classify before investing.
  2. **O1/O2 name resolution failed** on every free source (Blockscout Base/BSC Cloudflare-blocked, Etherscan-V2 free tier rejects Base/BSC, Sourcify no match, Firecrawl out of credits). Identification must be by decompiler.
  3. **Solana O16–O21** have no resolved program ID in any source touched (DL-listed only) — they are funded but unlocated.
  4. The shared **Alchemy key was monthly-cap-exceeded** during pass6; all reads here used public RPCs.
  5. Point-in-time **2026-10-24**; re-read live state before acting. Nothing here is an instruction to transact.

---

## 6. Files & CI

- `summary.json` — counts, OPEN list, one-liner.
- `analysis/rows.json` — machine-readable 177-row disposition table (schema: lane/candidate/chain/funds/lane_verdict/disposition/cite).
- `analysis/DISPOSITIONS.md` — the full markdown table.
- `analysis/build.py` — table builder (source of truth).
- `ci/check.py`, `ci/run.sh` — CI validation: count reconciliation, public-RPC live-funds re-reads, secret/keyed-URL scan.
- `ci-out/` — `validation.json`, `live_checks.json` (written by CI).
- **CI:** GitHub Actions `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, branch `pass6-recon` — **run URLs: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40134733308 and https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40134958713** (custom job `ci/run.sh` → `[pass6-recon] validation exit=0`; `ok:true`, counts reconciled, 0 keyed-URL hits). Artifacts: `ci-artifacts/result-pass6-recon/`, log `ci-log.txt`.

*Prepared 2026-10-24 · ZH4 pass-6 residual reconciliation · read-only · no secrets.*
