# PASS3-RECON — ALL ROWS (per-name disposition)

Companion to `../README.md`. One row per named candidate or grouped name-list. Columns: **Lane | Candidate | Disp | Evidence / citation**.
Disp: RF=README-FINDING · RC=README-CLOSED · LC=LANE-CLOSED · PC=PRIOR-COVERED · PP=PRIOR-PARTIAL · NP=NOT-A-PROTOCOL · OPEN.

## pass3 README layer (already handled)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| README | Pharaoh CL gauge (Avax + Nile/Nuri/Cleopatra) | RF | P3-01; pharaoh-gauge/; gauge-family.md |
| README | BiFi Lending | RF | P3-02; bifi/; paused |
| README | SimpleAccount/Guardian | RF | P3-03; simpleaccount/ |
| README | Cooler MonoCooler | RF | Tier-3 #13; cooler-monocooler/ |
| README | Eva Markets | RF | Tier-3 #1 (removed) |
| README | Waterline Reservoir | RF | Tier-3 #2 |
| README | Trueo | RF | Tier-3 #12; trueo/ |
| README | OnRe | RF | Tier-3 #10 |
| README | Cetus CLMM, STON.fi V2, RISEx, Gimo, Verio, Manifest, Hyperbeat, Sport.fun | RC | removed list |
| README | Wildcat, Deri V4, Predict Fun, Atomic Green, Argent, Secured Finance, AlpsCon, launchpads, bridges, DEX forks, yield, LST, RWA, curators, approvals, leaked keys, time-wrap, fresh pools | RC | closed table |

## lane-old.md (22 ranked + triaged-out)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane-old | Wildcat Protocol | RC | wildcat.md |
| lane-old | Deri V4 | RC | deri.md |
| lane-old | Metronome Synth | LC | quote marks msUSD at $0.884 |
| lane-old | Sovryn Zero | LC | TCR 11.06, 31 troves |
| lane-old | Flux Finance | LC | cf=0 public markets |
| lane-old | Katana DEX (Ronin) | LC | 767-pair skim <$10 |
| lane-old | ABC Pool (Conflux) | OPEN | unverified impl; ConfluxScan SPA |
| lane-old | Quickswap V3 | PP | prior non_llama #138 |
| lane-old | Agni Finance | LC | dex-evm closed |
| lane-old | VVS Flawless | OPEN | not reached |
| lane-old | PinkSale locks | LC | owner renounced |
| lane-old | MUX Perps | OPEN | GMX-v1 recipe untested |
| lane-old | Blur Lending (Blend) | LC | audited |
| lane-old | Alpaca Finance 2.0 | PC | ZH1 H-20; repo 404 |
| lane-old | Scallop Lend | PC | prior non-EVM |
| lane-old | Turbos/Mole/Aftermath | PC | prior non-EVM |
| lane-old | Cetus CLMM | RC | removed |
| lane-old | FluidTokens | PC | prior non-EVM |
| lane-old | Gravity Bridge | LC | validator-set |
| lane-old | ioTube | PC | key incident |
| lane-old | Wrapped.com | NP | custodial |
| lane-old | stUSDT | OPEN | unchecked proxy |
| lane-old | triaged list: ether.fi, Lido, Aave, Uniswap v2/v3, Curve, Maker/sDAI, Fraxlend, Frax Ether, Frax Swap, Pancake V3/StableSwap, Sushi V3, Camelot V3, RealT, NEOPIN, BSCSwap, Fulcrom, PulseX, SyncSwap, BakerySwap, Blur Bids, MetalX, xExchange, WhaleEx, ICPSwap, DeDust/STON/Storm, Meld Gold, Lofty, JustCryptos, GETH(Guarda), ExinPool, APX Bridge, Paradex Bridge, Sky RWA, stake.link, Meta Pool ETH, GLIF, Stakee, Hydration, STON.fi, Summer.fi, Realms | PC/NP | grouped (44) |

## lane-lending.md (20 ranked + 46 triaged)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane-lending | Cooler MonoCooler | RF | Tier-3 #13 |
| lane-lending | EtherFi Borrowing Market | OPEN | Spoke unverified; RWA feeds |
| lane-lending | Flex | LC | oracle==PPS |
| lane-lending | JPY DeFi | LC | JPY feeds correct |
| lane-lending | SomniaLend | LC | configs sane |
| lane-lending | Threshold thUSD | LC | Liquity v1 |
| lane-lending | Mezo Borrow | OPEN | RPC unreachable |
| lane-lending | Venus Flux | OPEN | oracle not traced |
| lane-lending | Flux Finance | LC | dup lane-old |
| lane-lending | Fraxlend | LC | 71 pairs |
| lane-lending | BAMM | LC | MED |
| lane-lending | Revert Lend | LC | C4 2024-03 |
| lane-lending | Native Credit Pool | LC | HIGH |
| lane-lending | Templar Protocol | LC | EVM $0 |
| lane-lending | Enosys Loans | LC | HIGH |
| lane-lending | VETRO | LC | HIGH |
| lane-lending | mStable V2 | LC | dHEDGE |
| lane-lending | BIMA/BTCFi CDP | LC | out of EVM |
| lane-lending | Hyperbeat USD | RC | removed |
| lane-lending | Rezerve Lending | LC | Euler curator |
| lane-lending | prior hits: USDD, Jupiter Lend, Tydro, Curve LlamaLend(+V2), STRATO, Alpaca 2.0, Kava, Vesu, Vena, Morpho Midnight, Capyfi, Inverse, YeiLend, MORE, Longbow, JustLend V2, Arkadiko, Bastion, Orbit, Scallop, marginfi, RealT RMM, Sovryn, Mystic, Kinza, Mendi, Enosys Bridge | PC | grouped (27) |
| lane-lending | dust: dTRINITY, Bastion, XOXNO, Teller, Swaylend, Delea, Orbit | LC | <$1M |
| lane-lending | non-EVM: Figure, Hydration, Zest, Project 0, Jupiter Offerbook, Liquidium, FluidTokens, Swaylend, Affluent/Delea, XOXNO, REX, Rujira, Kava, Mezo | NP | out of scope |

## lane-dex-evm.md (19 rows)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane-dex-evm | Pharaoh CL gauges ×5 | RF | P3-01 |
| lane-dex-evm | Lista DEX | LC | Curve port |
| lane-dex-evm | Agni | LC | $0 |
| lane-dex-evm | Merchant Moe LB | LC | $0 |
| lane-dex-evm | Pharaoh DLMM | LC | $0 |
| lane-dex-evm | Angstrom | LC | $0 |
| lane-dex-evm | Katana DEX | LC | $0 |
| lane-dex-evm | Thruster V3 | LC | $0 |
| lane-dex-evm | Frax Swap | LC | $0 |
| lane-dex-evm | SyncSwap | PC | ZH4 vault V1 closed |
| lane-dex-evm | Mezo Swap/Tigris | OPEN | unverified |
| lane-dex-evm | BulbaSwap V3 | OPEN | no explorer API |
| lane-dex-evm | Tempo Stablecoin DEX | NP | precompile |
| lane-dex-evm | HyperSwap V2/V3, Nado, BDEX V3, RocketSwap, Icarus/up/Aero Lite, Metric, SparkDEX, BSCSwap | PC | grouped (8) |
| lane-dex-evm | VVS Flawless, MerlinSwap, DOOAR V2, Diamond Finance, Gate Swap | OPEN/PP | not reached (5) |

## lane-dex-nonevm.md (20 ranked + 12 triaged)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane-dex-nonevm | Cetus CLMM | RC | removed |
| lane-dex-nonevm | STON.fi V2 | RC | removed |
| lane-dex-nonevm | Manifest Trade | RC | removed |
| lane-dex-nonevm | RocketSwap Anubis | LC | fake USDT; bridge backed |
| lane-dex-nonevm | Byreal CLMM | LC | source clean |
| lane-dex-nonevm | SaucerSwap V2 | OPEN | distinct CLMM |
| lane-dex-nonevm | DeepBook V3 | LC | audited |
| lane-dex-nonevm | Futarchy AMM | LC | audited |
| lane-dex-nonevm | Minswap | LC | audited |
| lane-dex-nonevm | PancakeSwap V3 Solana | OPEN | not reviewed |
| lane-dex-nonevm | Bittensor dTAO | OPEN(parked) | pallet |
| lane-dex-nonevm | Hydration DEX | OPEN(parked) | native |
| lane-dex-nonevm | Osmosis DEX | PC | native; bOSMO separate |
| lane-dex-nonevm | ICPSwap | OPEN(parked) | address=ledger |
| lane-dex-nonevm | InitiaDEX | OPEN(parked) | native Move |
| lane-dex-nonevm | Temple | NP | Canton P-class |
| lane-dex-nonevm | Cantex | NP | Canton P-class |
| lane-dex-nonevm | XRPL DEX | PC | native |
| lane-dex-nonevm | Stellar AMM | PC | native |
| lane-dex-nonevm | MetalX/xExchange/Gala Swap | OPEN(parked) | old native |
| lane-dex-nonevm | triaged: Sui old pkgs (BlueMove/Typus/Scallop/Full Sail/Virtue), Turbos, Bluefin, Momentum, ThalaSwap, FlowX, BisonFi, GoonFi, Scorch, Tessera, FluxBeam, Saber, Serum, Raydium V3, Jupiter Lend DEX, SundaeSwap V3/V4, SUNSwap V3/V4, BDEX, Zia/Bond, Kumbaya/FaroSwap/Vena | PC | grouped (12 clusters) |

## lane-lst.md (18 ranked + lists)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane-lst | Verio | RC | removed |
| lane-lst | Gimo | RC | removed |
| lane-lst | Hyperbeat | RC | removed |
| lane-lst | Prime Staking V3_2 | LC | MED solvency, not E-U |
| lane-lst | Ascend | LC | verified |
| lane-lst | Endur | OPEN | no RPC |
| lane-lst | InceptionLRT | LC | small |
| lane-lst | Biquid | LC | non-EVM |
| lane-lst | OpenGDP | LC | Karak |
| lane-lst | JustLend sTRX | OPEN | unreviewed |
| lane-lst | Stakee | LC | canonical TON pool |
| lane-lst | Adrastea | NP | native validator |
| lane-lst | Hylo LSTs | LC | audited |
| lane-lst | CatFee | NP | 9 EOAs |
| lane-lst | Qearn | OPEN | tooling |
| lane-lst | White-label Solana LSTs: The Vault, JagPool, DoubleZero, Gate SOL, Helius, Phantom, Forward, DFDV, Definity, Japan, Lantern, Stronghold, Save SOL, Bonk, JPool, Drift dSOL, Raiku | LC | shared programs (17) |
| lane-lst | frameworks: Mantle Restaking, Mellow, Meta Pool ETH, Infrared, Solayer, Volo, Haedal, Aftermath afSUI, Puffer, Frax Ether, mETH, stake.link | LC | audited (12) |
| lane-lst | Kyros/Fragmetric | LC | address mismatch |
| lane-lst | prior: Kinetiq, Phase, marginfi LST, NEOPIN, SparkDEX stFLR, ExinPool, JustLend V2, custodial list | PC/NP | grouped |

## lane-yield.md (20 ranked + 45 triaged)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane-yield | RockSolid Network | LC | P; EOA custody |
| lane-yield | Syntropia | LC | H-O/S |
| lane-yield | SuperEarn | LC | audited |
| lane-yield | Ledgity | LC | JIT neutralised |
| lane-yield | Royco V2 | LC | closed |
| lane-yield | Llama Airforce | LC | uneconomic |
| lane-yield | StableHodl | LC | P/S |
| lane-yield | Lazy | LC | operator-only |
| lane-yield | Zoo Finance | LC | NFT-gated |
| lane-yield | Mezo Vaults | OPEN | unverified strategy |
| lane-yield | lisAster | LC | S |
| lane-yield | Goldilocks | OPEN | unverified |
| lane-yield | DexFi Aggregator | OPEN | not reached |
| lane-yield | CGO Finance | OPEN(parked) | low value |
| lane-yield | Nerona | OPEN | no addresses |
| lane-yield | TermFinance | LC | audited |
| lane-yield | Toros | LC | audited |
| lane-yield | Yield Yak | LC | audited |
| lane-yield | Spectra V2 | LC | audited |
| lane-yield | Puffer UniFi / Solid Yield | LC | audited |
| lane-yield | triaged: Avalon, Kinetiq, Faiyah, Startale, Rujira, Mezo Swap, Convergence, Troves/Aftermath, giants (Spark, CIAN, Fluid Lite, Lorenzo, Wise, Aster asBNB, sDAI, Pendle/Penpie/Radpie, Hyperbeat, GrowiHF), non-EVM list, Royco V1, Trevee/Rings, DexFi legacy, CGO pools, Kava Earn, CityCoins, BTCST, BendDAO APE, Solid, Llama uFXS/uPRISMA/uBAL | PC/LC | grouped (45) |

## lane-rwa.md (16 ranked + 15 dead-end)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane-rwa | Eva Markets | RC | removed |
| lane-rwa | OnRe | RF | Tier-3 #10 |
| lane-rwa | HiYield | OPEN | unverified proxy |
| lane-rwa | Kamui | LC | whitelisted |
| lane-rwa | Estate Protocol | LC | KYC |
| lane-rwa | Theo thBILL | LC | permissioned |
| lane-rwa | Frax USD | LC | math checks |
| lane-rwa | Lista RWA | LC | permissioned |
| lane-rwa | OpenTrade | LC | institutional |
| lane-rwa | ISC | LC | multisig |
| lane-rwa | T-RIZE | LC | paused |
| lane-rwa | Clearpool TPOOL/USDX | LC | stablecoin supply |
| lane-rwa | ZTLN-P | LC | dead |
| lane-rwa | GPC | LC | dormant |
| lane-rwa | Uranium.io | LC | plain ERC20 |
| lane-rwa | stUSDT | OPEN | unchecked |
| lane-rwa | dead-end: Sky RWA, Anemoy, KAIO, Sygnum, R25, Valos, Ethena USDtb, Lofty, Meld Gold, Kea, Defa, Mansory, RealT | PC/NP | grouped (13) |

## lane-curators.md (18 ranked + 41 triaged)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane-curators | Apostro Resolv | LC | impaired; re-arm |
| lane-curators | Duplicated Key | LC | impaired |
| lane-curators | frobUSDC | LC | impaired |
| lane-curators | MEV Capital Elixir | LC | impaired |
| lane-curators | Waterline Reservoir | RF | Tier-3 #2 |
| lane-curators | Steakhouse High Yield Edition | LC | oracle correct |
| lane-curators | Sentora PRIME | LC | oracle sane |
| lane-curators | Paypal USD Main | LC | correct |
| lane-curators | Grove x Steakhouse | LC | blue-chip |
| lane-curators | sky.money USDT | LC | 0.96 buffer |
| lane-curators | Steakhouse Prime USDT | LC | closed |
| lane-curators | Sentora Huma | LC | closed |
| lane-curators | Pendle Ecosystem High Yield | LC | oracle correct |
| lane-curators | RockawayX USDC | LC | within buffer |
| lane-curators | Hyperithm USDC Apex | LC | closed |
| lane-curators | Mainstreet USDC | LC | 100% util |
| lane-curators | Adpend/1337 USDC | LC | frozen |
| lane-curators | Gauntlet USDC Prime | LC | blue-chip |
| lane-curators | triaged brands (41): Grove, Sky, Lombard, Solv, Gain/Kelp, Plasma, Neutral, Loopscale, Avant, ETH Strategy, Mt Pelerin, UltraYield, RockawayX Confidential, Hyperithm private, Felix, SparkDAO, Armitage, Galaxy, Clearstar, Keyrock, KPK, Bitwise, Flowdesk, Api3, August, Presto, SharpByte, Architect, Unified Labs, Euler, Yearn V3, Spectra MetaVaults, Lagoon (Hub Capital, 1212, Gami, Tulipa, 9Summits, DAMM) | PC/LC | grouped |

## lane-bridge.md (23 rows)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane-bridge | PulseChain Omnibridge | LC | onlyMediator |
| lane-bridge | Sonic Gateway | LC | MPT proof |
| lane-bridge | Aster/Astherus | LC | role-gated |
| lane-bridge | Taiko Bridge | LC | proof-gated |
| lane-bridge | SoDEX Bridge | LC | role-gated |
| lane-bridge | StandX Gateway | OPEN(parked) | Solana program |
| lane-bridge | Gravity Bridge | LC | closed |
| lane-bridge | Merlin's Seal | LC | relayer whitelist |
| lane-bridge | Unit/HyperUnit | NP | off-chain |
| lane-bridge | Function FBTC | NP | custodial |
| lane-bridge | SolvBTC | NP | custodial |
| lane-bridge | Lorenzo enzoBTC | NP | custodial |
| lane-bridge | Nexus BTC | NP | custodial |
| lane-bridge | B2 Buzz/uBTC | PC | pass2 |
| lane-bridge | FAssets | NP | oracle quorum |
| lane-bridge | Lombard BTC.b | NP | custodial |
| lane-bridge | Bitget bgBTC | NP | minter role |
| lane-bridge | OKX xBTC/Kraken kBTC/Binance BTC/Coinbase/Circle/tzBTC/Wrapped.com/JustCryptos | NP | custodial (8) |
| lane-bridge | Grvt/ADI Bridge | LC | zkSync standard |
| lane-bridge | Morph Bridge | LC | Scroll-fork |
| lane-bridge | Mezo Bridge | LC | tBTC standard |
| lane-bridge | Endurance Bridge | LC | role-gated |
| lane-bridge | OP-stack/L2s (SX, Lisk, Mode, Zora, Eclipse, Ink, World, Soneium, Unichain, Robinhood) | LC | standard (10) |
| lane-bridge | token-supply "bridges": Lighter, edgeX | NP | token supply |

## lane-consumer.md (20 rows)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane-consumer | Predict Fun | RC | removed |
| lane-consumer | Trueo | RF | Tier-3 #12 |
| lane-consumer | Sport.fun | RC | removed |
| lane-consumer | GoPlus Locker | LC | gate sims |
| lane-consumer | PinkSale | LC | gate sims |
| lane-consumer | Punks Terminal | LC | gate sims |
| lane-consumer | StonkBrokers | LC | source review |
| lane-consumer | HoodLock | LC | $732 real |
| lane-consumer | USDR (RISE) | LC | P |
| lane-consumer | Buzz Farming | LC | custodial |
| lane-consumer | Blur Bids | NP | token address |
| lane-consumer | Bio Protocol | LC | LOW |
| lane-consumer | StakePoint | OPEN | not reviewed |
| lane-consumer | DaVinciGraph | OPEN | not reviewed |
| lane-consumer | Stargate VeChain | LC | audited |
| lane-consumer | Sigmausd | LC | LOW |
| lane-consumer | Terminal Finance | OPEN(parked) | at bar |
| lane-consumer | Stellar DeFi Hub | LC | audited |
| lane-consumer | AILayer | NP | token address |
| lane-consumer | Swell L2 Farm | PC | giant |
| lane-consumer | excluded: Fang, Meridian, Levr Bet, Katana Pre-Launch, Saturn, UNCX, NOXA/Statics/DeepLock/Flap/Flaunch/SunPump/four.meme | PC | grouped |

## lane_derivs.md (24 ranked + 18 excluded)
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| lane_derivs | RISEx | RC | removed |
| lane_derivs | Antarctic AMLP/AHLP | LC | P/S |
| lane_derivs | SMARDEX USDN | OPEN | liq math |
| lane_derivs | Derive V3 | LC | zk+outbox |
| lane_derivs | Aegis YUSD | LC | signature-gated |
| lane_derivs | JUSD Finance | LC | P |
| lane_derivs | Monetrix | LC | P (C4 M-01) |
| lane_derivs | Aster USDF | LC | role-gated |
| lane_derivs | Antarctic AHLP | LC | P/S |
| lane_derivs | Phoenix Perp | LC | audited team |
| lane_derivs | Hypercall | LC | LOW |
| lane_derivs | Premia V3 | OPEN | oracles not read |
| lane_derivs | Opyn Squeeth | LC | old |
| lane_derivs | Evedex | LC | P |
| lane_derivs | Storm Trade | OPEN(parked) | TON |
| lane_derivs | Lavarage | OPEN(parked) | Solana |
| lane_derivs | Synthetix V4 | OPEN(parked) | small |
| lane_derivs | AnyHedge | LC | per-contract |
| lane_derivs | Hakka | NP | out of class |
| lane_derivs | BMX Freestyle | PC | SYMMIO |
| lane_derivs | DeSyn Basis | OPEN(parked) | Bitlayer |
| lane_derivs | SoSoValue Basis | NP | USDC.e address |
| lane_derivs | Apex Omni | OPEN | no contracts |
| lane_derivs | MUX Perps | OPEN | GMX-v1 |
| lane_derivs | excluded: Jupiter Perp, Hyperliquid HLP, dYdX, Extended, Lighter, Decibel, Papertrade, Arcus, AZverse, Moonlander, HertzFlow, Perpl, Meridian, BitFi, BULK, SYMMIO, Fulcrom, Deri V4, BounceBit, Manta CeDeFi | PC | grouped (20) |

## Vector lanes
| Lane | Candidate | Disp | Evidence |
|---|---|---|---|
| incidents | Argent wallet | RC | argent2.md |
| incidents | AlpsCon | RC | closed |
| incidents | BiFi | RF | P3-02 |
| incidents | 854-ETH sweep | NP | key compromise |
| incidents | webhook/OAuth | NP | credential theft |
| incidents | Cysic Bridge | LC | halted |
| incidents | Qubic | OPEN(parked) | network halted |
| incidents | EtherVista | PC | ZH3-C5 |
| incidents | UNCX | PC | correction |
| incidents | Coffer | LC | $0.70 |
| incidents | Drift / Aztec | NP | laundering |
| approvals | 25 ranked spenders + 8 extra (RelayApprovalProxyV3, AllowanceHolder, TransferDelegate, SpokePoolPeriphery, TychoRouterV3, SwapProxy, SwftSwap, Decentraland, Disperse, FrogHeadBulkBurner, PermanentNFTStaking, FortuneFi, BatchTransferHelper, BatchFactory, KSAllowanceHub, Argonauts, PlayClaw, Moonbirds, Conduit, LimitBreak PP V3, AegisRouterV1, ScentDexV6, MEVCaptureRouter, SKTokenTransferProxy, AquaRouter, AggregatorGuard, ApprovalProxy, 1inch-proxy, batch helper) | LC | all authority-correct |
| approvals | RelayDepository, UUPSProxy | OPEN(parked) | unverified follow-up |
| approvals | 3 EOAs w/ ~500 approvals | NP | key-holder |
| leaked-keys | Twyne | LC | $0; latent $11.19M |
| leaked-keys | Taiko (SGX) | LC | $0; ZkRequired |
| leaked-keys | Curvance | LC | test key |
| leaked-keys | hdwallet, ProjectLiberty, Oasys, Pledge, Web3-Subscriptions, Hegota, Euro3, Paymaster, AgentFiDefy, Umia, Zama | LC | $0 (11) |
| replay | Atomic Green | RC | atomic-green.md |
| replay | SafeTransfer | LC | ACTIVATOR_ROLE |
| replay | Lumi/Sodium | OPEN | residual scan pending |
| replay | Nimiq | PC | ZH2 |
| replay | GiddyVaultV3 | LC | empty |
| replay | Dexodus | LC | $1.27 TVL |
| replay | TokenStore | NP | false positive |
| replay | BiddableEscrow | LC | no gain |
| replay | WeiDex/Cryptex/MarketPlace | LC | stale-order only |
| replay | LASiR artifact | NP | dataset |
| timewrap | SimpleAccount | RF | P3-03 |
| timewrap | Argent modules | RC | argent2.md |
| timewrap | Barz, Openfort, Candide, SoulWallet, LSP11, Authereum | LC | gated (6) |
| timewrap | HoodLock, StonkBrokers, UsualX, Umia, Kinetiq, Flying Tulip, Pheasant, Usd0PP, WealthManagementV2 | LC | gated (9) |
| timewrap | Governance timelocks | LC | self/owner |
| fresh-pools | 10 ranked pools + 5 phantom classes + 4,522 Base v2 pairs | LC/NP | artifacts |
| gauge-family | Pharaoh | RF | P3-01 |
| gauge-family | Nile, Nuri, Cleopatra | LC | dust |
| gauge-family | 12 patched (Ramses HyperEVM/Arb/Poly/RH, Pharaoh V3, Shadow, Etherex, Thena, Chronos, Equalizer, Velodrome/Aerodrome) | LC | patched |
| wildcat | 88 markets | RC | wildcat.md |
| deri | 6 vaults | RC | deri.md |
| predictfun | full stack | RC | predictfun.md |
| atomic-green | 18 positions | RC | atomic-green.md |
