#!/usr/bin/env python3
import json
c=json.load(open("analysis/counts.json"))
live=json.load(open("analysis/live-checks.json"))["checks"]
open_rows=[r for r in c["open"]]
summary={
 "finding":"CA2-RECON",
 "title":"CA2 residual reconciliation — every named candidate dispositioned + OPEN list",
 "date":"2026-11-03",
 "chains":["Ethereum","Arbitrum","Optimism","Base","Polygon","BSC","Avalanche","Sonic","Berachain","HyperEVM","Monad","CORE","TRON","Solana","Sui","Aptos","NEAR","TON","Starknet","Zilliqa","Cosmos/CosmWasm","Cardano","Bitcoin/Lightning","Stellar","Pharos","Tempo"],
 "headline_extractable_usd":0,
 "headline_confidence":"high",
 "headline_note":"No new live externally-unprivileged >$10k path was proven. CA2's three CRITICALs reconcile to a prior-measured $0.00 (Affluent), an existing Papertrade monitor, and a prior-covered compiler RCE (wasmer).",
 "categories":{"E-U":0,"H-O":0,"P":0,"S":0},
 "counts":{
   "enumerated":c["enumerated"],
   "by_source":c["by_source"],
   "by_disposition":c["by_disposition"],
   "prior_covered_rows":c["prior_covered_rows"],
   "open_rows":c["open_count"],
   "open_distinct_targets":7
 },
 "latest_block":{
   "ethereum":26328016,
   "arbitrum":519259394,
   "polygon":96362807,
   "bsc":int(live["gambit_bsc"]["block"] or 0),
   "pharos":int(live["r25_pharos"]["block"] or 22016133),
   "monad":int(live["neverland_monad"]["block"] or 0),
   "tron":int(live["tron_trio"]["block"] or 87679544),
   "hyperevm":50221178,
   "ton_seqno":102935760
 },
 "targets_checked":c["enumerated"],
 "live_targets":9,
 "closed_reasons":[
   "prior measured $0.00 (Affluent redeem leg)",
   "prior monitor / already handled (Papertrade, Premia, Initia, TAC, Zodiac, Startale, Secured Finance)",
   "prior weaponisation blocked (CWA-2026-006 M1-M4)",
   "patched / paused / roles revoked (Notional, zkLink, Troves, b14g, Hifi, WAX)",
   "denylisted / $0 realizable (ether.fi AtomicQueue, Aperture, SatoHook)",
   "drained / unfunded (Fence, Oatfi, Thetanuts, Raydium legacy, BlueMove)",
   "key compromise / supply chain / CEX (Mercado, Predict Fun, WAX X-Bridge, Swell, Polymarket)",
   "sub-threshold value (Vara $12, Coffer <$1, Yapeswap $119, BSC router $203)"
 ],
 "poc":{"tests_passed":0,"tests_total":0,"ci_run_urls":["https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41644931903","https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41645359298"]},
 "open":[
   {"rank":1,"target":"R25 WrappedVault family","chain":"Pharos","addresses":["0x94f7ebc6ae0819a4b4e231ae6ddaaf9bfd2a1a86","0x1c2bc8b553d9a7e61f7531a3a4bf2162f4569268","0xee26bb0989691735c997dfdc49a4a607f75e190b","0xd0428799fbc35557834d33121ba4472692c8908a","0x6Ce4bc043398Ac40392d1E063328048072b2075d"],"measured_funds_usd":169413236.76,"plausibility":2,"score":10,"why_open":"prior pass2 LANE-CLOSED says 0 USDC held; live totalAssets contradicts it; unverified async vault","next_check":"decompile impl 0xe5d7e7e079eca99ebe5295e24a3908374e8aed42; enumerate redeem/NAV auth"},
   {"rank":2,"target":"Gambit Vault USDG redemption","chain":"BSC","addresses":["0xc73A8DcAc88498FD4b4B1b2AaA37b0a2614Ff67B"],"measured_funds_usd":99000,"plausibility":3,"score":6,"why_open":"real unprivileged accounting defect; only blocked by absence of a USDG market","next_check":"enumerate USDG holders/venue; fork-test mint->redeem if a pair appears"},
   {"rank":3,"target":"SunSwap V4 PoolManager","chain":"Tron","addresses":["TVjuTE3V5bMVdpfNhid8kD2v35T2k1u1Br"],"measured_funds_usd":134700000,"plausibility":1,"score":5,"why_open":"57,582-byte unverified singleton; source unpublished; no verdict","next_check":"decompile runtime; check hook auth + unlock payer accounting"},
   {"rank":4,"target":"Stellar DeFi Hub Evergreen share vault","chain":"Stellar","addresses":["CALFCZ4TY2CLHDHNJWCZX6JKYGUPV7P3GNQ3UVABXNE5JCV2E774APUM"],"measured_funds_usd":113840000,"plausibility":1,"score":5,"why_open":"protocol $113.84M; Evergreen vault unverified and not hash-matched","next_check":"fetch contract spec; verify require_auth and share math"},
   {"rank":5,"target":"Tron trio CherryPool/PokerGame/FireFullContract","chain":"Tron","addresses":["TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR","TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn","TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW"],"measured_funds_usd":1077360,"plausibility":2,"score":4,"why_open":"$1.08M in unverified contracts; arbitrary-caller withdraw executes but pays 0","next_check":"decompile; identify balance mapping and any contract-funded payout"},
   {"rank":6,"target":"ApolloX EIP-2535 diamond","chain":"BSC","addresses":["0x1b6F2d3844C6ae7D56ceb3C3643b9060ba28FEb0"],"measured_funds_usd":123423,"plausibility":1,"score":2,"why_open":"29 facets unreviewed; 123k USDT in diamond","next_check":"enumerate facets; check onlyOrderBook/oracle validation"},
   {"rank":7,"target":"Wanchain Cardano-BNB bridge","chain":"Cardano","addresses":["8c027908260ebc29410ce4fffe788da510e4d7fd67f4b39d3c77db5e"],"measured_funds_usd":0,"plausibility":1,"score":1,"why_open":"218,156 ADA treasury; replacement script unverified","next_check":"decode Plutus script/datum; test injectivity of signed-message encoding"}
 ],
 "key_facts":[
   "198 named candidates: 39 README-named + 159 agent-only",
   "70 rows prior-covered/partial; 101 agent-only leads; 11 not-a-protocol; 9 OPEN rows = 7 targets",
   "Affluent: mint primitive live but prior measured redeemable value $0.00 (MASTER row 32)",
   "Papertrade: existing ZH3-C3 monitor; CA2 adds no new primitive",
   "wasmer GHSA-v2h8: new advisory, same CWA-2026-006 compiler family; impact is validator RCE",
   "R25 prior LANE-CLOSED '0 USDC' contradicted by live $169.41M totalAssets (Pharos block 22015709)",
   "Gambit USDG defect: $75.4k at-face capacity, $0 extractable without a USDG acquisition venue",
   "Tron trio: $1.08M in three unverified contracts; calls execute but return 0 for a non-user"
 ],
 "caveats":[
   "OPEN plausibility is low; unverified code is not an exploit",
   "TVL/funds figures are not extractable value and must not be summed into an E-U headline",
   "Some chains had no working RPC/logs during CA2 (Optimism/zkSync/Blast/Berachain; Avalon/Flow/Plume/Robinhood/AssetChain/BESC/Fuse)",
   "Papertrade Exchange/Executor/SKM and R25/SunSwap/Stellar/Tron/ApolloX implementations remain unverified",
   "wasmer/CWA-2026-006 exploit technique is not public",
   "BTCPay/Fearless operator and victim populations are unmeasured"
 ],
 "one_liner":"No new live unprivileged >$10k path survives; CA2's criticals are a $0-measured TON primitive, an existing Papertrade monitor and a prior-covered compiler RCE; the real residual is the unverified $169.4M R25 vault family on Pharos plus six smaller unverified surfaces."
}
json.dump(summary, open("summary.json","w"), indent=1)
print("wrote summary.json")
