# PASS4-RECON — full disposition table (every named candidate in `zombie-hunt-iv/pass4/`)

Legend — **Disposition**: `README-FINDING` (listed in pass4 README Tier1/2/3 or carry-over) · `README-CLOSED` (in the README "VERIFIED CLOSED" table / closed-list) · `LANE-CLOSED` (lane file gives a closing verdict — line cited) · `PRIOR-COVERED` (verdict in an earlier tracker/pass/folder) · `PRIOR-PARTIAL` (same protocol, distinct angle) · `NOT-A-PROTOCOL` (metric/address/token/hypothesis/pattern) · `OPEN` (funded ≥~$1k + plausible unprivileged path + no verdict anywhere) · `LANE-LEAD` (named watchlist lead, not verified / below OPEN bar).

**Prior-source abbreviations:** P1=`ci/ZH4-RESULTS-TRACKER.md` (pass1) · P2=`ci/ZH4P2-RESULTS-TRACKER.md` · P3=`ci/ZH4P3-RESULTS-TRACKER.md` · P4=`ci/ZH4P4-RESULTS-TRACKER.md` · P5=`ci/ZH4P5-RESULTS-TRACKER.md` · ZH3=`ci/ZH3-RESULTS-TRACKER.md` · ZH2B=`ci/ZH2B*-RESULTS-TRACKER.md` · MON=`ci/MONITOR-LIST.md` · pass2/pass3/pass5 = `zombie-hunt-iv/passN/`.

---

## Lane 1 — `affluent.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 1 | Affluent / Factorial Finance — BasicPool `EQCrEHHG…` (+7 pools, MultiplyVaults) | TON | $766k pool / ~$3.5M protocol | HIGH, unpatched incident, path UNPROVEN | **README-FINDING** (P4-01) — *withdrawn 2026-10-23 as FALSE POSITIVE*; also **PRIOR-COVERED** | P4 log "Affluent = FALSE POSITIVE"; MON row 60 |
| 2 | AdvancedPool `EQBCXQp2…` / EthenaPool / Storm* / LendingVaultPool / Tradoor | TON | $342k/$272k/$8k/$24k | same codebase, no delta | **NOT-A-PROTOCOL** (sub-instances of #1) | affluent.md §1 |
| 3 | Affluent strategy/lending vaults (Sentora, TON-Multiply-1, …) | TON | ~$3.5M | context custody | **NOT-A-PROTOCOL** (context) | affluent.md §1 |

## Lane 2 — `bmx-deli.md` (+ `verify-bmx-mellow.md`)

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 4 | BMX Deli Swap (DeliHook, DailyEpochGauge, IncentiveGauge, FeeProcessor, Voter) | Base | ~$12.0k | CLOSED, 0/8 Highs live | **README-CLOSED** | README closed table |
| 5 | BMX Deli Voter H-2/H-3 (code present, frozen) | Base | ~$11.6k | code-present but frozen | **README-CLOSED** | README closed row + verify-bmx-mellow A.3 |
| 6 | Abandoned earlier Deli deployment (`0xC384B99A…`, old gauges) | Base | dust | superseded | **NOT-A-PROTOCOL** | bmx-deli §2 |
| 7 | BMX Freestyle / Classic Perps | Base | $1.30M/$116k | different product | **NOT-A-PROTOCOL** | bmx-deli §6 |

## Lane 3 — `contest-gap.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 8 | Fluid DEX v2 money-market H-1 | Ethereum | $0 affected | FIXED live | **README-CLOSED** + PRIOR-COVERED (P5, pass3) | contest-gap row 1 |
| 9 | Yield Basis LT H-1 | Ethereum | $0 affected | FIXED live | **README-CLOSED** + PRIOR-COVERED (P5) | row 2 |
| 10 | Centrifuge V3.1 H-1 | multi | $0 affected | FIXED live | **README-CLOSED** + PRIOR-COVERED (P5) | row 3 |
| 11 | BMX Deli Swap (contest rows) | Base | ~$12k | frozen/mixed | **README-CLOSED** | row 4 |
| 12 | Mellow Core (Flexible Vaults) 6 Highs | Ethereum | $0 affected | FIXED live | **README-CLOSED** + PRIOR-COVERED (P5) | row 5 |
| 13 | Recall IPC gateway / subnet actors | Filecoin | $0 | testnet-only | **README-CLOSED** | row 6 |
| 14 | Burve H-5 | Berachain | $32k | acknowledged-unfixed | **README-FINDING** (P4-02) | row 7 |
| 15 | Peapods Finance PodUnwrapLocker H-1/H-2 | Ethereum | $0 affected | FIXED live | **README-CLOSED** | row 8 |
| 16 | Tangent / USG H-1/H-2 | Ethereum | $0 affected | FIXED live | **README-CLOSED** | row 9 |
| 17 | RAAC / Regnum Aurum | Ethereum | $0 | testnet-only | **README-CLOSED** | row 10 |
| 18 | Virtuals Protocol (AgentVeToken/NFT) | Base | — | audited code superseded | **LANE-CLOSED** | row 11 |
| 19 | **Cabal LST** | Initia | **$2.11M DL** | unverified live lead (H-01) | **OPEN** | row 12 |
| 20 | Notional Exponent | Ethereum | $182 | acknowledged, below bar | **README-CLOSED** | row 13 |
| 21 | Malda | — | none found | dead | **README-CLOSED** | row 14 |
| 22 | Gamma — Perpetual Vault | GMX chains | — | live address not located | **LANE-CLOSED** | row 15 |
| 23 | Zaros | Arbitrum | ~$0 | dead | **README-CLOSED** | row 16 |
| 24 | Curve scrvUSD Storage Proofs | multi | — | undeployed | **README-CLOSED** | row 17 |
| 25 | BattleChain Confidence Pools | Cyfrin L2 | — | 0 Highs | **LANE-CLOSED** | row 18 |
| 26 | Liquid Ron H-01 | — | ~$45k | mitigation confirmed | **LANE-CLOSED** | dead ends |
| 27 | IQ AI H-01 | — | — | all mitigated | **LANE-CLOSED** | dead ends |
| 28 | Thorwallet H-01/H-02 | — | — | mitigation confirmed | **LANE-CLOSED** | dead ends |
| 29 | CodeHawks private contests (Benqi Ignite, Remora ×2, Starknet Staking ×2, Open Eden, Cyfrin Attester) | — | — | findings private | **NOT-A-PROTOCOL** | dead ends |
| 30 | Ammplify | — | — | not on DefiLlama | **README-CLOSED** | dead ends |
| 31 | Dango DEX | — | — | dead | **README-CLOSED** | dead ends |
| 32 | Next Generation | Fantom | — | dead | **LANE-CLOSED** | dead ends |
| 33 | Garden / Brix / Covenant / Flare-FAsset / Upside / BitVault | multi | — | 0 Highs | **LANE-CLOSED** | dead ends |
| 34 | Monad client (EIP-7702 DoS) · Succinct SP1 · Initia rollup modules · ZetaChain H-2 · Solana Foundation | multi | — | non-E-U / infra | **NOT-A-PROTOCOL** | dead ends |
| 35 | Immunefi public disclosures · Cantina | — | — | dead paths | **NOT-A-PROTOCOL** | dead ends |

## Lane 4 — `gap-chains.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 36 | Burve SimplexDiamond `0xa1beD164…` | Berachain | $32k | acknowledged-unfixed | **README-FINDING** (P4-02) | row 1 |
| 37 | Kuru AccountCore / MarginAccount | Monad | $379.7k (H-O) | unverified clones | **README-FINDING** (P4-03) | row 2 |
| 38 | Infrared deposits `0x9b6761bf…` | Berachain | $19.0M | unverified impl | **README-FINDING** (P4-04) | row 3 |
| 39 | **shMonad `0x1B68626d…`** | Monad | $212.7k (contract) / $7.72M DL | verified, not deep-diffed | **OPEN** | row 4 |
| 40 | **Metropolis DLMM VaultFactory `0x197d40B3…`** | Sonic | no custody | vault-side admin not read | **OPEN** (low) | row 5 |
| 41 | D2 Finance VaultV3 (Bera/HyperEVM) | multi | $12.44M | false positive (owner-gated) | **README-CLOSED** | row 6 / §3 |
| 42 | Kinetiq Earn BoringVault `0x9BA2EDc4…` | HyperEVM | $7.19M | gated (UNAUTHORIZED) | **PRIOR-COVERED** (MON Kinetiq) | row 7 |
| 43 | Kinetiq StakingManagerRouter `0x393D0B87…` | HyperEVM | $12.79M | role-gated | **PRIOR-COVERED** (MON) | row 8 |
| 44 | Hyperbeat WithdrawManager `0x9d0B0877…` | HyperEVM | $130.8k | role-gated | **PRIOR-COVERED** (P3 "Hyperbeat E-U $0") | row 9 |
| 45 | Sonic Market BookManager `0xD4aD5Ed9…` | Sonic | $381 | self-scoped | **LANE-CLOSED** | row 10 |
| 46 | Sturdy V2 (Sei) DataProvider | Sei | $0 | empty markets | **LANE-CLOSED** | row 11 |
| 47 | Yuzu YuzuILPV3 / yzUSD | Plasma/Monad | $65M DL | role-gated | **PRIOR-COVERED** (pass2 mini-chains: deposits closed) | row 12 |
| 48 | Reservoir Protocol (BorrowableCToken/fToken/EulerEarn/GHO/CollateralVault) | multi | $60.9M DL | gated | **LANE-CLOSED** | row 13 |
| 49 | Silo V2 `Silo` (34) | Sonic | — | gated / one-shot init | **LANE-CLOSED** | row 14 |
| 50 | Hyperbeat/Kinetiq/Plasma BoringVault family (11 more) | HyperEVM/Plasma | — | Veda owner==0, authority set | **PRIOR-PARTIAL** (ZH3 BoringVault class) | row 15 |
| 51 | NEM-class `sync()` sweep (258 contracts) | 10 chains | — | 0/258 | **README-CLOSED** | negatives |
| 52 | `owner()==0` sweep (13 contracts) | — | — | all benign (Veda) | **NOT-A-PROTOCOL** | negatives |
| 53 | Hyperbeat MetaMorphoV1_1.skim | HyperEVM | — | upstream-identical | **LANE-CLOSED** | negatives |
| 54 | Infrared `redeemIbgtForBera` (RewardsLib) | Berachain | — | caller's own iBGT | **LANE-CLOSED** | negatives |
| 55 | Rings Puppeteer + VotingEscrow | Sonic | — | role-gated | **LANE-CLOSED** | negatives |
| 56 | Katana/ApeChain/XDC/Taiko census | multi | — | canonical forks | **LANE-CLOSED** | §2 |

## Lane 5 — `hacklab-patterns.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 57 | ether.fi/Veda AtomicQueue `0xD45884…` | Ethereum | $0 (re-arm) | unpatched, approvers drained | **README-FINDING** (Tier3 #4) + PRIOR-COVERED (ZH1 C-07) | §2 P1 |
| 58 | Reservoir GaslessReservoirEnabler `0x9B58fDAd…` | Polygon | $0 (re-arm) | unpatched | **README-FINDING** (Tier3 #5) + PRIOR-COVERED (ZH2) | §2 P1 |
| 59 | BitBay UsdcDaiV4Vault `0x048E8831…` | Polygon | $0 | code live, drained | **PRIOR-COVERED** (ZH3-H6 / MON) | §2 P5 |
| 60 | Set Protocol RebalancingSetTokenV3 `0x54e8371C…` | Ethereum | $0 | code live, empty | **PRIOR-COVERED** (P5 "Set Protocol V3") | §2 P5 |
| 61 | Likwid LikwidVault `0x065d449e…` | BSC | 17.70 BNB | path EXHAUSTED | **PRIOR-COVERED** (P4) | §2 P1/P5 |
| 62 | TIPMine `0x412c7bd2…` | BSC | $0 | dead | **PRIOR-COVERED** (pass2/pass5 incidents) | §2 P3 |
| 63 | FlashLoopAdapter `0x16bb8B91…` | Ethereum | $0 | unused | **PRIOR-COVERED** (pass2/pass3/pass5) | §2 P2 |
| 64 | X7Finance / X7Pioneer `0x70000299…` | Ethereum | 0.0216 ETH | reward-recount | **PRIOR-COVERED** (pass5 community-leads/incidents; rearm-watch) | §2 P6 |
| 65 | GoldPesa hook `0x4519e2b0…` | Base | ~$0 | trigger gated | **PRIOR-COVERED** (ZH3-H5 / MON) | §2 P4 |
| 66 | MOKE / RELEASE | BSC | $0 | tx.origin latch | **PRIOR-COVERED** (pass2) | §2 P9 |
| 67 | PositionManager `0x7cedB2e5…` | BSC | $0 | spot-price | **PRIOR-COVERED** (P1/L2/pass2/pass3) | §2 P4 |
| 68 | PrimeFinance pool `0xb339448E…` | HyperEVM | $0 | empty | **LANE-CLOSED** | §2 P4 |
| 69 | CozyFinance Set `0x17705474…` | Optimism | $0 | empty | **LANE-CLOSED** | §2 P1 |
| 70 | PerpetualProtocol v2 Vault `0x28bB4820…` | Optimism | $0 | empty | **LANE-CLOSED** | §2 P1 |
| 71 | MakerDAOFlipKeeper keeper proxy `0x9c05a058…` | Ethereum | drained | closed | **PRIOR-COVERED** (pass5 maker-keepers) | §2 P10 |
| 72 | Versa ModuleManager | — | — | not the bug | **PRIOR-COVERED** (ZH2B7/ZH3) | §4 |
| 73 | unwallet/zenguard LockManager | — | — | not the bug | **LANE-CLOSED** | §4 |
| 74 | primordium TimelockAvatar | — | — | not the bug | **LANE-CLOSED** | §4 |
| 75 | AtomicQueue forks — Nucleus/Plume, PeggyJV/cellar-contracts, Paxos, Theoriq, Veda | multi | $0 | template unpatched, addrs unresolved | **PRIOR-COVERED** (ZH1 C-07 / MON "AtomicQueue forks") | §4 |
| 76 | 15-pattern map (P1–P15) | — | — | patterns | **NOT-A-PROTOCOL** | §1 |

## Lane 6 — `incidents.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 77 | Slice (FundsModule) | Base | $0 | patched+paused | **README-CLOSED** | row 1 |
| 78 | Institutional MORPHO EIP-7702 drain | Ethereum | $2.3M | key/delegation compromise | **NOT-A-PROTOCOL** | row 2 |
| 79 | Drift Protocol exploiter | Ethereum | — | laundering | **NOT-A-PROTOCOL** | row 3 |
| 80 | Aztec rollup exploiter | Ethereum | — | laundering | **NOT-A-PROTOCOL** | row 4 |
| 81 | $NEM `flushLpSellRecycle` | BSC | ~$1.8k | replayable but tiny, one-off | **README-FINDING** (Tier3 #7-class) + PRIOR-COVERED (P4) | row 5 |
| 82 | Atomic Green / AtomicLending `partialBurn` | Arbitrum | ~$105k | replay (decimal error) | **PRIOR-COVERED** (pass3 replay) | top-3 #2 |
| 83 | BiFi Lending | ETH/BSC | ~$324k | paused, re-arms | **README-FINDING** (carry-over) + PRIOR-COVERED (pass3) | top-3 #3 |
| 84 | Argent smart-wallet | — | $59.8k | pass2/pass3 | **PRIOR-COVERED** | excluded |
| 85 | AlpsCon | BSC | $152.8k | pass2/pass3 | **PRIOR-COVERED** (MON) | excluded |
| 86 | UNCX Vesting V2 | — | — | pass2 | **PRIOR-COVERED** (MON) | excluded |
| 87 | EtherVista | — | — | ZH3 | **PRIOR-COVERED** (MON) | excluded |
| 88 | Qubic · Cysic · Kolan · THEO | multi | — | pass2/pass3 | **PRIOR-COVERED** | excluded |
| 89 | Base vault wstETH whitelist drain (Oct-4, $6M) | Base | $6M | prior incident | **LANE-CLOSED** (prior incident, not a live target) | ambiguity note |
| 90 | Lagoon v0.5.2 `syncDeposit` (RockSolid family) | — | — | JIT-yield edge closed, re-check | **LANE-LEAD** | §4 E |
| 91 | SafeTransfer `hiddenCollect` | Ethereum | — | ACTIVATOR_ROLE-gated | **LANE-CLOSED** | §4 C |
| 92 | TMM/USDT, BeatXswap, LOOPSDAO, FoxMarket, MCN Labs, Dream Health Chain, ORBToken | multi | — | reserve-manipulation class | **LANE-CLOSED** (class) / MCN Labs → microcap | §4 F |
| 93 | Patterns A–F (burn/sync, trusted-return, sig replay, EIP-7702, idle interest, reserve oracle) | — | — | patterns | **NOT-A-PROTOCOL** | §4 |

## Lane 7 — `mellow.md` (+ `verify-bmx-mellow.md` target B)

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 94 | Mellow Core / Flexible Vaults (6 Highs) | Ethereum/multi | $296M TVL, $0 at risk | FIXED live | **README-CLOSED** + PRIOR-COVERED (P5) | mellow §1 |
| 95 | Mellow `0x0285805e…` RedeemQueue (missing Jan-2026 fee `burn`) | Ethereum | — | informational (not profitable) | **LANE-CLOSED** | mellow §4 |
| 96 | Mellow Signature*Queues | — | — | not wired to any vault | **LANE-CLOSED** | mellow §3 |

## Lane 8 — `microcap.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 97 | Affluent / Factorial | TON | ~$690k | HIGH, unpatched | **README-FINDING** (P4-01) — withdrawn FP | row 1 |
| 98 | RouterDrain (unnamed BSC router) `0xa331fde0…` | BSC | $0 | unpatched, no funded approvals | **README-CLOSED** | row 2 |
| 99 | Umia (hub/marketCore/vault/LBP) | Base | $3.67M | reviewed, no cheap bug | **README-CLOSED** | row 3 |
| 100 | flaunch flETH `0x000000000d56…` | Base | $1.73M | closed (no bug) | **LANE-CLOSED** | row 4 |
| 101 | MCN Labs LPBonus `0x52272524…` | BSC | ~$540 | below bar | **LANE-CLOSED** | row 5 |
| 102 | Slice FundsModule | Base | $0 | closed | **README-CLOSED** | row 6 |
| 103 | TIPMine / TIP | BSC | $0 | drained | **PRIOR-COVERED** (pass2/pass5) | row 7 |
| 104 | CrowdRingCircle (CRC) | BSC | $0 | pair dust | **LANE-CLOSED** (prior wave1 r2) | row 8 |
| 105 | **Kipseli** (Base/BSC reserve wallets) | Base/BSC | $694k Base / $401k BSC | LOW (Base reserve unverified) | **OPEN** | row 9 |
| 106 | Adrastea Validator | Solana | $28.8M | native validator, no contract | **PRIOR-COVERED** (pass3 lane-lst) | watchlist |
| 107 | Hylo LSTs | Solana | $21.1M | standard stake-pool | **PRIOR-COVERED** (pass3 lane-lst) | watchlist |
| 108 | Raiku Staked SOL | Solana | $19.2M | SPL stake-pool | **PRIOR-COVERED** (pass3/pass5) | watchlist |
| 109 | CatFee Staking Vault | Tron | $17.6M | operator wallets | **PRIOR-COVERED** (pass3 lane-lst) | watchlist |
| 110 | Kyros / Fragmetric | Solana | $12.8M | DL address = token mint | **PRIOR-COVERED** (pass3 lane-lst) | watchlist |
| 111 | StakePoint | Solana | $4.28M | program not decompiled | **PRIOR-COVERED** (pass3 lane-consumer) | watchlist |
| 112 | Vectis Finance | Solana/Eth | $5.14M | unverified lead | **LANE-LEAD** | watchlist |
| 113 | LiquidLoans | Pulse | $2.83M | flagged, not investigated | **LANE-LEAD** (pass2 collapses note) | watchlist |
| 114 | Pay Protocol | Tron/BSC/ETH | $1.92M | payment module, unverified | **LANE-LEAD** | watchlist |
| 115 | SunPump | Tron | $2.16M | launchpad, prior | **PRIOR-COVERED** (pass2/pass3) | watchlist |
| 116 | Trevee Earn | Sonic | $930k | "not reached" | **LANE-LEAD** | watchlist |
| 117 | Magma Staking | Monad/IoTeX | $767k | listed, 0 audits | **PRIOR-COVERED** (zombie_hunt non_llama) | watchlist |
| 118 | Bio Protocol | ETH/Base | $3.43M | audited incumbent | **PRIOR-COVERED** (pass3 lane-consumer) | watchlist |
| 119 | ORBToken / RWC / CrowdRingCircle | BSC | $0 | drained | **LANE-CLOSED** (prior pass5 incidents) | negatives |
| 120 | PrimeFi (HyperEVM) | HyperEVM | — | patched | **LANE-CLOSED** | negatives |
| 121 | Avici / Tria / Solayer-Pay | Solana | ~$1.1M | programs upgraded | **LANE-CLOSED** | negatives |
| 122 | Amnext (BSC PoolTogether-V3 fork) | BSC | — | token codeless | **LANE-CLOSED** | negatives |
| 123 | Chainflip (TRON) | TRON | — | paused | **LANE-CLOSED** | negatives |
| 124 | Internet Token | Base | — | prior/closed | **LANE-CLOSED** | negatives |
| 125 | GoldPesa | Base | — | ZH3-H5 monitor | **PRIOR-COVERED** (MON) | negatives |
| 126 | Unknown Vault `0xD189…CABC` | Base | $6M | 3-of-7 Safe compromise | **NOT-A-PROTOCOL** | negatives |
| 127 | 79thVault / Cysic Bridge | BSC | $14.3M | privileged/key compromise | **NOT-A-PROTOCOL** | negatives |
| 128 | MOKE | BSC | $907k | prior/excluded | **PRIOR-COVERED** (pass2) | negatives |
| 129 | Perpetual Protocol | Optimism | — | off target-chain | **LANE-CLOSED** | negatives |
| 130 | NEM | BSC | — | internal codename (microcap could not locate) | **PRIOR-COVERED** (P4/incidents) | negatives |

## Lane 9 — `off-llama.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 131 | USDSM | Etherlink | $12.09M | role-gated | **README-CLOSED** | row 1 |
| 132 | Startale USD (USDSC) | Soneium | $4.48M | role-gated | **README-CLOSED** | row 2 |
| 133 | MokuVaultV2 `0x43A9bbcE…` | Ronin | ~$63k | onlyRedeemer/onlyOwner | **README-CLOSED** | row 3 |
| 134 | Morpho VaultV2 `0x5C6F9354…` | World Chain | $231k | curator-gated | **LANE-CLOSED** | row 4 |
| 135 | Ronin AccountProxy `0xF57Aa324…` | Ronin | ~$182k | not a protocol (user wallet) | **NOT-A-PROTOCOL** | row 5 |
| 136 | AIPF token | Polygon | $6.43M pool | plain ERC-20 | **NOT-A-PROTOCOL** | row 6 |
| 137 | AS Token | Polygon | $6.60M pool | plain token | **NOT-A-PROTOCOL** | row 7 |
| 138 | xBTC / wSPYx / wNVDAx / wTSLAx | X Layer | $2.56M… | issuer-custodied tokens | **NOT-A-PROTOCOL** | row 8 |
| 139 | HashKey Treasury | HashKey | 5.23M HSK | privileged treasury | **NOT-A-PROTOCOL** | row 9 |
| 140 | Firelight stXRP | Flare | $58–67M | CLOSED wave2/v7 | **PRIOR-COVERED** (wave2/v7) | negatives |
| 141 | Saturn USD / USDat · mUSD · spSEI | Monad/Sei | $150M/$…/$6.05M | on DefiLlama | **NOT-A-PROTOCOL** | negatives |
| 142 | "F/DAI" (Arb) · "ZOZO/DAI" (Pulse) pools | multi | fake | spoofed screener artifacts | **NOT-A-PROTOCOL** | negatives |
| 143 | RUGBUG/PEAR/GB/AISA/宝宝/RUGW new pools | multi | — | memecoins/LP | **NOT-A-PROTOCOL** | negatives |
| 144 | Wrapped natives / SafeProxy / ProxyAdmin / LZ SendUln302 / EntryPoint / PoolManager / TAC / Filecoin `0xfF0000…` | multi | — | infra | **NOT-A-PROTOCOL** | negatives |
| 145 | Unlink (Monad private settlement) | Monad | — | no verifiable TVL/custody | **LANE-LEAD** | §METHOD ch.3 |
| 146 | Tokenized-equity contracts on X Layer | X Layer | — | issuer-custodied | **NOT-A-PROTOCOL** | negatives |

## Lane 10 — `recall.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 147 | Recall IPC gateway / registry / subnet actors | Filecoin | $0 | testnet-only | **README-CLOSED** | recall §VERDICT |
| 148 | Calibration funded gateway `0x1AEe8A87…` (10,357.5 tFIL) | Filecoin Calibration | $0 (tFIL) | testnet faucet | **NOT-A-PROTOCOL** | recall §2b |
| 149 | Recall mainnet (chain 24816) / Base contracts | Recall | $0 | unreachable / Base | **NOT-A-PROTOCOL** | recall §2c |

## Lane 11 — `skim-burn.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 150 | Pro `0x8D657445…` pair | BSC | $21.56M | GATED (fork-proven) | **LANE-CLOSED** | §3 #1 |
| 151 | 79AU `0xC35ef056…` pair | BSC | $8.21M | GATED (AccessControl) | **LANE-CLOSED** | §3 #2 |
| 152 | SPR `0x71967D91…` pair | BSC | $6.29M | GATED (`SPR__OnlyStaking`) | **LANE-CLOSED** | §3 #3 |
| 153 | BTCΞ `0xb1939843…` | BSC | $2.86M | unresolved (pair-scoped "T0") | **README-FINDING** (Tier3 #3) + PRIOR-COVERED (P4) | §3 #4 |
| 154 | AIGO `0xa6344A67…` | BSC | $1.46M | GATED | **LANE-CLOSED** | §3 #5 |
| 155 | MS `0x6dc3bcec…` | BSC | $1.30M | GATED | **LANE-CLOSED** | §3 #6 |
| 156 | KEY `0x32990983…` | BSC | $1.29M | GATED | **LANE-CLOSED** | §3 #7 |
| 157 | NS `0x33F1c4FB…` | BSC | $625k | unresolved (4-of-6 Safe) | **README-FINDING** (Tier3 #3) + PRIOR-COVERED (P4) | §3 #8 |
| 158 | DMD `0x939dF4A5…` | BSC | $285k | unresolved (admin EOA) | **README-FINDING** (Tier3 #3) + PRIOR-COVERED (P4) | §3 #9 |
| 159 | **TOPS `0x842B1bFA…`** | BSC | $92k | UNRESOLVED (buy reverted) | **OPEN** (low) | §3 #10 |
| 160 | **LVIN `0x33bc8653…`** | BSC | $91k | UNRESOLVED (`recycle fail`) | **OPEN** (low) | §3 #11 |
| 161 | PEPGEM `0x0fd1eBe9…` | BSC | $59k | not profitable (fork) | **LANE-CLOSED** | §3 #12 |
| 162 | AGX `0xe766023F…` | BSC | ~$0 | GATED | **LANE-CLOSED** | §3 #13 |
| 163 | BURN/竹笋/超级社区/BNBLP/BNCQ2.0/MINE/ANG/NF/FC | BSC | $0.6–90k | not profitable | **LANE-CLOSED** | §3 #14 |
| 164 | Pattern family (SKP, STO, JUDAO, AM, MONA, MT, OCA, DIP, NEX, WETC, BCE, BFC, LULA, CCC, FH) | BSC | drained | all pairs drained | **LANE-CLOSED** (drained; some also PRIOR-COVERED in pass5 incidents) | §1 |
| 165 | Cross-chain BULL `0x8e9de09f…`, 7AΩ∞ `0x622b6330…` | Ethereum | $123/$165 | low-liquidity | **LANE-CLOSED** | §3 |

## Lane 12 — `small-chain-scout.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 166 | Multicall3Router `0x6222f994…` (Wheelx) | Metis | $0 | unguarded cleanupERC20 (latent) | **README-FINDING** (Tier3 #2) | row 1 |
| 167 | CIAN Yield Layer vaults `0x6B2BA8F2…`/`0x74D2Bef5…` | Mantle | ~$110M | unverified impl, whitelist/admin-gated | **README-CLOSED** | row 2 |
| 168 | MokuVaultV2 | Ronin | ~$25k | gated | **README-CLOSED** | row 3 |
| 169 | TendaEscrow `0x9D0193f7…` | Celo | fresh escrow | clean (pays creator) | **LANE-CLOSED** | row 4 |
| 170 | Fluent Auction/Marketplace/CreditTicket/Treasury/OrderBook | Fluent | new stack | role-gated/self-scoped | **LANE-CLOSED** | row 5 |
| 171 | Flare ClubVaultV2 `0x9B51319B…` | Flare | complex vault | owner-gated | **LANE-CLOSED** | row 6 |
| 172 | Fluent `claimToken(address)` `0xE81825Ec…` | Fluent | dust | pays fixed beneficiary | **LANE-CLOSED** | row 7 |
| 173 | Aurora BastionVault / ReaperVaultv1_4 / MagikVault | Aurora | drained | onlyOwner | **LANE-CLOSED** | row 8 |
| 174 | Metis RewardDistributor / NitroPool | Metis | small | role-gated | **LANE-CLOSED** | row 9 |
| 175 | Ronin Staking `0x545edb75…` | Ronin | 65.97M RON | canonical role-gated | **LANE-CLOSED** | row 10 |
| 176 | Manta CeDeFi mBTC/mETH/mUSD | Manta | $26.9M | mint AccessControl-gated | **LANE-CLOSED** | row 11 |
| 177 | Rootstock PaystandTokenBridge | Rootstock | bridge | role-gated | **LANE-CLOSED** | row 12 |
| 178 | Telos ProtocolFeeHook `0xe01bf830…` | Telos | ~$2k | onlyOwner | **LANE-CLOSED** | row 13 |
| 179 | GOAT Locking / DynamicCheckInJackpot | GOAT | <$5k | onlyDev | **LANE-CLOSED** | row 14 |
| 180 | Astar CCIP pools / AnyswapV6 Swapin/Swapout | Astar | pools | onlyAuth | **LANE-CLOSED** | row 15 |
| 181 | Flare bonding-curve `sell` / TaxConverter / CatVault `refund` | Flare | sale flow | self-scoped/no owner | **LANE-CLOSED** | row 16 |
| 182 | Init Capital (Mantle/Blast) | multi | — | Compound-style, audited | **LANE-CLOSED** | negatives |
| 183 | Flare un-covered (Mystic/Kinetic/Sceptre) | Flare | — | already ZH2 | **PRIOR-COVERED** (ZH2) | negatives |

## Lane 13 — `trusted-caller.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 184 | BigShot `0x274D146c…` | Optimism | $0 | fork-proven sweepToken | **README-FINDING** (Tier3 #1) | row 1 |
| 185 | Uniswap-V3/V4 fork routers/position managers (Celo SwapRouter, Gnosis EtherRouter, Unichain MultiFiller/Tycho, MultiPositionManager) | multi | ≤15 CELO etc | gated | **LANE-CLOSED** | row 2 |
| 186 | Slice FundsModule (OP/ETH proxies) | multi | ~1 wei | not vulnerable code | **README-CLOSED** | row 3 |
| 187 | ApprovalSwapRouter `0x06621dFf…` | Optimism | $0 | reverts | **LANE-CLOSED** | row 4 |
| 188 | UnimonRefunds `0x51b71C47…` | Unichain | 3.84 ETH | msg.sender-scoped | **LANE-CLOSED** | row 5 |
| 189 | MultiPositionManager `0x4a1947d5…` | Unichain | 0.86 ETH | share/owner-gated | **LANE-CLOSED** | row 6 |
| 190 | Slice ecosystem clients (SlicerPurchasable, sharkstreet, otherslice, merchsquad, sharkfrens, zerohex) | Base | — | no trust flaw | **LANE-CLOSED** | row 7 |
| 191 | 0xSplits SplitMain | multi | — | validSplitHash | **LANE-CLOSED** | row 8 |
| 192 | OZ/thirdweb PaymentSplitter | multi | — | shares-gated | **LANE-CLOSED** | row 9 |

## Lane 14 — `unverified-impl.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 193 | `0x1ecdb32e…` (OTC offer-settlement, impl `0x623620b3…`) | Ethereum | $271,555 | AccessControl-gated, fork no change | **README-CLOSED** (22 unverified-impl proxies) | row 1 |
| 194 | `0xc9d748e6…` (router/relayer, impl `0xd0ad4810…`) | Ethereum | $228k | WITHDRAWER_ROLE | **README-CLOSED** | row 2 |
| 195 | `0x235f7326…` (reward/mint controller) | Ethereum | $44,911 | Ownable | **README-CLOSED** | row 3 |
| 196 | `0x974b2d86…` (impl `0x5fabe98f…`) | Ethereum | 13.22 ETH | Ownable | **README-CLOSED** | row 4 |
| 197 | `0x7ff8a32e…` (impl `0x500cdce8…`) | Ethereum | ~$450 liquid | UUPS gated | **README-CLOSED** | row 5 |
| 198 | 11 ETH proxies below $10k (`0x618a769c…` … `0xe38d7119…`) | Ethereum | ≤$4,837 | below bar | **README-CLOSED** | rows 6–16 |
| 199 | Base proxies `0x0000efc4…` (9.445 ETH), `0xa834e703…` (3.986 ETH) + 4 | Base | ≤$25.5k | gated | **README-CLOSED** | Base addendum |
| 200 | Medium-frequency-impl proxies (2,992) | multi | — | all verified impls | **NOT-A-PROTOCOL** | §method |

## Lane 15 — `verify-fluid.md`

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 201 | Fluid DEX v2 MM H-1 (live 0.8.34 module) | Ethereum | $0 affected | FIXED, unused | **README-CLOSED** + PRIOR-COVERED (P5) | verify-fluid §c |
| 202 | Fluid vulnerable 0.8.29 module `0x073320FA…` / `0x675C2E62…` | Ethereum | $0 | not wired to any proxy | **LANE-CLOSED** | verify-fluid §a |
| 203 | Fluid V1 `FluidVaultT1` ($900M TVL) | multi | $900M | different code path | **NOT-A-PROTOCOL** (context) | verify-fluid §c |

---

## Lane 16 — cross-lane prose leads (from `incidents.md` §3–4 and pattern families)

| # | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|
| 204 | SIEVE | BSC | ~$11k (drained) | incident, drained | **LANE-CLOSED** | incidents §3 (HashDit round-up) |
| 205 | DTXT | BSC | drained | fee-on-transfer desync (P12) | **LANE-CLOSED** | hacklab P12 / skim-burn §1 |
| 206 | TMM (Movie) | BSC | $1.7M (drained) | reserve-manip oracle | **LANE-CLOSED** | incidents §4 F |
| 207 | LOOPSDAO | — | — | reserve-manip oracle | **LANE-CLOSED** | incidents §4 F |
| 208 | FoxMarket | — | — | reserve-manip oracle | **LANE-CLOSED** | incidents §4 F |
| 209 | LlamaPay-style payout contracts | multi | — | amount is caller's own accrued balance | **NOT-A-PROTOCOL** | trusted-caller §negatives 7 |

---

**Total enumerated candidates: 209** (rows 1–209; several rows group multiple named names). Counts by disposition are in `summary.json`.
