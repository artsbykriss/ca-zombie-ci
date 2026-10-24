#!/usr/bin/env python3
# ZH4-PASS6 residual reconciliation — build the full disposition table + machine-readable rows.
# Read-only. No secrets. Emits analysis/rows.json and analysis/DISPOSITIONS.md.
import json, os, collections

OUT = os.path.dirname(os.path.abspath(__file__))
# (lane, candidate, chain, funds, lane_verdict, disposition, cite)
R = [
# ---------------- L: next-hack board (rows 1-19 + prose) ----------------
("next-hack","Cardboard Trade (perp DEX)","Solana","$1.08M","row1 / P6 CLOSED","README-CLOSED","pass6 README §5; cardboard.md"),
("next-hack","Monetrix (USDM/mxHYPE/mxBTC)","HyperEVM 999","~$4.9M","row2 / P6 CLOSED","README-CLOSED","pass6 README §5; monetrix.md"),
("next-hack","INFER / imdUSD","Ethereum","<=$340k","row3 LOW-MED","ASSIGNED","ZH4P6 tracker (infer-imdusd/)"),
("next-hack","Robinhood-Chain Morpho x tokenized equities","Robinhood 4663","$3.4M+","row4 / P6-01 PROVEN-armed","ASSIGNED","ZH4P6 tracker (robinhood-oracle/)"),
("next-hack","Arcus pTokens (17)","Robinhood 4663","~$720k","row5 MED","README-CLOSED","pass6 README §5; arcus-ptokens.md (dup Z3-H12)"),
("next-hack","VETRO","Ethereum","~$906k","row6 LOW-MED","README-CLOSED","pass6 README §5; vetro.md"),
("next-hack","StonkBrokers","Robinhood 4663","$1.16M","row7 LOW-MED","README-CLOSED","pass6 README §5; stonkbrokers.md"),
("next-hack","Pacifica Bridge","Solana","$24.16M (artifact)","row8 LOW-MED","README-CLOSED","pass6 README §5; pacifica-bridge.md"),
("next-hack","Ascend","0G 16661","~$3.4M","row9 / P6-02","ASSIGNED","ZH4P6 tracker (ascend-0g/)"),
("next-hack","URM Fortress","Base","$69k CDP","row10 LOW","PARKED","next-hack.md row10; no address published"),
("next-hack","JPY DeFi (Liquity-v2 fork)","Ethereum","$840k","row11 LOW-MED","ASSIGNED","ZH4P6 tracker (jpy-defi/); PRIOR-PARTIAL = JPYdf closed ZH4"),
("next-hack","The Moats","Avax/RH/Monad/BSC/Base","$1.4M","row12 LOW","ASSIGNED","ZH4P6 tracker (moats/)"),
("next-hack","Exceed Finance (exUSDC/exSOL/exBTC)","Solana","$704k","row13 LOW","ASSIGNED","ZH4P6 tracker (exceed-finance/)"),
("next-hack","JUSD Finance","Ethereum+Arbitrum","$25.0M","row14 P","README-CLOSED","pass6 README §5"),
("next-hack","Fake World Assets V2","Ethereum","~$1.57M","row15 no-path","README-CLOSED","pass6 README §5"),
("next-hack","CommunityV3","Ethereum","$6.3M","row16 no-path","README-CLOSED","pass6 README §5"),
("next-hack","Bebop bopAMM","Ethereum","~$0","row17 no-path","README-CLOSED","pass6 README §5"),
("next-hack","Aero Basic / Aero Slipstream","Base+6","$48M/$79M","row18 not-a-fork","README-CLOSED","pass6 README §5 (Dromos merger)"),
("next-hack","Choice Exchange V1","Injective","$283k","row19 privileged","NOT-A-PROTOCOL","next-hack.md §5 (CosmWasm, multisig admin)"),
("next-hack","Nova Perps","?","$208k","Gains 1:1 fork","LANE-CLOSED","next-hack.md §5 (Safe+timelocks)"),
("next-hack","Hyperliquid Earn","HyperCore","$1.43B","native primitive","NOT-A-PROTOCOL","next-hack.md §5"),
("next-hack","Strat Perps","Initia Move","-","non-EVM, 2x Zellic","NOT-A-PROTOCOL","next-hack.md §5"),
("next-hack","Solana fresh-LST cluster (Forward/Definity/Raiku/Japan)","Solana","$254-350M","privileged manager","README-CLOSED","pass6 README §5"),
("next-hack","HoodLock","-","-","no E-U","README-CLOSED","pass6 README §5"),
("next-hack","Popdex Bridge","Arbitrum","$73.3M","ZH4-internal repeat","PRIOR-COVERED","v14-popdex.md"),
("next-hack","STRATO Bridge","-","$16.19M","H2-05 closed","PRIOR-COVERED","H2-05"),
("next-hack","Lucid Labs","-","-","pass5 closed","PRIOR-COVERED","pass5"),
("next-hack","SundaeSwap V4","Cardano","-","not verifiable","LANE-CLOSED","next-hack.md §5"),
("next-hack","xALPH","Alephium","-","no external path","LANE-CLOSED","next-hack.md §5"),
("next-hack","Robinhood tail (Ouro/Raphael/Goo/Titan/Arrowfarm/Crossbow/Abyss)","Robinhood 4663","$84-444k","UniV2/V3 forks","LANE-CLOSED","next-hack.md §5"),
("next-hack","Prosper Alpha","-","-","kept on board, no lead","LANE-CLOSED","next-hack.md §5"),
("next-hack","Forest Road Vault","Ethereum","-","role/KYC gated","LANE-CLOSED","next-hack.md §5"),
("next-hack","NEMO Trading","-","-","ifSenderWhitelisted","LANE-CLOSED","next-hack.md §5"),
("next-hack","Hub Capital / Odyssey Digital AM / DeTrade","-","-","Lagoon curator-gated","LANE-CLOSED","next-hack.md §5"),
("next-hack","Ditto Earn","Ethereum","$45.88","dust","LANE-CLOSED","next-hack.md §5"),
("next-hack","Excluded repeats (FermiSwap/Kipseli/HertzFlow/LevrBet/Kamui/Longbow/Phase/GoonFi/Scorch/BisonFi/TONCO/Reflect/BDEX/Waterline/Architect/LibertySwap/MetricV1/RNTLend/Faiyah/Papertrade/JustLend sTRX)","multi","-","zh4-check EXCLUDE","PRIOR-COVERED","next-hack.md §5 (24 names)"),
("next-hack","Carry-over monitors (Radworks/HAI/CL-gauge/Startale/Shibarium WBONE/Affluent/Burve/Kuru/Infrared)","multi","-","monitor","PRIOR-COVERED","next-hack.md §6; MONITOR-LIST.md"),

# ---------------- L: arcus-ptokens ----------------
("arcus-ptokens","Arcus pToken factory + 17 BeaconProxy vaults","Robinhood 4663","$693,796","CLOSED E-U $0","README-CLOSED","arcus-ptokens.md (dup Z3-H12)"),

# ---------------- L: base-bsc-fresh ----------------
("base-bsc-fresh","Wager Predict (SpotEngine/Vault/USDW)","BSC","$173.7k","MED lead; no cheap drain; USDW impl unread","OPEN","base-bsc-fresh.md row1"),
("base-bsc-fresh","Tapir Protocol (DepegPool/AMM)","Base","$55k","MED unread","OPEN","base-bsc-fresh.md row2"),
("base-bsc-fresh","Prodigy.Fi V2 (PositionManager, unverified impl)","Base","$68.9k DL","MED opaque core","OPEN","base-bsc-fresh.md row3"),
("base-bsc-fresh","Nullmask (ZK privacy pool)","Base(+BSC)","12.50 ETH ~$28.9k","MED unread; prior PARKED","OPEN","base-bsc-fresh.md row4; residual-recon PARKED"),
("base-bsc-fresh","Primus Confidential Vault (FHE)","BSC","reported >$1M / backend $38.6M","MED-HIGH address-thin","OPEN","base-bsc-fresh.md row5 (addresses unresolved)"),
("base-bsc-fresh","Doppler Finance XDP Staking","Base","$560k staked","NEG inert (0 reward periods)","LANE-CLOSED","base-bsc-fresh.md row6 (monitor first addRewardPeriod)"),
("base-bsc-fresh","ArexAIStaking","BSC","115M ARXAI ($0 realizable)","LOW no drain","LANE-CLOSED","base-bsc-fresh.md row7"),
("base-bsc-fresh","StakedVault + CooldownSilo","Base","$0","NEG","LANE-CLOSED","base-bsc-fresh.md row7"),
("base-bsc-fresh","PhoenixCo","BSC","~$3k","LOW","LANE-CLOSED","base-bsc-fresh.md row8"),
("base-bsc-fresh","Berry Finance / Berry Juicer","Base","small","LOW unverified EIP-1167","LANE-CLOSED","base-bsc-fresh.md row9"),
("base-bsc-fresh","BASE STREET presale","Base","~$25k","NEG treasury EOA","NOT-A-PROTOCOL","base-bsc-fresh.md row10"),
("base-bsc-fresh","Based Eggman","Base","$0","NEG","NOT-A-PROTOCOL","base-bsc-fresh.md row11"),
("base-bsc-fresh","ZiG / ZAOIN","Base","$0","NEG honeypot/1155","NOT-A-PROTOCOL","base-bsc-fresh.md row12"),
("base-bsc-fresh","Today's fresh-verified Base/BSC (50)","Base+BSC","0 native","NEG","LANE-CLOSED","base-bsc-fresh.md row13"),
("base-bsc-fresh","Fresh DEX tokens (212)","Base+BSC","0 native","NEG","LANE-CLOSED","base-bsc-fresh.md row14"),
("base-bsc-fresh","AXIS Robotics","Base","$2.47M pool","no custody contract yet","LANE-CLOSED","base-bsc-fresh.md negatives"),
("base-bsc-fresh","Concrete (CT)","BSC","-","out-of-lane","PRIOR-COVERED","base-bsc-fresh.md negatives"),
("base-bsc-fresh","Nesa","BSC","-","prior-covered","PRIOR-COVERED","base-bsc-fresh.md negatives"),
("base-bsc-fresh","Paimon/pPOLY","BSC","-","prior-covered pass5","PRIOR-COVERED","base-bsc-fresh.md negatives"),
("base-bsc-fresh","Fake-liquidity cluster (USDB/ATC/GALABET/etc)","Base+BSC","artifact","NEG","NOT-A-PROTOCOL","base-bsc-fresh.md negatives"),
("base-bsc-fresh","CEX/MM wallets (0x28e2ea09/0x8a08d98c/0x6aba0315)","BSC","-","NEG exchange wallets","NOT-A-PROTOCOL","base-bsc-fresh.md negatives"),
("base-bsc-fresh","0xD189 vault","Base","$6M","prior-corpus, not E-U","PRIOR-COVERED","ZOMBIE-HUNT-II.md"),
("base-bsc-fresh","UNCX/Slice/NEM/AlpsCon/Umia/RouterDrain","multi","-","corpus-closed","PRIOR-COVERED","base-bsc-fresh.md negatives"),

# ---------------- L: bpool-forks ----------------
("bpool-forks","Balancer V1 BPool fork census (6,538 pools / 9 chains)","multi","net $0","CLOSED","README-CLOSED","pass6 README §5; bpool-forks.md"),
("bpool-forks","Canonical OCEAN/USDC pool 0x9a16bddf","Ethereum","$135k","value token frozen","LANE-CLOSED","bpool-forks.md §3"),
("bpool-forks","Swaap Finance Pool 0x7f5f7411","Polygon","$107k","different math, closed","README-CLOSED","swaap.md"),
("bpool-forks","Base/Arb BCoWPool families","Base+Arb","-","functions removed","LANE-CLOSED","bpool-forks.md"),

# ---------------- L: cardboard ----------------
("cardboard","Cardboard Trade oracle/settle","Solana","$1.08M","CLOSED E-U $0","README-CLOSED","cardboard.md"),

# ---------------- L: deployer-lineage ----------------
("deployer-lineage","LauncherV2 proxy 0xe1795625","Arbitrum","$125.7k","funded, NOT extractable","LANE-CLOSED","deployer-lineage.md #1"),
("deployer-lineage","CrowdRingCircle 6-token sell-destroy family","BSC","$0","template, unfunded","LANE-CLOSED","deployer-lineage.md #2"),
("deployer-lineage","BitBay/StableVault ~25-vault family","Polygon","$0","template, unfunded","LANE-CLOSED","deployer-lineage.md #3"),
("deployer-lineage","UNCX VestingManager lineage (75 contracts)","ETH/ARB/Poly","$4.18M nominal","no new sibling","PRIOR-COVERED","deployer-lineage.md #4; pass2"),
("deployer-lineage","KolanHook deployer lineage","Ethereum","$0","no second hook","ASSIGNED","deployer-lineage.md #5 (kolan-hooks/)"),
("deployer-lineage","GoldPesa GPXHooks","Base","$0","drained","PRIOR-COVERED","ZH3-H5 monitor"),
("deployer-lineage","ether.fi AtomicQueue","Ethereum","$0","one instance; forks unresolved","PRIOR-COVERED","ZH1 C-07 / pass4"),
("deployer-lineage","FlashLoopAdapter + 30 same-deployer modules","Ethereum","$0","possible self-attestation in siblings (unread)","PRIOR-PARTIAL","ZOMBIE-HUNT-II.md (closed) + sibling tail unread"),
("deployer-lineage","MOKE / MokeRelease family","BSC","$0","paused","LANE-CLOSED","deployer-lineage.md #9"),
("deployer-lineage","AlpsCon V6-V9 lineage","BSC","$8,333","known, whitelist re-arm","PRIOR-COVERED","pass5"),
("deployer-lineage","EtherVista factory lineage","Ethereum","$0","router-gated (privileged)","PRIOR-COVERED","pass2/3"),
("deployer-lineage","BiFi TokenHandler lineage (89)","Ethereum","dust","known, paused","PRIOR-COVERED","pass3/5"),
("deployer-lineage","Arrakis G-UNI lineage","Ethereum","$0","-","LANE-CLOSED","deployer-lineage.md #13"),
("deployer-lineage","USM lineage","Ethereum","small","-","LANE-CLOSED","deployer-lineage.md #14"),
("deployer-lineage","Float Protocol lineage","Ethereum","$0","-","LANE-CLOSED","deployer-lineage.md #15"),
("deployer-lineage","Balancer V1 BPool deployer","Ethereum","$0","-","README-CLOSED","deployer-lineage.md #16"),
("deployer-lineage","MALT sLP","Polygon","$0","-","PRIOR-COVERED","deployer-lineage.md #17"),
("deployer-lineage","BigShot","Optimism","$0","pass4","PRIOR-COVERED","pass4"),
("deployer-lineage","Allbridge CCTP","Base","$0","-","LANE-CLOSED","deployer-lineage.md #19"),
("deployer-lineage","SandboxOFT","Base","$0","-","LANE-CLOSED","deployer-lineage.md #20"),
("deployer-lineage","Perpetual Protocol v2 Curie OrderBooks","Optimism","$0 ($435k patched)","live bug, empty/patched","LANE-CLOSED","deployer-lineage.md #21; child C"),
("deployer-lineage","Sodium smart-account lineage (479 contracts)","Arbitrum","$0","no clone references impl","PRIOR-COVERED","carry-over (sodium/ kept)"),

# ---------------- L: fresh-deploy-sweep ----------------
("fresh-deploy-sweep","Fresh-verified contracts (10,566 / 21 chains)","multi","714 funded","0 drains","LANE-CLOSED","fresh-deploy-sweep.md §0"),
("fresh-deploy-sweep","Funded fresh table rows 1-30 (Safes/UniV2V3/Pendle/ERC-4626/ApeChain dapps)","multi","$5.0M+","all guarded-by-design","LANE-CLOSED","fresh-deploy-sweep.md §2"),
("fresh-deploy-sweep","P6-01 ChimeraQuoteHook404 (v4 hook + ERC-404 launchpad)","Ink","fees in per-pool vaults","LOW unproven","OPEN","fresh-deploy-sweep.md §3"),
("fresh-deploy-sweep","P6-02 BondingCurveManager","Ronin","190 ERC-20s","LOW unproven","OPEN","fresh-deploy-sweep.md §3"),
("fresh-deploy-sweep","P6-03 Unichain ImmutableProxy family (~130 clones)","Unichain","~$130k","LOW unproven (probe reverts)","OPEN","fresh-deploy-sweep.md §3"),
("fresh-deploy-sweep","zksync fresh-verified feed","zkSync","-","not covered (0 rows)","LANE-CLOSED","fresh-deploy-sweep.md §4"),

# ---------------- L: incidents-siblings ----------------
("incidents-siblings","WAX Multi-Chain Bridge","WAX","~$1.5k residual","PATCHED","LANE-CLOSED","incidents-siblings.md #1"),
("incidents-siblings","Arkadiko (USDA CDP)","Stacks","TVL $138k","governance, non-EVM","NOT-A-PROTOCOL","incidents-siblings.md #2"),
("incidents-siblings","Swell (swETH/rswETH)","Ethereum","~2,500 ETH exposure","key/upgrade","NOT-A-PROTOCOL","incidents-siblings.md #3"),
("incidents-siblings","Balancer V1 BPool (DPI)","Ethereum","$234k","immutable, forks $0","README-CLOSED","incidents-siblings.md #4"),
("incidents-siblings","Cysic bridge","BSC","$744k moved","off-chain/halted","NOT-A-PROTOCOL","incidents-siblings.md #5"),
("incidents-siblings","CoinDCX","multi","$16M flagged","CEX cleanup","NOT-A-PROTOCOL","incidents-siblings.md #6"),
("incidents-siblings","Ngrave wallet","multi","$2.65M","phishing","NOT-A-PROTOCOL","incidents-siblings.md #7"),
("incidents-siblings","Drift exploiter laundering","Ethereum","$122.3M","not an exploit","PRIOR-COVERED","incidents-siblings.md #8"),
("incidents-siblings","PHP/LiteLLM/eMudhra","off-chain","-","infra","NOT-A-PROTOCOL","incidents-siblings.md #9"),
("incidents-siblings","UNCX VestingManager siblings (17/8 chains)","multi","dust; RH $658k locked","flatFee=uint256.max","PRIOR-COVERED","incidents-siblings.md §2 #1"),
("incidents-siblings","KolanHook + launchpad 14 hooks","Ethereum","$0","code-identical, $0","ASSIGNED","incidents-siblings.md §2 #2"),
("incidents-siblings","TIP/TIPMine","BSC","$0","pool drained; clone uninitialized","LANE-CLOSED","incidents-siblings.md §2 #3"),
("incidents-siblings","NEM/NemTokenV2","BSC","$1.79k","prior-covered","PRIOR-COVERED","incidents-siblings.md §2 #4"),
("incidents-siblings","CrowdRingCircle (CRC)","BSC","$0","0/301k pairs","LANE-CLOSED","incidents-siblings.md §2 #5"),
("incidents-siblings","MOKE","BSC","$0","claim paused","LANE-CLOSED","incidents-siblings.md §2 #6"),
("incidents-siblings","Perpetual Protocol v2","Optimism","$0","empty/patched","LANE-CLOSED","incidents-siblings.md §2 #7"),
("incidents-siblings","AlpsCon V7/V8/V9","Ethereum","$8,333","V9 no code","PRIOR-COVERED","incidents-siblings.md §2 #9"),
("incidents-siblings","BiFi Lending","BSC/AVAX/Kaia","~$97k BSC","paused","PRIOR-COVERED","carry-over closed by us"),
("incidents-siblings","EtherVista","Ethereum","~$291k WETH","router-gated","PRIOR-COVERED","incidents-siblings.md §2 #11"),
("incidents-siblings","Argent-style smart wallet","Ethereum","~24-28 ETH nominal","$0 affordable payload","PRIOR-COVERED","incidents-siblings.md §2 #12"),
("incidents-siblings","Slice FundsModule","Base","$0","patched/paused","PRIOR-COVERED","incidents-siblings.md §2 #13"),
("incidents-siblings","MORPHO EIP-7702","Ethereum","$2.3M","key/delegation","NOT-A-PROTOCOL","incidents-siblings.md #16"),
("incidents-siblings","X7 Finance (X7Pioneer)","Ethereum","$52","drained","LANE-CLOSED","incidents-siblings.md #18"),
("incidents-siblings","MALT (Malt Stablecoin)","Ethereum","8,658 DAI","prior-corpus","PRIOR-COVERED","incidents-siblings.md #19"),
("incidents-siblings","Pirate Chain (ARRR)","Pirate L1","79.8M ARRR forged","chain consensus","NOT-A-PROTOCOL","incidents-siblings.md #20"),
("incidents-siblings","Qubic","-","~$1.13M frozen","wallet-side","NOT-A-PROTOCOL","incidents-siblings.md #21"),
("incidents-siblings","Gamdom/Fearless/Ngrave/Ledger","-","-","key/supply-chain","NOT-A-PROTOCOL","incidents-siblings.md #23"),
("incidents-siblings","Affluent (TON) / Coffer (Solana)","TON/Solana","$1.05M / $0.70","drained/dust","PRIOR-COVERED","incidents-siblings.md #24"),
("incidents-siblings","Secured Finance (ETH/FIL/ARB)","multi","$168.7k","CLOSED $0 (re-open refuted)","README-CLOSED","secured-finance.md"),

# ---------------- L: kestrel / monetrix / pacifica ----------------
("kestrel","Kestrel Long Yield Carry","Solana","$441.6k","CLOSED E-U $0","README-CLOSED","kestrel.md"),
("monetrix","Monetrix (USDM/mxHYPE/mxBTC)","HyperEVM 999","~$4.75M","CLOSED E-U $0","README-CLOSED","monetrix.md"),
("pacifica-bridge","Pacifica Bridge (PCFA + sol-bridge)","Solana","$24.33M (P-class)","CLOSED E-U $0","README-CLOSED","pacifica-bridge.md"),

# ---------------- L: probed-protocols ----------------
("probed-protocols","BSC 0x16ceff8d V4-hook 'bank' (54.5 BNB)","BSC","64.2 BNB + USDT","probed; no unguarded path","ASSIGNED","bsc-v4-hook-bank/"),
("probed-protocols","BSC 0x6aba0315 proxy ($8.63M / 155.9M txs)","BSC+4","~$3.28M BSC verified","reverts for stranger; unverified","OPEN","probed-protocols.md #2"),
("probed-protocols","ETH 0x278d858f + BSC 0xa9010523 whitelist-router family","ETH+BSC+12","~$400k ETH verified; $6.9M family","whitelist works; unverified/obfuscated","OPEN","probed-protocols.md #3"),
("probed-protocols","Uniswap Continuous Clearing Auction 0xa93807cd","Ethereum","5.17 ETH","LOW","LANE-CLOSED","probed-protocols.md #4"),
("probed-protocols","Axiom Uniswap-V4 hook 0x9689992f","Ethereum","$0","LOW","LANE-CLOSED","probed-protocols.md #5"),
("probed-protocols","Cross-chain swap 0x8ea5ad2a / 0x86d5db2a","Base+BSC","~0.067 ETH","LOW","LANE-CLOSED","probed-protocols.md #6"),
("probed-protocols","Hatchlings mintFree","Ethereum","-","sold out, not E-U","NOT-A-PROTOCOL","probed-protocols.md #7"),
("probed-protocols","Packed-command contracts (0xae629bf1/0x29be31e7/0x56320386)","Base+BSC","spam tokens","LOW reverts","LANE-CLOSED","probed-protocols.md #8-10"),
("probed-protocols","getRich honeypot 0x913b87c7","Base","-","LOW","NOT-A-PROTOCOL","probed-protocols.md #11"),
("probed-protocols","executeProgram proxy 0x774c69ab","Base","-","LOW","LANE-CLOSED","probed-protocols.md #12"),
("probed-protocols","EIP-2535 Diamond 0xb44446b0","Ethereum","-","LOW","LANE-CLOSED","probed-protocols.md #13"),
("probed-protocols","OptimizedBatchClaimer 0xd6510531","Ethereum","$0","LOW","LANE-CLOSED","probed-protocols.md #14"),
("probed-protocols","Fresh-EOA one-offs (0x26ff4608/0xfdf682f5)","Base","-","LOW","LANE-CLOSED","probed-protocols.md #15"),
("probed-protocols","169-ETH Base tag-dispatch contract 0x08fb3354","Base","169.39 ETH","prior-covered pass5 row15","PRIOR-COVERED","probed-protocols.md #16 (monitor)"),
("probed-protocols","OKX/Across/UniversalRouter/1inch/Seaport/UniswapV4Router04","multi","dust","legit infra","LANE-CLOSED","probed-protocols.md negatives"),
("probed-protocols","EIP-7702 delegation designators","Base+ETH","-","MEV bots","PRIOR-COVERED","ZH4 monitor"),

# ---------------- L: robinhood-oracle ----------------
("robinhood-oracle","Robinhood-Chain Morpho equity oracle staleness","Robinhood 4663","$1.69M debt; $215.5k free","LOW, armed; mechanism proven","README-FINDING","pass6 P6-01; robinhood-oracle.md"),
("robinhood-oracle","Robinhood mock oracle 0x20925300 unprotected setPrice","Robinhood 4663","$0","mock markets only","LANE-CLOSED","robinhood-oracle.md §7"),

# ---------------- L: solana-fresh ----------------
("solana-fresh","Kestrel Long Yield Carry","Solana","$440k","CLOSED","README-CLOSED","kestrel.md"),
("solana-fresh","Tessera V","Solana","$9.18M","LOW (router-proxy untested)","README-CLOSED","tessera.md"),
("solana-fresh","AlphaQ prop-AMM","Solana","~$1.0M","LOW; admin gated; swap unresolved","OPEN","solana-fresh.md #3"),
("solana-fresh","Exceed Finance","Solana","$704k","LOW-MED; update_pair_limits gated","ASSIGNED","exceed-finance/"),
("solana-fresh","DiversiFi index vaults","Solana","$745k","LOW; rebalance untested","OPEN","solana-fresh.md #5"),
("solana-fresh","Flipcash bonding-curve launchpad","Solana","$415k","LOW immutable","PRIOR-PARTIAL","residual-recon r4:53 (immutable+audited)"),
("solana-fresh","Overpass wrapper factory","Solana","$141k","LOW unread","OPEN","solana-fresh.md #7"),
("solana-fresh","Zodial (marginfi fork)","Solana","$201k","LOW fork-drift","OPEN","solana-fresh.md #8"),
("solana-fresh","Umbra Privacy V2","Solana","$252k","P5 OPEN-B tail","PRIOR-COVERED","solana-fresh.md #9"),
("solana-fresh","Sat Rush","Solana","$847k","LOW unlocated","OPEN","solana-fresh.md #10"),
("solana-fresh","Loyal Earn","Solana","$393k","LOW unlocated","OPEN","solana-fresh.md #11"),
("solana-fresh","TRUE DEX","Solana","$281k","LOW unlocated","OPEN","solana-fresh.md #12"),
("solana-fresh","Pascal","Solana","$2.24M","LOW unlocated","OPEN","solana-fresh.md #13"),
("solana-fresh","N1 Exchange Bridge","Solana","$1.37M","LOW unlocated","OPEN","solana-fresh.md #14"),
("solana-fresh","Byzanlink RWA Markets","Solana","$2.09M","LOW unlocated","OPEN","solana-fresh.md #15"),
("solana-fresh","Webot","Solana","$3.59M","CEX off-chain","NOT-A-PROTOCOL","solana-fresh.md #16"),
("solana-fresh","Definity/Raiku/Japan/Forward-Industries SOL","Solana","$293M","SPL stake pools","README-CLOSED","solana-fresh.md #17"),
("solana-fresh","Prior-corpus repeats (BisonFi/GoonFi/Aquifer/Phase/Scorch/Loopscale/Reflect/Pacifica/Exponent/Save/marginfi/Drift/DefiTuna/Jupiter Offerbook/Bordrless/DeepSwap)","Solana","-","excluded","PRIOR-COVERED","solana-fresh.md negatives"),

# ---------------- L: stonkbrokers / swaap / tessera / vetro ----------------
("stonkbrokers","StonkBrokers lockers + TokenEscrowReserve","Robinhood 4663","$1.01M + $7.07M reserve","CLOSED E-U $0","README-CLOSED","stonkbrokers.md"),
("swaap","Swaap Finance Pool 0x7f5f7411","Polygon","$107k","CLOSED E-U $0","README-CLOSED","swaap.md"),
("swaap","Swaap Maker V2 (SafeguardPool)","multi (11)","$454k","out-of-scope flag, unread","OPEN","swaap.md §4 out-of-scope"),
("tessera","Tessera V (Wintermute prop-AMM)","Solana","$8.5M","LOW; whitelist+operator gates","README-CLOSED","tessera.md"),
("vetro","VETRO (VUSD/vetBTC)","Ethereum","$906k","CLOSED E-U $0","README-CLOSED","vetro.md"),
("vetro","VETRO VUSD LayerZero OFT lockbox","Ethereum","230,820 VUSD","correctly configured; monitor","LANE-CLOSED","vetro.md §5.7"),

# ---------------- known pass6 items (handled elsewhere) ----------------
("assignments","Robinhood oracle (P6-01)","Robinhood 4663","$0.3-1.5M","assigned","ASSIGNED","ZH4P6 tracker"),
("assignments","Ascend (P6-02)","0G","<=$3.4M","assigned","ASSIGNED","ZH4P6 tracker"),
("assignments","INFER/imdUSD","Ethereum","<=$340k","assigned","ASSIGNED","ZH4P6 tracker"),
("assignments","JPY DeFi","Ethereum","<=$840k","assigned","ASSIGNED","ZH4P6 tracker"),
("assignments","The Moats","multi","<=$1.4M","assigned","ASSIGNED","ZH4P6 tracker"),
("assignments","Exceed Finance","Solana","<=$704k","assigned","ASSIGNED","ZH4P6 tracker"),
("assignments","Kolan launchpad x14 hooks","Ethereum","$0 re-arm","assigned","ASSIGNED","ZH4P6 tracker"),
("assignments","BSC V4-hook bank (54.5 BNB)","BSC","64.2 BNB","assigned","ASSIGNED","ZH4P6 tracker"),
("assignments","Sodium/AGLHook/Spot/StablePair/BiFi (carry-overs)","multi","-","closed by us","PRIOR-COVERED","ZH4P6 tracker; pass5"),
]

DISPOSITIONS = ["README-FINDING","README-CLOSED","LANE-CLOSED","PRIOR-COVERED","PRIOR-PARTIAL","NOT-A-PROTOCOL","ASSIGNED","PARKED","OPEN"]

rows = []
for i,(lane,cand,chain,funds,lv,disp,cite) in enumerate(R,1):
    rows.append({"n":i,"lane":lane,"candidate":cand,"chain":chain,"funds":funds,"lane_verdict":lv,"disposition":disp,"cite":cite})

cnt = collections.Counter(r["disposition"] for r in rows)
open_rows = [r for r in rows if r["disposition"]=="OPEN"]

data = {
  "finding":"ZH4-PASS6-residual-recon",
  "title":"Residual reconciliation of pass6 (20 lanes) vs prior coverage; every named candidate dispositioned",
  "date":"2026-10-24",
  "counts":{
     "named_candidates_enumerated": len(rows),
     "README-FINDING": cnt["README-FINDING"],
     "README-CLOSED": cnt["README-CLOSED"],
     "LANE-CLOSED": cnt["LANE-CLOSED"],
     "PRIOR-COVERED": cnt["PRIOR-COVERED"],
     "PRIOR-PARTIAL": cnt["PRIOR-PARTIAL"],
     "NOT-A-PROTOCOL": cnt["NOT-A-PROTOCOL"],
     "ASSIGNED": cnt["ASSIGNED"],
     "PARKED": cnt["PARKED"],
     "OPEN": cnt["OPEN"],
  },
  "open_list": open_rows,
  "rows": rows,
}
with open(os.path.join(OUT,"rows.json"),"w") as f:
    json.dump(data,f,indent=2)

# markdown
md=["# ZH4-PASS6 residual reconciliation — full disposition table","",
    f"**{len(rows)} named candidates** across the 20 pass6 lanes. Vocabulary: README-FINDING / README-CLOSED / LANE-CLOSED (cite) / PRIOR-COVERED / PRIOR-PARTIAL / NOT-A-PROTOCOL / ASSIGNED (handled by another pass6 agent) / PARKED (funded but unlocated / trigger-only) / **OPEN**.","",
    "| # | Lane | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |","|---|---|---|---|---|---|---|---|"]
for r in rows:
    md.append(f"| {r['n']} | {r['lane']} | {r['candidate']} | {r['chain']} | {r['funds']} | {r['lane_verdict']} | **{r['disposition']}** | {r['cite']} |")
md.append("")
md.append("## Counts")
md.append("")
for k,v in data["counts"].items():
    md.append(f"- {k}: **{v}**")
with open(os.path.join(OUT,"DISPOSITIONS.md"),"w") as f:
    f.write("\n".join(md)+"\n")
print(json.dumps(data["counts"],indent=2))
print("OPEN:", [r["candidate"] for r in open_rows])
