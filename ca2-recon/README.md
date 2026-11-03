# CA2 residual reconciliation — every named candidate dispositioned, plus the OPEN list

**Date:** 2026-11-03 · **Source corpus:** `ca2/` (README 23.7 KB; `.work/` 52 agent reports, 9 synth groups, 10 promote, 5 promote2, 14 final) · **Prior corpus:** `ci/ZH4P7 → ZH2B*`, `ci/L2-*`, `ci/TIER3-LOW-TRACKER.md`, `ci/MONITOR-LIST.md`, `ci/MASTER-EXTRACTION-TABLE.md`, `ci/CROSS-CHAIN-FEASIBILITY.md`, `ci/CA2-RESULTS-TRACKER.md`, kept root folders, `zombie-hunt-iv/zh4-check.sh`, pass1–7 closed lists.
**Status:** read-only. No transactions broadcast, no keys used, no keyed URLs or `.env` contents copied. All live checks are `eth_call`/`cast call`/TronGrid constant calls at the blocks stated.

---

## 1. TL;DR

- **198 named candidates** were extracted and given exactly one disposition: **39 named in the CA2 README** (tables and prose) and **159 agent-only** (only in the 52 `.work/agents` reports, synth, promote or final files).
- **No new CRITICAL survives reconciliation.** CA2's three CRITICALs resolve as: **Affluent = prior measured $0.00** (the redeem leg CA2 did not measure), **Papertrade = escalation of our ZH3-C3 monitor** (handled), **wasmer GHSA = new advisory in the already-covered CWA-2026-006 compiler family, and an infrastructure RCE rather than a fund-drain primitive** (handled).
- **70 candidates are prior-covered/partial** (60 + 10), **101 are agent-only leads with a closing verdict**, **11 are not-a-protocol** (key compromise / supply chain / CEX), **7 are README-named but not prior-covered** (BTCPay, Fearless, b14g, Vara, Hifi, Few-and-Far, Coffer — all handled by CA2 wave folders).
- **9 OPEN rows = 7 distinct targets.** None has a demonstrated unprivileged path; they are open because (a) the code is unverified and (b) in one case a prior closure rests on a balance statement that is now false. Ranked by funds × plausibility in §4.
- **The residual money is not in CA2's headline list.** It is in unverified Tron/Pharos/Stellar contracts and one BSC GMX-fork accounting defect.

### Disposition counts

| Disposition | Rows | Meaning |
|---|---:|---|
| README-CRITICAL | 0 | no README critical survives as a live, non-prior finding |
| README-HIGH | 2 | BTCPay, Fearless (new, handled; no on-chain value proof) |
| README-LOW | 5 | b14g, Vara, Hifi, Few-and-Far, Coffer (new, handled; sub-bar) |
| README-REJECTED | 0 | README rejects are either prior-covered or not-a-protocol |
| AGENT-ONLY-LEAD | 101 | named only in agent reports; closed/low/unverified |
| PRIOR-COVERED | 60 | a dispositive prior verdict exists |
| PRIOR-PARTIAL | 10 | same protocol/class, different instance or angle |
| NOT-A-PROTOCOL | 11 | key compromise, supply chain, CEX, or no deployed protocol |
| **OPEN** | **9** | **funded + plausible-but-unproven path + no dispositive verdict** |
| **Total** | **198** | |

---

## 2. Method and disposition rules

1. **Extraction.** Every table row, every named contract in prose, and every "watch"/"coverage-gap" item in the 52 `ca2/.work/agents/*.md` reports was captured; the 9 synth groups, 10 `promote/`, 5 `promote2/` and 14 `final/` reports were skimmed for named candidates and corrections. Case-level and class-level items (e.g. "Compound-V2 donation surface") are kept as one row each and marked as such.
2. **Prior test.** A candidate is `PRIOR-COVERED` when a tracker or kept folder records a dispositive verdict for that protocol/instance; `PRIOR-PARTIAL` when the prior verdict is for the same protocol but a different chain, contract or bug angle. Mere keyword presence in the corpus is not enough — the verdict must be identifiable.
3. **Not-a-protocol.** Key-compromise incidents, frontend/RUM supply chain, CEX, and chain-node bugs with no deployed contract target are separated so they are not counted as closed contract findings.
4. **OPEN test.** Funded (>$10k), a plausible unprivileged vector that has *not* been falsified, and no dispositive verdict in either corpus. "Unverified code" alone qualifies only where value is material and the prior closure is absent or contradicted. OPEN means **unproven**, not extractable.
5. **Read-only / value discipline.** USD figures are the reporting source's, not re-priced, except where a live read is stated. TVL is not extractable value; the OPEN ranking uses measured liquid balances where available.

---

## 3. The three CA2 CRITICALs, reconciled

### 3.1 Affluent (TON) — CA2 CRITICAL → prior **$0.00 measured**
CA2 proved the mint primitive with TVM emulation (fresh sender, arbitrary amount, arbitrary beneficiary) and cited `$13,504.32` realised on 2026-10-16. It explicitly did **not** measure the redeem leg. Our prior reinvestigation did: `affUSDTl` vault balance = **1 raw**, a burn emits **no USDT**, and the `$1.34M` is DefiLlama TVL/custody (tsTON/XAUt0/tsUSDe) with no matching share vault. `MASTER-EXTRACTION-TABLE` row 32 records **max extractable ≈ $0.00 (measured)**. The primitive is real and unpatched; the money is not there. **PRIOR-COVERED; handled by `affluent-recheck/`.**

### 3.2 Papertrade (HyperEVM) — CA2 CRITICAL → **PRIOR-PARTIAL (monitor, escalation)**
Papertrade is our **ZH3-C3** finding, kept as a monitor in `papertrade/` after the 2026-10-10 $1.28M drain. CA2's contribution is the "no deviation breaker is possible" byte-scan and the open-relayer evidence; its `$4,912,307.74` `lpBankrollAvailable()` and `$25.5–30.4M` treasury are consistent with our monitor. The unresolved item is the same one we already track: the Exchange implementation is unverified and the off-chain relayer policy is unpublished. **Not a new finding; handled by `ca2-papertrade`.**

### 3.3 wasmer GHSA-v2h8-j899-r676 — CA2 CRITICAL → **PRIOR-PARTIAL / infrastructure, not fund-drain**
The advisory is new (published 2026-11-02, CVSS 10.0, no patched release), and CA2 correctly maps Juno `v31.0.0 → wasmvm v3.0.8 → wasmer 7.4.2` with open upload/instantiate. But (i) it is the same Singlepass/CosmWasm compiler family we already covered as **CWA-2026-006** (`ZH2B3 C2-26`, `MASTER` 33/35/36, `CROSS-CHAIN-FEASIBILITY`), (ii) CA2 itself rates the impact as **validator/sentry RCE, not a direct fund-theft primitive**, and (iii) its own files contradict each other on whether wasmer 7.5.0 is fixed. **PRIOR-PARTIAL; handled by `wasmer-ghsa/`.**

---

## 4. OPEN list (ranked by funds × plausibility)

**Scoring:** funds 1–5 (5 = >$100M measured/credible, 4 = $10–100M, 3 = $1–10M, 2 = $100k–1M, 1 = <$100k); plausibility 1–5 (5 = proven unprivileged code path, 3 = real defect with an economic/venue blocker, 1 = unverified code with no identified vector). Score = product. **All are unproven; none is claimed as extractable.**

| Rank | Target | Chain | Address(es) | Funds (basis) | Plaus. | Score | Why OPEN (what is not closed) | Next check |
|---:|---|---|---|---|---:|---:|---|---|
| 1 | **R25 WrappedVault family** | Pharos (1672) | `vRPCQuarterlyVault 0x94f7ebc6ae0819a4b4e231ae6ddaaf9bfd2a1a86`; `vRPCWeeklyVault 0x1c2bc8b553d9a7e61f7531a3a4bf2162f4569268`; `vRPCSemiYearlyVault 0xee26bb0989691735c997dfdc49a4a607f75e190b`; `apcVault 0xd0428799fbc35557834d33121ba4472692c8908a`; `hybVault 0x6Ce4bc043398Ac40392d1E063328048072b2075d` | **$169,413,236.76 measured** (block 22,016,133: 84,364,217.74 + 2,085,032.21 + 10,019,986.32 + 72,845,136.26 + 98,864.23) | 2 | **10** | Prior pass2 `LANE-CLOSED` says **"Manager-set NAV; 0 USDC held; role-gated updates"**. The live read contradicts the balance premise: the five vaults hold **$169.4M** of `0xC879…1815`. Impl `0xe5d7e7e079eca99ebe5295e24a3908374e8aed42` is **unverified**; `maxWithdraw()` reverts `NotSupported`, so this is a non-standard async/queued vault. No path has been shown either way. | Decompile/verify `0xe5d7…` and `0x6360…`/`0x880a…`; enumerate deposit/redeem/request/claim functions and their auth; check whether NAV is oracle- or manager-set and whether a public `requestRedeem` + `claim` is gated; read admin `0xd83c0a13…` (contract, 1,018 B) type. |
| 2 | **Gambit Vault USDG redemption** | BSC (56) | Vault `0xc73A8DcAc88498FD4b4B1b2AaA37b0a2614Ff67B`; USDG `0x85E76cbf…5a7` (truncated in CA2) | Vault ~$228k; **$99k liquid** (75,188.02 USDT + 34.78 WBNB at block 131,441,271); **$75.4k at-face capacity** | 3 | **6** | The accounting defect is real, verified source (Sourcify exact match), and unprivileged: `getRedemptionAmount(USDT,1000e18) = 1000e18` while the vault backs USDG at ~$0.784. It is not closed by code or pause; it is closed only **economically** — no USDG DEX pair exists, and minting costs face. An OTC buyer below $0.784 can still redeem. | Enumerate USDG holders/approvals and any OTC/CEX venue; re-check DexScreener/BSC factory pairs; monitor `Transfer` of USDG. If any venue appears, fork-test mint→redeem. |
| 3 | **SunSwap V4 PoolManager** | Tron | `TVjuTE3V5bMVdpfNhid8kD2v35T2k1u1Br` (note: the CA2 table has a typo variant `…pfNhid8…`) | **$134.70M TVL** (CA2/DefiLlama; not re-priced here) | 1 | **5** | 57,582-byte deployed singleton named `PoolManager`, origin EOA `TU3rMHyWHzeEJBReWLzHko728hbz6MtfNg`, `verify_status: null` (source **not published**), no auditReportUrl. V4-style singleton with hook support and all V4 liquidity. No vector identified; no verdict anywhere. | Obtain/decompile the 57,582-byte runtime; check hook-callback authorization and `unlock`/`lock` payer accounting; enumerate pools and whether any hook is attacker-registerable. |
| 4 | **Stellar DeFi Hub — "Evergreen" share vault** | Stellar | `CALFCZ4TY2CLHDHNJWCZX6JKYGUPV7P3GNQ3UVABXNE5JCV2E774APUM` (wasm `3bd05dfa…`, created 2026-10-02) | Protocol **$113.84M**; Evergreen share of that not isolated | 1 | **5** | The XLM/USDC vaults are verified and read clean against `Into-The-Block-Corp/StellarVaults@c29a8bf`; the **Evergreen** vault is unverified and not hash-matched to the repo. No path shown; no prior verdict. | Fetch the contract spec/ledger entries; confirm `require_auth` on deposit/withdraw/share-mint; diff wasm against the repo build. |
| 5 | **Tron trio: CherryPool / PokerGame / FireFullContract** | Tron | `TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR`; `TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn`; `TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW` | **3,378,815.83 TRX ≈ $1.08M** at $0.3189 (block 87,679,689) | 2 | **4** | Unverified (v0) contracts holding 916,374 / 1,040,717 / 1,421,725 TRX. `withdrawTronAll()` (11,011 energy, returns 0), `withdraw()` (604 energy, empty), `withdraw()` (7,345 energy, empty) all **execute** for an arbitrary caller — but each returns zero/empty, consistent with per-user accounting, not a shared pot. No source, no decompile, no proof either way. | Decompile the three runtime bytecodes; identify the balance mapping and whether any path pays `msg.sender` from contract balance; check owner/`selfdestruct`/`delegatecall` surfaces; simulate with a funded fake account on a Tron fork. |
| 6 | **ApolloX EIP-2535 diamond** | BSC | `0x1b6F2d3844C6ae7D56ceb3C3643b9060ba28FEb0` | **123,423 USDT + 0.53 BNB** in the diamond; $70.5M protocol-reported elsewhere | 1 | **2** | CA2 explicitly left it "unreviewed — 29 facets". The $70.5M is in treasury/staking/bridge contracts, not the perp engine; only ~$123k is at the diamond. No verdict. | Enumerate the 29 facets and their selectors; check `onlyOrderBook`/`onlyBroker` coverage and oracle validation; confirm the 123k USDT is protocol-owned vs user-withdrawable. |
| 7 | **Wanchain Cardano↔BNB bridge** | Cardano | check script `8c027908260ebc29410ce4fffe788da510e4d7fd67f4b39d3c77db5e`; treasury `1cfb41dc…5234` (truncated) | **218,156 ADA + tokens** in treasury; last tx 2026-10-10 | 1 | **1** | The vulnerable V2 script is unused since the exploit; the **replacement** script is unverified, and CA2 could not decode its authorization logic. No path shown; no prior verdict. | Locate the full treasury/script addresses in the Wanchain post-mortem; fetch the Plutus script and datum; check whether the signed-message encoding is injective and whether the treasury UTxO is spendable by a forged message. |

**Live re-check (2026-11-03, blocks: Pharos 22,016,133 · BSC 131,441,271 · Tron 87,679,689 · Monad 119,053,973):** R25 totalAssets **$169,413,236.76**; Gambit **75,188.02 USDT + 34.78 WBNB**, `getRedemptionAmount(USDT,1000e18)=1000e18`; Tron trio **916,374.11 / 1,040,716.80 / 1,421,724.92 TRX**, constant calls return `0x0`/empty at 11,011/604/7,345 energy; ApolloX **0.5349 BNB** (6,039-byte diamond proxy). Raw output: `analysis/live-checks.json`; re-run in CI to `ci-out/live-checks.json`.

**Open-list total measured/credible funds:** ≈ **$169.41M (R25) + $134.70M (SunSwap TVL) + $113.84M (Stellar TVL) + $1.08M (Tron) + $0.10M (Gambit liquid) + $0.12M (ApolloX) + ~$0.1M (Wanchain, unpriced ADA)**. These are **not** extractable values and must not be added into an E-U headline; they are the size of the unassessed surface.

---

## 5. Full disposition table

### 5.1 OPEN (9 rows)

| # | Candidate | Chain | Funds / at-risk (as reported) | CA2 rating | Disposition | Conf. | Basis |
|---|---|---|---|---|---|---|---|
| 58 | Wanchain Cardano<->BNB bridge non-injective message encoding | Cardano | 218,156 ADA treasury + tokens; script 8c027908260ebc29410ce4fffe788da510e4d7fd67f4b39d3c77db5e; treasury 1cfb41dc...5234; replacement logic unverified | LOW | **OPEN** | low | Only unresolved Cardano lead; see OPEN |
| 75 | Stellar DeFi Hub vaults incl. Evergreen share vault | Stellar | $113.84M protocol TVL; Evergreen CALFCZ4TY2CLHDHNJWCZX6JKYGUPV7P3GNQ3UVABXNE5JCV2E774APUM unverified | LOW | **OPEN** | low | Verified XLM/USDC vaults clean; Evergreen (created 2026-10-02) unassessed; see OPEN |
| 76 | SunSwap V4 PoolManager singleton | Tron | $134.70M TVL; PoolManager TVjuTE3V5bMVdpfNhid8kD2v35T2k1u1Br (57,582 B, unverified) | LOW | **OPEN** | low | Source unpublished; hooks supported; no identified vector; see OPEN |
| 80 | Gambit Vault USDG redemption accounting | BSC | Vault 0xc73A8DcA...Ff67B ~$228k; $99k liquid; $75.4k at-face capacity | LOW | **OPEN** | medium | Real unprivileged defect; only blocker is acquiring USDG (no DEX pair); see OPEN |
| 82 | ApolloX EIP-2535 diamond | BSC | Diamond 0x1b6F2d38...FEb0: 123,423 USDT + 0.53 BNB; $70.5M protocol-reported | LOW | **OPEN** | low | 29 facets unreviewed; see OPEN |
| 114 | CherryPool withdrawTronAll() | Tron | TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR: 916,374.11 TRX (~$292k) | LOW | **OPEN** | low | Unverified; arbitrary-caller call executes but pays 0; see OPEN |
| 115 | PokerGame withdraw() | Tron | TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn: 1,040,716.80 TRX (~$332k) | LOW | **OPEN** | low | 604-energy early return for non-user; see OPEN |
| 116 | FireFullContract withdraw()/activateSuperPlayer() | Tron | TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW: 1,421,724.92 TRX (~$453k) | LOW | **OPEN** | low | 7,345-energy call executes; no value for caller; see OPEN |
| 139 | R25 WrappedVault family | Pharos | $169.4M measured across 5 vaults: 0x94f7.../0x1c2b.../0xee26.../0xd042.../0x6Ce4... (2026-11-03) | LOW | **OPEN** | low | Prior LANE-CLOSED said 0 USDC - contradicted; unverified async vault; see OPEN |

### 5.2 README-named candidates (39 rows)

| # | Candidate | Chain | Funds / at-risk (as reported) | CA2 rating | Disposition | Conf. | Basis |
|---|---|---|---|---|---|---|---|
| 1 | Affluent (ex-Factorial) forged transfer_notification -> unbacked mint | TON | $1.34M TVL (claim); $13,504 realized; our measured redeemable $0.00 | CRITICAL | **PRIOR-COVERED** | high | MASTER #32 DEAD $0 (redeem leg measured); ci/CA2-RESULTS-TRACKER; affluent-recheck |
| 2 | Papertrade midpoint-oracle manipulation / open relayer | HyperEVM 999 | $4,912,307.74 free LP (CA2); $25.5-30.4M TVL | CRITICAL | **PRIOR-PARTIAL** | medium | ZH3-C3 real finding; monitor papertrade/; escalation being verified (ca2-papertrade) |
| 3 | wasmer-compiler-singlepass implicit-else escape GHSA-v2h8-j899-r676 (wasmer 7.4.2) | Cosmos / Juno+ | Juno contract-held 14,417,519.86 JUNO ~ $87,270 | CRITICAL | **PRIOR-PARTIAL** | medium | New advisory but same CWA-2026-006 class covered by ZH2B3 C2-26 / MASTER 33/35/36 / CROSS-CHAIN; handler ca2-wasmer |
| 4 | CWA-2026-006 CosmWasm Singlepass sandbox escape (wasmvm 1.x-3.x, 19 chains) | Cosmos (Archway, Shido, Desmos, Neutaro, Uptick +14) | Archway ~$146.1k contract-held / ~$116k exit; Shido ~$284k not wasm-reachable | HIGH | **PRIOR-COVERED** | high | CROSS-CHAIN-FEASIBILITY (11 chains); weaponisation M1-M4 blocked; MASTER 33/35/36 |
| 5 | Premia V3 PoolInternal._withdraw inflated claimableFees | Arbitrum | $64,346 across 1,518 pools; largest $5,135; vaults ~$2,460 | HIGH | **PRIOR-PARTIAL** | high | pass3 tail; complete 56,674-pool sweep in promote2; handler ca2-premia |
| 6 | BTCPay Server <=2.4.1 LND macaroon exposure | Bitcoin / Lightning (self-hosted) | Unquantified merchant hot wallets (LND-only) | HIGH | **README-HIGH** | low | New; handled by ca2-supplychain; no on-chain artifact |
| 7 | Fearless Wallet extension 3.0.3-3.0.5 seed exfiltration | Polkadot / Chrome | ~$15.4k reported (8 accounts) | HIGH | **README-HIGH** | medium | New; handled by ca2-supplychain; tonscanner.org dead; v4.2.4 clean |
| 8 | Initia mainnet script_enabled / private initiad v1.4.11 | Initia (interwoven-1) | $7.42M DeFi TVL | HIGH | **PRIOR-PARTIAL** | low | pass7 real-time halt; initia-crosscheck; handler ca2-initia |
| 9 | UNCX Vesting V2 VestingManager share double-debit | ETH/BSC/ARB/POLY/Base/Unichain | Nominal ~$652k; realizable <$30k; realized $86k (2026-10-14) | latent HIGH | **PRIOR-COVERED** | high | ZH3-C1 / ZH4 corr.1 / ZH4-P2 corr; monitor flatFee=max; ETH pool ~$41 |
| 10 | Zodiac Roles v2.1.0 / Delay v1.1.0 ERC-1271 revert-data bypass | Ethereum + Polygon | Vendor ~$200k attributable; ~$2.46M reachable-but-blocked | latent HIGH | **PRIOR-PARTIAL** | high | Prior lead-list only; handler ca2-tac-zodiac; 1,071 tests / 0 permissive |
| 11 | Secured Finance TokenVault in-block price-ratio collateral inflation | Ethereum | ~$82.6k (CA2 latent); pass6 closed $0 | latent HIGH | **PRIOR-PARTIAL** | medium | pass6 README-CLOSED (patched/refuted); handler ca2-startale-secured |
| 12 | Startale ERC-7579 re-callable initializeAccount via EIP-1153 | Ethereum | $2,876 historical; bounded to pending pre-funding | latent HIGH | **PRIOR-PARTIAL** | high | Prior partial (startale-earn is a different contract); handler ca2-startale-secured |
| 13 | TAC JettonProxy unauthenticated transfer_notification relay | TON | ~$553k USDT + $69k BLUM + $3.9k tsTON in proxy | latent HIGH | **PRIOR-COVERED** | high | EVM mint gated by sequencer-quorum Merkle root; fix sequencer-side; handler ca2-tac-zodiac |
| 14 | zkLink Nova Arbitrator message spoofing | Ethereum | ~$1,400 (ZkLink paused) | LOW | **PRIOR-COVERED** | high | ZH4-P2 / ZH2B3; handler ca2-low-c |
| 15 | b14g Merge Marketplace batch withdraw | CORE | $0 (Marketplace/CoreVault/FairShare paused) | LOW | **README-LOW** | high | Handled ca2-low-a; root cause proven; all avenues closed |
| 16 | Vara Bridge proof verifier forged Merkle root | Ethereum | ~$12.05 (<=$166 best case) | LOW | **README-LOW** | high | Handled ca2-low-a; soft pause lapsed 2026-11-02 but value sub-threshold |
| 17 | Hifi Finance permissionless harvestIdle + hijacked Governor | Ethereum | $0 (BalanceSheet empty; sweep goes to attacker Safe) | LOW | **README-LOW** | high | Handled ca2-low-a; latent only |
| 18 | Notional V1 fCash unbacked mint | Ethereum | $0 at head; $1,658,524.86 at pre-patch control | REJECTED | **PRIOR-COVERED** | high | Escrow re-pointed to EmptyProxy; fork test 0 at head |
| 19 | ether.fi Liquid / Veda AtomicQueue unauthenticated solve() | ETH + Arbitrum | $0 realizable; nominal $1,376 | LOW | **PRIOR-COVERED** | high | pass7 caller-target (denylisted); promote2 enumeration 849 acceptors, $0 |
| 20 | BlueMove DEX cross-version reserve_x desync | Sui | $0.19 (9.353 CETUS) | LOW | **PRIOR-COVERED** | high | L2-PHASE1 #36 E-U $0.05; promote/bluemove-fnf |
| 21 | Few-and-Far nft_resolve_transfer unguarded refund callback | NEAR | $0 (free-mint POAPs, listings disabled) | LOW | **README-LOW** | high | Handled ca2-low-b; guard absent, no value |
| 22 | SatoHook v4 hook identity/cooldown defects | Ethereum | 1,013.55 ETH balance but only ~446 ETH curve-redeemable (fair value) | LOW | **PRIOR-COVERED** | high | pass2 PRIOR-COVERED; ZH4 monitor; g4 falsified drain |
| 23 | Unnamed BSC DEX router 0xa331fde0 unauthenticated V3 callback | BSC | $177-203 verified; approvals unenumerated | LOW | **PRIOR-PARTIAL** | high | pass7 re-probe: impl upgraded 0xc700cf8d; monitor |
| 24 | Aperture Finance instant-liquidity router payer confusion | ETH/ARB/OP/POLY | ~$0 (swept) | LOW | **PRIOR-PARTIAL** | high | Prior corpus; handler ca2-low-c; path proven, no value |
| 25 | Yapeswap WorkersUnion zero-quorum governor | Ethereum | ~$119 (mechanism HIGH) | LOW | **PRIOR-COVERED** | high | pass7 real-time; ZH4P7 monitor; factory attacker-owned |
| 26 | Coffer Solana rounding (M-08) | Solana | <$1 | LOW | **README-LOW** | high | Handled ca2-low-c; fix deployed 2026-10-19 |
| 27 | AlpsCon share accounting | BSC | ~$9.35k total; hubs closed; no DEX pair | LOW | **PRIOR-COVERED** | high | pass5/pass7; V6-V9 whitelist closed; monitor |
| 28 | Solana new programs >$10M upgraded <=60d | Solana | Onre disabled; Upshift/Kamino clean | LOW | **PRIOR-COVERED** | high | final/solana-new-programs; pass5/pass6 closed |
| 29 | New-chain deployments (Monad/Plasma/Ink/Pharos/Robinhood) | multi | Aave-fork inflation precondition unmet; Tempo node code | LOW | **PRIOR-COVERED** | medium | pass2 Tempo OPEN; R25 lane-closed (balance contradicted, see OPEN) |
| 30 | Mercado Bitcoin ~$40M multi-chain event | BTC/ETH/SOL/XLM/TRON | 106.07 BTC + 50.68 ETH + 6.71M XLM residual at exchange wallets | REJECTED | **NOT-A-PROTOCOL** | high | AuditKey: signed by source wallets; key/signing compromise, not contract bug |
| 31 | Troves (ex-STRKFarm) retired rebalancer | Starknet | ~$0 reachable; ~$4.43M TVL not reachable | REJECTED | **PRIOR-COVERED** | high | L2/prior; relayer roles revoked, vaults paused |
| 32 | WAX Multi-Chain Bridge eth.token negative fee | WAX | ~$42k residual on Ethereum release proxy | REJECTED | **PRIOR-COVERED** | high | Patched 2026-10-22; bridge.wax hardened; handler prior |
| 33 | Polymarket International frontend/RUM supply chain | Polygon | ~$2.7M historical | REJECTED | **NOT-A-PROTOCOL** | high | Third-party frontend/RUM; deposit-wallet contracts clean |
| 34 | Predict Fun owner-key drain | BSC | ~$398k historical | REJECTED | **NOT-A-PROTOCOL** | high | Bitquery: 33 drains signed by owners' own keys; no contract called |
| 35 | Zilliqa X-Bridge 1-of-1 validator | ZIL/ETH/BSC | ~$8-9k in lock contracts | REJECTED | **NOT-A-PROTOCOL** | high | Single EOA validator; key compromise; no unprivileged verification flaw |
| 36 | Swell swETH/rswETH unbacked NAV | Ethereum | ~2,500 ETH staged; paused | LOW | **NOT-A-PROTOCOL** | high | Key/oracle compromise; deposits/withdrawals paused |
| 37 | CoinDCX / Qubic / Binance / other key-compromise incidents | multi | n/a | REJECTED | **NOT-A-PROTOCOL** | high | Not external unprivileged contract bugs |
| 38 | EtherVista pair uint112 overflow / routerSetter | Ethereum | Latent $69k target / $317k fleet; $0 E-U today | rejected | **PRIOR-COVERED** | high | ZH3-C5 / ZH4 corr.3; monitor routerSetter |
| 39 | Limit Break Payment Processor V2 ERC-2771 taker spoof | Ethereum (+ApeChain V3) | WETH leg ~0; NFT leg ~0 across 3 collections | HIGH->LOW | **PRIOR-COVERED** | high | c-01 EXCLUDED (active crime, not extraction); g5 demoted |

### 5.3 Agent-only candidates (145 rows)

| # | Candidate | Chain | Funds / at-risk (as reported) | CA2 rating | Disposition | Conf. | Basis |
|---|---|---|---|---|---|---|---|
| 40 | RNT Lend (Reental) RWA collateral at 75% LTV, issuer oracle | Polygon | ~$242k idle stables; $21.3M TVL | LOW | **PRIOR-COVERED** | high | ZH4P7 closed; pass6 excluded repeat (RNTLend) |
| 41 | Keom / Tender unseeded cToken markets | Polygon / Arbitrum | ~$0 (all cash=0) | LOW | **AGENT-ONLY-LEAD** | high | No value; donation precondition present but empty |
| 42 | Systemic Compound-V2-fork donation surface (21 comptrollers) | many | Not demonstrable | LOW | **AGENT-ONLY-LEAD** | medium | No zero-supply market with non-zero cash |
| 43 | Aave V3 fork oracle misconfiguration class (25 pools) | many | $0 repeat of 2026-02-26 class | LOW | **AGENT-ONLY-LEAD** | high | All 25 pools within +/-2.5% of reference |
| 44 | Hegic HegicPool repeatable withdrawal (5 instances) | Ethereum | <=1.84 DAI across all five | LOW | **AGENT-ONLY-LEAD** | high | Bug present, no funded instance |
| 45 | Hegic HegicStakeAndCover | Arbitrum | 1,040,692 USDC.e | REJECTED | **AGENT-ONLY-LEAD** | high | withdrawalsEnabled=false; admin-only |
| 46 | Hegic HegicOperationalTreasury | Arbitrum | 314,487 USDC.e | REJECTED | **AGENT-ONLY-LEAD** | high | withdraw() DEFAULT_ADMIN_ROLE |
| 47 | Hegic V8888 HegicStaking | Ethereum | ~$370k HEGIC+stables | rejected | **AGENT-ONLY-LEAD** | medium | No unprivileged drain found |
| 48 | Venus Core Pool supply-cap bypass / donation | BSC | Unquantified; risky-market CF zeroed | LOW | **PRIOR-PARTIAL** | low | Deployed facet unverified; prior Venus Flux/contest coverage |
| 49 | Neverland dLEND empty-reserve index inflation | Monad | $6.11M supplied / $10.94M borrowed | LOW | **PRIOR-COVERED** | high | ZH4 monitor; live check 2026-11-03: no near-zero aToken supply with cash |
| 50 | dTRINITY dLEND exchangeCollateral build drift | Sonic | $185k supplied | LOW | **AGENT-ONLY-LEAD** | high | Role-gated exchangeCollateral* |
| 51 | Berafarm tranche vaults / RewardVault delegateStake | Berachain | 754,297 HONEY + 1,609 WBERA | LOW | **PRIOR-COVERED** | high | ZH4-06 E-U $0; patch complete |
| 53 | Verus <-> Ethereum bridge submitImports missing value binding | Ethereum | ~$1.0k reserves | LOW | **AGENT-ONLY-LEAD** | high | Live unfixed; re-fund monitor (drained twice) |
| 54 | Symbiosis BTC BridgeV2 message-verification bypass | BNB / Ethereum | Portals ~$1.79M; BTC route halted | LOW | **AGENT-ONLY-LEAD** | medium | No live vulnerable path; defect unpublished |
| 55 | Meter Passport wMTRG unbacked mint | BNB | ~$3 exit liquidity | LOW | **AGENT-ONLY-LEAD** | high | Patch unknown, no liquidity |
| 56 | Dano Finance missing debt guard on collateral withdraw | Cardano | 117,012 USDCx + 117,201 NIGHT in pool; 0 position UTXOs | LOW | **AGENT-ONLY-LEAD** | high | Protocol paused; operational not code fix; re-arm if leverage resumes |
| 57 | AnetaBTC cBTC unauthorised mint | Cardano | ~$0.40 (Minswap pool 2.02 ADA) | LOW | **AGENT-ONLY-LEAD** | high | Immutable bug, no exit liquidity |
| 59 | CWA-2026-002 (wasmd 0.61.0-0.61.8) | CosmWasm (Neutron, Lumera, Warden, Akash, Kiichain) | Unquantified | LOW | **AGENT-ONLY-LEAD** | low | IBCv2 precondition unverified |
| 60 | CWA-2025-006 (wasmd <=0.54.x) | CosmWasm (Union, Amitis, Axone, Bitcanna, blg24) | Unquantified | LOW | **AGENT-ONLY-LEAD** | low | Version-scoped; no technique |
| 61 | Starknet BTC Staking 'Ghost Staking' (rdin777 claim) | Starknet | ~$50.7M TVL claim | REJECTED | **AGENT-ONLY-LEAD** | high | Claim falsified with code + on-chain reads |
| 62 | zkLend market | Starknet | $0 (all bad debt) | REJECTED | **PRIOR-COVERED** | high | DefiLlama TVL 0; C2-51 prior |
| 63 | mySwap CL share accounting | Starknet | $5,738 | REJECTED | **AGENT-ONLY-LEAD** | high | Below bar; no path |
| 64 | 'everything' UniPoolRouter sweep(recipient,token,...) | ETH/ARB | $0 (native 0; spam token) | LOW | **AGENT-ONLY-LEAD** | high | Permissionless by design; transient balances |
| 65 | UniV3/Pancake V3/Algebra NonfungiblePositionManager sweepToken | multi | $0 dust | LOW | **AGENT-ONLY-LEAD** | high | Canonical design; recovers mis-sent tokens |
| 66 | The DAO framework clone 0xd838...45aa | Ethereum | 19.097 ETH (~$44k) + 5.759 ETH extraBalance | LOW | **AGENT-ONLY-LEAD** | high | Token-gated/refund balances; no E-U path; reports disagree on refund() |
| 67 | PulseX StableSwap 3pool | PulseChain | $500.6k nominal TVL | LOW | **PRIOR-COVERED** | high | C-39 E-U ~$0.023; 254,985 pairs scanned |
| 68 | PancakeSwap StableSwap (31 BSC + 5 ARB + 2 ETH pools) | BSC/ARB/ETH | n/a | LOW | **AGENT-ONLY-LEAD** | high | No native-coin or hook token; all nonReentrant |
| 69 | Ellipsis 3EPS | BSC | n/a | LOW | **AGENT-ONLY-LEAD** | high | Vyper 0.2.11 nonreentrant; no callback primitive |
| 70 | FWA v2 NFT/ETH pool floor-oracle | Ethereum | 289.01-422.43 ETH (~$651.6k-$1.42M) | LOW | **PRIOR-COVERED** | high | ZH4 monitor FWA V2; floor ask manipulation currently profitless |
| 71 | communityv3 | Ethereum | $12.7M | rejected | **AGENT-ONLY-LEAD** | high | Stock Uniswap V3; factory owner burned |
| 72 | Derive v3 SpotVault / WithdrawalOutbox | Ethereum | $177.9M | rejected | **PRIOR-COVERED** | high | ZH4P7; onlyOwner escrow; VERIFIABLE_APP-gated |
| 73 | HoodLock RobinhoodLocker / HoodLockLPLocker | Robinhood Chain | $1.7M | rejected | **AGENT-ONLY-LEAD** | high | Reviewed; onlyLockOwner + nonReentrant; audit mitigations |
| 74 | Prop-AMM cluster (BisonFi, GoonFi V1/V2, AlphaQ, Tessera V, Scorch) | Solana | $40.7M combined | LOW | **PRIOR-COVERED** | high | pass6 excluded repeats; Z3-H17 $0; Onre/PDA closed |
| 77 | Unverified custom swap router 0xc87c...b9da | Ethereum | $0 (all approvers revoked/empty) | LOW | **AGENT-ONLY-LEAD** | high | Payer confusion real; immutable; swept |
| 78 | SwapNet (Matcha Meta) aggregator | Base | ~$13.4M historical | rejected | **AGENT-ONLY-LEAD** | high | Proxy impl pointer zeroed; calls are no-ops |
| 79 | Sodium ERC-4337 account implementation | Arbitrum | ~$0.30-$1 across ~8,800 accounts | LOW | **PRIOR-COVERED** | high | P5-01 monitor; instant re-arm |
| 81 | Gambit liquidatePosition fixed $5 fee | BSC | <=$5 per liquidatable position | LOW | **AGENT-ONLY-LEAD** | high | Self-liquidation break-even |
| 83 | MUX OrderBook/Trade | Arbitrum | $8.46M | rejected | **AGENT-ONLY-LEAD** | high | onlyBroker/onlyOrderBook + reference-oracle checks |
| 84 | Small/dead GMX V1 forks (BMX, HMX, Vela, Morphex, MUFEX, SakePerp...) | multi | <$111k each | rejected | **AGENT-ONLY-LEAD** | high | No reachable value >$10k |
| 85 | Limit Break Payment Processor V3 | ApeChain | Not measured | LOW | **AGENT-ONLY-LEAD** | low | No ApeChain indexer reachable |
| 86 | DoinGud Diamond bid replay | Polygon | $0 (drained $35,486) | REJECTED | **AGENT-ONLY-LEAD** | high | Dormant; historical |
| 87 | Fence/Valinor TranchePool draw double-draw | Avalanche | $0 (drained $1.013M) | REJECTED | **AGENT-ONLY-LEAD** | high | Immutable bytecode but unfunded; same as Oatfi |
| 88 | Oatfi TranchePool | Avalanche | $0 drained 2026-10-28 | REJECTED | **AGENT-ONLY-LEAD** | high | Historical |
| 89 | Thetanuts legacy option vaults (143 deployments) | Ethereum | $0 | REJECTED | **AGENT-ONLY-LEAD** | high | Zero-supply sweep; all empty |
| 90 | Aurellion Diamond dead owner / outstanding allowances | Arbitrum | $0 (all approvers 0 USDC) | LOW | **AGENT-ONLY-LEAD** | high | Owner codeless; initialize locked |
| 91 | Slice FundsModule permissionless release | Base | $0 (patched) | LOW | **PRIOR-COVERED** | high | pass6 closed; selector gone |
| 92 | TheRedVillage PolygonTRVRouter upgrade relay | Polygon | $0 | rejected | **AGENT-ONLY-LEAD** | high | Upgrade role false; WETH balance 0 |
| 93 | Renegade / Kinto proxies | Arbitrum | ~0.0024 ETH dust | rejected | **AGENT-ONLY-LEAD** | high | Initialize reverts; empty |
| 94 | Enjin reserve registries | Ethereum | 3,272,608 ENJ locked | rejected | **AGENT-ONLY-LEAD** | high | initialize now reverts 'locked'; manager unrecovered but no new-caller path |
| 95 | OrderFactory / Account System | Ethereum | $0 | rejected | **AGENT-ONLY-LEAD** | high | accountBalances=0 for all victims |
| 96 | BiFi UsdtHandlerProxy | Ethereum | Untracked (RPC timeout) | rejected | **PRIOR-COVERED** | medium | bifi folder / ZH4-P3 monitor; ETH patched |
| 97 | FlashLoopAdapter Safe module | Ethereum | n/a | rejected | **AGENT-ONLY-LEAD** | high | Out of scope (module confused deputy) |
| 98 | Coinbase Smart Wallet impl proxies | Ethereum | $0 (false positives) | rejected | **AGENT-ONLY-LEAD** | high | ownerCount=2; namespaced storage |
| 99 | EVAA Protocol | TON | $7.8M TVL | LOW | **AGENT-ONLY-LEAD** | low | Unverified; no source/balance check |
| 100 | Storm Trade | TON | $3.9M TVL | LOW | **AGENT-ONLY-LEAD** | low | Unverified; no path |
| 101 | GoonFi V2 | Solana | $5.48M measured | LOW | **PRIOR-COVERED** | high | Patched/re-upgraded; pass6 |
| 102 | Rain card fleet (4 programs) | Solana | $1.1M historical | LOW | **PRIOR-COVERED** | high | All four re-deployed; no un-redeployed funded program |
| 103 | Aquifer | Solana | $176,634 TVL | LOW | **PRIOR-COVERED** | high | Redeployed after drain; single-key authority (P) |
| 104 | Raydium legacy LP V3 | Solana | 349.49 RAY stranded | REJECTED | **PRIOR-COVERED** | high | ProgramData missing; dead |
| 105 | Raydium legacy LP V2 | Solana | ~5,554 RAY + 4,935 USDC stranded | REJECTED | **PRIOR-COVERED** | high | ProgramData missing; dead |
| 106 | anchor-lang Program<System> CVE-2026-45137 | Solana framework | No live affected program identified | LOW | **PRIOR-COVERED** | high | ZH4-P5 monitor |
| 107 | anchor-lang InterfaceAccount RUSTSEC-2026-0146 | Solana framework | No live program identified | LOW | **AGENT-ONLY-LEAD** | medium | Only 1.0.0-rc.1 |
| 108 | Cetus CLMM arithmetic / Magma fork | Sui | n/a | rejected | **AGENT-ONLY-LEAD** | high | Patched at v11; fork checked |
| 109 | Turbos reward_manager update_reward_emissions | Sui | n/a | rejected | **AGENT-ONLY-LEAD** | medium | PoolRewardInfo.manager guard |
| 110 | Scallop flash loan receipt | Sui | n/a | rejected | **AGENT-ONLY-LEAD** | high | Hot potato + whitelist + version check |
| 111 | Joule Finance res::register_coin<T0> | Aptos | $0 (no asset movement) | LOW | **AGENT-ONLY-LEAD** | high | Authorization defect, non-extractive |
| 112 | Decibel execute_transfer_with_capability | Aptos | $0 | LOW | **AGENT-ONLY-LEAD** | high | Falsified as drain |
| 113 | Cellana vote_manager rescue_stuck_rewards | Aptos | $0 | LOW | **AGENT-ONLY-LEAD** | high | Funds return to pool |
| 117 | JustLend / SunStaker / SafeVault / ReferalVault / TronBet / SmartDeposit / Game / Eclipcity / DEFI_DEMO | Tron | n/a | REJECTED | **AGENT-ONLY-LEAD** | high | All value-movers revert or return UNAUTHORIZED |
| 118 | WOK token adminTransferFrom | Tron | $0 market | REJECTED | **AGENT-ONLY-LEAD** | high | Unguarded but no market |
| 119 | X100 Freezer permanent governance takeover | Ethereum | $0 (X sell cap exhausted; no non-X assets) | LOW | **PRIOR-COVERED** | high | ZH4P7 monitor; re-arms on any refill |
| 120 | X100 uncapped non-X treasury drain | Ethereum | $0 today | LOW | **PRIOR-COVERED** | high | ZH4P7; latent |
| 121 | Yapeswap v1 factory fake-Yearn trap | Ethereum | $0 now; steals future deposits | HIGH state | **PRIOR-COVERED** | high | ZH4P7; attacker-privileged trap |
| 122 | Yapeswap FeeManager / VotingEscrowLock leftovers | Ethereum | 2,216.75 USDT | LOW | **AGENT-ONLY-LEAD** | high | EOA/timelock controlled (P) |
| 123 | Zq2 migration escrow EscrowInit v1 | Zilliqa | 1,521,695,880 ZIL (~$2.8M) | LOW | **AGENT-ONLY-LEAD** | high | Groth16 BIP-32 parent-node proof; system-only upgrade |
| 124 | Zq2 staking Deposit v9 | Zilliqa | 3.246B ZIL (~$5.6M) | LOW | **AGENT-ONLY-LEAD** | high | onlyControlAddress + BLS PoP; patched |
| 125 | Zq2 delegated staking family (16 proxies) | Zilliqa | ~103M ZIL (~$190k) | LOW | **AGENT-ONLY-LEAD** | low | OnlyOwner config; unverified |
| 126 | zq2 v0.21.10 ZRC2 commit-discard | Zilliqa | ~$12k | HIGH | **AGENT-ONLY-LEAD** | medium | Mainnet now v0.22.1 (g1) -> likely patched; value sub-bar |
| 127 | USD.AI StakedUSDai / LoanRouterV2 / EscrowTimelock upgrade | Arbitrum | $269.6M TVL | LOW | **AGENT-ONLY-LEAD** | medium | Fresh upgrade; minShares guard; escrow balance 0 |
| 128 | ether.fi Borrowing Market DebtManagerCore upgrade | Optimism | $307.3M TVL | LOW | **AGENT-ONLY-LEAD** | medium | Fresh upgrade; borrowTokenMinShares guard |
| 129 | sentora-curator Aave V4 HubInstance upgrade | Ethereum | $2.64B TVL | rejected | **AGENT-ONLY-LEAD** | medium | Upgrade diffed; no guard removed |
| 130 | OptimismPortal2 upgrade | Ethereum | $602.8M TVL | rejected | **AGENT-ONLY-LEAD** | high | Canonical; no path |
| 131 | ListaStakeManager upgrade | BSC | $770.1M TVL | rejected | **PRIOR-COVERED** | high | ci/recon/lista; canonical |
| 132 | Kamino kvault | Solana | $68.9M | REJECTED | **PRIOR-COVERED** | high | pass5/pass6; strict post-transfer deltas |
| 133 | Upshift August Digital vaults | Solana/multi | $442.4M | REJECTED | **PRIOR-COVERED** | high | pass5 closed |
| 134 | Onre onreapp prop-AMM | Solana | $305.6M | REJECTED | **PRIOR-COVERED** | high | pass6; pair PDA uninitialised |
| 135 | BisonFi | Solana | $21.5M | LOW | **PRIOR-COVERED** | medium | pass6 excluded repeat; unverified build |
| 136 | metric-v1 | ETH/Base/ARB/HyperEVM | ~$0.66 | rejected | **PRIOR-COVERED** | high | pass1 closed; no value |
| 137 | Tempo enshrined Stablecoin DEX | Tempo | $16.73M | LOW | **PRIOR-COVERED** | medium | pass2 OPEN (LOW, unfuzzed); node code, not EVM |
| 138 | RISEx CollateralManager | RISE | $21.1M | unassessed | **AGENT-ONLY-LEAD** | low | Proxy unverified; no code evidence |
| 143 | Klever KLV unbounded mint (CVE-2026-54755/-54) | Klever | n/a | REJECTED | **AGENT-ONLY-LEAD** | high | Fork active since epoch 5741 |
| 144 | ixo x/bonds DID-resolved payer drain (CVE-2026-61604) | ixo | n/a | REJECTED | **AGENT-ONLY-LEAD** | high | Node v8.0.0; bonds disabled |
| 145 | tbtc-v2 P2PKH-as-P2SH reveal | Bitcoin | n/a | REJECTED | **AGENT-ONLY-LEAD** | medium | Bridge insolvency class; no live path |
| 146 | GiddyVaultV3 incomplete EIP-712 replay | Ethereum | drained 2026-04-23 | REJECTED | **AGENT-ONLY-LEAD** | high | Path paused/migrated; fully drained |
| 147 | The Internet Token LiquidityUnifier | Base | ~$9.1k (never extractable) | REJECTED | **AGENT-ONLY-LEAD** | high | TOKEN_MINTER has 0 holders |
| 148 | NEAR Intents MetaWallet deposit-notification | EVM x9 | $117.6M held | REJECTED | **AGENT-ONLY-LEAD** | high | Patched 2026-10-02; funds returned |
| 149 | NEP-141 ft_resolve_transfer class | NEAR | n/a | REJECTED | **AGENT-ONLY-LEAD** | high | Patched / no live instance |
| 150 | Gas.zip GasLZV2 1-of-1 DVN receive config | Arbitrum | 0.00256 ETH (~$6) | LOW | **AGENT-ONLY-LEAD** | high | Needs DVN signer compromise (not unprivileged) |
| 151 | KelpDAO rsETH OFTAdapter 1-of-1 DVN | Ethereum | 17,025 rsETH escrowed | REJECTED | **AGENT-ONLY-LEAD** | high | Patched to 4 required DVNs; Unichain peer removed |
| 152 | 59 live OApps / 390 OFT-named contracts | multi | n/a | rejected | **AGENT-ONLY-LEAD** | high | No unprotected setPeer/setDelegate; peers resolve |
| 153 | Sumer.money FeedPriceOracle spot-LP path | Berachain | $679k supplied | LOW | **AGENT-ONLY-LEAD** | medium | All 11 markets use RedStone/FixedPrice; path unwired |
| 154 | Capyfi ChainlinkPriceOracle | Ethereum | $6.84M TVL | LOW | **PRIOR-COVERED** | high | ZH4-P2 excluded prior finding; Comptroller blocks zero price |
| 155 | Moonwell ChainlinkOracle | Base | $8.19M TVL | LOW | **AGENT-ONLY-LEAD** | high | All 21 feeds fresh; composite min updatedAt |
| 156 | Malt sLP treasury-funded rebalance | Polygon | 8,658.02 DAI treasury; pool dust | LOW | **PRIOR-COVERED** | high | pass6 PRIOR-COVERED |
| 157 | Reflexer GEB quitSystem | Ethereum | 0 (safes drained) | rejected | **AGENT-ONLY-LEAD** | high | Historical/drained |
| 158 | Cozy V2 protection sets | Optimism | 4,168 USDC.e | rejected | **PRIOR-COVERED** | high | pass2 PRIOR-COVERED; sub-threshold |
| 159 | Set Protocol RebalancingSetTokenV3 actualizeFee | Ethereum | 0 WETH | rejected | **PRIOR-COVERED** | high | pass2 closed |
| 160 | Balancer V1 BPool joinswap rounding | Ethereum | ~$1 (drained) | rejected | **PRIOR-COVERED** | high | MASTER c-02; EIP-7825 also blocks |
| 161 | Allbridge CCTP Router forged attestation | Base | 0 USDC/USDT | rejected | **AGENT-ONLY-LEAD** | high | Live but empty |
| 162 | Reddio RSV | Reddio | 1 wei stETH | rejected | **PRIOR-COVERED** | high | TIER3 prior |
| 163 | UnifiProtocol treasury | BSC | ~9.17 BNB (~$5.5k) | rejected | **PRIOR-COVERED** | high | ZH4P7/TIER3; sub-threshold |
| 164 | ChainBridge ERC20Handler (Palm) | Ethereum | n/a | rejected | **AGENT-ONLY-LEAD** | high | Relayer-key gated |
| 165 | Hyperlane threshold-1 ISM routes | multi | largest ~$219 | rejected | **PRIOR-COVERED** | high | MASTER/TIER3; relayer-key gated |
| 166 | WAX Ethereum release proxy 0x24b22b03 | Ethereum | ~$42,150 | LOW | **AGENT-ONLY-LEAD** | medium | Unverified impl; no reachable unprivileged path |
| 167 | Tectonic tTONIC donation + DEX manipulation | Cronos | ~$120.4M gross historical; $9.19M unrecovered | rejected | **AGENT-ONLY-LEAD** | high | Chain rolled back to block 90,896,188; patched |
| 168 | Bonzo Lend spot-price incident | Hedera | $9.05M historical; TVL $4.05M | rejected | **PRIOR-COVERED** | high | Registry isInsolvent; L2/corpus closed |
| 169 | Moonwell oracle incidents | Base | $9.5M debt vs worthless mMAMO (2026-08-27) | LOW | **AGENT-ONLY-LEAD** | high | mMAMO still listed but feeds fresh; incident remediated |
| 170 | Kinetic Compound-fork donation/rounding | Flare | $38M cash | rejected | **PRIOR-COVERED** | high | C2-12: all 19 markets non-empty; E-U $0 |
| 171 | Hundred Finance Compound-v2 donation | Optimism | ~$3 | LOW | **PRIOR-COVERED** | high | hWBTC market holds 190 wei; sub-bar |
| 172 | Sonne Finance | Optimism | $20M historical | rejected | **PRIOR-COVERED** | high | soVELO delisted; no empty market |
| 173 | Radiant V2 | Arbitrum/BNB | historical | rejected | **AGENT-ONLY-LEAD** | high | Patched; no live instance |
| 174 | Sturdy V1 | Ethereum | historical | rejected | **AGENT-ONLY-LEAD** | medium | V1 deprecated; sturdy-v2 is a different deployment |
| 175 | Iron Bank | Ethereum/Fantom | historical | rejected | **AGENT-ONLY-LEAD** | high | No unpatched reachable path with funds |
| 176 | CREAM Finance | Ethereum/BSC | historical | rejected | **PRIOR-COVERED** | high | Prior corpus; all markets empty/paused |
| 177 | Benqi | Avalanche | $0 path | rejected | **AGENT-ONLY-LEAD** | high | 15 markets scanned; no unseeded cash |
| 178 | Flux Finance | Ethereum | $0 path | rejected | **AGENT-ONLY-LEAD** | high | 21 comptrollers; no live defect |
| 179 | Agave / Moola | Gnosis/Celo | Moola ~$0.03 dust | rejected | **PRIOR-COVERED** | high | C2-17 Moola E-U dust; Agave closed |
| 180 | UwU Lend | Ethereum | historical | rejected | **AGENT-ONLY-LEAD** | high | Patched after 2024 incident |
| 181 | Onyx | Ethereum | historical | rejected | **AGENT-ONLY-LEAD** | high | Patched |
| 182 | Exponent | Solana | unverified | LOW | **AGENT-ONLY-LEAD** | low | No verified source; partially reviewed |
| 183 | Reflect | Solana | unverified | LOW | **AGENT-ONLY-LEAD** | low | No verified source |
| 184 | DeFindex | Stellar | unverified | LOW | **AGENT-ONLY-LEAD** | low | Vault source internally consistent; deployment not hash-matched |
| 185 | TrustedVolumes RFQ resolver | Ethereum | unknown; dormant since 2026-05-28 | LOW | **PRIOR-COVERED** | high | C-25: vulnerable selectors unregistered; dust |
| 186 | Mendi Finance | Metis/Linea | ~$1.05M TVL | LOW | **AGENT-ONLY-LEAD** | low | Comptroller not obtainable; unverified lead |
| 187 | Kelp rsETH LayerZero message forgery | multi | $292M historical | REJECTED | **AGENT-ONLY-LEAD** | high | DVN observation-layer compromise; contracts clean |
| 188 | Ankr ankrFLOW | Flow EVM | $410k historical | REJECTED | **AGENT-ONLY-LEAD** | high | Paused pending Ankr upgrade; root cause undisclosed |
| 189 | Resupply / PrismaLST / Nucleus | multi | historical | REJECTED | **AGENT-ONLY-LEAD** | high | Patched; Nucleus queue address not identified |
| 190 | Ember Sword NFT auction | Ethereum | 60 WETH historical (2024) | REJECTED | **AGENT-ONLY-LEAD** | medium | Unverified historical contract; no live successor |
| 191 | Splash / Surf / SecondFi / Bodega / Bitrue (Cardano) | Cardano | $3.6k / CEX | rejected | **AGENT-ONLY-LEAD** | medium | Patched, admin-key, CEX or node bug |
| 192 | Scilla DeFi (ZilSwap, PlunderSwap, Avely, Pillar, 400+) | Zilliqa | frozen | rejected | **AGENT-ONLY-LEAD** | high | Scilla side protocol-paused since 2026-07-20; funds frozen |
| 194 | Alien Base StableSwap | Base | ~$1.9k | rejected | **AGENT-ONLY-LEAD** | high | Below bar; no callback primitive |
| 195 | Cysic / Payy / Demex / Chainflip / Nomic | multi | various | REJECTED | **AGENT-ONLY-LEAD** | medium | Paused/suspended, patched, or key-gated; Payy class has no funded sibling |
| 196 | Merad / Tesseract / other one-off incident restatements | multi | n/a | REJECTED | **AGENT-ONLY-LEAD** | high | No live deployed instance found |
| 197 | Aave V3 fork cluster: Tydro (Ink), Vena (Fluent), Zona (Pharos), Kaskad/Oter-fi (Robinhood) | multi | Tydro $133.0M; Vena/Zona/Kaskad unquantified | LOW | **AGENT-ONLY-LEAD** | medium | Empty-reserve liquidity-index precondition unmet on the canonical pools; isolated markets not exhaustively read |
| 198 | Plasma Saving Vaults | Plasma | unassessed (Plasma USD Vault prior $699k latent disproven) | LOW | **PRIOR-COVERED** | medium | ZH4-P2 monitor: accounting artifact; solver-only exit |

### 5.4 Not-a-protocol / key-compromise (11 rows)

*Six of these are also shown in §5.2 because CA2 named them in the README; they are not double-counted in the totals.*

| # | Candidate | Chain | Funds / at-risk (as reported) | CA2 rating | Disposition | Conf. | Basis |
|---|---|---|---|---|---|---|---|
| 30 | Mercado Bitcoin ~$40M multi-chain event | BTC/ETH/SOL/XLM/TRON | 106.07 BTC + 50.68 ETH + 6.71M XLM residual at exchange wallets | REJECTED | **NOT-A-PROTOCOL** | high | AuditKey: signed by source wallets; key/signing compromise, not contract bug |
| 33 | Polymarket International frontend/RUM supply chain | Polygon | ~$2.7M historical | REJECTED | **NOT-A-PROTOCOL** | high | Third-party frontend/RUM; deposit-wallet contracts clean |
| 34 | Predict Fun owner-key drain | BSC | ~$398k historical | REJECTED | **NOT-A-PROTOCOL** | high | Bitquery: 33 drains signed by owners' own keys; no contract called |
| 35 | Zilliqa X-Bridge 1-of-1 validator | ZIL/ETH/BSC | ~$8-9k in lock contracts | REJECTED | **NOT-A-PROTOCOL** | high | Single EOA validator; key compromise; no unprivileged verification flaw |
| 36 | Swell swETH/rswETH unbacked NAV | Ethereum | ~2,500 ETH staged; paused | LOW | **NOT-A-PROTOCOL** | high | Key/oracle compromise; deposits/withdrawals paused |
| 37 | CoinDCX / Qubic / Binance / other key-compromise incidents | multi | n/a | REJECTED | **NOT-A-PROTOCOL** | high | Not external unprivileged contract bugs |
| 52 | The Moats factory | Monad | DefiLlama $1.4M misattributed | REJECTED | **NOT-A-PROTOCOL** | high | getAllDeployedContracts()==[]; no contracts |
| 140 | Bloom Trading Bot third-party module RCE | Solana | $953k historical | LOW | **NOT-A-PROTOCOL** | high | Server-side RCE; no program involvement |
| 141 | TermFinance vault governance proposal | multi | $8.5M | rejected | **NOT-A-PROTOCOL** | high | Privileged governance |
| 142 | Hyperliquid CoreWriter non-atomic credit class | HyperEVM | none confirmed | LOW | **NOT-A-PROTOCOL** | low | Class lead; no live instance |
| 193 | Ledger tampered-device supply chain | physical | ~$93M historical | REJECTED | **NOT-A-PROTOCOL** | high | Physical implant; not an external code path |

---

## 6. Corrections and conflicts found during reconciliation

1. **R25 prior closure is stale/contradicted.** `pass2-recon` records `R25 | Pharos | $164.4M | LANE-CLOSED | Manager-set NAV; 0 USDC held; role-gated updates`. The live read at Pharos block 22,016,133 finds **$169.41M** across five vaults. Either the prior read was of a different contract/chain or it was wrong. This is the single most important reason R25 is OPEN.
2. **Affluent `$1.34M` is TVL, not redeemable value.** CA2's own caveat says the redeem leg was not measured; the prior measurement is $0.00. The realised `$13,504.32` is historical, not repeatable.
3. **wasmer 7.5.0 contradiction.** `promote2/wasmer-ghsa-live-chains.md` lists 7.5.0 as fixed; `promote2/wasmer-ghsa-advisory.md` says the vulnerable lowering is still present in 7.5.0 and that v3.0.9/v2.3.6 are also affected. The rating does not depend on which is right for the fund-drain question (impact is RCE), but the version range is unresolved.
4. **Papertrade value range.** CA2 quotes `$4,912,307.74` free LP, `$4.669M` `lpBankrollAvailable()`, `$25.5M` and `$30.4M` treasury at different blocks. The free-LP figure is the only one that matters for extraction; the treasury/TVL figures should not be used as at-risk.
5. **Tron trio "withdraw executes" is not evidence of a drain.** Constant calls return `0`/empty for a fresh caller at 604–11,011 energy. That is consistent with per-user accounting. The funds are real; the path is not shown.
6. **The DAO clone `0xd838…` internal disagreement.** `target-d838.md` says `refund()` reverts; `synth/g6.md` reproduced `refund()` success on three RPCs but notes it pays `balances[msg.sender]` pro-rata. Either way the path is token-gated and there is no E-U route; the balance is $43–44k.
7. **Notional `HIGH` in g5 vs `REJECTED` in promote2.** The promote2 fork test is decisive: pre-patch block drains 1,658,524.86 USDC; head = 0. The g5 reading inspected the ERC-1155 proxy, not the escrow that was re-pointed. Promote2 wins.
8. **CA2 H-1 value vs our bound.** CA2 says Archway ≈$146.1k contract-held / $116k exit; our `CROSS-CHAIN-FEASIBILITY` bound was ~$54–72k. The difference is measurement scope (all contract-held bank balances vs bridge-exitable value). Both are below the cost of a weaponised chain halt; the verdict is unchanged.

---

## 7. Coverage gaps (explicitly unassessed, not cleared)

- **Chains with no working public RPC at CA2 run time:** Avalon (IoTeX/Bitlayer/Merlin/Pharos), More Markets (Flow), Solera (Plume), Kaskad and Zona (Robinhood), Eden (AssetChain), HyperLoan (BESC), Voltage (Fuse), oter-fi, Ploutos's non-Hemi chains, Arc and Robinhood UNCX flat-fee reads.
- **No working `eth_getLogs`:** Optimism/zkSync/Blast/Berachain and several new chains (CA2 §8).
- **Unverified code reasoned from bytecode only:** Papertrade Exchange/Executor/SKM, R25 impls, SunSwap V4, Stellar Evergreen, ApolloX facets, Tron trio, WAX release proxy, RISEx, Plasma Saving Vaults.
- **No public exploit technique:** wasmer GHSA-v2h8-j899-r676 and CWA-2026-006; the CWA technique remains withheld (last advisory update 2026-09-29).
- **Solana prop-AMM cluster:** no verified build for BisonFi/GoonFi/AlphaQ/Tessera/Scorch; closed on prior state, not on source.
- **Off-chain relayer policy:** Papertrade's submission API is unpublished; a hidden per-account policy cannot be excluded.
- **BTCPay / Fearless:** operator and victim populations unmeasured; no on-chain artifact.

---

## 8. Verdict

- **No new live, externally-unprivileged, >$10k extractable path was identified.** CA2's three CRITICALs reconcile to a $0-measured TON primitive, an existing Papertrade monitor, and an infrastructure RCE in a prior-covered compiler family.
- **The highest residual risk is not a CA2 headline.** It is the **unverified $169.4M R25 vault family on Pharos**, whose prior closure is contradicted by a live balance read. It is followed by the **Gambit** accounting defect (real code, $75.4k at-face, blocked only by USDG acquisition) and three large unverified non-EVM/Tron surfaces (SunSwap V4, Stellar Evergreen, Tron trio).
- **Confidence:** high on the disposition of the 189 non-OPEN rows (each has a code/state/prior citation); **low** on all OPEN plausibility. The OPEN list is a *work queue*, not a value claim.
- **What would change the verdict:** verified source or a decompiler pass on R25/SunSwap/Stellar/Tron; a USDG market on BSC; a new Pharos/Stellar TVL report that isolates the Evergreen vault.

---

## 9. Files, reproduction and CI

| File | Contents |
|---|---|
| `analysis/candidates.csv` / `.json` | 198-row machine-readable disposition table |
| `analysis/counts.json` | disposition/source counts used above |
| `analysis/live-checks.json` | live reads at stated blocks (R25, Gambit, ApolloX, Neverland, Tron) |
| `analysis/live_checks.py` | re-runnable read-only check script (public RPCs only) |
| `analysis/gen.py` / `render.py` | regenerate the table and counts |
| `analysis/prior-coverage-matrix.csv` | keyword/address hits in the prior trackers |
| `ci/run.sh` / `ci-out/` | CI validation + live-check output |
| `ci-log.txt` / `ci-artifacts/` | CI log and artifacts |

**CI:** all heavy/validation work runs on `artsbykriss/ca-zombie-ci` via `bash /home/heisenberg/CA/ci/ci-run.sh ca2-recon`; the run URL is recorded in §9.1 after the run. Local work was limited to light RPC reads, `cast call`, TronGrid constant calls and text processing.

### 9.1 CI run

- **Primary run URL:** https://github.com/artsbykriss/ca-zombie-ci/actions/runs/41644931903
- **Conclusion:** **success** (all 9 validation checks PASS; live checks completed). A post-edit re-run `41645359298` also returned **success**; its log download failed at fetch time, so the primary run is the artifact of record.
- **Artifacts:** `ci-out/counts.json`, `ci-out/live-checks.json`, `ci-out/live-summary.txt`, `ci-out/validation.txt` (artifact `result-ca2-recon`, ID 13234528062)
- **CI-measured:** R25 **$169,413,236.76** at Pharos block **22,016,133**; Gambit 75,188.02 USDT + 34.78 WBNB, redemption 1:1; Tron trio 916,374.11 / 1,040,716.80 / 1,421,724.92 TRX; ApolloX 0.5349 BNB.
- **Note:** the public CI cannot use keyed RPCs; it used `infra.originstake.com/pharos/evm`, `rpc.monad.xyz`, `1rpc.io/bnb` and TronGrid. One Tron `withdraw()` constant call rate-limited in CI; the balance and the other two calls succeeded, and the local run recorded all three.
