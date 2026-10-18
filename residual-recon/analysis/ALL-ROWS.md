# ZH4 Wave-B0 — full residual disposition table

Every candidate row and named prose/negative lead from the 7 wave-1 lanes and d2a–d2d. **612 named candidates** in 371 rows/groups. Status vocabulary: FINDING (README Tier 1/2), LOW (README Tier 3), OPEN (actionable residual), PARKED (below-bar/unlocated/watch/trigger/P-class), closed (README or in-lane verdict), excluded (prior corpus).

## r1 — r1-evm-fresh

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | SatoHook (SATO) | $2.58M hook ETH | closed (README) | byte-identical rebuild + fork fuzz; $0 E-U — `README:CLOSED#1` |
| 2 | Avalon Superearn | $142.3M | closed (README) | all value fns whitelist/role-gated — `README:CLOSED#2` |
| 3 | Derive V3 (Options) | $185.2M DL; >=$44.5M sampled | closed (in-lane) | zk-proven Outbox, permissioned batchSubmitter, $2M throttle; no E-U path at recon depth; watch zk layer — `r1:11; r1 top5#3` |
| 4 | Metric V1 | $7.05M | closed (README) | pool byte-identical to factory source; collectPoolFees fixed destinations — `README:CLOSED#22` |
| 5 | FWA V2 | $1.357M | closed (README) | 7 contracts; fork-proved gates; VRF FIFO — `README:CLOSED#37` |
| 6 | Saturn (USDat/sUSDat) | $150M | closed (in-lane) | modules onlyVault/onlyVaultRole; buy/sell/migrate operator-gated — `r1:14` |
| 7 | Privacy Boost | $1.58M | closed (README) | impl byte-identical; verifiers re-ceremonied — `README:CLOSED#35` |
| 8 | Flex | $1.9M | **OPEN** | Liquity-v1 fork + custom PriceOracle + exotic collaterals; oracle/redemption math unproven — `r1:16` |
| 9 | Alchemix V3 | $40.6M | **OPEN** | fresh VaultV2 ERC-4626 (Apr 2026); donation/first-redeemer/harvest share math unread — `r1:17` |
| 10 | Curve LlamaLend V2 | $42.1M | **OPEN** | fresh Jun-Jul 2026 markets/new oracles; soft-liquidation/partial-repay edge unexamined — `r1:18` |
| 11 | Morpho Midnight | $8.6M | PARKED | immutable, Morpho-audited, no concrete path; watch market config — `r1:19` |
| 12 | JPYdf | $849k | **OPEN** | receiveFromStrategy(declaredAmount)/claim public; shortfall/backstop accounting unread — `r1:20` |
| 13 | 3F | $38.0M DL | PARKED | contracts not located; desk lead — `README:L133; r1:21` |
| 14 | Zama | $128.9M DL | PARKED | wrappers not located; desk lead — `README:L133; r1:22` |
| 15 | TxFlow Bridge | $30.6M DL | PARKED | contracts not located; desk lead — `README:L133; r1:23` |
| 16 | Hibachi Bridge | $4.3M | closed (README) | canonical Risc0+SP1 verifiers; proof replay closed — `README:CLOSED#7` |
| 17 | Kamui | $2.9M DL | PARKED | contracts not located; desk lead — `README:L133; r1:25` |
| 18 | Robinhood Chain Bridge (ETH side) | $652.6M DL | PARKED | contracts not located; likely permissioned relayer — `README:L133; r1:26` |
| 19 | Tori Finance | $71.4M | closed (in-lane) | mint/redeem onlyRole + whitelist + EIP-712 — `r1:36` |
| 20 | Axis | $65.7M | closed (in-lane) | mint/bridgeMint/burn role-gated — `r1:37` |
| 21 | JUSD Finance | $22.9M | closed (in-lane) | onlyAuth/onlyStrategy vault paths — `r1:38` |
| 22 | Vetro | $0.75M | closed (in-lane) | PeggedToken mint onlyGateway — `r1:39` |
| 23 | Monolith Market | $0.31M | PARKED | below budget; tiny factory lender — `r1:40` |
| 24 | Wise Token | $69.9M DL | closed (in-lane) | DL row is ownerless WISE/ETH LP share, not a protocol — `r1:41` |
| 25 | Textile FX | $1.8M | closed (in-lane) | non-custodial maker wallets; stateless reactor — `r1:42` |
| 26 | Cooler Loans | $232M | PARKED | long-lived/heavily reviewed lineage; deprioritized — `r1:43` |
| 27 | Yield Basis | $130M | PARKED | long-lived/heavily reviewed lineage; deprioritized — `r1:43` |
| 28 | Curve LlamaLend v1 | n/a | PARKED | long-lived lineage; deprioritized (v2 row is separate) — `r1:43` |
| 29 | Fluid | n/a | PARKED | long-lived/heavily reviewed lineage; deprioritized — `r1:43` |
| 30 | Prior-corpus excluded names (Tydro, STRATO, FermiSwap, HertzFlow, NaraUSD, SUBFROST, up v3, Scorch, Icarus, Longbow, Meridian, Aero Lite, Fang, UNCX, Notional, Symbiosis, Cozy, Flamincome, Venus lineage) (19 names) | - | excluded | checker hits / prior waves — `r1:44` |
| 31 | Locus Finance | $35.8k | closed (README) | starved; signature primitive live but hit vault drained — `README:CLOSED#6` |
| 32 | Set Protocol V3 | $21.9k incident | closed (in-lane) | 50/50 rSet vaults starved; $0 E-U — `r1:45; README:CORR#5` |
| 33 | MakerDAO legacy keeper | $0 today ($538k taken) | LOW | impl family sweep incomplete; sibling watch — `README:LOW#2` |
| 34 | Silo V3 | $734k DL | PARKED | fresh 2026-05-18, not excluded; unexamined, below priority — `r1:50` |

## r2 — r2-x-radar

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | BeraFarm | $257.9k | **FINDING** | patched overnight; two unverified impls; monitor — `README:ZH4-06` |
| 2 | Locus Finance v2 | $35.8k | closed (README) | only vulnerable vault drained; report path starved — `README:CLOSED#6` |
| 3 | THEO / Autheo | $40.5k pool residual | LOW | single relayer key, not rotated; key/infra class — `README:LOW#1` |
| 4 | Kolan Protocol (KolanHook) | $0 today | PARKED | proven accept() recipe but input-starved; re-arms per window deposit — `r2:14; README:MONITOR` |
| 5 | MakerDAO legacy auction-keeper class | $0 today | LOW | victim drained; sibling Flipper/impl sweep incomplete — `README:LOW#2` |
| 6 | CL8Y | 126.7 ETH (~$304k) in EOA | closed (in-lane) | identified as CeramicLiberty.com memecoin (BSC/Terra); both 0x addresses are EOAs, no code; Oct-15 BSC incident/recovery notice; no contract E-U surface — `r2:16 + 2026-10-18 check` |
| 7 | Carrot Funding | unknown | PARKED | blackpaper index only; no data; below bar — `r2:17` |
| 8 | Set Protocol RebalancingSetTokenV3 | $0 (incident $21.9k) | closed (in-lane) | all 50 rSet vaults dust; starved — `r2:38` |
| 9 | 79thVault / 79AU | $12.5-14.35M incident | excluded | privileged OPERATOR_ROLE key; not E-U — `r2:39` |
| 10 | Ledger / CryptoBilis | $92.9M incident | excluded | supply-chain device tampering; no contract surface — `r2:40` |
| 11 | Bofur Capital phisher | $2M DAI | excluded | social engineering; not a protocol bug — `r2:41` |
| 12 | Malt | $64k incident | excluded | V2-malt in ZH3 corpus; pool drained — `r2:42` |
| 13 | MUSystem | 5.335 ETH incident | closed (in-lane) | drained; $0 remains — `r2:43` |
| 14 | Startale ERC-7579 re-init | pre-window | excluded | corpus wave; pre-window — `r2:44` |
| 15 | RsETHSafeModule / UX4 hook redirect | pre-window | excluded | corpus wave; pre-window — `r2:44` |
| 16 | GoldPesa | Z3-H5 | excluded | prior corpus closed post-drain — `r2:45` |
| 17 | CrowdRingCircle | BSC Jul-2026 | closed (in-lane) | post-hoc PoC publication; no new funding — `r2:46` |
| 18 | Phishing/poisoning sweeps | not protocol | excluded | address poisoning/key compromise — `r2:47` |
| 19 | Disclosure hunt (unpatched public claims) | - | closed (in-lane) | negative in window; no concrete EVM protocol lead — `r2:48` |
| 20 | Prior-closure corrections (UNCX, Papertrade, EtherVista, X7 Finance, BitBay) (5 names) | - | excluded | excluded protocols; monitors only — `r2:29-34; README:CORR#1-4` |

## r3 — r3-disclosure-gap

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | Olas POL LiquidityManagerCore | $0 today | **FINDING** | deployed unfixed impl; re-arm monitor — `README:ZH4-04` |
| 2 | Kinetiq (kHYPE) | $880M | closed (README) | H-01/H-03 fixed in deployed facets — `README:CLOSED#14` |
| 3 | Olas ServiceManager signature paths | bond pool unmeasured | closed (in-lane) | H-07/H-09 bond-lock/phishing class, not direct theft; v1.3.0 not deployed — `r3:11` |
| 4 | K2 (Stellar/Soroban lending) | $1.8k | PARKED | 18 Highs but below bar; re-check TVL — `r3:12` |
| 5 | Sequence v3 wallet modules | user wallets | PARKED | fixed upstream; legacy-impl monitor only — `r3:13` |
| 6 | UNCX Vesting V2 | $1.16M nominal | excluded | prior corpus; monitor FlatFeeUpdated — `r3:24; README:CORR#1` |
| 7 | Notional V1 escrow | $59.2k frozen | closed (in-lane) | EmptyProxy; all calls revert — `r3:26; README:CORR#4` |
| 8 | Megapot H-01 | Base | closed (in-lane) | fixed in live deployment — `r3:27` |
| 9 | Olas H-06 reentrancy | - | closed (in-lane) | fixed in live v1.2.8 — `r3:28` |
| 10 | Olas H-05/H-10 | - | closed (in-lane) | StakingNativeToken unused; production uses StakingToken — `r3:29` |
| 11 | Panoptic Next Core | - | closed (in-lane) | mitigation review confirmed — `r3:30` |
| 12 | Blackhole | - | closed (in-lane) | H-02 mitigated; governor not deployed — `r3:31` |
| 13 | Swafe | - | closed (in-lane) | mitigation confirmed — `r3:32` |
| 14 | Intuition | - | closed (in-lane) | mitigation confirmed — `r3:32` |
| 15 | Jupiter Lend | $916M | closed (README) | 34 sims; protocol signer + 3 gate layers — `README:CLOSED#11` |
| 16 | Monetrix | - | closed (in-lane) | 0 High findings — `r3:33` |
| 17 | Merkl | - | closed (in-lane) | 0 High findings — `r3:33` |
| 18 | Silo | - | closed (in-lane) | 0 High findings — `r3:33` |
| 19 | Meteora DBC | - | closed (in-lane) | Medium-only — `r3:33` |
| 20 | Morpheus | - | closed (in-lane) | Medium-only — `r3:33` |
| 21 | Lido CSM | - | closed (in-lane) | no High section — `r3:33` |
| 22 | Ekubo | - | excluded | prior C-21 coverage — `r3:33` |
| 23 | LayerZero Sui/Starknet/Stellar endpoints | - | closed (in-lane) | 0 High findings — `r3:34` |
| 24 | GTE | - | closed (in-lane) | Highs are DoS/order-book, not theft — `r3:35` |
| 25 | SukukFi | $54 TVL | closed (in-lane) | dead — `r3:36` |
| 26 | Hybra Finance | - | excluded | prior H-33 — `r3:37` |
| 27 | Trail of Bits Provenance HASH | $500k pre-patch | closed (in-lane) | patched 2026-08-25 — `r3:39` |
| 28 | Cantina competitions | - | excluded | findings not public; path closed — `r3:40` |

## r4 — r4-non-evm

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | Current (Sui lending) | $57.9M | closed (README) | package upgraded; capability/whitelist gates; ADL falsified — `README:CLOSED#24` |
| 2 | Jupiter Lend | $916M | closed (README) | protocol signer gates — `README:CLOSED#11` |
| 3 | SunSwap V4 | $109.1M | closed (README) | init-code byte-identical; hooks $1,278 — `README:CLOSED#12` |
| 4 | Rujira FIN | $68.2M custody | closed (README) | deployed=repo checksums; range fixes live — `README:CLOSED#16` |
| 5 | Decibel (Aptos) | $29.74M | closed (README) | 40+ modules disassembled; fee shares bind managers — `README:CLOSED#8` |
| 6 | Pacifica | $24.18M | closed (README) | authority-locked; operator-only outflows — `README:CLOSED#18` |
| 7 | Exponent | $62.5M+ | closed (README) | migration idempotent; NAV account-bound — `README:CLOSED#23` |
| 8 | Rujira Ghost Vault | $30.8M | closed (README) | deployed=repo; share math checked — `README:CLOSED#16` |
| 9 | JustLend sTRX | $3.3B | closed (README) | full STRXG2 source read; paths gated/pool-favoring — `README:CLOSED#27` |
| 10 | BULK | $8.14M | closed (README) | opcode surface enumerated; authority-locked — `README:CLOSED#18` |
| 11 | Tessera V | $12.0M | closed (README) | operator quote gate proven — `README:CLOSED#23` |
| 12 | Haedal Lending Vault | $6.38M | closed (README) | hot-potato receipts; round-trip -1 unit — `README:CLOSED#36` |
| 13 | Faiyah Staking | $4.86M | **FINDING** | commingled principal; H-O first-mover race — `README:ZH4-05` |
| 14 | SundaeSwap V4 | $2.5M | closed (README) | 14/14 scripts hash-verified; execution permissioned — `README:CLOSED#34` |
| 15 | Rujira Staking (sRUJI) | $13.5M | closed (README) | deployed=repo; SharePool math checked — `README:CLOSED#16` |
| 16 | JustLend Energy Rental (MarketG1) | $1.11M security deposits | **OPEN** | permissionless rent/liquidate/return; badDebt branch + return-after-liquidate double-refund untested — `r4:26` |
| 17 | TONCO V2 | ~$2.5M | LOW | pool re-init/fake-sender surfaces — `README:LOW#29` |
| 18 | Jupiter Offerbook | $1.32M | LOW | escrow-ATA/mint substitution; IDL recovery — `README:LOW#29` |
| 19 | Rujira BOW + Merge | $3.73M | closed (README) | deployed=repo; decay windows ended — `README:CLOSED#16` |
| 20 | PiggyBank | $1.73M | LOW | NAV anomaly 0.943-0.951; round-trip unproven — `README:LOW#29` |
| 21 | Extended (Starknet perp) | $2.77M spot | LOW | trading operator-gated; C4 highs fixed — `README:LOW#29` |
| 22 | USDD (CDP) | $1.23B | LOW | uncharted V2 minters/PSM — `README:LOW#30` |
| 23 | JustLend V1 | $3.72B | closed (in-lane) | Compound-v2 fork screened negative; admin Timelock; oracle poster-gated — `r4:45` |
| 24 | Loopscale Curation | $7.6M | PARKED | moved off-table; roles/NAV check deferred — `r4:46` |
| 25 | R25 (Sui side) | $150.8M | closed (in-lane) | AdminCap asserts; no E-U found — `r4:47` |
| 26 | WaterX | $462k | closed (in-lane) | vault/PSM sound; perp engine not located — `r4:48` |
| 27 | Hermetica hBTC | 46.9 BTC | closed (in-lane) | full read; floors both ways; 3/6 msig — `r4:49` |
| 28 | XP Union Vault | Xphere | closed (in-lane) | source-read sound; non-upgradeable — `r4:50` |
| 29 | Stellar DeFi Hub | $55.1M | excluded | admin-upgradeable Soroban; P-class custody — `r4:51` |
| 30 | BitSafe CBTC | $3.37M | excluded | attestor/issuer-custodial — `r4:51` |
| 31 | Circle Bitcoin | $14.2M | excluded | issuer-custodial — `r4:51` |
| 32 | Canton trio (Temple/Cantex/Alpend) | ~$11.5M | PARKED | Daml private network; unverifiable — `r4:51` |
| 33 | WESO (Terra) | sub-$1M | PARKED | tooling-limited — `r4:51` |
| 34 | xALPH (Alephium) | sub-$1M | PARKED | tooling-limited — `r4:51` |
| 35 | XOXNO (MultiversX) | sub-$1M | PARKED | tooling-limited — `r4:51` |
| 36 | XORA (XRPL) | sub-$1M | PARKED | tooling-limited — `r4:51` |
| 37 | Definity / Raiku / Japan Staked SOL / Forward Industries SOL (4 names) | $314M | excluded | stake-pool wrappers/treasury custody — `r4:52` |
| 38 | Reflect Tranches | - | closed (in-lane) | immutable + audited — `r4:53` |
| 39 | Flipcash | - | closed (in-lane) | immutable + audited — `r4:53` |
| 40 | Deriverse | - | closed (in-lane) | Cyfrin v2 audited — `r4:53` |
| 41 | Cosmos community pools (Akash, Dymension, XION, Saga, Noble) (5 names) | - | closed (in-lane) | quorum cost >> pool value; Noble has no distribution — `r4:54` |
| 42 | Elys / Pryzm / OmniFlix / Quasar / Kujira (5 names) | - | PARKED | chains halted/unreachable; do not trust numbers — `r4:55` |
| 43 | Rujira Redacted sub-wallets | ~$800 dust | closed (in-lane) | immutable but dust — `r4:56` |
| 44 | Rujira Vesting / DAO-DAO | $23.3M | closed (in-lane) | privileged claim surfaces; no E-U — `r4:56` |
| 45 | Rhea Lend | $203M | closed (README) | old kill path absent; new oracle stack sound — `README:CLOSED#15` |
| 46 | NEAR Intents | $3.8M incident | excluded | BSC-side; ZH2 fresh-incidents sweep — `r4:59` |
| 47 | Stader / Meta Pool / LiNEAR (3 names) | - | excluded | corpus-hit — `r4:59` |
| 48 | Ref Finance / Burrow (2 names) | - | PARKED | free but unexamined; small priority — `r4:59` |
| 49 | stUSDT | ~$56M | PARKED | not worth a wave-1 row — `r4:60` |
| 50 | Switchboard-Move / BisonFi / GoonFi / Rain / Phase-Stake / Scorch / Loopscale core / Drift / Save-Solend / marginfi / Raydium legacy / DeFiTuna / Bonzo Lend (13 names) | - | excluded | prior corpus excluded (checker-verified) — `r4:61` |

## r5 — r5-exotic

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | Popdex Bridge | $70.7M | closed (README) | full EIP-712 scheme reversed; replay/edit/release/UUPS/re-init revert — `README:CLOSED#21` |
| 2 | Beacon-proxy account module 0x535023ed | $423.9k ETH + ~$178k tokens | closed (in-lane) | all real fund movers gate msg.sender==address(this); live eth_calls hit empty fallback; tripwire on beacon upgrade — `r5:10; v15:5-7` |
| 3 | TokenSender 0xF6AE00D4 | $0 today | closed (README) | permissionless sweeper; historic victims dry and camped — `README:CLOSED#28; README:MONITOR` |
| 4 | No-auth sweeper 0xa9099c2d | $0 today | closed (README) | zero caller check; same bot fleet — `README:CLOSED#28; README:MONITOR` |
| 5 | Ambire Account 7702 | $96.5k across 165 EOAs | PARKED | execute paths ECDSA/session-gated; audited build; watch — `r5:13` |
| 6 | Hibachi settlement | $4.34M | closed (README) | imageID/verifier checked; proof replay; PROVER_ROLE — `README:CLOSED#7` |
| 7 | ZTO OFT | $0 | closed (README) | peer unwired; adapter balance 0 — `README:CLOSED#28` |
| 8 | ProfitDistributorProxy uninitialized impls | $0 | closed (README) | impl-storage-only init; live proxy already initialized — `README:CLOSED#28` |
| 9 | EntryPoint v0.8 postOp gas | n/a | closed (README) | maintainer-closed issue #606 — `README:CLOSED#28` |
| 10 | UniswapX v4 modular reactor | no deployment | closed (README) | no live v4 reactor found — `README:CLOSED#28` |
| 11 | WIN/GULD permissioned v4 hooks | $10.3M pools | closed (README) | approver-ECDSA + per-hook nonce + UR.msgSender — `README:CLOSED#10` |
| 12 | GPO Hooks | $100M claim / $9.6k real | closed (README) | paper supply; liquidity locked; permission bits exact — `README:CLOSED#9` |
| 13 | Unnamed Arbitrum v4 hook | $4.5M pool | LOW | 13.9KB unverified AFTER_SWAP hook — `README:LOW#24` |
| 14 | Euler v2 / EVK vault web | $303M | LOW | fresh eVault config enumeration gap — `README:LOW#25` |
| 15 | Airdrop/points claim class | $12.3M+ screened | closed (in-lane) | 807 contracts; all standard/auth-gated — `r5:32` |
| 16 | Permit-phishing RewardDistributor/RewardClaimer | - | excluded | requires victim signature; not E-U — `r5:33` |
| 17 | ERC-7540 Lagoon v5 | $141M | closed (in-lane) | settle/update onlySafe/onlyValuationManager — `r5:34` |
| 18 | UniswapX V2/V3/Exclusive/Priority reactors | - | closed (in-lane) | execution verifies Permit2 witness signature — `r5:35` |
| 19 | Anoma / Essential | - | PARKED | no live unprivileged target identified — `r5:35` |
| 20 | Paymasters | - | PARKED | no enumerable registry; budget-limited gap — `r5:36` |
| 21 | Restaking / AVS | - | PARKED | per-AVS contracts out of budget; no lead — `r5:37` |
| 22 | Tydro oracle misconfig | $130M Ink | excluded | USDe reserve frozen LTV=0; no path; ZH2 H2-02 — `r5:38` |
| 23 | EIP-7702 dead ends (Poisoner, 0x7785a22f, 0x34fff33d, Flashbots, MetaMask, Alchemy, Coinbase/Trust/Bitget/OKX/Fireblocks/Uniswap Calibur/Simple7702/BEBE/ZeroDev) (13 names) | - | closed (in-lane) | attacker-gated or audited signature/self-gated stacks — `r5:40` |
| 24 | Unverified MEV/arb system (deployer 0x000000000901403f) | $0 | closed (in-lane) | systematically probed; only ProfitDistributor impls accept initialize; all balances $0 — `r5:41` |
| 25 | v4 hook negatives (Aztec LBP, Angstrom, Clanker, Flaunch, Doppler) (5 names) | - | closed (in-lane) | audited/named/zero custody — `r5:42` |
| 26 | Morpho-Blue HERMES cluster (Base) | wash | closed (in-lane) | single address sole supplier+borrower; loop inflation — `r5:43` |
| 27 | Lagoon v0.5 other vaults | ~$141M | PARKED | stale-NAV sync-deposit theory; not swept — `r5:44` |
| 28 | Robinhood-Chain hook economy | $382k+ | PARKED | ecosystem lead; not individually assessed — `r5:45` |

## r6 — r6-new-chains

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | Firelight | $68M | closed (README) | deployed impl == patched repo; F1/F4 inert/dominated — `README:CLOSED#3` |
| 2 | Katana Vault Bridge / vbASSET stack | ~$27.7M L1 vault assets + $6.67M L2 vbUSDC | **OPEN** | L2 LZ minter peer(30101)=0xb5ba... set but lzReceive/peer binding unverified; L1 backing is ERC-4626 vaults (our reads); owner EOA; deep-dive — `r6:13` |
| 3 | Startale Earn | $857k vault; $50-105/day | **FINDING** | JIT epoch yield capture, fork-proven — `README:ZH4-02` |
| 4 | SparkDEX V4 | $16.3M | closed (README) | byte-exact Algebra 1.2.2; Kevlar hook closed — `README:CLOSED#25` |
| 5 | Shibarium canonical bridge | $5-8M escrow | closed (README) | patched pos-portal; forged exit/replay fail — `README:CLOSED#4` |
| 6 | Crystal | $25.5k | closed (README) | routerWithdraw targets in-tx scratchpad; 0 lifetime calls — `README:CLOSED#5` |
| 7 | Metric V1 | $7.05M | closed (README) | pool byte-identical; collect fees fixed — `README:CLOSED#22` |
| 8 | Kayen Finance V3 + LST | $882k | LOW | UniV3 fork + LST queue; 0 audits — `README:LOW#16` |
| 9 | Privacy Boost | $1.58M | closed (README) | verifiers re-ceremonied; all paths gate — `README:CLOSED#35` |
| 10 | Sophon Farm | $2.99M | LOW | custom boosted-farm math — `README:LOW#17` |
| 11 | Enosys AMM V3 | $6.83M | LOW | UniV3-fork drift — `README:LOW#18` |
| 12 | Ascend a0G | $3.56M | closed (in-lane) | queue claim self-scoped; pull queue-gated; no unguarded drain; P upgrade — `r6:23` |
| 13 | Gimo st0G | $3.5M plausible; exit ~$1.1k | PARKED | mint/updateMinter gated; impl unreviewed; exit liquidity tiny — `r6:24` |
| 14 | Nerona USD (USDnr) | $1.37M supply; ~$746k exit | PARKED | wrap onlySwapFacility; facility config unreviewed — `r6:25` |
| 15 | MoneyOnChain | $22.1M | closed (README) | MoC family; oracle senate capture ~96% float + 30d locks — `README:CLOSED#19` |
| 16 | RIF On Chain | $24.9M | closed (README) | same MoC analysis — `README:CLOSED#19` |
| 17 | NEOPIN Staking | $58.5M | closed (README) | GC node-staking admin; user product $159.8k drain-mode — `README:CLOSED#17` |
| 18 | Katana Perps (Niseko) | $1.34M | PARKED | addresses not located; explorer APIs 404 — `r6:29` |
| 19 | SakeFinance | $450-610k | LOW | Aave v3 fork oracle/reserve config — `README:LOW#19` |
| 20 | Kyo Finance | $807k | LOW | V3/V2 forks + ve-lock compounder — `README:LOW#20` |
| 21 | Unitus (dForce fork) | $4.4M | LOW | Compound-v2 empty-market class; Unitroller TBD — `README:LOW#21` |
| 22 | Perpl | $3.3M | LOW | unverified proxy; margin vault TBD — `README:LOW#23` |
| 23 | Levr Bet | $1.85M | LOW | Monad unverified — `README:LOW#23` |
| 24 | Neverland (Aave v3 fork) | $7.6M supplied | LOW | custom self-repay UserVaultBeacon — `README:LOW#22` |
| 25 | FaroSwap | $1.19M | LOW | V2/V3 fork on Pharos — `README:LOW#23` |
| 26 | BitFi Basis | $27M | LOW | watch — `README:LOW#23` |
| 27 | Zia | $1.9M | PARKED | small/0G fork — `r6:35` |
| 28 | Bond | $0.9M DL / ~$175k visible | PARKED | DL inflated — `r6:35` |
| 29 | FluxFlow V3 | $0.86M | PARKED | small — `r6:35` |
| 30 | InkySwap | $895k | PARKED | lockers clean — `r6:35` |
| 31 | UntitledBank | $115k | PARKED | Beosin-audited — `r6:35` |
| 32 | Katana DEX (Ronin) | $9.57M | PARKED | fork edges; not read — `r6:35` |
| 33 | Yuzu Money (Plasma) | $65.7M | PARKED | 2 audits; watch — `r6:35` |
| 34 | Chiliz Gov Staking | $35.5M | PARKED | addresses TBD — `r6:35` |
| 35 | ABC Pool (Conflux) | $5.95M | PARKED | not read — `r6:35` |
| 36 | Satsuma (Citrea) | $480k | PARKED | small — `r6:35` |
| 37 | Colend (CORE) | $198k TVL / $0 borrowed | closed (in-lane) | no debt; nothing to liquidate — `r6:35; d2d:L5` |
| 38 | Molten V3 (CORE) | $211k | PARKED | small — `r6:35` |
| 39 | Swappi V3 / SHUI / Nucleon (3 names) | - | PARKED | Conflux forks; not read — `r6:35` |
| 40 | Solid Yield (Fuse) | $616k | PARKED | small — `r6:35` |
| 41 | Meridian Lend/CDP | - | excluded | ZH3-H17 cluster — `r6:35` |
| 42 | JuiceSwap (Citrea + CDP) | - | PARKED | not read — `r6:35` |
| 43 | Neemo / Comet Swap V3 (2 names) | - | PARKED | Astar; not read — `r6:35` |
| 44 | sTLOS / REX (Telos) (2 names) | - | PARKED | not read — `r6:35` |
| 45 | Silo V3 MegaETH | $0 | closed (in-lane) | empty — `r6:35` |
| 46 | Tempo enshrined DEX | $15.8M | excluded | 1-byte stub; chain-native module; no EVM surface — `r6:35; r6:52` |
| 47 | RH-chain/other watchlist (BlazeSwap, Clearpool TPOOL, FanX, WoofSwap, VoltSwap, Monarq, Spectra V2, MegaETH L1 bridge) (8 names) | - | PARKED | watchlist; not individually assessed — `r6:35` |
| 48 | R25 (Pharos) | $150.8M | closed (in-lane) | institutional async vaults; KYC-gated — `r6:45` |
| 49 | Plasma Savings Vaults (Veda) | $1.1M | closed (in-lane) | permissioned withdrawals; role-gated — `r6:46` |
| 50 | PonsV2FeeEscrow | $2.04M | closed (in-lane) | claims self-scoped; CEI — `r6:47` |
| 51 | HoodLock RobinhoodLocker | - | closed (in-lane) | withdraw onlyLockOwner; admin fees only — `r6:48` |
| 52 | Zircuit ZtakingPool | $58.5M | closed (in-lane) | migrate gated; withdraw self-debit — `r6:49` |
| 53 | Katana LxLy bridge | - | closed (in-lane) | GER manager gates updateExitRoot — `r6:50` |
| 54 | OP-stack canonical bridges (Soneium/Ink/Unichain/World/Shape/Zora/BOB/Lisk/Superseed) (9 names) | - | PARKED | quick pass only; left to r5 — `r6:53` |
| 55 | Rocket Markets / Narwhal Finance (2 names) | - | PARKED | sub-bar ($117/$380) — `r6:54` |
| 56 | Swaap / Enjoyoors / Sherpa / Aegis hooks (4 names) | - | PARKED | sub-bar — `r6:54` |
| 57 | Curvance (Monad) | $80.68M debt | closed (in-lane) | full census; no account at true liquidation threshold — `r6:55; d2d childB` |
| 58 | BDEX V2/V3 (BOT) | - | excluded | prior E-U $0; byte-identical UniV3 — `r6:55` |
| 59 | Vena (Fluent) | - | excluded | prior E-U $0 — `r6:55` |
| 60 | Chain-level TVL deflation (Deri, Noon, Mellow, SolvBTC, PumpBTC, River, Avalon, Shoebill, LayerBank, Meson, iZiSwap-BOB, TeleSwap, Eigenpie, SyncSwap-Sophon) (14 names) | ~$0-50k | excluded | no live funds worth a target — `r6:56` |
| 61 | Xai / Superseed / Lisk / Zora / Shape DEX (5 names) | dust | PARKED | dust — `r6:56` |
| 62 | Sovryn-on-BOB | max pool $7.3k | PARKED | dust — `r6:56` |
| 63 | RPC-dead/no-money chains (Canto, Wanchain, Botanix, Corn, Velas, Palm, Oasis) (7 names) | - | excluded | no execution / <=$100k — `r6:57` |
| 64 | Tropykus kUSDT/kRIF | ~$230k nominal; cash ~$4 | closed (in-lane) | both markets still listed but cash 4.39 rUSDT / 0.061 rRIF vs 191.9k/416.6k borrows; insolvent, no extractable cash; override resolved — `r6:58 + 2026-10-18 check` |

## r7 — r7-beyond-llama

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | RealT RMM v3 + RealTokenWrapper | $29.3M nominal | **FINDING** | whitelist gate + exit market ~$0; E-U $0 — `README:ZH4-07` |
| 2 | DeepLock Locker v1/v2 | $2.34M | closed (README) | 63,991 locks enumerated; all withdraw gates hold — `README:CLOSED#20` |
| 3 | Zappy (Liquity-v1 fork) | ~$90k live | LOW | not diffed vs patched Liquity; d2d L7 says domain dead (contradiction; on-chain evidence wins) — `README:LOW#8` |
| 4 | PegaSys V2 | ~$85k stables | LOW | unverified UniV2-style pairs; 44% of chain USDC — `README:LOW#9` |
| 5 | Unnamed zkSync Era settlement vault 0x621425a1 | $5.5M+ (1,121 ETH + 2.18M USDC + 181k USDT + 12.5M ZK) | **OPEN** | unverified 61.9KB; public withdraw(address,address,uint256); fresh caller underflow; owner EOA; 199k txs; decompile accounting — `r7:15 + 2026-10-18 check` |
| 6 | Elastos OmniBridge | $2.03M | LOW | unverified OmniBridge v2 impl; validator/replay path — `README:LOW#10` |
| 7 | Hashport escrows | $1.78M | LOW | escrow withdraw auth + Hedera mint validation — `README:LOW#11` |
| 8 | Hop Protocol (sunset) | $3.71M | LOW | hToken mint/burn + bonder custody — `README:LOW#12` |
| 9 | cVault Finance | $6.40M DL | LOW | vault addresses unverified — `README:LOW#13` |
| 10 | zkSync Wrapped Ether clone | $3.61M | closed (in-lane) | WETH-like; zero-balance withdraw reverts — `r7:20` |
| 11 | TelosNativeOFT | $880k | LOW | LZ OFT adapter diff pending — `README:LOW#15` |
| 12 | OTSea | $582k | LOW | order escrow lifecycle unread — `README:LOW#14` |
| 13 | Flare accumulator | $795.6k | closed (in-lane) | fallback-only; zero outbound txs ever; no public extraction — `r7:23` |
| 14 | MoreMarkets.xyz | $30 RLUSD vault; $432k is mToken market cap | PARKED | located; Ethereum RLUSD vault totalAssets $30.68; $432k is hyperETH/BTC/USD token market value, not custody; no protocol pot — `r7:24 + 2026-10-18 check` |
| 15 | zkSwap V2 (legacy zkSync AMM) | $533k | **OPEN** | factory 0xeeE1... 48 pairs, unverified UniV2 fork; pair 0 holds 8,926 USDC + 3.74 WETH; decompile/diff — `r7:25 + 2026-10-18 check` |
| 16 | Gravita Protocol | $399k DL | PARKED | addresses TBD; Liquity v1 fork — `r7:26` |
| 17 | MUFEX | $6.5k live (DL $276k stale) | PARKED | 3 vault contracts; USDT 1,766 Arb + 3,234 Poly + 1,486 Mantle + ~0.3 BSC; below bar — `r7:27 + 2026-10-18 check` |
| 18 | Lendle | $174k live | PARKED | 11 reserves, $174k aToken cash, ~$13k borrows; no empty market; Aave-v2 fork, no concrete path — `r7:28 + 2026-10-18 check` |
| 19 | xDollar | $161k nominal; collateral ~$11.7k | closed (in-lane) | IoTeX trove managers: 28 troves, 143.9k XUSD debt, 3.05M WIOTX collateral (~$11.7k) => ~8% TCR; insolvent, no extraction — `r7:29 + 2026-10-18 check` |
| 20 | Ronin deprecated staking manager 0x8Bd81a19 | $157k (756k RON + 101.5k AXS) | closed (in-lane) | proxy impl admin-only withdrawEther/withdrawToken revert for random caller; no user unstake/exit in impl; P/S class — `r7:30 + 2026-10-18 check` |
| 21 | Gnosis arbitraryCalls proxy | $41k | PARKED | below bar — `r7:32` |
| 22 | Astar unverified proxy | $30.8k | PARKED | below bar — `r7:32` |
| 23 | Gnosis 2021 clone depositAlice | $10.3k | PARKED | dormant; below bar — `r7:32` |
| 24 | Elastos stELA | $10.8k | PARKED | below bar — `r7:32` |
| 25 | Energi EnergiTokenLock | $9.1k | PARKED | live claims; below bar — `r7:32` |
| 26 | Telos Escrow | $123.4k | PARKED | official bridge escrow; unexamined — `r7:32` |
| 27 | IMX game-vault cluster | ~$40k | PARKED | creator cluster; below bar — `r7:32` |
| 28 | zkSync Basilisk bETH | $90.9k | PARKED | DL dead; unexamined — `r7:32` |
| 29 | MemeDex (Conflux) | $56k DL | closed (README) | ghost reserves; all pairs zero — `README:CLOSED#30` |
| 30 | SparkDEX Perps | TBD | PARKED | addresses TBD — `r7:32` |
| 31 | SiO2 Finance (Astar) | $54k | PARKED | Compound fork; small — `r7:32` |
| 32 | YuzuSwap / GemKeeper (Oasis) (2 names) | $100k / $91k | PARKED | APIs closed — `r7:32` |
| 33 | Particle LAMM (Blast) | $138k | PARKED | not read — `r7:32` |
| 34 | illumineX (Sapphire) | $189k | PARKED | cross-chain bridge; not read — `r7:32` |
| 35 | PegaSys farm Chef quest | - | PARKED | dup of PegaSys row; farm unread — `r7:32` |
| 36 | o1.exchange launchpad vesting | - | PARKED | audited 2026-09-08; new — `r7:32` |
| 37 | Prior-corpus closes (Sceptre, FlareBank, Nile, Kinetix, Orbit, Splice, MonoSwap, Thruster, FstSwap, BSCSwap, EmpireDEX, BakerySwap, MinMax, ReactorFusion, Orchid, Swapr V3, 1Hive, Gardens, SBCWrapper, Syscoin bridge, Enjin, Sandbox, Agave) (23 names) | - | excluded | prior waves; do not re-check — `r7:44` |
| 38 | Dead+funded screen (429 rows, 263 un-covered, 316 triaged) | - | closed (in-lane) | no new flagship; mostly covered protocols/CEXs — `r7:45` |
| 39 | marginfi $36.9M dead | - | excluded | metadata artifact — `r7:45` |
| 40 | RealT Tokens / RMM Marketplace V2 | $155M/$29.08M rows | closed (README) | oracle-valuated RWA supply; v2 pool empty — `r7:45; README:ZH4-07` |
| 41 | Chain sweeps (Energi, Syscoin, Astar, Gnosis, Flare/Songbird, Ronin, Immutable) (7 names) | - | closed (in-lane) | nothing fresh; system contracts/Safes — `r7:46` |
| 42 | Failed chain probes (Linea, Mantle, Blast, Chiliz, Kaia, Core, Conflux eSpace, Oasis, IoTeX, Kava, Viction, Moonbeam, opBNB, BTTC, zkLink Nova, Velas) (16 names) | - | PARKED | no open top-balance API; <=15 min each — `r7:47` |
| 43 | Channel failures (DeBank, DappRadar, DefiSafety, DefiSentinel, Alchemy dapps) (5 names) | - | excluded | no data — `r7:48` |
| 44 | Social/style-of-life sweep (GameFi, Telegram, NEAR Confidential, Canton) | - | PARKED | no new custody target — `r7:49` |
| 45 | Verified-safe probes (zkSync WETH, Flare accumulator, RMM v2) (3 names) | - | closed (in-lane) | negative — `r7:50` |

## d2a — d2a-fresh14d

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | Mezo Swap | $5.67M | closed (README) | byte-identical Aerodrome/Slipstream; fork swaps exact — `README:CLOSED#26` |
| 2 | Statics Protocol | $704k | LOW | vault verified; hook not located — `README:LOW#27` |
| 3 | Mosh | $308k | LOW | fresh swarm/vault system; no source located — `README:LOW#27` |
| 4 | HedgeHood Stock Yield | $65.9k | LOW | operator digest handshake; replay/auth unread — `README:LOW#27` |
| 5 | Bordrless Bridge | $112.7k | LOW | day-old Solana bridge; unpublished code — `README:LOW#27` |
| 6 | Ditto Earn | $104k DL; yieldSplit totalAssets $45.9M with $0 cash | PARKED | operator-posted NAV; proxy holds 0 USDC; no protocol pot; deposit-dependent dilution only — `d2a:13 + 2026-10-18 check` |
| 7 | Abyss DEX | $156k | PARKED | addresses TBD; code unseen — `d2a:14` |
| 8 | Ouro DEX V3 | $124k | PARKED | addresses TBD — `d2a:15` |
| 9 | Qualia | $89k | PARKED | contracts not located; Kintsu yield engine — `d2a:16` |
| 10 | BaiBai | $120k | PARKED | contracts not located; Base DEX — `d2a:17` |
| 11 | DeepSwap | $78.7k | **OPEN** | Raydium cp-swap fork program HCrCy...; fee-recipient/withdraw auth diff unread — `d2a:18` |
| 12 | The Moats | $1.42M | closed (in-lane) | audited MultiLockMoat; all sensitive paths owner/MoatManager-gated — `d2a:19` |
| 13 | Titan Locker | $162k | closed (in-lane) | every state-changing path onlyOwner; no UNCX share bug — `d2a:20` |
| 14 | Motoswap / VampChef | $55.6k | **OPEN** | proxies; legacy accRewardPerShare/lpSupply sync and emergencyWithdraw unread — `d2a:21` |
| 15 | Nullmask / Tacit (2 names) | $71k / $69k | PARKED | contracts not located; privacy pools — `d2a:22` |
| 16 | Alcor Liquid Staking / Alcor Bridge (2 names) | $90.9k / $87.7k | PARKED | contracts not located; EOSIO/bridge — `d2a:23` |
| 17 | USDP (Base) fresh pool | GT artifact | closed (in-lane) | Doppler hook; $46.7M reserve impossible; no extractable value — `d2a:33` |
| 18 | TREV/Trevifolk (Monad) | GT artifact | closed (in-lane) | pool holds 4.49 USDC; fixed-supply ownerless token — `d2a:34` |
| 19 | trUSD/strUSD (Monad) | $577k/$572k | closed (in-lane) | mint simulated revert; owner contract controls both — `d2a:35` |
| 20 | Statics GenesisVault | $704k | closed (in-lane) | verified + _enforceSolvency; clean — `d2a:38` |
| 21 | Fresh-pool sweep (GeckoTerminal page 1) | - | closed (in-lane) | no other >=$50k genuine custody — `d2a:39` |
| 22 | Pre-covered/excluded (Papertrade, Fang, HertzFlow, JUSD, BeraFarm, BitSafe, SundaeSwap, Metric, JPYdf, Derive, SunSwap, Pacifica, Startale, UNCX) (14 names) | - | excluded | already assigned/excluded — `d2a:40` |

## d2b — d2b-staleprice

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | Shibarium stale-WBONE cluster | ~$17.2k pooled; +$877/cycle | **FINDING** | fork-verified 3x; bridge exit MED — `README:ZH4-03` |
| 2 | shibbex WBONES/WETH + dogswap WBONES/WETH (2 names) | ~$0.4k | covered (ZH4-03) | covered by ZH4-03; do not deep-dive — `d2b:12; README:ZH4-03 deep-dive in flight` |
| 3 | Aurora APE/wNEAR | $644 | PARKED | entry via Rainbow bridge unverified; one-shot small — `d2b:13` |
| 4 | Celo mCUSD/BTC | +$691 nominal | closed (in-lane) | TRAP: all Celo BTC venues drained; bridge idle — `d2b:14` |
| 5 | Aurora BUSD/wNEAR | - | closed (in-lane) | trap-leaning; BUSD exit circular — `d2b:15` |
| 6 | shibbex SHEX/WETH | $2,495 | closed (in-lane) | locked: only 58 SHEX outside pool — `d2b:16` |
| 7 | Sonic 9MM trio | phantom | closed (in-lane) | llama price 80x off; pools correctly priced — `d2b:17` |
| 8 | Conflux MemeDex | $56k DL | closed (README) | all 13 pairs hold zero; ghost reserves — `README:CLOSED#30` |
| 9 | KCC KuSwap DAI pools | phantom | closed (in-lane) | broken legacy DAI; internally consistent — `d2b:19` |
| 10 | WEMIX CLMM | $1.99M | LOW | not CLMM-swept — `README:LOW#26` |
| 11 | Fuse Voltage V4/AMM | $267k/$71k | LOW | Algebra CLMM + AMM; scan inconclusive — `README:LOW#26` |
| 12 | AZverse Perps custody wallets | $50.4M | excluded | plain EOAs/custody; not E-U — `d2b:22; README:CORR#12` |
| 13 | Shibarium dust list (10 factories) | <$5 each | closed (in-lane) | complete child scan — `d2b:45` |
| 14 | Chains unreachable (Canto, Velas, DFK, Moonbeam) (4 names) | - | excluded | no execution; Moonbeam halted 2026-08-10 — `d2b:46` |
| 15 | Fuse Voltage AMM enumeration | $267k ALG | closed (in-lane) | all token reads null on two RPCs; inconclusive — `d2b:47` |
| 16 | Perp/oracle dead-derivative shortlist (FinNexus, InsureDAO, Particle LAMM, Kinetix) (4 names) | - | excluded | no actionable frozen-mark venue — `d2b:48` |

## d2c — d2c-dormantdao

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | HAI (Let's Get HAI) | $122k treasury + ~$927k protocol | **FINDING** | live governance capture; hardening unexecuted at check — `README:ZH4-01` |
| 2 | Ampleforth (FORTH) | $3.19M | closed (README) | timelock admin moved to 2-of-4 Safe; queue from governor reverts — `README:CLOSED#29` |
| 3 | Idle Finance | $310k+ | closed (README) | timelock admin moved to 3-of-6 Safe; queue reverts — `README:CLOSED#29` |
| 4 | Goldfinch | $802k | closed (README) | no Governor; token lacks votes interface; 6/12 Safe — `README:CLOSED#29` |
| 5 | BadgerDAO | $1.75M | closed (README) | no Governor; 5/8 Treasury Safe; active 2026 — `README:CLOSED#29` |
| 6 | mStable | ~$53k + 2.3M PT units | closed (README) | no Governor; human Safes; dormant — `README:CLOSED#29` |
| 7 | TrueFi | $0.01 timelock | closed (README) | TFIP-42 moved roles to 4-of-6 Safe; governor PROPOSER-only — `README:CLOSED#29` |
| 8 | Cream Finance | $0.78M v1 cash | closed (README) | no Governor; 2-of-4 Safe key-gated P-class — `README:CLOSED#29` |
| 9 | StrongBlock | already drained | closed (README) | attacker holds Governor — `README:CLOSED#29` |
| 10 | Fei/Tribe | husks | closed (README) | timelock disabled 2023 — `README:CLOSED#29` |
| 11 | Dopex/Stryke | - | closed (README) | rebrand, not capture — `README:CLOSED#29 (Dopex context)` |
| 12 | Aragon-legacy DAOs | unknown | closed (README) | enumerated gap only; subgraphs dead — `README:CLOSED#31; README:LOW#28` |
| 13 | Swerve | $304.9k LP | excluded | corpus; executor Agent empty; 4pool renounced — `d2c:41` |
| 14 | Ooki DAO | <$15 | excluded | corpus; no token-vote path — `d2c:42` |
| 15 | Panther | $14-18k realized | excluded | exploited Aug 6; protections restored — `d2c:46` |
| 16 | Unicly / TOP / BonkDAO / BarnBridge / Term / Neutron / Yam / Moonwell (8 names) | - | excluded | already exploited/covered — `d2c:47` |
| 17 | Balancer | - | closed (in-lane) | actively governed wind-down; wrong side of dormant condition — `d2c:48` |
| 18 | Seamless (Base) | $6.6M wind-down | excluded | corpus-covered; active distribution — `d2c:49` |
| 19 | Sceptre / Nucleus / UTONIC (3 names) | - | excluded | corpus-covered — `d2c:50` |
| 20 | InceptionLRT | - | PARKED | unchecked; no Governor/DEX indicators surfaced — `d2c:50` |
| 21 | Reserve hyUSD / Olas (2 names) | - | closed (in-lane) | attacks stopped; Olas thresholds raised — `d2c:51` |
| 22 | Dopex / Vesta / 88mph / Element / Fuji / Gro (6 names) | - | closed (in-lane) | no Compound-style dormant Governor with funds — `d2c:52` |
| 23 | Index Coop / PowerPool / BasketDAO / Domani / Cook / Indexed Finance (6 names) | - | excluded | corpus hits — `d2c:53` |
| 24 | Fantom/Moonbeam/Aurora ghost farms | - | closed (in-lane) | team multisigs/farm accounting; P-class — `d2c:54` |

## d2d — d2d-liqsweep

| # | Target | Live funds | Disposition | Why / citation |
|---|---|---|---|---|
| 1 | RAAC PSM pmUSD -> sUSDS | $36.9k sUSDS; +$9.9k latent | PARKED | swap reverts today: 17.07% < 20% reserve floor; trigger watch ReserveRatioFloorUpdated or >=$10k sUSDS deposit — `d2d:19` |
| 2 | Mezo MUSD redemption arb | +$894 max | PARKED | live but below bar; already farmed — `d2d:20` |
| 3 | HyperEVM Morpho kHYPE position | $356k conditional | PARKED | HF 1.0042; not liquidatable today; keeper race — `d2d:21` |
| 4 | Robinhood Chain spUSDG Morpho | $390k conditional | PARKED | HF 1.0026; not liquidatable today — `d2d:22` |
| 5 | Enosys Loans troves | $689/liq conditional | PARKED | lowest ICR 1.158 vs MCR 1.10; no liquidations today — `d2d:23` |
| 6 | Metronome Synth msUSD | $45.8M nominal | closed (in-lane) | swap active but 10% fee vs ~10% discount => -9% round trip; no liquidatable positions — `d2d:24` |
| 7 | Fedz FUSD | $1.61M at $0.957 | PARKED | redemption restricted to Fedz-NFT holders — `d2d:25` |
| 8 | Alchemix alUSD Transmuter | $10.1M at $0.9528 | PARKED | drip-limited by repayments; unscanned — `d2d:26` |
| 9 | USDB (Blast) | $9.88M at $0.9896 | PARKED | ~1% via bridge exit; below bar — `d2d:27` |
| 10 | satUSD (River) | $124.7M at $0.9938 | PARKED | 0.62% discount; conversion path unscanned — `d2d:28` |
| 11 | BEND (Berachain) | $6.41M borrowed | closed (in-lane) | 0 accounts HF<1 with collateral; keepers active; exits thin — `d2d:S1` |
| 12 | Euler v2 / EVK Sonic | ~$1-2M borrowed | closed (in-lane) | 461 Liquidate events; keeper-active; no vacuum — `d2d:S2` |
| 13 | Neverland canonical Pool | ~$24k latent | LOW | HF 1.0204; needs -1.96%; full history scan — `d2d:L1; README:LOW#4` |
| 14 | Neverland isolated market | ~$3.1k latent | LOW | HF 1.0108; needs -1.07%; debt-token drift flagged — `d2d:L2; README:LOW#7` |
| 15 | Unitus (Conflux) | ~$33k debt | LOW | ceiling ~$1.3-1.7k; no known liquidatable — `d2d:L3; README:LOW#5` |
| 16 | Unitus all-4-chain child sweep (Conflux/Arbitrum/BSC/Ethereum) | best single ~$370 gross; ~$1.2-1.4k multi-chain best case | closed (in-lane) | no single-shot >$1k; USX exit is a TRAP (Swappi/Camelot/Pancake drained); no claims>assets race — `d2d:childC` |
| 17 | Voltage Lending (Fuse) | ~$85 | LOW | 2 real accounts +$44/+$41; 7 zero-collateral traps — `d2d:L4; README:LOW#6` |
| 18 | Colend (CORE) | $0 borrowed | closed (in-lane) | no debt; nothing to liquidate — `d2d:L5` |
| 19 | Klend | $0 / dead | closed (in-lane) | klend.finance parked; DL entry BSC/OKExChain $0; no Kaia lending venue — `d2d:L6` |
| 20 | Zappy (Telos) | ~$90k live per r7; DL DEX $2.6k | LOW | d2d domain-dead contradicts r7 on-chain reads; README takes r7 on-chain evidence; verify troves before action — `d2d:L7; README:LOW#8` |
| 21 | Curvance (Monad) | $80.68M debt | closed (in-lane) | 24,334 Borrow events; no account at true liquidation threshold — `d2d:childB` |
| 22 | Takara Lend (Sei) | ~$0.011 extractable | closed (in-lane) | 558 live borrowers; only material underwater account stripped; max $0.0055 — `d2d:childA` |
| 23 | dTRINITY dLEND (Sonic) | $0 borrowed | closed (in-lane) | gap closed — `d2d:S-neg` |
| 24 | Silo v2 Sonic | $0 borrowed | closed (in-lane) | dead leg — `d2d:S-neg` |
| 25 | LayerBank | $0 except RSK/RHC | closed (in-lane) | RSK prior corpus; RHC other lanes — `d2d:S-neg` |
| 26 | ZeroLend | $0 borrowed | excluded | shut Feb-2026; prior H-5 census — `d2d:S-neg` |
| 27 | Ionic / Angle / Mendi / YeiLend (4 names) | - | excluded | prior corpus / shut — `d2d:S-neg` |
| 28 | INIT Capital / Orbit / Impermax v2 / Sumer.money / Gravita (5 names) | $0-tiny | closed (in-lane) | nothing — `d2d:S-neg` |
| 29 | Kaia / Chiliz / WEMIX / Metis / Fuse / Manta / Blast / Mode / Core lenders (9 names) | - | closed (in-lane) | no material borrowed or dead — `d2d:S-neg` |
| 30 | Aave v3 long-tail legs (Celo/Gnosis/Sonic/Linea/Scroll/Manta/Mode) (7 names) | - | closed (in-lane) | keeper-run; sizes small — `d2d:S-neg` |
| 31 | CDP depeg re-screen (~423 stablecoins) | - | closed (in-lane) | no new depegs; known artifacts — `d2d:S-neg` |
| 32 | Dolomite (Berachain/Ethereum) | $2.42M/$396M borrowed | closed (in-lane) | no under-margined account with collateral; sticky Liquid gated to whitelisted partial liquidators — `d2d:S-neg` |
| 33 | Altura / AVLT | $9.7M bad debt | excluded | ZH2 H2-02; lender-side loss, not E-U — `d2d:35` |
| 34 | Main Street USD (msUSD) | $289.94 USDC minter | closed (in-lane) | no redeem function; collapsed — `d2d:36` |
| 35 | Tangible USDR / Lybra eUSD v2 / Fathom FXD / Sovryn DLLR / Babelfish XUSD / Resolv USR / Cod3x cdxUSD / USDD / Kolibri / Liquid Loans / AP USDA / Anzen / HexTrust / LISUSD / BOLD / satUSD / USDo / REUSD (18 names) | - | closed (in-lane) | dead artifacts/custodial/at peg; no permissionless par route — `d2d:37` |
| 36 | Flying Tulip Lend (Sonic $2.2M + Ethereum $4.2M borrowed) | $6.4M | PARKED | hybrid PCA/PUT soft liquidation; not scoped — `d2d:94` |
| 37 | Hydro Lending + Neptune (Injective) (2 names) | $2.4M + $2.0M | PARKED | CosmWasm path not verified — `d2d:94` |
| 38 | TermMax (Ethereum) | $21M | PARKED | fixed-rate AMM liquidation engine not scoped — `d2d:94` |
| 39 | Silo v2 Arbitrum/ETH/Avax | $2.2M borrowed | PARKED | isolated-pair borrower enumeration not run — `d2d:94` |
| 40 | apxUSD (Base) | $9.4M at $0.9859 | PARKED | no permissionless redeem path found in quick pass — `d2d:94` |
