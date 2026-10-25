# ZH4-PASS7 — FULL DISPOSITION TABLE (every named candidate, all 17 lanes + README)

Dispositions: **README-FINDING** (pass7 README headline/board) · **README-CLOSED** (pass7 README §5 verified-closed or carry-over-closed) · **LANE-CLOSED** (closed inside its own lane) · **PRIOR-COVERED** (closed by an earlier pass) · **PRIOR-PARTIAL** (same protocol, different angle) · **NOT-A-PROTOCOL** (off-chain / key / CEX / chain-level / non-EVM / scam) · **ASSIGNED** (handled by a pass7 wave-1 or wave-2 agent) · **OPEN** (funded + plausible unprivileged path + no verdict anywhere).

`ASSIGNED` = handled elsewhere in pass7 (wave-1 = README 1 CRIT + 9 HIGH + 12 LOW; wave-2 = lane-level funded residuals, per `ci/ZH4P7-RESULTS-TRACKER.md` §COVERAGE AUDIT).

| # | Lane | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |
|---|---|---|---|---|---|---|---|
| 1 | README | P7-CRIT wsNET/USDG Morpho Blue oracle | Robinhood 4663 | cap $305,991; net $24k–$160k | CRITICAL fork-proven | **README-FINDING** | README §0/§2; wsnet.md; wsnet-verify.md |
| 2 | README | P7-01 Aragon-legacy governance | Ethereum | 227.3 ETH ~$546k | HIGH, $0 today | **README-FINDING** | README §3; gov-capture.md |
| 3 | README | P7-02 Hyperliquid Earn | HyperCore | $1.43B | HIGH watch-only | **README-FINDING** | README §3; accounting.md |
| 4 | README | P7-03 HyperLend core pool | HyperEVM 999 | $302M | HIGH, $0 today | **README-FINDING** | README §3; oracle.md |
| 5 | README | P7-04 USDT0 OFT adapter | Ethereum | $3.198B | HIGH, dormant 1-of-1 | **README-FINDING** | README §3; bridges.md |
| 6 | README | P7-05 Circle Gateway | multi | $63.8M | HIGH P-class | **README-FINDING** | README §3; bridges.md |
| 7 | README | Carry-over Robinhood-Chain equity feeds | Robinhood 4663 | cap $226,341 | carry-over monitor | **README-CLOSED** | README §3; ZH4P6 P6-01 |
| 8 | README | Carry-over Sodium | Arbitrum | $0 (dust) | carry-over monitor | **README-CLOSED** | README §3; ZH4P5 |
| 9 | README | Carry-over AGLHook | Ethereum | $1.43M ceiling | carry-over closed $0 | **README-CLOSED** | README §3; ZH4P5 |
| 10 | README | Carry-over Spot hook | Unichain | $4.22M ceiling | carry-over closed $0 | **README-CLOSED** | README §3; ZH4P5 |
| 11 | README | Carry-over StablePair/VolatilePair | ETH/Arb | $11.71M ceiling | carry-over closed $0 | **README-CLOSED** | README §3; ZH4P5 |
| 12 | README | Carry-over BiFi | BSC | ~$97k / ~$40k net | carry-over closed; BSC conditional | **README-CLOSED** | README §3; ZH4P3 |
| 13 | README | LOW#1 Morpho wSPYx/AUSD | Ethereum | $478k collat | LOW; $0–1.3k | **ASSIGNED** | README §4; oracle.md |
| 14 | README | LOW#2 LayerBank | Robinhood 4663 | $3.3M borrow | LOW; feeds stale-accurate | **ASSIGNED** | README §4; oracle.md |
| 15 | README | LOW#3 HyperLend isolated pairs | HyperEVM 999 | ~$50k | LOW | **ASSIGNED** | README §4; oracle.md |
| 16 | README | LOW#4 dTRINITY dLEND | Fraxtal | <=$947k siblings | LOW; patched | **ASSIGNED** | README §4; oracle.md |
| 17 | README | LOW#5 ApeChain instant-gov games | ApeChain | $3.9k/$2.2k/$1.9k | LOW | **ASSIGNED** | README §4; fresh-detector.md |
| 18 | README | LOW#6 Unlock Protocol gov | Base | ~$38k | LOW-MED; net $15–20k | **ASSIGNED** | README §4; gov-params.md |
| 19 | README | LOW#7 SudoGovernor | Ethereum | $537.9k nominal | LOW; DEX depth $35k | **ASSIGNED** | README §4; gov-params.md |
| 20 | README | LOW#8 Internet Token gov | Base | ~$339k nominal | LOW-MED | **ASSIGNED** | README §4; gov-params.md |
| 21 | README | LOW#9 Prosper Alpha | Pharos 1672 | $512k | LOW; market unread | **ASSIGNED** | README §4; fresh-deep.md |
| 22 | README | LOW#10 Hive Protocol | BSquared 223 | $234M staked | LOW; contracts not located | **ASSIGNED** | README §4; fresh-deep.md |
| 23 | README | LOW#11 Archer Exchange | Solana | $0.66M | LOW-MED | **ASSIGNED** | README §4; solana-sui.md |
| 24 | README | LOW#12 Hylo router | Solana | $37.6M | LOW; route unresolved | **ASSIGNED** | README §4; solana-sui.md |
| 25 | README | closed-lead TurboFlow | Solana | $6.7M | on-curve upgrade key | **ASSIGNED** | README §4; solana-sui.md |
| 26 | README | closed-lead NodeDAO | Ethereum | ~$0 liquid | frozen-oracle dead pool | **README-CLOSED** | README §4; lst-cluster.md |
| 27 | README | closed-lead Solstice | Solana | $4.59M eUSX | donation-neutral | **ASSIGNED** | README §4; solana-sui.md |
| 28 | README | uncovered Project 0 | Solana | $59M | marginfi-v2 fork | **ASSIGNED** | tracker §COVERAGE; solana-sui.md |
| 29 | README | uncovered GMX Solana | Solana | $26.5M | audited 2026-10-09 | **ASSIGNED** | tracker §COVERAGE; solana-sui.md |
| 30 | README | uncovered Perena | Solana | $14.67M | hinted-swap | **ASSIGNED** | tracker §COVERAGE; solana-sui.md |
| 31 | README | uncovered Streamflow | Solana | $13.3M | old audited vesting | **ASSIGNED** | tracker §COVERAGE; solana-sui.md |
| 32 | README | V1 Derive V3 | Ethereum | $175.9M | $0 proof-gated | **README-CLOSED** | README §5; fresh-deep.md |
| 33 | README | V2 Theo thUSD | Ethereum | $132M | $0 permissioned mint | **README-CLOSED** | README §5; fresh-deep.md |
| 34 | README | V3 Zoo Finance / InfraredBribeVaultV2 | Berachain | dust | all vaults closed() | **README-CLOSED** | README §5; accounting.md |
| 35 | README | V4 GoldPesa GPXHooks class | Base | $0 | 10,112 hooks scanned | **README-CLOSED** | README §5; accounting.md |
| 36 | README | V5 Frax Ether (sfrxETH) | Ethereum | $101M | donation-immune fork-proven | **README-CLOSED** | README §5; lst-cluster.md |
| 37 | README | V5 stake.link liquid | Ethereum | $82.7M | internal counter | **README-CLOSED** | README §5; lst-cluster.md |
| 38 | README | V5 Lorenzo sUSD1+ | BSC | ~$80M | net-negative | **README-CLOSED** | README §5; lst-cluster.md |
| 39 | README | V5 Wise Token | Ethereum | $66M | virtual sharePrice | **README-CLOSED** | README §5; lst-cluster.md |
| 40 | README | V5 Origin Ether (OETH) | ETH/Base | $82M | 1:1, rebase gated | **README-CLOSED** | README §5; lst-cluster.md |
| 41 | README | V5 Mantle Restaking | Ethereum | $38.98M | fork net 0 wei | **README-CLOSED** | README §5; lst-cluster.md |
| 42 | README | V5 Veno Finance (LCRO) | Cronos | $34M | ROLE_BOT-gated | **README-CLOSED** | README §5; lst-cluster.md |
| 43 | README | V6 AtomicQueue solve (8 instances) | ETH/Arb/Poly/Sonic/HyperEVM | $0 at head | fork-proven mechanism | **README-CLOSED** | README §5; caller-target.md |
| 44 | README | V7 Internet Token LiquidityUnifier | Base | $0 | mint role revoked | **README-CLOSED** | README §5; caller-target.md |
| 45 | README | V8 Unverified-impl proxies (65) | multi | $0 aggregate | 11 decompiled | **README-CLOSED** | README §5; unverified-impl.md |
| 46 | README | V9 Aragon-legacy vaults | Ethereum | $0 today | mechanism fork-proven | **README-CLOSED** | README §5; gov-capture.md |
| 47 | README | V10 X100 clones | 16 chains | none | event-signature scan | **README-CLOSED** | README §5; gov-capture.md |
| 48 | README | V11 Argus World | Arc 5042 | $931k | audited launchpad | **README-CLOSED** | README §5; fresh-deep.md |
| 49 | README | V12 Pons V2 launchpad | Robinhood 4663 | ~$0.3–3.3M | read end-to-end | **README-CLOSED** | README §5; fresh-deep.md |
| 50 | README | V13 Forest Road Vault | Ethereum | $2.5M | role-gated | **README-CLOSED** | README §5; fresh-deep.md |
| 51 | README | V14 The Moats | multi | $1.24M | MasterChef | **README-CLOSED** | README §5; fresh-deep.md |
| 52 | README | V15 Shift DeFi | Ethereum | $1.18M | operator-gated | **README-CLOSED** | README §5; fresh-deep.md |
| 53 | README | V16 Statics Protocol | Robinhood 4663 | $528k | solvency-checked | **README-CLOSED** | README §5; fresh-deep.md |
| 54 | README | V17 Mosh | Robinhood 4663 | $0.32M | prior-corpus | **README-CLOSED** | README §5; fresh-deep.md |
| 55 | README | V18 Bridges (~1,470) | multi | $0 E-U | CCTP/SODAX/LZ etc | **README-CLOSED** | README §5; bridges.md |
| 56 | README | V19 Hylo update_lst_prices | Solana | $0 | registry-bound | **README-CLOSED** | README §5; solana-sui.md |
| 57 | README | V20 Solstice YieldVault | Solana | $0 | donation-neutral | **README-CLOSED** | README §5; solana-sui.md |
| 58 | README | C1 AlpsCon V9 | BSC | ~$7.2k | gate closed | **PRIOR-COVERED** | README §6; real-time.md |
| 59 | README | C2 BSC DEX router 0xa331fde0 | BSC | 0 native | impl upgraded; needs probe | **PRIOR-PARTIAL** | README §6; caller-target.md |
| 60 | README | C3 Bitget unverified-impl FP | multi | $249M | 3-source gate | **LANE-CLOSED** | README §6; unverified-impl.md |
| 61 | README | C4 Internet Token mint revoked | Base | $0 | role revoked | **README-CLOSED** | README §6; caller-target.md |
| 62 | README | C5 NodeDAO frozen-oracle | Ethereum | dead pool | not a drain | **README-CLOSED** | README §6; lst-cluster.md |
| 63 | README | C6 Lorenzo stale-NAV | BSC | $0 | 2-period lockup | **README-CLOSED** | README §6; lst-cluster.md |
| 64 | README | C7 Yapeswap zero-quorum gov | Ethereum | attacker-owned | not a fork-math bug | **LANE-CLOSED** | README §6; real-time.md |
| 65 | real-time | KolanHook | Ethereum | $3.1k drained | CLOSED | **PRIOR-COVERED** | real-time.md #1; ZH4P6 |
| 66 | real-time | Affluent | TON | $1.05M | off-chain/backing drained | **NOT-A-PROTOCOL** | real-time.md #2; ZH4P4 FP |
| 67 | real-time | Bofur Capital | Ethereum | $2M DAI | phishing/key | **NOT-A-PROTOCOL** | real-time.md #3 |
| 68 | real-time | Pirate Chain | Pirate L1 | 39.8M ARRR | L1 consensus | **NOT-A-PROTOCOL** | real-time.md #4; ZH4P2 |
| 69 | real-time | Cysic bridge | BSC→ETH | 10M CYS | off-chain DB/halted | **NOT-A-PROTOCOL** | real-time.md #5 |
| 70 | real-time | Qubic | Qubic | $1.3M | wallet-side RNG | **NOT-A-PROTOCOL** | real-time.md #6 |
| 71 | real-time | Coffer | Solana | $0.70 | rounding dust | **NOT-A-PROTOCOL** | real-time.md #7 |
| 72 | real-time | AlpsCon AI Trade Hub V6/V9 | BSC | $7.2k | whitelist closed | **PRIOR-COVERED** | real-time.md #8; ZH4P2/P5 |
| 73 | real-time | Slice FundsModule | Base | ~$451 | proxy re-pointed | **PRIOR-COVERED** | real-time.md #9; ZH4P4 |
| 74 | real-time | TIP / TIPMine | BSC | $0 | pool drained | **PRIOR-COVERED** | real-time.md #10; ZH4P6 |
| 75 | real-time | NEM / NemTokenV2 | BSC | ~$1.79k | prior-covered | **PRIOR-COVERED** | real-time.md #11; ZH4P4 |
| 76 | real-time | Swell (swETH/rswETH) | multi | ~$6M exposure | BOT-key; paused | **NOT-A-PROTOCOL** | real-time.md #12 |
| 77 | real-time | CoinDCX | TRON | $15.99M | CEX | **NOT-A-PROTOCOL** | real-time.md #13 |
| 78 | real-time | MORPHO EIP-7702 drain | Ethereum | ~$2.3M | key/delegation | **NOT-A-PROTOCOL** | real-time.md #14 |
| 79 | real-time | WAX Multi-Chain Bridge | WAX | $90.5k | patched 10-22 | **PRIOR-COVERED** | real-time.md #15; bridges.md |
| 80 | real-time | Arkadiko | Stacks | $1.43M→$138k | governance; non-EVM | **NOT-A-PROTOCOL** | real-time.md #16 |
| 81 | real-time | Initia (MoveVM) | Initia | ~$2.7M | chain-level; halted | **NOT-A-PROTOCOL** | real-time.md #17 |
| 82 | real-time | Kimchi Token | Solana | ~$385k | KOL rug | **NOT-A-PROTOCOL** | real-time.md #18 |
| 83 | real-time | X100 (Freezer/DexTreasury) | Ethereum | $4.85M taken | residual $0 | **README-CLOSED** | real-time.md #19; gov-capture.md |
| 84 | real-time | Yapeswap (WorkersUnion gov) | Ethereum | attacker-owned | $0 E-U today | **LANE-CLOSED** | real-time.md #20 |
| 85 | real-time | F1 Yapeswap / WorkersUnion | Ethereum | 10.52 ETH attacker | attacker-owned | **LANE-CLOSED** | real-time.md (C) F1 |
| 86 | real-time | F2 Initia L1 / MoveVM | Initia | 1,135 ETH at-large | not E-U | **NOT-A-PROTOCOL** | real-time.md (C) F2 |
| 87 | real-time | F3 Cosmos EVM GHSA-7g4w | Cosmos-EVM | $14.8M | structural; patch 08-19 | **LANE-CLOSED** | real-time.md (C) F3 |
| 88 | real-time | F4 AlpsCon V6/V9 | BSC | $7.2k | gate closed | **PRIOR-COVERED** | real-time.md (C) F4 |
| 89 | real-time | F5 Base DeFi Vault | Base | $6M stolen | insider multisig | **NOT-A-PROTOCOL** | real-time.md (C) F5 |
| 90 | real-time | F6 carry-over monitors | multi | — | monitors | **README-CLOSED** | real-time.md (C) F6 |
| 91 | real-time | Retro Balancer V1 BPool DPI | Ethereum | $234k | forks net $0 | **README-CLOSED** | real-time.md retro; ZH4P6 |
| 92 | real-time | Retro Cosmos EVM | Cosmos-EVM | $14.8M | patch shipped | **LANE-CLOSED** | real-time.md retro |
| 93 | real-time | Retro MakerDAO legacy keeper | Ethereum | $543k | drained | **PRIOR-COVERED** | real-time.md retro; ZH4 B2 |
| 94 | real-time | Retro Liquid Network | Bitcoin L2 | ~$319M | incident | **NOT-A-PROTOCOL** | real-time.md retro |
| 95 | real-time | Retro Verus | Verus | — | incident | **NOT-A-PROTOCOL** | real-time.md retro |
| 96 | fresh-detector | X100 Freezer 0x79f35a33 | Ethereum | residual $0 | sell-capped | **README-CLOSED** | fresh-detector.md row1 |
| 97 | fresh-detector | Yapeswap YapeFactory | Ethereum | $0 | executed | **LANE-CLOSED** | fresh-detector.md row2 |
| 98 | fresh-detector | OrbitNativeOFTAdapter 0xe4103e80 | ApeChain | 876,645 APE | owner-gated 2024 | **LANE-CLOSED** | fresh-detector.md row3 |
| 99 | fresh-detector | PendingContributions 0xf058EE35 | Ethereum | 91.23 ETH | caller-scoped stuck | **PRIOR-COVERED** | fresh-detector.md row4; github_stuck_funds |
| 100 | fresh-detector | APEPredicts 0xF609394F | ApeChain | 30,921 APE | P2 gov; sub-bar | **ASSIGNED** | fresh-detector.md row5 |
| 101 | fresh-detector | CashOrCrash 0x8c63d2a7 | ApeChain | 17,349 APE | P9/P6; dust | **ASSIGNED** | fresh-detector.md row6 |
| 102 | fresh-detector | House 0x2054709F | ApeChain | 15,103 APE | dust | **ASSIGNED** | fresh-detector.md row6 |
| 103 | fresh-detector | GameApeVault 0xf467d9Aa | ApeChain | $72 | dust | **ASSIGNED** | fresh-detector.md row6 |
| 104 | fresh-detector | BSC …ffff token template (20+) | BSC | <$5k each | scam/honeypot | **NOT-A-PROTOCOL** | fresh-detector.md row7 |
| 105 | fresh-detector | Base ContentCoin template (30+) | Base | dust | scam template | **NOT-A-PROTOCOL** | fresh-detector.md row8 |
| 106 | fresh-detector | xXx_bank 0x22C8553B | Ethereum | 5 ETH | caller-scoped | **LANE-CLOSED** | fresh-detector.md row9 |
| 107 | fresh-detector | MindVault 0x26B1E19B | Ethereum | 0.09 ETH | onlyLiquidity | **LANE-CLOSED** | fresh-detector.md row10 |
| 108 | fresh-detector | ZK Pool 0x77b5EaBe | Ethereum | 0.2 ETH | proof-gated | **LANE-CLOSED** | fresh-detector.md row11 |
| 109 | fresh-detector | LlamaPay/V3Migrator/Rango/Bebop/Hypervisor etc | scroll/apechain | $0–10 | standard infra | **LANE-CLOSED** | fresh-detector.md row12 |
| 110 | fresh-detector | 9,667 fresh proxies | multi | 593 funded | Safe/OZ proxies | **LANE-CLOSED** | fresh-detector.md §4 |
| 111 | fresh-deep | Prosper Alpha | Pharos 1672 | $512k | market impl unread | **ASSIGNED** | fresh-deep.md row1 |
| 112 | fresh-deep | Forward Industries / Definity / Raiku / Japan Staked SOL | Solana | $281M/$31.3M/$18.1M/$7.2M | Sanctum LSTs | **README-CLOSED** | fresh-deep.md row2 |
| 113 | fresh-deep | Hive Protocol | BSquared 223 | $234M | not located | **ASSIGNED** | fresh-deep.md row3 |
| 114 | fresh-deep | Derive V3 | Ethereum | $175.9M | proof-gated | **README-CLOSED** | fresh-deep.md row4 |
| 115 | fresh-deep | Theo thUSD | Ethereum | $132.2M | permissioned mint | **README-CLOSED** | fresh-deep.md row5 |
| 116 | fresh-deep | Argus World | Arc 5042 | $931k | audited | **README-CLOSED** | fresh-deep.md row6 |
| 117 | fresh-deep | Pons V2 launchpad | Robinhood 4663 | $0.3–3.3M | read end-to-end | **README-CLOSED** | fresh-deep.md row7 |
| 118 | fresh-deep | Statics Protocol | Robinhood 4663 | $528k | prior-corpus confirm | **README-CLOSED** | fresh-deep.md row8 |
| 119 | fresh-deep | Forest Road Vault | Ethereum | $2.5M | role-gated | **README-CLOSED** | fresh-deep.md row9 |
| 120 | fresh-deep | The Moats | multi | $1.24M | MasterChef | **README-CLOSED** | fresh-deep.md row10 |
| 121 | fresh-deep | Shift DeFi | Ethereum | $1.18M | operator-gated | **README-CLOSED** | fresh-deep.md row11 |
| 122 | fresh-deep | Archery V3 | Arc 5042 | $613k | Algebra fork; empty V2 | **LANE-CLOSED** | fresh-deep.md row12 |
| 123 | fresh-deep | Risk-Curator cluster (Nonce/NEMO/DAMM/Hub/Odyssey/DeTrade/722) | multi | $603M | Lagoon/Veda/Upshift/Midas | **LANE-CLOSED** | fresh-deep.md row13 |
| 124 | fresh-deep | Hyperliquid Earn | HyperCore | $1.43B | no EVM contract | **ASSIGNED** | fresh-deep.md row14 |
| 125 | fresh-deep | Bittensor dTAO | Bittensor | $441.6M | non-EVM | **NOT-A-PROTOCOL** | fresh-deep.md row15 |
| 126 | fresh-deep | Lighter LLP | zkLighter | $96.7M | no EVM vault | **NOT-A-PROTOCOL** | fresh-deep.md row16 |
| 127 | fresh-deep | xALPH (LST) | Alephium | $644k | non-EVM unread | **ASSIGNED** | fresh-deep.md row17 |
| 128 | fresh-deep | Alpend | Canton | $2.09M | non-EVM unread | **ASSIGNED** | fresh-deep.md row18 |
| 129 | fresh-deep | BitSafe CBTC | Bitcoin | $3.28M | script/off-chain | **ASSIGNED** | fresh-deep.md row19 |
| 130 | fresh-deep | Longbow | Robinhood 4663 | $3.30M | carry-over P6-01 | **PRIOR-COVERED** | fresh-deep.md row20 |
| 131 | fresh-deep | cirBTC | Bitcoin | $37.4M | custodial issuer | **ASSIGNED** | fresh-deep.md §4 |
| 132 | fresh-deep | Wildcat Protocol | ETH/Plasma | $14.5M | by-design credit | **ASSIGNED** | fresh-deep.md §4 |
| 133 | fresh-deep | Bucket Protocol V2 | Sui | $27.7M | not read | **ASSIGNED** | fresh-deep.md §4 |
| 134 | fresh-deep | Morpho Midnight | multi | $8.6M | parked | **PRIOR-COVERED** | fresh-deep.md §4; residual-recon |
| 135 | fresh-deep | KTON / SUN.io / POWERCITY | multi | — | known frameworks | **LANE-CLOSED** | fresh-deep.md §4 |
| 136 | caller-target | AtomicQueue 0xD45884B5 (ETH) | Ethereum | 486.9 liquidETH allowance | fork $0 at head | **PRIOR-COVERED** | caller-target.md row1 |
| 137 | caller-target | AtomicQueue 0xb149ef0f (Arb) | Arbitrum | 14,698 sETHFI | fork $0 | **PRIOR-COVERED** | caller-target.md row2 |
| 138 | caller-target | Internet Token LiquidityUnifier | Base | $0 | role revoked | **PRIOR-COVERED** | caller-target.md row3 |
| 139 | caller-target | FlashLoopAdapter | Ethereum | $0 | ZH2 closed | **PRIOR-COVERED** | caller-target.md row4 |
| 140 | caller-target | Slice FundsModule | Base | ~$451 | prior corpus | **PRIOR-COVERED** | caller-target.md row5 |
| 141 | caller-target | BSC DEX router 0xa331fde0 | BSC | 0 | impl upgraded | **PRIOR-PARTIAL** | caller-target.md row6 |
| 142 | caller-target | PancakeV3SwapHelper 0x222c8580 | BSC | 0 (dust) | inventory drained | **LANE-CLOSED** | caller-target.md row7 |
| 143 | caller-target | AtomicQueueUCP 0x228c44bb | HyperEVM | — | patched | **LANE-CLOSED** | caller-target.md row8 |
| 144 | caller-target | AtomicQueue 0x1cee/0x1479/0x8234/0x22f7 | multi | ~$0 | placeholders | **LANE-CLOSED** | caller-target.md row9 |
| 145 | caller-target | BonfireSwap / Transit Finance / Limit Break PP V2 | multi | drained | prior corpus | **PRIOR-COVERED** | caller-target.md §4 |
| 146 | accounting | Hyperliquid Earn | HyperCore | $1.43B | precompile-only | **ASSIGNED** | accounting.md row1 |
| 147 | accounting | Zoo Finance / InfraredBribeVaultV2 | Berachain | dust | closed()==true | **README-CLOSED** | accounting.md row2 |
| 148 | accounting | BitBay UsdcDaiV4Vault family | Polygon | victim drained | siblings inconclusive | **PRIOR-COVERED** | accounting.md row3; ZH3-H6; childB (all siblings 0 DAI/USDC, non-vault) |
| 149 | accounting | GoldPesa GPXHooks class | Base | $0 | 10,112 hooks scanned | **README-CLOSED** | accounting.md row4 |
| 150 | accounting | Lazy Summer / FleetCommander Ark class | Ethereum | $6.04M taken | Summer.fi fixed; class open | **OPEN** | accounting.md row5 |
| 151 | accounting | Hyperbeat Earn | HyperEVM 999 | $18.4M | strategist-driven | **ASSIGNED** | accounting.md row6 |
| 152 | accounting | Goldilocks Goldivaults | Berachain | ~$527k | all view calls revert | **LANE-CLOSED** | accounting.md row7 |
| 153 | accounting | GrowiHF | HyperCore | ~$13.5M | HyperCore custody | **NOT-A-PROTOCOL** | accounting.md row8 |
| 154 | accounting | Plasma Saving Vaults | Plasma | ~$31.8M | curator-gated | **PRIOR-COVERED** | accounting.md row9 |
| 155 | accounting | DexFi Aggregator Vault V2 | multi | ~$2.75M | NOT REACHED | **ASSIGNED** | accounting.md row10 |
| 156 | accounting | CGO Finance | Cronos | ~$1.01M | NOT REACHED | **ASSIGNED** | accounting.md row11 |
| 157 | accounting | Neutral Trade | Solana/HyperCore | ~$23M | curator/permissioned | **NOT-A-PROTOCOL** | accounting.md row12 |
| 158 | accounting | Concrete | Berachain/Katana | ~$1.25B | institutional | **NOT-A-PROTOCOL** | accounting.md row13 |
| 159 | accounting | Felix Vaults / Liminal Basis / Project X | HyperCore/EVM | $32.1M/$20.9M/$33.7M | HyperCore/audited | **NOT-A-PROTOCOL** | accounting.md row14 |
| 160 | accounting | Nado Spot / Tydro / Curvance | Ink/Monad | $50.5M/$131M/$131.6M | prior corpus forks | **PRIOR-COVERED** | accounting.md row15 |
| 161 | accounting | LST/yield cluster ×8 | multi | $32–118M | not read this pass | **README-CLOSED** | accounting.md row16; lst-cluster.md |
| 162 | oracle | wsNET/USDG Morpho Blue | Robinhood 4663 | $305,991 cap | CRITICAL | **README-FINDING** | oracle.md row1; wsnet*.md |
| 163 | oracle | HyperLend core pool | HyperEVM 999 | $302.3M | LTV 0%/0.1% | **ASSIGNED** | oracle.md row2 |
| 164 | oracle | Morpho wSPYx/AUSD | Ethereum | $478k collat | $1,306 free liq | **ASSIGNED** | oracle.md row3 |
| 165 | oracle | LayerBank | Robinhood 4663 | $3.3M borrow | stale-accurate | **ASSIGNED** | oracle.md row4 |
| 166 | oracle | HyperLend isolated pairs | HyperEVM 999 | ~$50k | maxOracleDelay 7–70 d | **ASSIGNED** | oracle.md row5 |
| 167 | oracle | dTRINITY dLEND | Fraxtal | <=$947k siblings | patched | **ASSIGNED** | oracle.md row6 |
| 168 | oracle | Impermax V2 | multi | ~$579k | extractable <$10k | **LANE-CLOSED** | oracle.md row7 |
| 169 | oracle | Curvance | Monad 143 | $131.6M | heartbeat+deviation | **LANE-CLOSED** | oracle.md row8 |
| 170 | oracle | Moonwell | Base | — | corpus-covered | **PRIOR-COVERED** | oracle.md negatives |
| 171 | oracle | Reservoir Protocol (rUSD) | multi | $69.6M | not E-U (PSM) | **LANE-CLOSED** | oracle.md negatives |
| 172 | oracle | Felix / Ripe / Kaskad / Aave Horizon | multi | — | freshness-checked/allowlisted | **LANE-CLOSED** | oracle.md negatives |
| 173 | oracle | Edel V1/V2 | Ethereum | $859 | $0 reserves | **LANE-CLOSED** | oracle.md negatives |
| 174 | oracle | Ondo/Backed equity Morpho markets | multi | <$3.5k borrow | sub-bar | **LANE-CLOSED** | oracle.md negatives |
| 175 | oracle | Robinhood-Chain Morpho equity markets | Robinhood 4663 | $1.69M debt | pass-6 closed | **PRIOR-COVERED** | oracle.md negatives |
| 176 | oracle | RH Chain Zona/Paboxo/Own/Gage/Borro | Robinhood 4663 | sub-bar | sub-bar TVL | **LANE-CLOSED** | oracle.md negatives |
| 177 | oracle | 2026 BSC spot-price cluster (MOKE/LOOPSDAO/42DAO/DLMC/FoxMarket/BeatXswap/JB) | BSC | — | no funded lending sibling | **LANE-CLOSED** | oracle.md negatives |
| 178 | oracle | LayerBank-BSC / BitU / Kine | BSC | — | role-gated / fair-LP | **LANE-CLOSED** | oracle.md negatives |
| 179 | oracle | Tarot | Kava | $547k | LP oracle | **LANE-CLOSED** | oracle.md negatives |
| 180 | oracle | Teller V2 PriceAdapterUniswapV2 | — | $0.87M book | not deployed (uses V3/Aero) | **LANE-CLOSED** | oracle.md negatives |
| 181 | oracle | Exactly PriceFeedPool | — | — | display-only | **LANE-CLOSED** | oracle.md negatives |
| 182 | oracle | Silo V2 / 40 Acres / Revert Lend / Fira / QiDao / Sumer / Avalon / Abracadabra GM | multi | — | verified-safe | **LANE-CLOSED** | oracle.md negatives |
| 183 | oracle | Flying Tulip Lend | ETH/Sonic/BNB | ≈$9.17M | oracle located (Chainlink) | **ASSIGNED** | oracle.md negatives; childC (OracleRouterChainlink impl 0xefd7d547…) |
| 184 | oracle | Parallel V3 | 4 chains | ≈$0.91M | EIP-2535 Diamond located | **ASSIGNED** | oracle.md negatives; childC (facet impl 0xf659fac0…) |
| 185 | oracle | Sturdy V2 | Mode/ETH/Linea/Flow/OP | ~$0.23M (Sei $0) | unresolved; oracle located | **ASSIGNED** (PRIOR-PARTIAL: pass4 closed only the Sei leg) | oracle.md negatives; childC |
| 186 | gov-capture | Aragon-legacy funded-vault class | Ethereum | 227.3 ETH | ACL escalation fork-proven | **ASSIGNED** | gov-capture.md row1 |
| 187 | gov-capture | Aragon ANY-open newVote DAOs | Ethereum | $0.03–0.70 ETH | token illiquid | **ASSIGNED** | gov-capture.md row2 |
| 188 | gov-capture | Aragon DAO 0x2de83b50 (ANT) | Ethereum | 2.20 ETH | EOA-gated create | **LANE-CLOSED** | gov-capture.md row3 |
| 189 | gov-capture | Standard governors (Bravo/OZ) | multi | $0.9M–$1.9B | snapshot flash-proof | **PRIOR-COVERED** | gov-capture.md row4; pass2 |
| 190 | gov-capture | X100 code clones | 16 chains | none | event scan | **README-CLOSED** | gov-capture.md row5 |
| 191 | gov-capture | Senate/Council/Governor-named | 9 chains | — | name noise | **LANE-CLOSED** | gov-capture.md row6 |
| 192 | gov-capture | HAI | Optimism | $122k | prior-corpus | **PRIOR-COVERED** | gov-capture.md row7; ZH4-01 |
| 193 | gov-capture | Aragon DAO 0xca6c0111 (Solace) | Ethereum | 0.028 ETH | minAQ 51% dust | **LANE-CLOSED** | gov-capture.md §3 |
| 194 | gov-params | SudoGovernor | Ethereum | $537.9k | no timelock; illiquid | **ASSIGNED** | gov-params.md row1 |
| 195 | gov-params | Unlock Protocol | Base | ~$38k | cheapest capture | **ASSIGNED** | gov-params.md row2 |
| 196 | gov-params | Internet Token | Base | ~$339k | token dead | **ASSIGNED** | gov-params.md row3 |
| 197 | gov-params | Threshold | Ethereum | $1.42M | ratio 1.5; illiquid | **LANE-CLOSED** | gov-params.md row4 |
| 198 | gov-params | Seamless | Base | $59.1k | prior-corpus wind-down | **LANE-CLOSED** | gov-params.md row5 |
| 199 | gov-params | Lazy Summer | Base | $504k | cost > treasury | **LANE-CLOSED** | gov-params.md row6 |
| 200 | gov-params | AWE | Base | $308k | cost ≫ | **LANE-CLOSED** | gov-params.md row7 |
| 201 | gov-params | Diva | Ethereum | $0 (no market) | no liquidity | **LANE-CLOSED** | gov-params.md row8 |
| 202 | gov-params | Radworks | Ethereum | $11.0M | pass-2 | **PRIOR-COVERED** | gov-params.md row9 |
| 203 | gov-params | ENS | Ethereum | $55.7M | Security Council | **LANE-CLOSED** | gov-params.md row10 |
| 204 | gov-params | Compound | Ethereum | $6.6M | Proposal Guardian | **LANE-CLOSED** | gov-params.md row11 |
| 205 | gov-params | Gitcoin | Ethereum | $3.55M | guardian+veto | **PRIOR-COVERED** | gov-params.md row12; pass2 recon |
| 206 | gov-params | Venus | BSC | $1.5B TVL | guardian/vault-staked | **LANE-CLOSED** | gov-params.md row13 |
| 207 | gov-params | Inverse | Ethereum | $113M | guardian; pass-2 recon | **PRIOR-COVERED** | gov-params.md row14 |
| 208 | gov-params | Uniswap | Ethereum | ~$1.9B | cost | **LANE-CLOSED** | gov-params.md row15 |
| 209 | gov-params | GMX | Arbitrum | $0 | empty timelock | **LANE-CLOSED** | gov-params.md row16 |
| 210 | gov-params | Silo | Ethereum | $0 | empty timelock | **LANE-CLOSED** | gov-params.md row17 |
| 211 | gov-params | OpenDollar | Arbitrum | $7.7k TVL | no value | **LANE-CLOSED** | gov-params.md row18 |
| 212 | gov-params | KTON / Ring DAO | Darwinia | <$1k | no value | **LANE-CLOSED** | gov-params.md row19 |
| 213 | gov-params | aixbt / virtuals / rn / onchainaustria / ark | multi | $0 | no treasury | **LANE-CLOSED** | gov-params.md row20 |
| 214 | gov-params | 27 further DeGov DAOs | multi | $0–$60k | CLOSED/LOW | **LANE-CLOSED** | gov-params.md row— |
| 215 | lst-cluster | NodeDAO nETH | Ethereum | ~$0 liquid | frozen-oracle; holder-gated | **README-CLOSED** | lst-cluster.md row1 |
| 216 | lst-cluster | Lorenzo sUSD1+ | BSC | ~$80M | net-negative | **README-CLOSED** | lst-cluster.md row2 |
| 217 | lst-cluster | Mantle Restaking | Ethereum | $38.98M | fork net 0 wei | **README-CLOSED** | lst-cluster.md row3 |
| 218 | lst-cluster | Frax Ether (sfrxETH) | Ethereum | $101M | donation-immune | **README-CLOSED** | lst-cluster.md row4 |
| 219 | lst-cluster | Origin Ether (OETH) | ETH/Base | $82M | 1:1; rebase gated | **README-CLOSED** | lst-cluster.md row5 |
| 220 | lst-cluster | Veno Finance (LCRO) | Cronos | $34M | ROLE_BOT-gated | **README-CLOSED** | lst-cluster.md row6 |
| 221 | lst-cluster | stake.link liquid | Ethereum | $82.7M | internal counter | **README-CLOSED** | lst-cluster.md row7 |
| 222 | lst-cluster | Wise Token | Ethereum | $66M | virtual sharePrice | **README-CLOSED** | lst-cluster.md row8 |
| 223 | solana-sui | Solstice YieldVault (eUSX) | Solana | $4.59M | cooldown/vesting untested | **ASSIGNED** | solana-sui.md row1 |
| 224 | solana-sui | Hylo (exchange/earn/router) | Solana | $37.6M | update_lst_prices closed | **ASSIGNED** | solana-sui.md row2 |
| 225 | solana-sui | Archer Exchange | Solana | $0.66M | fresh unaudited | **ASSIGNED** | solana-sui.md row3 |
| 226 | solana-sui | Project 0 (marginfi-v2) | Solana | $59.0M | fork of excluded | **ASSIGNED** | solana-sui.md row4 |
| 227 | solana-sui | GMX Solana / GMTrade | Solana | $26.5M | audited 2026-10-09 | **ASSIGNED** | solana-sui.md row5 |
| 228 | solana-sui | Perena (Numeraire) | Solana | $14.67M | hinted-swap | **ASSIGNED** | solana-sui.md row6 |
| 229 | solana-sui | Streamflow | Solana | $13.3M | old audited | **ASSIGNED** | solana-sui.md row7 |
| 230 | solana-sui | TurboFlow Perps | Solana | $6.7M | plain-key upgrade | **ASSIGNED** | solana-sui.md row8 |
| 231 | solana-sui | Loopscale Curation | Solana | $7.07M | pass-5 open lead | **ASSIGNED** | solana-sui.md row9 |
| 232 | solana-sui | RateX | Solana | $2.37M | PT/YT pricing | **ASSIGNED** | solana-sui.md row10 |
| 233 | solana-sui | Oro Finance | Solana | $2.30M | digital-gold NAV | **ASSIGNED** | solana-sui.md row11 |
| 234 | solana-sui | Solayer USD (sUSD) | Solana | $0.71M | yield-stablecoin NAV | **ASSIGNED** | solana-sui.md row12 |
| 235 | solana-sui | Omnipair | Solana | $0.66M | audited | **ASSIGNED** | solana-sui.md row13 |
| 236 | solana-sui | Sat Rush / Loyal Earn / TRUE DEX / Pascal / N1 Bridge / Byzanlink | Solana | $0.29M–$2.33M | pass-6 OPEN tail | **PRIOR-COVERED** | solana-sui.md row14; pass6-open-tail |
| 237 | solana-sui | Sui fresh cluster (AlphaFi/DipCoin/Bluefin/Kai/Suigar) | Sui | $0.17M–$2.32M | not disassembled | **ASSIGNED** | solana-sui.md row15 |
| 238 | solana-sui | Phase Delegation / Phase Stake | Solana | 1.1M SOL | ZH2B7 closed | **PRIOR-COVERED** | solana-sui.md negatives |
| 239 | solana-sui | Solana LST cluster (Definity/Raiku/Japan/Forward/Jito/Marinade/Sanctum) | Solana | — | stake-pool programs | **README-CLOSED** | solana-sui.md negatives |
| 240 | solana-sui | Kestrel / Tessera V / Cardboard / Pacifica / AlphaQ / Exponent / R25 / WaterX / Haedal / DiversiFi / Overpass / Zodial / GoonFi / BisonFi / Scorch / Aquifer / Umbra / Flipcash / marginfi / Jupiter Lend / Save / Drift / DefiTuna / Loopscale core | Solana | — | prior-pass closed | **PRIOR-COVERED** | solana-sui.md negatives |
| 241 | solana-sui | Webot / Circle Bitcoin / BitSafe | Solana/BTC | — | off-chain/custodial | **NOT-A-PROTOCOL** | solana-sui.md negatives |
| 242 | unverified-impl | Bitget omnibus cluster (3 proxies) | Ethereum | $249M | signer-registry no-op | **LANE-CLOSED** | unverified-impl.md §2 pitch1 |
| 243 | unverified-impl | 15-owner multisig treasury 0x54805468 | Ethereum | $126–184M | 15-signer multisig | **LANE-CLOSED** | unverified-impl.md §2 pitch2 |
| 244 | unverified-impl | BSC UUPS omnibus pair | BSC | $94M | owner-gated upgrade | **LANE-CLOSED** | unverified-impl.md §2 pitch3 |
| 245 | unverified-impl | ERC-4626 vault 0x6926B434 (OP) | Optimism | $1.62M | standard 4626 | **LANE-CLOSED** | unverified-impl.md §3 |
| 246 | unverified-impl | 0x389f8B63 (Polygon) | Polygon | $3.9M | admin-gated proxy | **LANE-CLOSED** | unverified-impl.md §3 |
| 247 | unverified-impl | 0xBEE3211a (ETH) | Ethereum | $13.3M | registry-gated | **LANE-CLOSED** | unverified-impl.md §3 |
| 248 | unverified-impl | 0x3B4D794a (ZkLighter) | Ethereum | $580M | Etherscan-verified FP | **LANE-CLOSED** | unverified-impl.md §3 |
| 249 | unverified-impl | 0xFA103c21 (stale impl) | Ethereum | $3.2M | 32-byte impl | **LANE-CLOSED** | unverified-impl.md §3 |
| 250 | unverified-impl | Direct-unverified CEX/MM (Coinbase 10/Wintermute/etc) | multi | $252M/$65M/... | custody/MM | **NOT-A-PROTOCOL** | unverified-impl.md §1b |
| 251 | unverified-impl | **Unverified-impl proxy tail rows 13–22 (10 proxies)** | OP/Polygon/BSC/zkSync | $14k–$671k each (live re-read) | lane "scan"-only, not decompiled | **OPEN** | unverified-impl.md §1 rows13–22 |
| 252 | unverified-impl | Scroll proxies 0x25aB3Efd/0x740a7C5E/0x7BE980E3/0x7ba30C4c | Scroll | unvalued | Blockscout 403; unresolved | **OPEN** | unverified-impl.md §3 |
| 253 | bridges | USDT0 OAdapterUpgradeable | Ethereum | $3.198B | all live routes 3-of-3 DVN | **ASSIGNED** | bridges.md row0 |
| 254 | bridges | Circle Gateway (Minter+Wallet) | multi | $63.8M | signed-attestation; P-risk | **ASSIGNED** | bridges.md row1 |
| 255 | bridges | Payy RollupV1 + HonkVerifier | Ethereum | $710 | onlyProver-gated (not paused); Barretenberg class | **LANE-CLOSED** | bridges.md row2; childC (no other funded <v5.0.0 verifier; StealthPay/0G is bb5.x) |
| 256 | bridges | Symbiosis BridgeV2 BTC | BNB/ETH | $7.94 | halted | **LANE-CLOSED** | bridges.md row3 |
| 257 | bridges | Chainflip (Tron vault) | Tron | ~$12M | off-chain; upgraded | **LANE-CLOSED** | bridges.md row4 |
| 258 | bridges | Robinhood Chain Bridge | ETH→RH 4663 | $652.6M | standard Orbit | **LANE-CLOSED** | bridges.md row5 |
| 259 | bridges | SODAX (hub+spokes) | Sonic+~20 | ~$2.10M | child-C closed | **LANE-CLOSED** | bridges.md row6 |
| 260 | bridges | LayerZero V2 OApp/OFT + Hyperlane warp routes | 90+ | $11.17B/$75.7M | child-A closed | **LANE-CLOSED** | bridges.md row7 |
| 261 | bridges | Fresh EVM custom bridges (TxFlow/Hibachi/wTAO/pumpBTC/Keeta/1sec) | multi | $37.9M/$4.35M/$29.3M/$27.3M/$0.79M/$16.7k | child-B closed | **LANE-CLOSED** | bridges.md row8 |
| 262 | bridges | ioTube (TokenSafe) | Ethereum | ~$3.1M | EOA owner | **LANE-CLOSED** | bridges.md row9 |
| 263 | bridges | NEAR Intents (HOT Omni) | BSC/Near | recovered | patched | **LANE-CLOSED** | bridges.md row10 |
| 264 | bridges | WAX Multi-Chain Bridge | WAX | ~$1.5k | patched | **PRIOR-COVERED** | bridges.md row11 |
| 265 | bridges | Demex bridge (Carbon) | Demex | $0 | sunset | **LANE-CLOSED** | bridges.md row12 |
| 266 | bridges | Initia (LZ OFT adapters) | Initia→ETH | chain halted | MoveVM bug | **NOT-A-PROTOCOL** | bridges.md row13 |
| 267 | bridges | Katana Vault Bridge | ETH↔Katana | $27.7M | pass-1 B1 closed | **PRIOR-COVERED** | bridges.md row14 |
| 268 | bridges | Pacifica Bridge | Solana | $2.28M | pass-6 closed | **PRIOR-COVERED** | bridges.md row15 |
| 269 | bridges | Canonical L1↔L2 bridges (Arb/Base/OP/…24 chains) | multi | — | standard/upstream-audited | **LANE-CLOSED** | bridges.md §3 |
| 270 | bridges | LZ/CCIP/Axelar/Wormhole/Hyperlane/Polymer frameworks | multi | — | framework core sound | **LANE-CLOSED** | bridges.md §3 |
| 271 | bridges | Enosys / Alephium / Meter / Allbridge / Multichain / Nomad / Harmony / Coreum / Maya / SingularityNET | mixed | — | prior corpus | **PRIOR-COVERED** | bridges.md §3 |
| 272 | bridges | Sonic Gateway / PulseChain Omnibridge / Taiko / Aster / SoDEX / StandX / Gravity / Merlin / Endurance | mixed | — | pass-3 closed | **PRIOR-COVERED** | bridges.md §3 |
| 273 | bridges | Custodial BTC/XRP minters (Binance/Kraken/OKX/Coinbase/Circle-BTC/Bitget/Function/Solv/Lorenzo/Nexus/Lombard/FAssets/Unit) | BTC/XRP | — | permissioned mint | **NOT-A-PROTOCOL** | bridges.md §3 |
| 274 | bridges | CCTP v2 MessageTransmitterV2 | multi | — | attester+nonce | **LANE-CLOSED** | bridges.md §3 |
| 275 | bridges | Meson / Hashport / TeleSwap / ChainPort / Rosen / Butter / BoringDAO / Counterstake | mixed | $0.4–1.8M | owner/validator-gated spot-check | **LANE-CLOSED** | bridges.md §7 |
| 276 | bridges | N1 Exchange Bridge | Solana | $1.4M | pass-6-open-tail closed | **PRIOR-COVERED** | bridges.md §7; pass6-open-tail |
| 277 | bridges | STRATO / Mercata Bridge | multi | $1.4M | ZH2B6 H2-05 closed | **PRIOR-COVERED** | bridges.md §7 |
| 278 | bridges | Hibachi Bridge | Arbitrum | $4.3M | wave2/v16 closed | **PRIOR-COVERED** | bridges.md §7 |
| 279 | bridges | ADI Bridge | ETH→ADI | $6.1M | zkSync shared bridge | **LANE-CLOSED** | bridges.md §7 |
| 280 | bridges | Popdex Bridge | Arbitrum/Morph | $71.4M | wave-2 repeat | **PRIOR-COVERED** | bridges.md §7 |
| 281 | bridges | Stargate V2 / CCIP / Hyperlane | multi | — | framework | **LANE-CLOSED** | bridges.md §7 |
| 282 | child-A | Hyperlane TrustedRelayerIsm threshold-1 routes (~30) | multi | dust today (largest VRA/eth ≈$219) | needs relayer key (H-O) | **LANE-CLOSED** | _child_lz_hyperlane.md row1; childC (dust; H-O/P) |
| 283 | child-A | Hyperlane defaultIsm=TrustedRelayerIsm (moonriver/edgenchain/turkchain) | 3 chains | none | centralization | **LANE-CLOSED** | _child_lz_hyperlane.md row2 |
| 284 | child-A | EIP-7702-delegated trusted relayer 0x690f4e2f | Ethereum | ctUSD route (dust) | execute() reverts NotEntryPointOrSelf | **LANE-CLOSED** | _child_lz_hyperlane.md row3; childC (proved closed) |
| 285 | child-A | LayerZero V2 OApps (peer check) | all | n/a | no missing-peer | **LANE-CLOSED** | _child_lz_hyperlane.md row4 |
| 286 | child-A | LayerZero V2 DVN configs (448 OApps) | all | n/a | no active 1-of-1 | **LANE-CLOSED** | _child_lz_hyperlane.md row5 |
| 287 | child-B | txflow-bridge (Bridge2) | Arbitrum | $37.9M | prior-corpus re-verified | **PRIOR-COVERED** | _child_fresh_evm_bridges.md row1 |
| 288 | child-B | strato-bridge / Mercata | multi | $1.18M | prior-corpus re-verified | **PRIOR-COVERED** | _child_fresh_evm_bridges.md row2 |
| 289 | child-B | hibachi-bridge | Arbitrum | $4.35M | prior-corpus re-verified | **PRIOR-COVERED** | _child_fresh_evm_bridges.md row3 |
| 290 | child-B | circle-gateway | Ethereum | $63.84M | signed-attestation | **ASSIGNED** | _child_fresh_evm_bridges.md row4 |
| 291 | child-B | keeta-bridge | Base | ~$0.79M | observer quorum | **LANE-CLOSED** | _child_fresh_evm_bridges.md row5 |
| 292 | child-B | sodax spokes | multi | ≈$2.1M | validator+executor gate | **LANE-CLOSED** | _child_fresh_evm_bridges.md row6 |
| 293 | child-B | wtao | Bittensor/ETH | $29.3M | BRIDGE_ROLE EOA | **LANE-CLOSED** | _child_fresh_evm_bridges.md row7 |
| 294 | child-B | pumpbtc | BTC/ETH | $27.3M | onlyMinter | **LANE-CLOSED** | _child_fresh_evm_bridges.md row8 |
| 295 | child-B | 1sec | ICP/EVM | EVM $16.7k | below bar | **LANE-CLOSED** | _child_fresh_evm_bridges.md row9 |
| 296 | child-B | obeliskbtc / hemibtc | Bitcoin | $26.7M/$2.24M | BTC-only custody | **NOT-A-PROTOCOL** | _child_fresh_evm_bridges.md row11 |
| 297 | child-C | SODAX hub AssetManager recvMessage | Sonic 146 | $2.10M | executor+validator gate | **LANE-CLOSED** | _child_sodax.md path1 |
| 298 | child-C | SODAX spoke recvMessage | 12 EVM chains | ~$376.7k ETH | blocked | **LANE-CLOSED** | _child_sodax.md path2 |
| 299 | child-C | SODAX replay / cross-chain replay | Sonic/multi | — | receipts+chainId bound | **LANE-CLOSED** | _child_sodax.md paths3–4 |
| 300 | child-C | SODAX deployAsset / Wallet.executeStored | Sonic 146 | $0 direct | griefing only | **LANE-CLOSED** | _child_sodax.md paths5–6 |
| 301 | child-C | SODAX relay submit (off-chain split-tx) | off-chain | hub reserves | repo private; unverifiable | **LANE-CLOSED** | _child_sodax.md path8 |
| 302 | accounting | GoldPesa GPXHooks (class re-check) | Base | $0 | 10,112 hooks | **README-CLOSED** | accounting.md §3.2 |
