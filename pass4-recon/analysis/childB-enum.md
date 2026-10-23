# childB-enum — independent enumeration of every NAMED pass-4 candidate + prior-coverage detection

**Scope:** every named protocol/contract candidate across **all 16 lane files** in `zombie-hunt-iv/pass4/` (ranked tables, prose, negatives, dead-ends, watchlists).
**Method:** `bash zombie-hunt-iv/zh4-check.sh "<name>"` for every name + grep of the tracker corpus (`ci/ZH4P5/P4/P3/P2/ZH4/ZH3/ZH2B*/ZH2/TIER3-LOW/MONITOR-LIST/L2-*`), root-folder `ls -d`, and the pass1–5 / wave1–2 README closed lists.
**Exclusion discipline:** hits inside `llama_*`, `lane_*.tsv`, `gov/*`, `MASTER-BOARD` are DefiLlama/working data — **not counted** as prior verdicts. `MASTER-EXTRACTION-TABLE.md` and `ci/qc/*` are campaign disposition files (counted as prior coverage where they record a verdict).
**Mode:** read-only. No secrets. Point-in-time 2026-10-23.

Legend — Prior-coverage: `none` = no prior verdict found; `ZH4P4 tracker` = `ci/ZH4P4-RESULTS-TRACKER.md`; `MONITOR-LIST` = `ci/MONITOR-LIST.md`; `ZH2` = `zombie_hunt/ZOMBIE-HUNT-II.md`; `folder:x/` = kept root folder; `README` = `pass4/README.md`.

---

## A. Master table — every named candidate

| Name | Chain | Funds | Lane verdict | Prior-coverage (file or "none") | Note |
|---|---|---|---|---|---|
| Affluent / Factorial Finance | TON | ~$766k pool; ~$1.42M protocol | **HIGH** — unpatched incident, path unproven (affluent.md) | ZH4P4 tracker; ZH4P5 tracker; MONITOR-LIST; README | README P4-01; later reinvestigation → false positive / all backing drained |
| Affluent BasicPool `EQCrEHHG…` | TON | ~$766k | victim pool of P4-01 | parent Affluent (README) | sub-contract |
| Affluent AdvancedPool | TON | ~$342k | same family | parent Affluent (README) | sub-contract |
| Affluent EthenaPool | TON | ~$272k | same family | parent Affluent (README) | sub-contract |
| Affluent LendingVaultPool | TON | ~$24k | same family | parent Affluent (README) | sub-contract |
| Affluent StormUsdtPool | TON | ~$6.2k | same family | parent Affluent (README) | sub-contract |
| Affluent StormAdvancedPool | TON | ~$2.1k | same family | parent Affluent (README) | sub-contract |
| Affluent StormTonPool | TON | ~$0.16k | same family | parent Affluent (README) | sub-contract |
| Affluent TradoorAdvancedPool | TON | ~$0 | same family | parent Affluent (README) | sub-contract |
| Affluent Sentora-Wallet vault | TON | ~$1.27M | context custody | parent Affluent (README) | strategy vault |
| Affluent TON-Multiply-1 | TON | ~$722k | context custody | parent Affluent (README) | strategy vault |
| Affluent Gold-Multiply | TON | ~$290k | context custody | parent Affluent (README) | strategy vault |
| Affluent MultiplyVaults (V1/V2) | TON | $0.02–$21k each | 7 cleared; mint sink | parent Affluent (README) | confused-deputy sink |
| BMX Deli Swap | Base (+Mode) | ~$12.0k | **CLOSED** — 0/8 Highs live | ZH4P4 tracker; README; pass5/README | README "verified closed" |
| DeliHook `0x570A48F9…` | Base | ~$0 | fixed | parent BMX Deli (README) | component |
| DeliHookConstantProduct `0x95AFBC0F…` | Base | ~$0 | fixed | parent BMX Deli (README) | component |
| FeeProcessor `0x6506477D…` | Base | ~$83 | fixed | parent BMX Deli (README) | component |
| DailyEpochGauge `0xd8Df4f5a…` | Base | ~$307 | H-1/H-6 fixed | parent BMX Deli (README) | component |
| IncentiveGauge `0x59d7bFF1…` | Base | ~$29 | H-7 fixed | parent BMX Deli (README) | component |
| PositionManagerAdapter `0xfd9ca052…` | Base | ~$0 | H-1 fixed | parent BMX Deli (README) | component |
| BMX Voter `0xce9e7cf2…` | Base | ~$0.8k buffers | H-2/H-3 **present but Voter frozen** | ZH4P4 tracker; README; MONITOR-LIST | re-arm monitor |
| Fluid (DEX v2 money-market) H-1 | Ethereum | $0 in path | **CLOSED / FIXED** | ZH4P3/P4/P5 trackers; README | README closed |
| Fluid Money Market proxy `0xe3B7e3f4…` | Ethereum | $0 (unused) | fixed 0.8.34 module | parent Fluid (README) | component |
| Fluid V1 `FluidVaultT1` | multi | ~$900M | not affected by H-1 | ZH4P5 tracker | context |
| Yield Basis (yb-core / LT) H-1 | Ethereum | $0 in path | **CLOSED / FIXED** | pass5/README; README | README closed |
| Centrifuge V3.1 H-1 | Ethereum/multi | $0 in path | **CLOSED / FIXED** | ZH4P4/P5 trackers; README | README closed |
| Mellow Core / Flexible Vaults (6 Highs) | Ethereum (+Monad/RSK) | $0 from bugs | **CLOSED / FIXED** | ZH4P4 tracker; README; pass5/README | README closed |
| Mellow `RedeemQueue 0x0c139266…` etc | Ethereum | $0 | fixed | parent Mellow (README) | component |
| Recall IPC gateway (9 Highs) | Filecoin FVM | $0 | **CLOSED** — not on mainnet | ZH4P4/P5 trackers; README | README closed |
| Burve `SimplexDiamond 0xa1beD164…` | Berachain | $32k | **MED** acknowledged-unfixed H-5 | ZH4P4 tracker; MONITOR-LIST; README | P4-02 → later $0 (product conflation) |
| SimplexDiamond impl `0x223184e3…` | Berachain | $32k | same | ZH4P4 tracker | component |
| Peapods Finance H-1/H-2 | Ethereum | $0 in path (TVL $1.59M) | **CLOSED / FIXED** | README ("Peapods") | README closed |
| PodUnwrapLocker `0xaCE71C69…` | Ethereum | $0 | fixed | parent Peapods (README) | component |
| Tangent / USG H-1/H-2 | Ethereum | $0 in path ($3.83M TVL) | **CLOSED / FIXED** | README ("Tangent") | README closed |
| USG | Ethereum | — | part of Tangent | parent Tangent (README) | component |
| RAAC (Regnum Aurum) | ETH mainnet+Sepolia | $0 (audited code testnet-only) | **LOW / CLOSED** | README ("RAAC") | README closed |
| Regnum Aurum | Sepolia | $0 | testnet-only | parent RAAC (README) | component |
| Virtuals Protocol (6 Highs) | Base | large; audited code superseded | **LOW** (unverified) | none | code superseded by AgentFactoryV7 |
| Cabal LST H-01 | Initia | $2.77M | **LOW** (unverified, Move not diffed) | none | best remaining unverified lead |
| Notional Exponent | Ethereum | $182 | **CLOSED** (below bar) | README | README closed |
| Malda H-1 | (lending) | $0 (no live markets) | **CLOSED** | README | README closed |
| Gamma — Perpetual Vault | GMX chains | live addr not located | **LOW** | none | CodeHawks 20+ Highs |
| Zaros | Arbitrum | ~$0 (token dead) | **CLOSED** | README | README closed |
| Curve scrvUSD Storage Proofs | OP/Base/… | $0 (undeployed) | **CLOSED** | README ("Curve Oracle-V2") | README closed |
| BattleChain Confidence Pools | Cyfrin BattleChain | $0 (sandbox) | **CLOSED** (0 Highs) | none | teaching sandbox |
| Liquid Ron H-01 | (live) | ~$45k | **CLOSED** (mitigation confirmed) | none | — |
| IQ AI H-01 | — | — | **CLOSED** (all mitigated) | none | — |
| Thorwallet H-01/H-02 | — | — | **CLOSED** (mitigation confirmed; F-9 DoS only) | none | — |
| Ammplify | — | not on DefiLlama | **CLOSED** | README | README closed |
| Dango DEX | — | dead | **CLOSED** | README | README closed |
| Next Generation | Fantom | dead | **CLOSED** | none | — |
| Garden | multi | — | **CLOSED** | ZH2; TIER3-LOW; wave1 | prior-covered |
| Brix | — | — | **CLOSED** (0 Highs) | none | — |
| Covenant | — | — | **CLOSED** (0 Highs) | none | — |
| Flare-FAsset | Flare | — | **CLOSED** | README; wave2 | prior-covered |
| Upside | — | — | **CLOSED** (0 Highs) | wave2 | prior-covered |
| BitVault | — | — | **CLOSED** (0 Highs) | none | — |
| Succinct SP1 | — | — | **CLOSED** (circuit soundness, non-E-U) | none | not a contract drain |
| Initia rollup modules | Initia | — | **CLOSED** (L1→L2 DoS) | none | not E-U |
| ZetaChain H-2 | ZetaChain | — | **CLOSED** (state/precompile) | ZH1 FINDINGS; L2 trackers | prior-covered |
| Benqi Ignite | — | — | **CLOSED** (private contest) | none | no public findings |
| Remora (×2) | — | — | **CLOSED** (private contest) | ZH1 FINDINGS; L2-WATCHLIST; ZH4P5 | prior-covered |
| Starknet Staking (×2) | Starknet | — | **CLOSED** (private contest) | none | no public findings |
| Open Eden | — | — | **CLOSED** (private contest) | none | no public findings |
| Cyfrin Attester | — | — | **CLOSED** (private contest) | none | no public findings |
| Kuru AccountCore `0x264123a9…` | Monad | 5.16M MON + 270k USDC ≈ $380k | **LOW** (unverified clone) | ZH4P4 tracker; MONITOR-LIST; README | P4-03 → later $0 (OZ proxies) |
| Kuru MarginAccount `0x2A68ba18…` | Monad | incl. above | same | ZH4P4 tracker | component |
| Infrared deposits `0x9b6761bf…` | Berachain | $19.0M | **LOW** (unverified impl) | ZH4P4 tracker; MONITOR-LIST; README | P4-04 → later $0 (iBERA LST) |
| shMonad `0x1B68626d…` | Monad | 9.5M MON ≈ $213k | **LOW** (not deep-diffed) | none | verified ShMonad |
| Metropolis DLMM VaultFactory | Sonic | n/a (factory) | **LOW** | none | permissionless vault creation |
| D2 Finance VaultV3 (×16) | Berachain/HyperEVM | $12.44M sys | **CLOSED** (false positive) | ZH4P4 tracker; README | withdrawn |
| Kinetiq Earn BoringVault `0x9BA2EDc4…` | HyperEVM | 89k HYPE ≈ $7.19M | **CLOSED** (RolesAuthority) | MONITOR-LIST ("Kinetiq") | prior-covered via Kinetiq monitor |
| Kinetiq StakingManagerRouter | HyperEVM | 158k HYPE ≈ $12.79M | **CLOSED** (role-gated) | MONITOR-LIST ("Kinetiq") | prior-covered |
| Hyperbeat WithdrawManager | HyperEVM | 1,620 HYPE ≈ $131k | **CLOSED** | ZH4P3 tracker; pass3/README | prior-covered |
| Sonic Market BookManager | Sonic | 6,756 S ≈ $381 | **CLOSED** | none | v4-style singleton |
| Sturdy V2 DataProvider | Sei | $0 | **CLOSED** | none | empty market |
| Yuzu YuzuILPV3 | Plasma/Monad | $65M + $7.6M | **CLOSED** (role-gated) | wave1 | prior-covered |
| Reservoir Protocol (lending) | Monad/Plasma/Berachain | $60.9M Monad | **CLOSED** (role-gated) | none | distinct from GaslessReservoirEnabler |
| Silo V2 | Sonic/XDC | $0 (uninitialized none) | **CLOSED** | ZH4P3 tracker | prior-covered |
| ether.fi / Veda AtomicQueue `0xD45884…` | Ethereum | $0 (161 approvers drained) | **HIGH bug / $0** | ZH4P4 tracker; MONITOR-LIST; ZH4P3; ZH2 | README Tier3 row 4 |
| Reservoir GaslessReservoirEnabler `0x9B58fDAd…` | Polygon | $0 (201 drained) | **HIGH bug / $0** | ZH4P4 tracker; ZH2 | README Tier3 row 5 |
| BitBay UsdcDaiV4Vault `0x048E8831…` | Polygon | $0 | **MED / $0** | ZH3 tracker; MONITOR-LIST | prior-covered |
| Set Protocol RebalancingSetTokenV3 `0x54e8371C…` | Ethereum | $0 | **MED / $0** | ZH1; ZH4P5; wave1/wave2 | prior-covered |
| Likwid LikwidVault `0x065d449e…` | BSC | 17.7 BNB ≈ $13.2k | **HIGH code / LOW extractable** (gated) | ZH4P4 tracker; README | path exhausted |
| TIPMine `0x412c7bd2…` | BSC | $0 | **MED / $0** (drained) | none | fresh, not excluded |
| FlashLoopAdapter `0x16bb8B91…` | Ethereum | $0 (unused) | **HIGH / $0** | ZH2; wave1 | prior-covered |
| X7Finance X7Pioneer `0x70000299…` | Ethereum | 0.0216 ETH | **CLOSED** ($0) | none | — |
| GoldPesa hook `0x4519e2b0…` | Base | ~$0 | **CLOSED** (Z3-H5) | ZH3 tracker; MONITOR-LIST | prior-covered |
| MOKE / RELEASE | BSC | $0 | **CLOSED** | zombie_hunt/non_llama_and_directories.md | prior-covered |
| PositionManager `0x7cedB2e5…` | BSC | $0 | **CLOSED** | none | — |
| PrimeFinance pool `0xb339448E…` | HyperEVM | $0 | **CLOSED** | none | — |
| CozyFinance Set `0x17705474…` | Optimism | $0 | **CLOSED** | none | — |
| PerpetualProtocol v2 Vault `0x28bB4820…` | Optimism | $0 | **CLOSED** | zombie_hunt/FINDINGS.md; ci/L2-PHASE1-TRACKER.md ("Perpetual") | off target-chain list |
| MakerDAOFlipKeeper `0x9c05a058…` | Ethereum | drained | **CLOSED** | wave1 | prior-covered |
| Versa ModuleManager | — | — | **CLOSED** (not the bug) | ZH2B7; ZH3; TIER3; SUBAGENT-BRIEF | prior-covered |
| unwallet LockManager | — | — | **CLOSED** | none | local mapping |
| zenguard Identity | — | — | **CLOSED** | none | consistent |
| primordium TimelockAvatar | — | — | **CLOSED** | none | local mapping |
| Slice FundsModule `0x61bcd1ed…` | Base | $0 (patched+paused) | **CLOSED** | ZH4P4/P5 trackers; README | README closed |
| $NEM token `0x9Cf0E3aD…` | BSC | ~$1.8k | **replayable / MED** (one-off) | ZH4P4/P5 trackers; README | README closed (not a template) |
| Atomic Green / AtomicLending | Arbitrum | $105k TVL (real net ~$0) | **replay / MED**; pass3 decimal error | ZH4P3/P4 trackers; README; pass3/README | README correction |
| BiFi Lending | ETH/BSC/AVAX/Kaia | ~$324k | **paused**; ETH patched; BSC conditional ≈$40k | ZH4P3/P4/P5; MONITOR-LIST; folder:bifi/ | README carry-over |
| Argent smart-wallet | multi | thin MARK/WETH | **CLOSED** | ZH4P2/P3; L2 | prior-covered |
| AlpsCon V7–V9 | BSC | V9 ~$29k draining; S $331k | **CLOSED / monitor** | ZH4P2/P3/P5; MONITOR-LIST | prior-covered |
| UNCX SmartTokenVesting | ETH/BSC | $0 live | **CLOSED** ($0; claim rejected) | ZH4P2/P3; MONITOR-LIST; folder:uncx-vesting/ | prior-covered |
| EtherVista | Ethereum | ~$69k latent; extortion | **CLOSED / monitor** (not E-U) | ZH3/ZH4/ZH4P2; MONITOR-LIST | prior-covered |
| Qubic | — | — | **CLOSED** | pass2/README | prior-covered |
| Cysic | — | — | **CLOSED** | pass2/README | prior-covered |
| Kolan KolanHook | Ethereum | — | **CLOSED / monitor** | MONITOR-LIST | prior-covered |
| THEO / Autheo | — | ~$1.8k | **CLOSED** | ZH2; L2; MASTER-EXTRACTION-TABLE | prior-covered |
| SIEVE | BSC | ~$11k | **CLOSED** (incident) | none | 10-19 round-up |
| LULA | BSC | $578k (drained) | **CLOSED** | none | recycle() family |
| AIDC | BSC | — | **CLOSED** | wave2 | prior-covered |
| FH Token | BSC | — | **CLOSED** | none | sell-hook family |
| RWC | BSC | $109k (drained) | **CLOSED** | none | burn-from-pair |
| ORBToken | BSC | $33k (drained) | **CLOSED** | none | reserve-manip oracle |
| CashCowCoin | BSC | $117k (drained) | **CLOSED** | zombie_hunt/github_stuck_funds.md | prior-covered |
| TMM | BSC | $1.7M (drained) | **CLOSED** | none | reserve-manip oracle |
| DTXT | BSC | — | **CLOSED** | none | fee-on-transfer |
| SafeMoon-class | BSC | — | **CLOSED** | ZH4 tracker; zombie_hunt | prior-covered |
| Lagoon v0.5.2 syncDeposit | — | — | **CLOSED / re-check** | ZH4 tracker; wave1 | prior-covered |
| BeatXswap V3 slot0 | — | — | **CLOSED** | TIER3-LOW | prior-covered |
| LOOPSDAO | — | — | **CLOSED** | none | reserve-manip |
| FoxMarket | — | — | **CLOSED** | none | reserve-manip |
| MCN Labs LPBonus `0x52272524…` | BSC | ~$540 | **LOW** | none | ceiling <$1k |
| Dream Health Chain | — | — | **CLOSED** | zombie_hunt/x_social_leads.md | prior-covered |
| SafeTransfer hiddenCollect | Ethereum | — | **CLOSED** (ACTIVATOR_ROLE) | ZH4 tracker; x_social_leads | prior-covered |
| ZOZO / DAI pool | PulseChain | spoofed $9.93B | **not-a-protocol** (screener artifact) | none | fake liquidity |
| F / DAI pool | Arbitrum | spoofed $21.4M | **not-a-protocol** | none | fake liquidity |
| RUGBUG | Monad | memecoin | **not-a-protocol** | none | fresh pool |
| PEAR ×2 | HyperEVM | memecoin | **not-a-protocol** | ZH4P3 tracker | prior-covered |
| AISA | Arbitrum | Sushi LP token | **not-a-protocol** | ZH4P3 tracker | prior-covered |
| xBTC / wSPYx / wNVDAx / wTSLAx | X Layer | $2.56M/$3.59M/$1.54M/$1.27M | **LOW** (issuer-custodied) | wave2 (xBTC) | tokenized equities |
| RouterDrain `0xa331fde0…` | BSC | $0 (re-arm) | **HIGH mechanism / $0** | ZH4P4 tracker; README | README closed |
| Umia hub/marketCore/vault | Base | $3.67M | **LOW** (surface only) | ZH4P4 tracker; README | README closed |
| flaunch flETH | Base | $1.73M | **CLOSED** (no bug) | wave1 | prior-covered |
| Kipseli reserves | Base/BSC | $703k/$401k | **LOW** (P-custody) | none | reserve wallets |
| Adrastea Validator | Solana | $27.9M | watchlist (CLEAN) | none | zero-audit lane |
| Hylo LSTs | Solana | $21.4M | watchlist (CLEAN) | none | hyloSOL |
| Raiku Staked SOL | Solana | $19.2M | watchlist | none | listed 2026-09-19 |
| CatFee Staking Vault | Tron | $17.6M | watchlist | none | big Tron custody |
| Kyros | Solana | $12.8M | watchlist | none | LRT |
| StakePoint | Solana | $4.28M | watchlist | none | locker/claim |
| Vectis Finance | Solana/Eth | $5.14M | watchlist | none | yield |
| LiquidLoans | Pulse | $2.83M | watchlist | none | CDP |
| Pay Protocol | Tron/BSC/ETH | $1.92M | watchlist | none | payments |
| SunPump | Tron | $2.16M | watchlist | none | launchpad |
| Trevee Earn | Sonic | $930k | watchlist | none | yield |
| Magma Staking | Monad | $767k | watchlist | none | LST |
| Bio Protocol | Base | $3.43M | watchlist | none | launchpad |
| Avici | Solana | ~$1.1M (Aug-28) | **CLOSED** (upgraded) | none | Rain-card |
| Tria | — | ~$1.1M | **CLOSED** (upgraded) | ZH2; L2; MASTER-EXTRACTION-TABLE; folder:l2-triage-* | prior-covered |
| Solayer-Pay | Solana | ~$1.1M | **CLOSED** (upgraded) | none | Rain-card |
| Amnext | BSC | codeless | **CLOSED** | none | PoolTogether fork |
| Chainflip | TRON | paused | **CLOSED** | none | — |
| Internet Token | Base | — | **CLOSED** (prior) | zombie_hunt/ZOMBIE-HUNT-II.md; zombie_hunt/github_stuck_funds.md ("InternetToken") | fake-pool mint |
| 79thVault | BSC | $14.3M | **CLOSED** (key compromise, not E-U) | wave1 | prior-covered |
| Cysic Bridge | BSC | — | **CLOSED** (privileged) | none | key compromise |
| USDSM | Etherlink | $12.09M | **LOW** (role-gated) | ZH4P4 tracker; README; wave2 | README closed |
| Startale USD (USDSC) | Soneium | $4.48M | **LOW** (role-gated) | ZH4P4 tracker; README | README closed |
| MokuVaultV2 `0x43A9bbcE…` | Ronin | ~$63k | **LOW** (onlyRedeemer) | README | README closed |
| Morpho VaultV2 | World Chain | $231k | **LOW** (curator-gated) | L2-PHASE1 tracker | prior-covered |
| Ronin AccountProxy `0xF57Aa324…` | Ronin | ~$182k | **N/A** (user wallet) | none | not-a-protocol |
| AIPF token | Polygon | $6.43M liq | **LOW** (no custody) | none | plain ERC-20 |
| AS Token | Polygon | $6.60M liq | **LOW** (no custody) | none | plain token |
| HashKey Treasury | HashKey | 5.23M HSK | **LOW** (privileged) | none | chain treasury |
| Firelight stXRP | Flare | $58–67M | **CLOSED** (excluded) | ZH4P5 tracker; wave2/v7-firelight; README | prior-covered |
| Saturn USD / USDat | Monad | $150M | excluded (on DefiLlama) | none | not off-llama |
| MetaMask USD / mUSD | Monad | 17.0M | excluded (on DefiLlama) | none | not off-llama |
| Splashing spSEI | Sei | $6.05M | excluded (on DefiLlama) | none | not off-llama |
| Pro token `0x8D657445…` | BSC | $21.56M USDT pair | **GATED** ($0) | none | balancePool() governance-gated |
| 79AU `0xC35ef056…` | BSC | $8.21M USDT pair | **GATED** ($0) | wave1 | prior-covered |
| SPR `0x71967D91…` | BSC | $6.29M USDT pair | **GATED** ($0) | none | onlyStaking |
| BTCΞ `0xb1939843…` | BSC | $2.86M BTCB | **UNRESOLVED → $0** | ZH4P4 tracker; README | gate resolved (pair-scoped "T0") |
| AIGO `0xa6344A67…` | BSC | $1.46M USDT | **GATED** ($0) | wave2 | prior-covered |
| MS `0x6dc3bcec…` | BSC | $1.30M USDT | **GATED** ($0) | none | recycle() |
| KEY token `0x32990983…` | BSC | $1.29M USDT | **GATED** ($0) | none | setSellTax sync |
| NS `0x33F1c4FB…` | BSC | $625k USDT | **UNRESOLVED → $0** | ZH4P4 tracker; README | gate = 4-of-6 Safe |
| DMD `0x939dF4A5…` | BSC | $285k USDC | **UNRESOLVED → $0** | ZH4P4 tracker; README | gate = admin EOA |
| TOPS `0x842B1bFA…` | BSC | $92k USDT | **UNRESOLVED** | none (grep hit false-positive) | buy reverted in probe |
| LVIN `0x33bc8653…` | BSC | $91k USDT | **UNRESOLVED** (state cond.) | none | "recycle fail" |
| PEPGEM `0x0fd1eBe9…` | BSC | $59k USDT | **NOT PROFITABLE** (−505 USDT loop) | none | — |
| AGX `0xe766023F…` | BSC | ~$0 real | **GATED** ($0) | none | Pro template |
| SKP | BSC | $234k (drained) | **CLOSED** (context) | none | pattern family |
| STO | BSC | $16k (drained) | **CLOSED** (context) | none | pattern family |
| JUDAO | BSC | $228k (drained) | **CLOSED** (context) | none | pattern family |
| MONA / BurnAddress | BSC | — | **CLOSED** (context) | none (grep hit = "Monad") | pattern family |
| MT (Movie) | BSC | $242k (drained) | **CLOSED** (context) | none | extractFromPoolForLpMining |
| OCA | BSC | $420k (drained) | **CLOSED** (context) | zombie_hunt (context) | pattern family |
| NEX (AIC) | BSC | $21k (drained) | **CLOSED** (context) | none (grep hit false-positive) | pattern family |
| WETC | BSC | $100k (drained) | **CLOSED** (context) | none | pattern family |
| BCE / BFC / CCC | BSC | $679k+ (drained) | **CLOSED** (context) | zombie_hunt (context) | pattern family |
| BULL / 7AΩ∞ | Ethereum | $123 / $165 | **not profitable** | none | cross-chain hits |
| Multicall3Router `0x6222f994…` | Metis | $0 (latent) | **MED / $0** | ZH4P4 tracker; MONITOR-LIST; README | README Tier3 row 2 |
| CIAN Yield Layer `0x6B2BA8F2…` | Mantle | ~$110M | **LOW** (unverified impl, gated) | README ("CIAN") | README closed |
| TendaEscrow `0x9D0193f7…` | Celo | fresh escrow | **CLOSED** | none | pays creator |
| Fluent Auction/Marketplace/CreditTicket/Treasury/OrderBook | Fluent | new stack | **CLOSED** | none | role-gated/self-scoped |
| Fluent claimToken `0xE81825Ec…` | Fluent | dust | **LOW** (fixed beneficiary) | none | not attacker-profitable |
| Flare ClubVaultV2 `0x9B51319B…` | Flare | complex vault | **CLOSED** | none | onlyOwner |
| Aurora BastionVault/ReaperVault/MagikVault | Aurora | mostly drained | **CLOSED** | none | onlyOwner |
| Metis RewardDistributor / NitroPool | Metis | small | **CLOSED** | none | admin-gated |
| Ronin Staking `0x545edb75…` | Ronin | 65.97M RON ≈ $30M | **CLOSED** (canonical) | none | role-gated |
| Manta CeDeFi mBTC/mETH/mUSD | Manta | $26.9M | **CLOSED** (minter role) | none | — |
| Rootstock PaystandTokenBridge | Rootstock | bridge | **CLOSED** (role-gated) | none | — |
| Telos ProtocolFeeHook `0xe01bf830…` | Telos | ~$2k | **CLOSED** (onlyOwner) | none | — |
| GOAT Locking / DynamicCheckInJackpot | GOAT | <$5k | **CLOSED** | none | onlyDev |
| Astar CCIP pools / AnyswapV6 | Astar | pools | **CLOSED** (onlyAuth) | zombie_hunt (AnyswapV6) | prior-covered |
| Init Capital | Mantle/Blast | — | **CLOSED** (2 audits) | wave2 | prior-covered |
| Mystic Finance / Kinetic / Sceptre | Flare | — | **CLOSED** (ZH2) | ZH2; ZH2B2/B6/B7 | prior-covered |
| Clearpool TPOOL / Monarq / FAssets | multi | — | **CLOSED** (curator/lender) | pass3/README; wave1 | prior-covered |
| BigShot `0x274D146c…` | Optimism | $0 (latent) | **HIGH code / $0** (fork-proven) | ZH4P4 tracker; MONITOR-LIST; README | README Tier3 row 1 |
| ApprovalSwapRouter `0x06621dFf…` | Optimism | $0 | **CLOSED** | none | reverts |
| UnimonRefunds `0x51b71C47…` | Unichain | 3.84 ETH | **CLOSED** (msg.sender-scoped) | none | — |
| MultiPositionManager `0x4a1947d5…` | Unichain | 0.86 ETH | **CLOSED** (owner/share-gated) | none | — |
| 0xSplits SplitMain | ETH/multi | — | **CLOSED** (validSplitHash) | L2; ZH3; wave1/wave2 | prior-covered |
| OZ/thirdweb PaymentSplitter | multi | — | **CLOSED** (shares check) | L2-PHASE1; zombie_hunt | prior-covered |
| Juicebox | — | — | **CLOSED** (self-bound) | zombie_hunt | prior-covered |
| Drips | Ethereum | — | **CLOSED / monitor** | MONITOR-LIST; ZH4P2; pass2/README | prior-covered |
| LlamaPay | — | — | **CLOSED** (self-bound) | none | — |
| Uniswap-V3/V4 fork routers (sweepToken class) | Optimism/Unichain/… | gated/$0 | **LOW** (gated) | none | class |
| Unverified-impl proxy `0x1ecdb32e…` | Ethereum | $271,555 | **CLOSED** (AccessControl) | README ("22 proxies") | funnel |
| Unverified-impl proxy `0xc9d748e6…` | Ethereum | $228k | **CLOSED** (WITHDRAWER_ROLE) | README ("22 proxies") | funnel |
| Unverified-impl proxy `0x235f7326…` | Ethereum | $44,911 | **CLOSED** (Ownable) | README ("22 proxies") | funnel |
| Unverified-impl proxy `0x974b2d86…` | Ethereum | 13.22 ETH | **CLOSED** (Ownable) | README ("22 proxies") | funnel |
| Unverified-impl proxy `0x7ff8a32e…` | Ethereum | ~$450 liquid (TARA) | **CLOSED** (UUPS gated) | README ("22 proxies") | funnel |
| Unverified-impl proxy `0x0000efc4…` | Base | 9.445 ETH ≈ $25.5k | **CLOSED** | README ("22 proxies") | funnel |
| Unverified-impl proxy `0xa834e703…` | Base | 3.986 ETH ≈ $10.8k | **CLOSED** | README ("22 proxies") | funnel |
| Nile CL gauge `0x4d0af1ea…` | Linea | ~$121 gross / <$50 net | **CLOSED** (pass3 gauge class) | ZH4P4/P3; L2; MONITOR-LIST | README Tier3 row 6 |
| Nuri CL gauge | Scroll | $0 material | **CLOSED** (ZH2) | ZH4P4/P3; L2; MONITOR-LIST | README Tier3 row 6 |
| Cleopatra CL gauge | Mantle | dust | **CLOSED** | ZH4P4/P3 | README Tier3 row 6 |
| Pharaoh CL gauges | Avalanche | ~$7.2k net | **LIVE E-U ≈$7.2k** | ZH4P4/P3; MONITOR-LIST; folder:pharaoh-gauge/ | pass-3 carry-over |
| Radworks | Ethereum | $14.76M gross | **LIVE E-U ≈$3.0M** (capital-gated) | ZH4P4/P3/P2; MONITOR-LIST; folder:radworks/ | pass-2 carry-over |
| Papertrade | — | $1.28M | **CLOSED / monitor** | ZH3; ZH4; MONITOR-LIST; folder:papertrade/ | prior-covered |
| Olas POL | — | — | **CLOSED / monitor** | ZH4; MONITOR-LIST | prior-covered |
| BeraFarm | — | $257.9k | **CLOSED / monitor** | ZH4; MONITOR-LIST; wave2 | prior-covered |
| Segment | opBNB | — | **CLOSED / monitor** | ZH2; MONITOR-LIST; TIER3-LOW | prior-covered |
| Tarot | Kava | latent $2.83k | **CLOSED / monitor** | ZH2; MONITOR-LIST; TIER3-LOW | prior-covered |
| Fables | — | — | **CLOSED / monitor** | ZH3; MONITOR-LIST; folder:fables/ | prior-covered |
| Scorch | — | $4.26M | **CLOSED / monitor** | ZH3; MONITOR-LIST | prior-covered |
| AZverse | — | $52M | **CLOSED / monitor** | ZH3; MONITOR-LIST | prior-covered |
| FermiSwap | — | ~$0.78M/epoch | **CLOSED / monitor** | ZH3; MONITOR-LIST | prior-covered |
| Rain | — | fleet | **CLOSED / monitor** | ZH3; MONITOR-LIST | prior-covered |
| Red Village | — | P $50.51 | **CLOSED / monitor** | ZH3; MONITOR-LIST | prior-covered |
| Neverland | Monad | ~$3.1k | **CLOSED / monitor** | MONITOR-LIST; ZH4 | prior-covered |
| FWA V2 | — | profitless | **CLOSED / monitor** | MONITOR-LIST; wave1/wave2 | prior-covered |
| JustLend Energy Rental | Tron | — | **CLOSED / monitor** | ZH2; ZH2B6; ZH4; MONITOR-LIST | prior-covered |
| LlamaLend V2 | OP markets | — | **CLOSED / monitor** | MONITOR-LIST; ZH4 | prior-covered |
| Flex | — | ~$290–1,737 | **CLOSED / monitor** | L2; MONITOR-LIST | prior-covered |
| Bordrless | Solana | ~$96k | **CLOSED / monitor** | MONITOR-LIST; ZH4 | prior-covered |
| BitFi bfBTC | — | $26.9M | **CLOSED / monitor** | MONITOR-LIST; ZH4 | prior-covered |
| Extended | Starknet | ~$2.77M | **CLOSED / monitor** | MONITOR-LIST; ZH4 | prior-covered |
| Startale Earn | Soneium | ~$122k/yr | **CLOSED / monitor** | MONITOR-LIST; ZH4; wave1/wave2 | prior-covered |
| Pirate Chain | ARRR | $19.6M notional | **conditional** (miner-only) | MONITOR-LIST; ZH4P2; folder:pirate-chain/ | prior-covered |
| CapyFi | — | ~$5.1M cash | excluded (prior finding) | ZH2B2; MONITOR-LIST; ZH4P2 | prior-covered |
| NOXA Fun | — | $3.90M locked; fees ~$30k | **CLOSED** (P) | MONITOR-LIST; ZH4P2 | prior-covered |
| Plasma USD Vault | — | conditional ≈$2.25k | **CLOSED** (accounting artifact) | MONITOR-LIST; ZH4P2 | prior-covered |
| Rujira FIN | THORChain | conditional ≤$1.69M | **conditional** | MONITOR-LIST; ZH4P2/P3; folder:rujira-fin/ | prior-covered |
| bOSMO / Backbone | Osmosis | ~$965 | **LIVE E-U ≈$965** | MONITOR-LIST; ZH4P2; folder:bosmo-backbone/ | prior-covered |
| OpenFour | BSC | $0 | **CLOSED** | MONITOR-LIST; ZH4P2 | prior-covered |
| Genius.fun | BSC | $0 | **CLOSED** | MONITOR-LIST; ZH4P2 | prior-covered |
| Waterline Reservoir | — | $5.10M borrower | **CLOSED / monitor** | MONITOR-LIST; ZH4P3 | prior-covered |
| Eva Markets | — | $5.31M | **CLOSED / monitor** | MONITOR-LIST; ZH4P3 | prior-covered |
| Cooler MonoCooler | Ethereum | conditional ≤$3.61M | **conditional** | MONITOR-LIST; ZH4P3; folder:cooler-monocooler/ | prior-covered |
| Gimo st0G | 0G | ~$5.1–12.7k latent | **CLOSED** | MONITOR-LIST; ZH4P3; folder:gimo-st0g/ | prior-covered |
| Trueo | Base | conditional $50,819 | **conditional** | MONITOR-LIST; ZH4P3; folder:trueo/ | prior-covered |
| Manifest Trade | Solana | $12.85M | **CLOSED** (byte-identical) | ZH4P3 tracker; pass3/README | prior-covered |
| Sport.fun | Base | $2.69M | **CLOSED** ($0) | ZH4P3 tracker | prior-covered |
| Cetus CLMM | Sui | $3M pool | **CLOSED** (v15 identical) | ZH4P3 tracker; pass3/README | prior-covered |
| STON.fi V2 | TON | $14.35M | **CLOSED** (byte-identical) | ZH2; ZH2B7; ZH4P3 | prior-covered |
| RISEx | RISE | $25.89M | **CLOSED** (all gated) | ZH4P3 tracker | prior-covered |
| Verio | Story | $2.37M | **CLOSED** (hypothesis disproven) | ZH4P3 tracker; folder:verio/ | prior-covered |
| Wildcat | Ethereum | — | **CLOSED** (88 markets) | ZH4P3; MONITOR-LIST | prior-covered |
| Deri V4 | — | $167.7k real | **CLOSED** | ZH3; H-RESULTS; zombie_hunt | prior-covered |
| Predict Fun | — | — | **CLOSED** | ZH4P3 tracker | prior-covered |
| Secured Finance | 3 chains | — | **CLOSED** | ZH4P2/P3 trackers | prior-covered |
| Echo Bridge | — | — | **CLOSED** | ZH4P2 tracker | prior-covered |
| zkLink Nova | — | legit exit | **CLOSED** | ZH4P2 tracker; wave1 | prior-covered |
| HAI | Optimism | $111k treasury | **CLOSED** (hardened) | zombie_hunt; MONITOR-LIST; pass2/README | prior-covered |
| Drift Protocol exploiter | Ethereum | laundering | **not-a-bug** | none | — |
| Aztec rollup exploiter | Ethereum | laundering | **not-a-bug** | none | — |
| Institutional MORPHO (EIP-7702) | Ethereum | $2.3M | **not-a-bug** (key compromise) | none | — |
| Dolomite | — | — | **CLOSED** | ZH4P2 tracker; pass2/README; wave2 | prior-covered |
| Jupiter Lend | Solana | — | **CLOSED** | ZH4P2 tracker; wave1/wave2 | prior-covered |
| Blast wstETH whitelist vault | Base | $6M (10-04) | **unresolved** (not in window) | none | MAI-vault naming collision |
| "Base MAI vault drain" | Base | — | **unresolved** (no source) | none | likely naming collision |
| RocketSwap-Anubis | BOT | $354M | **CLOSED** | ZH4P3; TIER3-LOW; wave1 | prior-covered |
| BDEX V3 | BOT | $31.2M | **CLOSED** | ZH2; TIER3-LOW | prior-covered |
| ZilSwap / Avely / PlunderSwap | Z2 EVM | — | **CLOSED** | ZH2; TIER3-LOW | prior-covered |
| BloctoTokenStaking | Flow | 62M BLT | **CLOSED** | ZH2; TIER3-LOW | prior-covered |
| Pools Finance | IOTA | $1.83M | **CLOSED** | ZH2; TIER3-LOW | prior-covered |
| Virtue | IOTA | bad debt | **CLOSED** | ZH2B6; TIER3-LOW | prior-covered |
| Weft / RadLock / RlyFun | Radix | ~$101.5 | **KEPT** (Tier-3) | ZH2; TIER3-LOW; MASTER-EXTRACTION-TABLE | prior-covered |
| ShadeSwap | Secret | ~$7,541 | **KEPT** (Tier-3) | ZH2; TIER3-LOW | prior-covered |
| 1Hive / Gardens / Orchid | Gnosis | 1Hive KEPT | **KEPT/CLOSED** | ZH2; TIER3-LOW; wave1 | prior-covered |
| SBCWrapper | Gnosis | $0.34 | **KEPT** (dust) | ZH2; MONITOR-LIST; TIER3-LOW | prior-covered |
| FilDA / deFusion / AntePool | BTTC/Viction/Aurora | ~$2.1 | **KEPT/CLOSED** | ZH2; TIER3-LOW | prior-covered |
| HashKey Treasury / FAssets / Clearpool | multi | — | **CLOSED** | pass3/README; wave1 | prior-covered |

---

## B. CANDIDATES NOT IN pass4/README.md AND NOT PRIOR-COVERED

These are named in a pass-4 lane file, are **absent from `pass4/README.md`**, and have **no hit** in `zombie_hunt/`, `zombie-deep/`, the `ci/` trackers, or any root folder (working-data hits excluded). Verdicts are the lanes' own. Component contracts of a README-covered parent are excluded (noted as such above).

**Novel / open-ish leads (worth a first look):**

| Name | Chain | Funds | Lane verdict | Note |
|---|---|---|---|---|
| **Virtuals Protocol** | Base | large protocol; audited code superseded | **LOW** — 6 Code4rena Highs; AgentFactoryV4/V5 superseded by V7/V4 | audited contracts ≠ live ones |
| **Cabal LST** (H-01) | Initia | **$2.77M** | **LOW** — LP-unstake ratio distortion; live Move modules never diffed | best remaining unverified live lead |
| **Gamma — Perpetual Vault** | GMX chains | live addr not located | **LOW** — CodeHawks 20+ Highs (totalShares inflation, KeeperProxy, ADL) | live address not found |
| **shMonad** `0x1B68626d…` | Monad | **9,506,163 MON ≈ $213k** | **LOW** — verified ShMonad; no unguarded value mover (not deep-diffed) | LST |
| **Metropolis DLMM `VaultFactory 0x197d40B3…`** | Sonic | n/a (factory) | **LOW** — `createMarketMakerOracleVault` permissionless by design | vault-side admin not read |
| **Sonic Market `BookManager 0xD4aD5Ed9…`** | Sonic | 6,756 S ≈ $381 | **CLOSED** — collect() self-scoped; `onlyByLocker` | v4-style singleton |
| **Sturdy V2 `DataProvider 0x4534F53A…`** | Sei | $0 | **CLOSED** — single market, all totals 0 | empty market |
| **Reservoir Protocol** (BorrowableCToken/fToken/GHO) | Monad/Plasma/Berachain | $60.9M Monad | **CLOSED** — `_checkDaoPermissions` / factory-auth / facilitator-gated | distinct from GaslessReservoirEnabler |
| **TIPMine `0x412c7bd2…` / TIP pair** | BSC | $0 | **MED / $0** — fresh (not excluded) but pair drained; `mine()` reverts | monitor |
| **MCN Labs LPBonus `0x52272524…`** | BSC | ~$540 | **LOW** — reserve-manip reward index; ceiling <$1k | below bar |
| **Kipseli reserves** | Base/BSC | $703k / $401k | **LOW** — "reserve wallets"; BSC = Gnosis Safe (P), Base unverified | P-custody |
| **Pro token `0x8D657445…`** | BSC | **$21.56M USDT pair** | **GATED $0** — `balancePool()` governance-gated (fork-proven) | largest BSC pair of the family |
| **SPR `0x71967D91…`** | BSC | $6.29M USDT pair | **GATED $0** — `recycle()` `SPR__OnlyStaking` | fork-proven |
| **MS `0x6dc3bcec…`** | BSC | $1.30M USDT | **GATED $0** — custom error | fork-proven |
| **KEY `0x32990983…`** | BSC | $1.29M USDT | **GATED $0** — "Unauthorized" | fork-proven |
| **TOPS `0x842B1bFA…`** | BSC | $92k USDT | **UNRESOLVED** — buy reverted in probe | gate not disproven |
| **LVIN `0x33bc8653…`** | BSC | $91k USDT | **UNRESOLVED** — "recycle fail" state condition | gate not disproven |
| **PEPGEM `0x0fd1eBe9…`** | BSC | $59k USDT | **NOT PROFITABLE** — 20× loop = −505 USDT | fork-proven loss |
| **AGX `0xe766023F…`** | BSC | ~$0 real | **GATED $0** — same template as Pro | fork-proven |
| **TendaEscrow `0x9D0193f7…`** | Celo | fresh escrow | **CLOSED** — refunds pay `e.creator` | — |
| **Fluent** Auction/Marketplace/CreditTicket/Treasury/OrderBook/claimToken | Fluent | new stack | **CLOSED** — role-gated/self-scoped; `_disableInitializers()` | — |
| **Flare ClubVaultV2 `0x9B51319B…`** | Flare | complex vault | **CLOSED** — onlyOwner/self-scoped | — |
| **Aurora BastionVault / ReaperVault / MagikVault** | Aurora | mostly drained | **CLOSED** — onlyOwner; init window long expired | — |
| **Metis RewardDistributor / NitroPool** | Metis | small | **CLOSED** — `onlyGov`/owner-gated | — |
| **Ronin Staking `0x545edb75…`** | Ronin | 65.97M RON ≈ $30M | **CLOSED** — MIGRATOR_ROLE-gated (canonical) | — |
| **Manta CeDeFi mBTC/mETH/mUSD `0x1468177D…`** | Manta | $26.9M | **CLOSED** — minter role | CeFi-backed |
| **Rootstock PaystandTokenBridge `0x15DE7B57…`** | Rootstock | bridge | **CLOSED** — relay/refund roles | — |
| **Telos ProtocolFeeHook `0xe01bf830…`** | Telos | ~$2k | **CLOSED** — onlyOwner | — |
| **GOAT Locking / DynamicCheckInJackpot** | GOAT | <$5k | **CLOSED** — onlyDev | — |
| **ApprovalSwapRouter `0x06621dFf…`** | Optimism | $0 | **CLOSED** — reverts; code lacks selector | — |
| **UnimonRefunds `0x51b71C47…`** | Unichain | 3.84 ETH | **CLOSED** — msg.sender-scoped + hasClaimed | — |
| **MultiPositionManager `0x4a1947d5…`** | Unichain | 0.86 ETH | **CLOSED** — owner/share-gated | — |
| **LlamaPay** | — | — | **CLOSED** — amount is caller's own accrued balance | not the class |
| **X7Finance / X7Pioneer `0x70000299…`** | Ethereum | 0.0216 ETH | **CLOSED** ($0) | — |
| **PrimeFinance pool `0xb339448E…`** | HyperEVM | $0 | **CLOSED** | — |
| **CozyFinance Set `0x17705474…`** | Optimism | $0 | **CLOSED** | — |
| **PositionManager `0x7cedB2e5…`** | BSC | $0 | **CLOSED** | — |
| **unwallet LockManager / zenguard Identity / primordium TimelockAvatar** | — | — | **CLOSED** — local mappings, not confused deputies | not-a-bug |
| **SIEVE** | BSC | ~$11k | **CLOSED** (incident, drained) | — |
| **LULA `0xF5d7029e…`** | BSC | $578k (drained) | **CLOSED** — `recycle(uint256)` family | — |
| **FH Token** | BSC | — | **CLOSED** — `_sellTransfer` family | — |
| **RWC** | BSC | $109k (drained) | **CLOSED** — burn-from-pair + sync | — |
| **ORBToken** | BSC | $33k (drained) | **CLOSED** | — |
| **TMM** | BSC | $1.7M (drained) | **CLOSED** — reserve-manip oracle | — |
| **DTXT** | BSC | — | **CLOSED** — fee-on-transfer | — |
| **LOOPSDAO** | — | — | **CLOSED** — reserve-manip | — |
| **FoxMarket** | — | — | **CLOSED** — reserve-manip | — |
| **ZOZO / DAI pool** | PulseChain | spoofed $9.93B | **not-a-protocol** — screener artifact | fake liquidity |
| **RUGBUG** | Monad | memecoin | **not-a-protocol** | — |
| **wSPYx** (and wNVDAx/wTSLAx siblings) | X Layer | $3.59M pool | **LOW** — issuer-custodied token, no on-chain custody | not-a-protocol |
| **Saturn USD / USDat** | Monad | $150M | **excluded** — on DefiLlama | not off-llama |
| **MetaMask USD / mUSD** | Monad | 17.0M | **excluded** — on DefiLlama | not off-llama |
| **Splashing spSEI** | Sei | $6.05M | **excluded** — on DefiLlama | not off-llama |
| **Ronin AccountProxy `0xF57Aa324…`** | Ronin | ~$182k | **N/A** — user smart-account, not a protocol | not-a-protocol |
| **AIPF `0x2c72d255…`** | Polygon | $6.43M liq | **LOW** — plain ERC-20, no custody contract | not-a-protocol |
| **AS Token `0x6a92b1e9…`** | Polygon | $6.60M "mcap" | **LOW** — plain token, no proxy | not-a-protocol |
| **HashKey Treasury `0xA9936032…`** | HashKey | 5.23M HSK | **LOW** — operator-controlled treasury | privileged |
| **Blast wstETH whitelist vault (10-04, $6M) / "Base MAI vault drain"** | Base | $6M | **unresolved** — not a 10-20/21 incident; likely MAI/qiDAO naming collision | monitor |
| **Drift Protocol exploiter / Aztec rollup exploiter / Institutional MORPHO (EIP-7702)** | ETH | laundering / $2.3M | **not-a-bug** — key/delegation compromise, no unprivileged primitive | not E-U |
| **Adrastea Validator** | Solana | $27.9M | watchlist — CLEAN; stake-pool share accounting | zero-audit lane |
| **Hylo LSTs (hyloSOL)** | Solana | $21.4M | watchlist — CLEAN | zero-audit lane |
| **Raiku Staked SOL** | Solana | $19.2M | watchlist | listed 2026-09-19 |
| **CatFee Staking Vault** | Tron | $17.6M | watchlist — big Tron custody, source not reachable | zero-audit lane |
| **Kyros** | Solana | $12.8M | watchlist | LRT |
| **Vectis Finance** | Solana/Eth | $5.14M | watchlist | yield |
| **StakePoint** | Solana | $4.28M | watchlist | locker/claim (UNCX-class) |
| **LiquidLoans `0x9159f1d2…`** | Pulse | $2.83M | watchlist | CDP |
| **SunPump** | Tron | $2.16M | watchlist | launchpad |
| **Pay Protocol** | Tron/BSC/ETH | $1.92M | watchlist | payment module |
| **Trevee Earn** | Sonic | $930k | watchlist | yield |
| **Magma Staking** | Monad | $767k | watchlist | LST |
| **Bio Protocol** | Base | $3.43M | watchlist | launchpad |
| **Avici / Tria / Solayer-Pay** | Solana | ~$1.1M (Aug-28) | **CLOSED** — programs upgraded (Tria already prior-covered) | vendor confirmed |
| **Amnext** | BSC | codeless | **CLOSED** — PoolTogether-V3 fork, token codeless | — |
| **Chainflip** | TRON | paused | **CLOSED** | — |
| **Cysic Bridge** | BSC | — | **CLOSED** — privileged/key compromise | not E-U |
| **Next Generation** | Fantom | dead | **CLOSED** | — |
| **Brix / Covenant / BitVault / BattleChain Confidence Pools** | — | $0 / sandbox | **CLOSED** (0 Highs / below bar) | teaching/sandbox |
| **Liquid Ron (H-01) / IQ AI (H-01) / Thorwallet (H-01/02)** | — | ~$45k / — / — | **CLOSED** — mitigation confirmed | — |
| **Succinct SP1 / Initia rollup modules / Benqi Ignite / Remora / Starknet Staking / Open Eden / Cyfrin Attester** | — | — | **CLOSED** — non-E-U (circuit/DoS) or private contest (no public findings) | not contract drains |
| **Uniswap-V3/V4 fork routers (`sweepToken`/`unwrapWETH9`/`refundETH` class)** | OP/Unichain/Soneium/Celo/Gnosis | $0 at rest / gated | **LOW** — public-by-design; funded hits gated | class (BigShot is the only live impl) |

**Note on near-duplicates:** `Nile CL`/`Nuri CL`/`Cleopatra` (all in README row 6), `NS`/`DMD`/`BTCΞ` (README row 3), and `Peapods`/`Tangent`/`USG`/`RAAC`/`Regnum Aurum`/`Curve scrvUSD`/`CIAN Yield Layer`/`Peapods` all resolve to **README-covered parents** and are excluded from the section above.

---

*Prepared 2026-10-23 · childB pass4-recon · read-only. Every "Prior-coverage" cell was produced by `zh4-check.sh` + tracker grep + root-folder `ls -d` + pass/wave README review; working-data files (`llama_*`, `lane_*.tsv`, `gov/*`, `MASTER-BOARD`) were excluded.*
