# CA3 Residual Reconciliation — every named candidate, one disposition

**Date:** 2026-11-10 · **Corpus reconciled:** the new CA3 of 2026-11-09 (466-line `README.md` + 48 files in `ca3/research/`) · **Mode:** read-only. No transaction was signed or broadcast; no key was used. All live reads are `eth_call` at the block stated in `analysis/live-checks.md`.

**Status line:** reconciliation only. This folder does **not** re-audit the live CA3 criticals (C1/C2, C3, C4/H2, C5) or the prior-assigned targets; it dispositions every named candidate, checks the residual surfaces, and publishes the OPEN list.

---

## 1. TL;DR

| Metric | Count |
|---|---:|
| Named candidate rows enumerated | **87** |
| Sourced from the CA3 README (headline + §7) | **45** |
| Sourced only from the 48 research files | **42** |
| Prior-covered / prior-assigned / prior-partial | **64** (9 assigned + 50 covered + 5 partial) |
| Research-only, closed in the research file or on re-read | **16** |
| Not a protocol / out of E-U scope | **4** |
| **OPEN (genuinely unassessed residual)** | **3 — all LOW coverage gaps, no path shown** |
| **New extractable value identified by this pass** | **$0** |

**Bottom line.** The new CA3 is almost entirely a re-packaging of prior work. Every headline finding (C1–C5, H1–H4) is either our own live finding (C1 pass7, C2 ZH4-02), already assigned to a live CA3 agent (C3, C4/H2, C5), or prior-covered (H1/H3/H4). Every §7 watchlist row is prior-covered or prior-assigned. The four bridges CA3 labels **“unassessed”** — Popdex ($77.2M), STRATO ($1.14M), Pacifica ($23.4M), JustLend sTRX ($3.135B) — were **fully assessed and closed at E-U $0 in prior passes**; their funds are still on-chain, but the closure stands (see §5). The only residual surfaces not covered by prior work are three low-plausibility coverage gaps: the Vesper V2 fleet ($87.4M, 2 of 19 pools previously checked), Faroo stPROS ($2.7M, 6 custody proxies unchecked), and Cellana’s no-signer `rescue_stuck_rewards` (Aptos, reward-only, simulation-negative).

**No OPEN candidate clears the >$10k unprivileged bar.** The honest output of this reconciliation is a corrected prior-coverage map plus a three-item low-tier watchlist, not a new finding.

> **Prior live E-U is not re-credited here.** C1 wsNET (free liquidity $396,780 at the CA3 read; pass7 read $460,865; net +$15k–$40k, +$150k pre-held) and C2 Startale ($1.124M vault, ~$92/day per $1M, income-class) remain live and are monitored by their existing folders. They are **not** this report’s headline because they are already handled.

---

## 2. Method

1. **Extraction.** Read the 466-line README and all 48 research files (13 text/JSON evidence files + 35 source/ABI/bytecode artefacts). Extracted every named protocol, contract family, bridge, vault, audit row, and non-EVM cluster into `analysis/candidates.json`.
2. **Disposition.** Each row got exactly one of: `PRIOR-ASSIGNED`, `PRIOR-COVERED`, `PRIOR-PARTIAL`, `RESEARCH-ONLY`, `NOT-A-PROTOCOL`, `OPEN`. The CA3 grade (CRITICAL/HIGH/LOW) is preserved separately.
3. **Prior-coverage test.** `ci/ZH4P7 → ZH4P6 → ZH4P5 → ZH4P4 → ZH4P3 → ZH4P2 → ZH4 → ZH3 → ZH2B*`, `CA2-RESULTS-TRACKER.md`, `CA3-C1-TRACKER.md`, `CA3-V2-TRACKER.md`, `L2-*`, `MONITOR-LIST.md`, `MASTER-EXTRACTION-TABLE.md`, `CROSS-CHAIN-FEASIBILITY.md`, the kept root folders, and `zombie-hunt-iv/zh4-check.sh "<name>"`.
4. **Residual hunt.** Focused on the research files and §7: the four “unassessed” bridges, non-EVM residual, new-protocol scans, audit-unfixed rows, and any name with no prior hit. For each OPEN: live existence, balance, source/auth probe, and a concrete next check.
5. **Live sanity checks.** Read-only `eth_call` on Ethereum (26,380,997), Base (55,405,158), Arbitrum (522,832,557), Pharos (22,609,065), plus the CA3 blocks for Robinhood/BSC/PulseChain. Full evidence in `analysis/live-checks.md`.
6. **CI.** The reconciliation validator runs on GitHub Actions (`artsbykriss/ca-zombie-ci`, folder `ca3-recon`) — counts, OPEN completeness, secret scan, and a check that no README/research candidate is left without a disposition. Results in `ci-out/`; run URL in §10.

---

## 3. Disposition table — README-sourced candidates (45)

| # | Candidate | Chain | CA3 grade | Disposition | Live state / verdict | USD context | Conf. | Key address / prior evidence |
|---|---|---|---|---|---|---:|---|---|
| R01 | **wsNET / USDG Morpho Blue (C1)** | Robinhood 4663 | CRITICAL | `PRIOR-COVERED` | LIVE E-U; free liquidity $396,780 (pass7 read $460,865); held-skew, CA3 net estimate +$15k-40k / +$150k pre-held (pass7 CI: +$58,365 all-in / +$301,773 pre-held) | $396,780 | high | `Morpho 0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010; market 0xaa586d26...0589; oracle 0xCDE95990...5F16` — zombie-hunt-iv/pass7/wsnet.md + wsnet-verify.md; keeps wsnet-oracle/; CA3-V2 says monitor, no re-audit |
| R02 | **Startale Earn (C2)** | Soneium 1868 | CRITICAL | `PRIOR-COVERED` | LIVE income E-U; $1.124M vault, ~$92/day per $1M; JIT epoch capture | $1,124,053 | high | `EarnVault 0xFdeB7e9F59cad080D9158ff850Ce79bCf6cdd5f0` — zombie-hunt-iv/wave2/v10-startale.md; keeps startale-earn/ |
| R03 | **GDC / WBNB pair (C3)** | BSC 56 | CRITICAL | `PRIOR-ASSIGNED` | ASSIGNED ca3-gdc; 44.0803 WBNB (~$30k), net ~$27k; 1,231 GDC + flash gate | $30,000 | medium-high | `pair 0xe3349ca6ac1656e02b20b8d5a4c095e28255eb0a; token 0x39a90d08...7777` — ca3-gdc (live session); research/incident-patterns.md §4 |
| R04 | **Neufund FeeDisbursal (C4, PulseChain)** | PulseChain 369 | CRITICAL | `PRIOR-ASSIGNED` | ASSIGNED ca3-neufund; 54.1828 ETH-T + 29,090.97 EUR-T (~$146k); verified-identity gate | $146,000 | high (state) / medium (fresh attacker) | `0x26B7DedAb33c58bC9Edc26D9CD81b8eEE43c24Dd` — ca3-neufund (live session); research/incident-patterns.md §6 |
| R05 | **HAI governance (C5)** | Optimism 10 | CRITICAL | `PRIOR-ASSIGNED` | ASSIGNED ca3-hai; treasury ~$37.4k, quorum ~$5.5k; KITE OTC gate | $37,400 | medium | `Governor 0xe807f3282f3391d237BA8B9bECb0d8Ea3ba23777; KITE 0xf467C7d5...1404` — ca3-hai (live session); ZH4-01; MONITOR row 9 |
| R06 | **Unlock Protocol governance (H1)** | Base 8453 | HIGH | `PRIOR-COVERED` | CLOSED E-U ~$0; $47.4k treasury but deployer 59.7M UP; turnout 6.58-13.85M | $47,400 | high | `Governor 0x65bA0624403Fc5Ca2b20479e9F626eD4D78E0aD9` — pass7 gov-params; keeps unlock-gov/; CA3-V2 row H1 |
| R07 | **Neufund FeeDisbursal (H2, Ethereum)** | Ethereum 1 | HIGH | `PRIOR-ASSIGNED` | ASSIGNED ca3-neufund; 29,090.97 EUR-T (~$31k); same identity gate | $31,000 | high (state) / medium (fresh attacker) | `0x26B7DedAb33c58bC9Edc26D9CD81b8eEE43c24Dd` — ca3-neufund (live session); research/incident-patterns.md §6 |
| R08 | **Shibarium stale-WBONE cluster (H3)** | Shibarium 109 | HIGH | `PRIOR-COVERED` | CLOSED above bar; E-U $739.07 net one-shot (CA3 quoted $877 gross); DAI/USDT exits dead | $739 | high | `WBONE/WETH 0xe4dbeE5Fa46fB8A4D00FB719deDCAEDc91AE5F13` — ZH4-03; keeps shibarium-wbone/ |
| R09 | **X7Finance X7Pioneer (H4)** | Ethereum 1 | HIGH | `PRIOR-COVERED` | LIVE but holder-gated to NFT #300; $45.93 pool; fresh EOA $0 | $46 | high | `0x70000299Ee8910cCaCD97B1bB560E34F49c9e4f7` — rearm-watch/; ZH3-H6/7/9/10; CA3 §4 |
| R10 | **StationX (L1)** | Linea 59144 | LOW | `PRIOR-COVERED` | DRAINED — 0 ETH at block 32,561,481; path in code, no fuel | $0 | high | `BuyDaoToken 0x9be2a2750b0bdfb9ff6bbb8a45e093f73e27e364` — stationx/; CA3 §6 |
| R11 | **HeavensGate HATE (L2)** | Ethereum 1 | LOW | `PRIOR-COVERED` | DRAINED / sub-threshold — pair WETH 0.0018535 (~$3.94) | $4 | high | `heavensgate/ (pair per CA3 §4)` — heavensgate/; CA3 §6 |
| R12 | **Ankr bridge (L3)** | Ethereum/Optimism + 8 | LOW | `PRIOR-COVERED` | DRAINED/PAUSED — ETH/ankrETH/ANKR 0; Mode unpaused but empty | $0 | high | `0xc437DF90B37C1dB6657339E31BfE54627f0e7181` — research/incident-patterns.md §5; MONITOR; prompt prior |
| R13 | **Zenji leveraged vaults (L4)** | Ethereum 1 | LOW | `PRIOR-ASSIGNED` | ASSIGNED ca3-zenji-siblings; Zenji itself dust ($19 + $137); permissionless rebalance survives | $156 | high | `0x23f189de34eed95f6303cff1c77f7676f211dd2c; 0x18e2f4f2e6565187fce73ecc707579e5f7933f74` — ca3-zenji-siblings (live session); research/incident-patterns.md §3 |
| R14 | **Neufund EtherToken v1** | Ethereum 1 | LOW/watch | `PRIOR-COVERED` | 2.07 ETH unclaimed across 3 addresses; per-user withdraw self-service; $0 E-U | $4,400 | high | `EtherToken v1 (3 holders; CA3 §7)` — CA3-V2 note: prior Neufund hits were EtherToken custody only |
| R15 | **Gambit Vault USDG** | BSC 56 | LOW/watch | `PRIOR-COVERED` | Defect real (74,934.51 USDT face capacity) but venue-blocked; E-U $0; float 6,479.92 USDG | $0 | high | `Vault 0xc73A8DcAc88498FD4b4B1b2AaA37b0a2614Ff67B; USDG 0x85E76cbf...F5a7` — CA2-OPEN-2; MONITOR row 101 (conditional $650.69-$16,273) |
| R16 | **ApolloX EIP-2535 diamond** | BSC 56 | LOW/watch | `PRIOR-COVERED` | CLOSED — 123,423 USDT is 98.8% broker liability; 229 selectors all self/role-gated; E-U $0 | $0 | medium-high | `0x1b6F2d3844C6ae7D56ceb3C3643b9060ba28FEb0` — CA2-OPEN-6; MONITOR row 103; research/gambit-apollox.md §3.3 |
| R17 | **CherryPool** | Tron | LOW/watch | `PRIOR-COVERED` | CLOSED — 916,374 TRX; all withdrawals self-scoped; 2020 dividend periods ended | $275,000 | high | `TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR` — research/tron-trio.md §3.1; prior CA2 |
| R18 | **PokerGame** | Tron | LOW/watch | `PRIOR-COVERED` | CLOSED — 1,040,716.80 TRX is cfo-only income; withdraw() self-scoped | $312,000 | high | `TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn` — research/tron-trio.md §3.2 |
| R19 | **FireFullContract** | Tron | LOW/watch | `PRIOR-COVERED` | CLOSED — 1,421,734.92 TRX; owner/SP gates; join() disabled at periods=1 | $427,000 | medium-high | `TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW` — research/tron-trio.md §3.3 |
| R20 | **R25 WrappedVault family** | Pharos 1672 | LOW/watch | `PRIOR-COVERED` | CLOSED — $169.8M totalAssets accounting, $0 USDC in vaults; all entry/exit auth-gated | $0 | high | `Q 0x94f7...1a86; W 0x1c2b...9268; S 0xee26...190b; A 0xd042...908a; H 0x6Ce4...075d` — CA2-OPEN-1; MONITOR row 100; research/r25-pharos.md |
| R21 | **SunSwap V4 PoolManager** | Tron | LOW/watch | `PRIOR-COVERED` | CLOSED — $131.7M TVL; runtime byte-match except metadata; all value paths NoLocker/role | $0 | medium | `TVjuTE3V5bMVdpfNhid8kD2v35T2k1u1Br` — research/sunsawp-tron.md; prior CA2 |
| R22 | **Stellar Evergreen / Sentora USDC** | Stellar | LOW/watch | `PRIOR-COVERED` | CLOSED — 51,220,558.94 USDC; every value path require_auth; E-U $0; P $33.75M | $0 | high | `CALFCZ4TY2CLHDHNJWCZX6JKYGUPV7P3GNQ3UVABXNE5JCV2E774APUM` — CA2-OPEN-4; MONITOR row 99; research/stellar-evergreen.md |
| R23 | **Popdex Bridge** | Arbitrum + Morph | LOW/watch | `PRIOR-COVERED` | CLOSED E-U $0 — full EIP-712/RE attack battery; $74.94M still in bridge (11-10 read); P-class keys | $74,937,816 | high | `bridge 0x0B15D6cF5e843C88034f64664D7fE66E5F79C5f2; gateway 0x48bB6AdE8DE61f6D4406266af17726934Cafc657` — zombie-hunt-iv/wave2/v14-popdex.md (21-path battery); CA3 §7 says 'unassessed' = stale |
| R24 | **STRATO Bridge** | Ethereum + 5 | LOW/watch | `PRIOR-COVERED` | CLOSED E-U $0 — 28 gate + 13 free-money sims revert; $1.144M ETH custody (live 11-10); 2-of-3 Safe = P | $1,144,000 | medium | `Safe 0x8c458f866e603335ef179a63a2528f357732f5d5; router 0xc3be40e5eae865d6d80ec334f009eb1bdd107e1b` — ZH2B6 H2-05; CA3 §7 'unassessed' = stale |
| R25 | **Pacifica Bridge** | Solana | LOW/watch | `PRIOR-COVERED` | CLOSED E-U $0 — 12 read-only sims; withdraw authority signer; $2.28M program + $22M Squads cold | $23,200,000 | high | `PCFA5iYgmqK6MqPhWNKg7Yv7auX7VZ4Cx7T1eJyrAMH` — zombie-hunt-iv/pass6/pacifica-bridge.md; pass5 non-evm; CA3 §7 'unassessed' = stale |
| R26 | **JustLend sTRX** | Tron | LOW/watch | `PRIOR-COVERED` | CLOSED E-U $0 — full STRXG2 source read; all paths gated/pool-favoring; P single-EOA admin | $0 | high | `STRXProxy TU3kjFuhtEo42tsCBtfYUAZxoqQ4yuSLQ5` — zombie-hunt-iv/wave1/r4-non-evm.md row 9; README CLOSED#27; CA3 §7 'unassessed' = stale |
| R27 | **Fables** | Robinhood 4663 | LOW/watch | `PRIOR-COVERED` | CLOSED E-U $0 — 13 hooks, no delta flags, all setters restricted; $36M TVL H-O | $0 | high | `registry 0x159a113e012593d9b3cc63ad45e30f0467e13ef3` — ZH3-H13; keeps fables/ (conditional park-capture monitor 0x06a88987...) |
| R28 | **Affluent / Factorial (TON)** | TON | LOW/watch | `PRIOR-PARTIAL` | Prior E-U $0 (false positive); mint primitive live but burn pays 0; E-U-conditional $1.013M if re-funded | $0 | medium | `8 pools; affUSDTl EQAGtgnr...cuSaW; affTONl EQADQ6Jc...UrfBN` — ZH4P4; CA2-C1; MONITOR row 97 |
| R29 | **BisonFi** | Solana | LOW/watch | `PRIOR-COVERED` | Prior LOW/unproven — $20.41M; closed-source prop AMM; no path shown | $20,407,740 | low | `BiSoNHVpsVZW2F7rx2eQ59yQwKxzU5NvBcmKshCSUypi` — research/non-evm-scan.md C2; prompt prior |
| R30 | **Tessera V** | Solana | LOW/watch | `PRIOR-COVERED` | Prior LOW/unproven — $11.88M; closed source; Wintermute prop AMM | $11,875,786 | low | `TessVdML9pBGgG9yGks7o4HewRaXVAMuoVj4x83GLQH` — research/non-evm-scan.md C3; prompt prior |
| R31 | **GoonFi v1/v2** | Solana | LOW/watch | `PRIOR-COVERED` | Prior LOW/unproven — $5.35M; Mar-2026 mispricing; v2 upgrade 11-06 | $5,348,846 | low | `v2 goonuddtQRrWqqn5nFyczVKaie28f3kDkHWkHtURSLE` — research/non-evm-scan.md C4; prompt prior |
| R32 | **Scorch** | Solana | LOW/watch | `PRIOR-COVERED` | Prior LOW/unproven — $3.56M; closed source; single-key upgrade monitor | $3,558,059 | low | `SCoRcH8c2dpjvcJD6FiPbCSQyQgu3PcUAWj2Xxx3mqn` — research/non-evm-scan.md C5; MONITOR row 20 |
| R33 | **AlphaQ** | Solana | LOW/watch | `PRIOR-COVERED` | Prior LOW/unproven — $1.01M; closed source; 41 markets | $1,012,605 | low | `ALPHAQmeA7bjrVuccPsYPiCvsi428SNwte66Srvs4pHA` — research/non-evm-scan.md C6; prompt prior |
| R34 | **Aquifer** | Solana | LOW/watch | `PRIOR-COVERED` | Prior LOW — $156.6k; Aug-31 $2.47M exploit; upgraded 10-22, no swap flow | $156,570 | low | `AQU1FRd7papthgdrwPTTq5JacJh8YtwEXaBfKU3bTz45` — research/non-evm-scan.md C7; prompt prior |
| R35 | **USX.Capital** | Scroll | LOW/watch | `PRIOR-ASSIGNED` | ASSIGNED ca3-usx-mezz; $568.7k treasury; Zellic 3.5 acknowledged trust trade-off, no E-U path | $568,700 | low (E-U) | `treasury 0x9F3d4b0C9E930Ca3957eCD3DEdb7417f8e0e4c35` — ca3-usx-mezz (live session); research/audit-unfixed.md §3.1 |
| R36 | **Mezzanine** | Ethereum 1 | LOW/watch | `PRIOR-ASSIGNED` | ASSIGNED ca3-usx-mezz; H-1 fixed live (OraclesNotInSync); M-1 fairness only; $5.19M TVL | $5,185,488 | high (H-1 fixed) | `IssuanceVault 0xbb03549117e38103589774ae1d6338d1b237ffa2` — ca3-usx-mezz (live session); research/audit-unfixed.md §3.2 |
| R37 | **OPINION** | BNB 56 | LOW/watch | `PRIOR-ASSIGNED` | ASSIGNED ca3-opinion-tenbin; $2.746M TVL; Pashov L-06 acknowledged, no address published | $2,746,424 | low | `DisputeResolver unpublished` — ca3-opinion-tenbin (live session); research/audit-unfixed.md §3.3 |
| R38 | **Securitize EVM Async Vault** | EVM | LOW/watch | `PRIOR-COVERED` | Prior — Cyfrin 1 High partially resolved; permissioned KYC RWA; no address/TVL | $0 | low | `unpublished` — research/audit-unfixed.md §3.4; prompt prior |
| R39 | **Tenbin Labs** | EVM | LOW/watch | `PRIOR-ASSIGNED` | ASSIGNED ca3-opinion-tenbin; Zellic 3.2/3.3 acknowledged but role-gated; no address/TVL | $0 | low | `unpublished` — ca3-opinion-tenbin (live session); research/audit-unfixed.md §3.5 |
| R40 | **BeraFarm** | Berachain | LOW/watch | `PRIOR-COVERED` | CLOSED — patch complete for Oct-9 vector; E-U $0; $257.9k live | $0 | high | `Kodiak 0xc6865dc8...; Bend 0xee965e0a...` — ZH4-06; MONITOR row 11 |
| R41 | **UNCX** | multi | LOW/watch | `PRIOR-PARTIAL` | E-U $0 live; flatFee=uint256.max freezes ~$1.16M nominal; $18.5-37k only if fee lowered | $0 | high | `UNCX manager pools (CA3 §7)` — ZH3-C1; ZH4-P2 corr; MONITOR row 6/42 |
| R42 | **Olas POL** | Ethereum/Base/OP | LOW/watch | `PRIOR-PARTIAL` | E-U $0 today; unpatched cardinality<=1 same-block sandwich; $1.16M-class re-arm | $0 | high | `LiquidityManagerCore (olas-pol/)` — ZH4-04; MONITOR row 10 |
| R43 | **Aragon-legacy** | Ethereum 1 | LOW/watch | `PRIOR-PARTIAL` | E-U $0 today; ACL escalation fork-proven; E-U-conditional 227.30 ETH (~$534k) on token listing | $0 | high (today) | `closest 0xf6b32eee... (1.71 ETH, minAQ=0)` — ZH4-P7-01; MONITOR row 82 |
| R44 | **USDT0 OFT** | multi | LOW/watch | `PRIOR-PARTIAL` | E-U $0; $3.197B escrow; 21 live routes 3-of-3; 4 dormant 1-of-1 routes need a PeerSet | $0 | high | `OFT adapter (Ethereum; ZH4-P7-04)` — ZH4-P7-04; MONITOR row 84 |
| R45 | **Circle Gateway** | Ethereum 1 | LOW/watch | `PRIOR-COVERED` | E-U $0; $63.9M; single-EOA UUPS owner + 4 batch signers = P-class, not E-U | $0 | high (classification) | `0x2222...C205 minter; 0x7777...1000eE wallet` — ZH4-P7-05; MONITOR row 85 |

**README disposition summary:** 9 prior-assigned (the live CA3 agents), 31 prior-covered, 5 prior-partial, 0 research-only, 0 not-a-protocol, 0 OPEN. The README contains **no unassigned live candidate**.

---

## 4. Disposition table — research-file-sourced candidates (42)

| # | Candidate | Chain | CA3 grade | Disposition | Live state / verdict | USD context | Conf. | Key address / prior evidence |
|---|---|---|---|---|---|---:|---|---|
| S01 | **BDEX V3** | BOT Chain 677 | — | `PRIOR-COVERED` | CLOSED E-U $0 — core byte-identical UniV3 v1.0.0; USDT mint MINTER_ROLE; $30.7M TVL | $0 | high | `factory 0x1C51c173323ec11BB4e3C4fD2314c225Dc4b5419` — TIER3 L2-23 (CI 38734388280) |
| S02 | **BDEX V2** | BOT Chain 677 | — | `PRIOR-COVERED` | CLOSED — all 84 pairs balance==reserve; feeTo=0; no skim excess | $0 | medium | `factory 0x117115f3B72C8d1989178089A67D0C26f8EE0AA3` — TIER3 L2-23; research/defillama-new.md §4.1 |
| S03 | **Shift DeFi** | Ethereum 1 | — | `PRIOR-COVERED` | CLOSED — every state transition OPERATOR/CONTAINER/RESHUFFLING role; claim self-scoped | $0 | high | `vault 0x1d71c888961c4600cF0E31F6196b4dA7fE72e4B3` — pass7 VERIFIED-CLOSED; research/defillama-new.md §4.2 |
| S04 | **FermiSwap** | Ethereum 1 | — | `PRIOR-COVERED` | CLOSED E-U $0 — own-inventory hypothesis refuted; provider-posted prices; ~$5.31M | $0 | high | `swapper 0xb1076fE3AB5e28005C7c323Bac5AC06a680d452e` — ZH3-H16 (CI 38848938942); MONITOR row 22 |
| S05 | **Vesper V2 fleet** | Ethereum/Base/OP | — | `OPEN` | OPEN-LOW (coverage gap): $87.36M (ETH $78.46M + Base $6.56M + OP $2.34M); research checked 2 vaults only; sampled pools gate reportEarning/migrateStrategy | $87,360,896 | low (no path shown) | `vaUSDC 0xa8b607Aa09B6A2E306F93e74c282Fb13f6A80452; vaETH 0xd1C117319B3595fbc39b471AB1fd485629eb05F2; Base vaUSDC 0x1e41238aCd3A9fF90b0DCB9ea96Cf45F104e09Ef` — research/defillama-new.md §4.7 ($9.69M subset); no prior hits (zh4-check empty) |
| S06 | **Faiyah Staking** | Xphere | — | `PRIOR-COVERED` | Prior E-U $0 (high); commingled-principal is H-O race, not extraction; $4.38M TVL | $0 | high | `factory 0x95c8853e6bD1DBCE2428Aa6953eb7680261F22fe` — ZH4-05 (CI 39083974093) |
| S07 | **Theo thUSD** | Ethereum 1 | — | `PRIOR-COVERED` | CLOSED — thUSD supply 0.000138; $138.57M is off-contract RWA; minter role + whitelist | $0 | high | `0xa3fE5c7596024E6811E14F029937D5bd8Ae485b3` — pass7 VERIFIED-CLOSED; research/defillama-new.md §4.6 |
| S08 | **Axis USDx** | Ethereum 1 | — | `RESEARCH-ONLY` | CLOSED at auth — 68.65M supply; mint/bridgeMint MARKET_ROLE; top minter is codeless EOA | $0 | medium | `0xa1fA7777974312f7d801A8880714a218F76233f8` — research/defillama-new.md §4.5; no prior hits |
| S09 | **JUSD Finance** | Ethereum/Arbitrum/Aleo | — | `PRIOR-COVERED` | CLOSED — ETH vault $35,325; mintShares/processUpTo* onlyStrategy; $27.48M mostly Arb/Aleo | $0 | high | `vault 0x2B5895b716311A1eaC8f93fB88C56aF9eC8C1A69` — pass6 (closed, not re-audited); research/defillama-new.md §4.9 |
| S10 | **Kamui Finance** | Ethereum 1 | — | `PRIOR-COVERED` | CLOSED E-U $0 (QC PASS) — 3 Lagoon vaults; owner/operator/allowance gates; $2.87M | $0 | medium-high | `0xcDA323c2DF692d989B24BA51D0aCCa924cf9a344` — ZH4 exotic/legacy QC (ci/qc/exotic-legacy-QC-VERIFY.md §9) |
| S11 | **Syntetika / Ember Hilbert BTC** | Base 8453 | — | `RESEARCH-ONLY` | CLOSED — $16.16M hBTC vault; `bridgeAdapter()` = 0 today; ERC-4626 deposit self-scoped | $0 | high (today) | `vault 0x9C2dCDbDB3F0A0F628D1112bBCABD9AE75353df3; impl 0x23cc7e7e237d84b1ec055e863097e864aa282a1c` — research/defillama-new.md §4.10; live check 2026-11-10 (block 55,405,158) |
| S12 | **Faroo stPROS** | Pharos 1672 | — | `OPEN` | OPEN-LOW (coverage gap): $2.73M TVL; only stPROS checked; 6 ERC1967 custody proxies, unverified impls | $2,729,582 | low (no path shown) | `stPROS 0x6b0a44c64190279f7034b77c13a566e914fe5ec4; BridgeVault 0xf1df1cb080256f48e8702c24149136e4a6dec25e; SlpDistributor 0xf772b375f93650f798bf724ce7a9a45c9e7a579f` — research/defillama-new.md §4.10; live check 2026-11-10 (block 22,609,065); no prior hits |
| S13 | **Ascend a0G** | 0G 16661 | — | `PRIOR-COVERED` | Prior E-U $0 — OFT endpoint/peer-gated; queue self-scoped; H-O $202,659; P $2.87M | $0 | high | `0x4B3c2f55fa67679b382c979A082Df1B32079B4cB` — P6-02 (CI 17/17) |
| S14 | **Longbow** | Robinhood 4663 | — | `PRIOR-COVERED` | PRIOR — 55 markets on the same Morpho singleton; market 0xaa586d26...0589 is C1 | $0 | high | `Morpho 0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010` — research/defillama-new.md §5; C1 pass7 |
| S15 | **RNT Lend** | Polygon | — | `PRIOR-COVERED` | PRIOR — RWA collateral 75% LTV, issuer oracle; no new entry | $0 | medium | `prior corpus (RNT)` — research/defillama-new.md §5 |
| S16 | **Papertrade** | Hyperliquid L1 | — | `PRIOR-COVERED` | PRIOR monitor — free LP $4.42-4.95M but E-U $0 at caps; oracle BBO no breaker | $0 | high | `Papertrade (Hyperliquid)` — ZH3-C3/CA2-C2; MONITOR row 7 |
| S17 | **Metric V1** | Ethereum | — | `PRIOR-COVERED` | PRIOR — ~$0.66 residual | $0 | high | `prior corpus` — research/defillama-new.md §5 |
| S18 | **CommunityV3** | Ethereum | — | `PRIOR-COVERED` | PRIOR — stock Uniswap V3; no deviation | $0 | medium | `prior corpus` — pass6 closed; research/defillama-new.md §5 |
| S19 | **The Moats** | Ethereum | — | `NOT-A-PROTOCOL` | NOT-A-PROTOCOL — getAllDeployedContracts() == [] | $0 | high | `none deployed` — research/defillama-new.md §5 |
| S20 | **Derive V3** | Derive/Lyra | — | `PRIOR-COVERED` | PRIOR — re-listing of long-lived deployment; pass7 verified-closed | $0 | high | `prior corpus` — pass7 VERIFIED-CLOSED; research/defillama-new.md §5 |
| S21 | **Aero Slipstream/Basic** | Base 8453 | — | `PRIOR-COVERED` | PRIOR — re-listing; not a fork; no new entry | $0 | medium | `Aerodrome` — pass6 closed; research/defillama-new.md §5 |
| S22 | **Hyperliquid Earn** | HyperCore | — | `NOT-A-PROTOCOL` | NOT-A-PROTOCOL for E-U — $1.43B, 4 days old, 0 audits, HyperCore-native (no EVM contract) | $0 | n/a | `none (HyperCore)` — ZH4-P7-02; MONITOR row 86 |
| S23 | **Risk-curator wrappers (Nonce, Waterline, NEMO, Keyrock, Flowdesk, August)** | multi | — | `RESEARCH-ONLY` | CLOSED — curator wrappers; underlying vault roles are the gate; no new entry | $0 | medium | `no published candidate` — research/defillama-new.md §5 |
| S24 | **Solana fresh-LST cluster (Forward Industries, Phase, Definity, Japan Staked, Raiku)** | Solana | — | `RESEARCH-ONLY` | UNASSESSED — excluded as 'SPL stake-pool style'; no program IDs / no fork test | $0 | n/a | `not resolved` — research/defillama-new.md §5 |
| S25 | **AFX Bridge** | Arbitrum | — | `RESEARCH-ONLY` | CLOSED — Zellic 3.1 Critical fixed; TVL $4.9987; no fuel | $5 | high | `unpublished` — research/audit-unfixed.md §4 |
| S26 | **Nori Bridge** | Rust/Bitcoin | — | `RESEARCH-ONLY` | CLOSED — 3.4 Critical is compromised-admin design; no TVL; privileged only | $0 | high | `unpublished` — research/audit-unfixed.md §4 |
| S27 | **Relay Protocol Oracle/Settlement** | Sui/EVM | — | `RESEARCH-ONLY` | CLOSED — Sui VM removed; remaining findings fee/DoS; no live TVL | $0 | medium | `unpublished` — research/audit-unfixed.md §4 |
| S28 | **Steer Phantom Liquidity Hook** | multi | — | `RESEARCH-ONLY` | NO-FINDING — Cyfrin 0 High / 0 Critical; 5 Medium resolved | $0 | high | `unpublished` — research/audit-unfixed.md §4 |
| S29 | **Audit negatives (Maple, Aave Labs, Notional, Vesu, Fluent, YieldFi, Tori, ODEI)** | multi | — | `RESEARCH-ONLY` | NO UNFIXED HIGH — parsed 2026 audit portfolios; 0 live unfixed Critical/High | $0 | medium | `n/a` — research/audit-unfixed.md §4 |
| S30 | **Injective Peggy** | Injective | — | `RESEARCH-ONLY` | CLOSED — public-known issues are rate-limit/fund-freeze, not unprivileged drain | $0 | medium | `n/a` — research/audit-unfixed.md §4 |
| S31 | **Choice Exchange V1** | Injective | — | `PRIOR-COVERED` | CLOSED — ~$290k Terraswap-style; standard audited code | $0 | medium | `inj1k9lcqtn3y92h4t3tdsu7z8qx292mhxhgsssmxg` — pass6 closed; research/non-evm-scan.md §5 |
| S32 | **Loopscale / curation** | Solana | — | `PRIOR-COVERED` | Prior E-U $0 — exponent vaults curated by on-curve EOA; PDA/role gates | $0 | high | `sVau1tXv... (13/72 vaults)` — ZH4P7 p7-solana-c; research/non-evm-scan.md §6 |
| S33 | **Neutron Drop / Astroport** | Neutron | — | `NOT-A-PROTOCOL` | OUT OF SCOPE — Sept-2026 ~$9.3M governance attacks, not unprivileged drains | $0 | high | `n/a` — research/non-evm-scan.md §5 |
| S34 | **Aptos ABI cohort (Aries, Echelon, Joule, Aptin, Merkle, Thala LSD, Ditto)** | Aptos | — | `RESEARCH-ONLY` | CLOSED — ABI scan; only Cellana lacked a signer; Joule/Merkle config fns move no value | $0 | medium | `n/a` — research/non-evm-scan.md §5 |
| S35 | **Cellana vote_manager::rescue_stuck_rewards** | Aptos | — | `OPEN` | OPEN-LOW (semantics): no-signer entry with arbitrary address; simulation u64=0/1/2 = zero balance change; TVL unlisted | $0 | low | `0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager::rescue_stuck_rewards` — research/non-evm-scan.md C8; no prior hits |
| S36 | **Ref Finance / Burrow** | NEAR | — | `RESEARCH-ONLY` | NOT RE-AUDITED — no new >$1M NEAR listing; no callback/auth regression identified | $0 | low | `prior deployments` — research/non-evm-scan.md §5 |
| S37 | **NAVI Curator** | Sui | — | `RESEARCH-ONLY` | VERIFIED NEGATIVE — withdraw keyed by owned Receipt; no arbitrary from/to; $16.28M | $0 | medium | `0x51cecaacaed0bd436f04ebbd8ba0ca1627c9c4d0e54ad28eff095ca78591518c` — research/non-evm-scan.md §4 |
| S38 | **Haedal Lending Vault** | Sui | — | `RESEARCH-ONLY` | VERIFIED NEGATIVE — ExtAuthGuard / owned Receipt; no public withdraw(from); $6.85M | $0 | medium | `0x3777fbddf314316bb4b3618538255b09eff5460de094f5084f21edbeacbec9a8` — research/non-evm-scan.md §4 |
| S39 | **Kelpie** | Sui | — | `RESEARCH-ONLY` | VERIFIED NEGATIVE — per-user vaults; VaultOwnerCap/KeeperCap; $37.6k | $0 | medium | `0x63d5fa6a...b7c1ec` — research/non-evm-scan.md §4 |
| S40 | **XOXNO Lending** | Stellar | — | `RESEARCH-ONLY` | VERIFIED NEGATIVE — every export reaches require_auth(admin); $137.6k | $0 | medium | `CBXRNDQMAJFG4VUKMKFEMFS75UUXE2SPSNV4LEEFCSNBCN66PYRWBKXO` — research/non-evm-scan.md §4 |
| S41 | **Exceed Finance** | Solana | — | `PRIOR-COVERED` | Prior E-U $0 — full Rust source; signer-bound; pair base vaults empty (trust issue) | $0 | high | `par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV` — P6-02 / Exceed (prior); research/non-evm-scan.md §4 |
| S42 | **ACryptoS attacker EOA** | Ethereum 1 | — | `NOT-A-PROTOCOL` | NOT-A-PROTOCOL — 75.366 ETH attacker/tracing address; stealing from exploiter is still theft | $0 | high | `0x5dc8df8d0d6cfae0443bb8d9eacdfbb72b2ef322` — research/incident-patterns.md §7 |

**Research disposition summary:** 19 prior-covered, 16 research-only closed, 4 not-a-protocol, 3 OPEN. The research files add breadth, not new live value.

---

## 5. The four “unassessed” bridges are prior-closed

CA3 §7 and `research/defillama-new.md` call Popdex, STRATO, Pacifica and JustLend sTRX “unassessed”. That is **stale**: all four have full prior dossiers. Their funds are still on-chain today, so they remain monitors, not findings.

| Target | CA3 label | Prior dossier | Prior verdict | Live funds (this pass) |
|---|---|---|---:|---:|
| **Popdex Bridge** (Arbitrum/Morph) | “$77.2M; custody unpublished; unassessed” | `zombie-hunt-iv/wave2/v14-popdex.md` | **CLOSED (E-U) $0** — both unverified impls reversed; EIP-712 domain+nonce+chainId+content+message-hash bound; 21-path attack battery all reverts (`MessageAlreadyProcessed`, `InsufficientPower`, `NotFinalizer`, `AccessControlUnauthorizedAccount`). Residual = `updateVerifiers` not 100% reconstructed (LOW) + single-EOA admin/upgrader + 4 hot verifier EOAs (P). | **74,937,815.66 USDT0** at Arb 522,832,117 |
| **STRATO Bridge** (Ethereum + 5) | “$1.14M; custom non-EVM chain; unassessed” | `ci/ZH2B6-RESULTS-TRACKER.md` H2-05 | **CLOSED E-U $0** — 28 gate sims + 13 free-money sims all revert; custody is a 2-of-3 Safe; `sweepERC20`/`sweepETH`/`setGnosisSafe`/`setPermitted` onlyOwner; destination mint on Strato not normal EVM. P = 3 Safe EOAs. | **70.3859 ETH + 438,616.80 USDC + 36,898.72 USDT + 55.7405 wstETH** (~$1.144M) at ETH 26,380,997 |
| **Pacifica Bridge** (Solana) | “$23.4M; program not resolved; unassessed” | `zombie-hunt-iv/pass6/pacifica-bridge.md` (re-verification of `wave2/v28-pacifica-bulk.md`) | **CLOSED E-U $0** — 12 read-only sims; `batch_withdraw`/`withdraw_from_fallback` require `withdraw_authority` signer; `deposit` requires depositor signer; nonce/authority bound. Residual = P hot keys over ~$2.28M program custody; $22M is a Squads cold reserve no program instruction can reach. | not re-read (prior: $2.28M program + $22M cold) |
| **JustLend sTRX** (Tron) | “$3.135B TVL; re-listing of a 2023 LST; unassessed” | `zombie-hunt-iv/wave1/r4-non-evm.md` row 9; `README:CLOSED#27` | **CLOSED E-U $0** — full verified `STRXG2` source read; deposit/withdraw/claim/round-queue/freeze/unfreeze all self-scoped or pool-favoring; donation-proof internal accounting; uint64 truncation bounded. P = single EOA admin over the proxy. | not re-read (DefiLlama $3.135B) |

**Why this matters.** The $77.2M / $1.14M / $23.4M / $3.135B numbers are real custody, but the prior dossiers already reduced them to **P-class key risk or $0 E-U**. Re-listing them as “unassessed” would trigger a fourth deep-dive with the same answer. The correct action is a monitor, not an assignment.

---

## 6. OPEN list — ranked by funds × plausibility

**Definition.** OPEN = named in CA3, **no prior dossier**, and **not closed by the research file’s own checks**. Plausibility is scored 1–5 (5 = proven unprivileged path; 3 = real defect with a venue/economic blocker; 1 = no identified vector). Funds score follows `defillama-new.md`: 5 = >$50M, 4 = $10–50M, 3 = $1–10M, 2 = $100k–1M, 1 = <$100k. **Score is triage, not extractable value.**

| Rank | Target | Chain | Funds (context) | F | P | Score | Why OPEN (what prior work missed) | Addresses | Next check |
|---:|---|---|---:|---:|---:|---:|---|---|---|
| 1 | **Vesper V2 fleet** | Ethereum / Base / OP | **$87.36M** (ETH $78.46M + Base $6.56M + OP $2.34M) | 5 | 2 | **10** | No prior hit in any tracker. CA3 `defillama-new.md` §4.7 checked only `vUSDC` + `vETH` yield vaults (**$9.69M**) and closed “every state transition is role-gated”. The protocol has **19 pools** (14 ETH + 5 Base) and the two checked vaults are not the pool fleet. | vaUSDC `0xa8b607Aa09B6A2E306F93e74c282Fb13f6A80452`; vaETH `0xd1C117319B3595fbc39b471AB1fd485629eb05F2`; Base vaUSDC `0x1e41238aCd3A9fF90b0DCB9ea96Cf45F104e09Ef` | Enumerate all 19 pools from `api.vesper.finance/pools?stages=prod` + `api-base.vesper.finance/pools`; per-pool: read ERC-1967 impl, probe `reportEarning` (`0x05bed046`), `migrateStrategy` (`0x6cb56d19`), `whitelistedWithdraw` (`0xff643a7c`), proxy admin/upgrade auth. Sampled 3/3 revert (`16` / `not-governor` / `not-a-keeper`) — extend to the other 16. |
| 2 | **Faroo stPROS** | Pharos 1672 | **$2.73M** TVL (5.12M PROS; on-chain custody ~1,378 PROS) | 3 | 2 | **6** | No prior hit. CA3 `defillama-new.md` §4.10 checked only `stPROS.totalAssets()` / rate and closed “standard LST; no public mint found”. The DefiLlama adapter shows **6 custody contracts** (stPROS, SlpDistributor, BridgeVault, RewardsVault, 2 SLP pools) plus the `0x4100…` staking precompile; five are 2,739-B ERC-1967 proxies with **unverified impls**. | stPROS `0x6b0a44c64190279f7034b77c13a566e914fe5ec4`; BridgeVault `0xf1df1cb080256f48e8702c24149136e4a6dec25e`; SlpDistributor `0xf772b375f93650f798bf724ce7a9a45c9e7a579f`; RewardsVault `0xd0c44d3079e97ff285dd7a3e4e0246320a9487e5`; staking `0x4100000000000000000000000000000000000000` | Read each proxy’s impl; test `withdraw`/`claim`/`unstake`/`migrate` from a fresh EOA; reconcile `totalAssets` against custody; check whether the staking precompile’s delegated principal is counted only once. |
| 3 | **Cellana `vote_manager::rescue_stuck_rewards`** | Aptos | TVL unlisted; reward-only | 1 | 1 | **1** | No prior hit. The function has **no `&signer`** and takes an arbitrary `address`, a vector of pool objects, and a `u64` — the only no-signer value-moving entry found in the Aptos ABI scan. The CA3 simulation covered 8 pools and saw **zero balance change**; the `u64` behaves like an iteration bound, and the payout appears to go to the passed address (owner), not the caller. Semantics unresolved. | `0x4bf51972879e3b95c4781a5cdcb9e1ee24ef483e7d22f2d903626f126df62bd1::vote_manager::rescue_stuck_rewards` | Fetch the Move source; simulate on a pool with non-zero “stuck” rewards; test whether the `address` argument can be an arbitrary recipient independent of the reward owner. Bounded to reward pools, not LP principal. |

**No OPEN candidate is above the $10k / plausible bar.** Vesper is a fleet-completeness gap, Faroo is an unverified-impl gap, Cellana is a semantics gap. None has a demonstrated path. If any of the three next checks produces a public value path, it graduates to a normal finding and needs a fork/simulation before any claim.

**Two research-only gaps were deliberately not promoted to OPEN.** (a) The Solana fresh-LST cluster (Forward Industries, Phase, Definity, Japan Staked, Raiku) has no resolved program IDs and is described as standard SPL stake-pool style; there is no lead to chase until an adapter resolves a custom program. (b) Ref Finance / Burrow was not re-audited, but no new >$1M NEAR deployment or auth regression appeared. Both stay `RESEARCH-ONLY`; promote only on a concrete program/contract.

---

## 7. Re-check queue (prior-closed, funds still present — not OPEN)

These are **not** assignments. They are the large-fund prior closures whose re-arm condition is cheap to monitor. All are prior dossiers; re-open only on the stated trigger.

| Target | Funds | Prior verdict | Re-arm trigger |
|---|---:|---|---|
| Popdex Bridge | $74.94M | CLOSED E-U $0 | `updateVerifiers` callable without a valid signer; verifier-set/admin change; any new inbound path |
| STRATO Bridge | $1.144M | CLOSED E-U $0 | Safe module/guard added; `setGnosisSafe`/`setPermitted`; destination mint verifier change |
| Pacifica Bridge | $23.4M | CLOSED E-U $0 | withdraw-authority/signer change; program upgrade |
| JustLend sTRX | $3.135B | CLOSED E-U $0 | `NewPendingImplementation`/`NewAdmin`; exchange-rate deviation |
| Affluent / Factorial | $1.215M | PRIOR-PARTIAL (E-U-conditional $1.013M) | vault idle jetton re-funded; pool code-hash change |
| Hyperliquid Earn | $1.43B | Prior monitor (HyperCore-native) | first audit; reserve/oracle changes |
| UNCX | $1.16M nominal | PRIOR-PARTIAL | `FlatFeeUpdated` / fee exemption lowering the flat fee |
| Olas POL | $0 today | PRIOR-PARTIAL | first LM funding / `BuyBackBurner` inflow |
| Aragon-legacy | $534k conditional | PRIOR-PARTIAL | AMM listing for a funded DAO token; `CREATE_VOTES_ROLE` change |
| USDT0 OFT | $3.197B escrow | PRIOR-PARTIAL | `PeerSet` on dormant EIDs 30165/30214/30375/30243; `setConfig`/`setDelegate` |

---

## 8. Corrections to CA3 produced by this reconciliation

1. **§7 “unassessed” is stale for all four bridges.** Popdex, STRATO, Pacifica and JustLend sTRX have full prior dossiers and E-U $0 verdicts (§5). Their balances are still live, but the correct disposition is `PRIOR-COVERED`, not `OPEN`.
2. **Syntetika is Ember’s hBTC vault.** The live vault `0x9C2dCDbD…` reports `name = "Ember Hilbert BTC"`, `symbol = "hBTC"`, not “Syntetika”. DefiLlama’s `syntetika` listing is the curator; the contract is Ember’s. `bridgeAdapter()` is **0**, so `bridgeMint` is disabled today. CA3’s “CLOSED at `onlyBridgeAdapter`” is correct for a different reason than stated.
3. **Vesper’s $9.69M is a subset.** DefiLlama shows **$78.46M Ethereum + $6.56M Base + $2.34M OP** across **19 pools**; CA3 checked two yield vaults. This is the only material coverage gap found.
4. **Faiyah’s “LOW / OPEN” label is stale.** ZH4-05 closed it at **E-U $0 (high)**, with **H-O ≈$476,956.60** and S $13,638; the commingled-principal flaw is a first-mover/last-mover race, not extraction.
5. **BDEX V3 is closed, not “source not hash-matched”.** TIER3 L2-23 compiled the core and found it **byte-identical to Uniswap v3-core v1.0.0**; USDT mint is `MINTER_ROLE`; no arb between V2/V3.
6. **Gambit/ApolloX numbers differ between CA3 and CA2.** CA3 says max DEX profit ≈$0.01 (Gambit) and 98.8% broker liability (ApolloX); CA2-OPEN-2/6 said conditional $650.69–$16,273 (Gambit) and “123,423 USDT unaccounted, only Safe+timelock can sweep (P)” with a 16.8 h stale FDUSD feed (ApolloX). Neither is live E-U; the CA3 breakdown is more precise on ApolloX, the CA2 conditional is more precise on Gambit.
7. **wsNET and Startale moved.** wsNET free liquidity is **$396,780** at the CA3 read vs **$460,865** at pass7; Startale’s vault is **$1.124M** vs **$848k** at the pass7 read. Both are prior-live, both monitored; no re-audit.
8. **HAI’s treasury is $37.4k at the CA3 KITE price**, vs **$111,008.63** in the prior monitor. The KITE price collapse is the reason; `ca3-hai` owns the re-check.

---

## 9. Caveats and confidence

- **Confidence in the prior map: high** where a tracker line or dossier is cited; **medium** where the only evidence is a research-file auth probe (`eth_call`, no fork); **low** on the three OPEN plausibility ratings (no path shown).
- **Point-in-time.** Balances are pinned to the blocks in `analysis/live-checks.md`; the chains move. Re-read before acting.
- **Coverage limits.** No historical-state RPC; no fork for the research-only closures; Faroo impls unverified; Vesper fleet not enumerated; Aptos tooling not provisioned for Cellana; OPINION/Tenbin/Securitize addresses unpublished. “No OPEN above bar” is bounded by these.
- **No secrets.** No `.env`, no keyed URL, no key material in this folder. The CI repo is public; the validator includes a secret scan.
- **Read-only attestation.** Every check was `eth_call`, `balanceOf`, `eth_getStorageAt`, a public API GET, or a local static read. No transaction was signed or broadcast.

---

## 10. Evidence index

| File | Contents |
|---|---|
| `analysis/candidates.json` | 87-row register: source, disposition, grade, funds, addresses, prior evidence, next check |
| `analysis/candidates.py` | The register + disposition logic (reproducible) |
| `analysis/render.py` | JSON + markdown table generator |
| `analysis/tables.md` | The two disposition tables |
| `analysis/live-checks.md` | Every live read, block, address, revert selector |
| `ci/run.sh` | CI validator: counts, OPEN completeness, secret scan, 48-file/README cross-check |
| `ci-out/` | Validator output (artifact) |
| `ci-log.txt` / `ci-artifacts/` | GitHub Actions log + downloaded artifact |
| `summary.json` | Machine-readable counts + OPEN list |

**CI run:** `https://github.com/artsbykriss/ca-zombie-ci/actions/runs/42731864017`

**Prior dossiers cited:** `zombie-hunt-iv/wave2/v14-popdex.md`, `pass6/pacifica-bridge.md`, `wave1/r4-non-evm.md`, `wave2/v10-startale.md`, `pass7/wsnet.md` + `wsnet-verify.md`, `pass7/gov-params.md`, `ci/ZH2B6-RESULTS-TRACKER.md` (H2-05), `ci/ZH4-RESULTS-TRACKER.md` (ZH4-03/04/05/06/07), `ci/ZH4P7-RESULTS-TRACKER.md`, `ci/MONITOR-LIST.md`, `ci/CA2-RESULTS-TRACKER.md` (CA2-OPEN-1/2/4/6), `ci/CA3-V2-TRACKER.md`.
