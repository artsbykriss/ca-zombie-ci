# CA2 residual reconciliation — every named candidate dispositioned, plus the OPEN list

**Date:** 2026-11-03 · **Source corpus:** `ca2/` (README 23.7 KB; `.work/` 52 agent reports, 9 synth groups, 10 promote, 5 promote2, 14 final) · **Prior corpus:** `ci/ZH4P7 → ZH2B*`, `ci/L2-*`, `ci/TIER3-LOW-TRACKER.md`, `ci/MONITOR-LIST.md`, `ci/MASTER-EXTRACTION-TABLE.md`, `ci/CROSS-CHAIN-FEASIBILITY.md`, `ci/CA2-RESULTS-TRACKER.md`, kept root folders, `zombie-hunt-iv/zh4-check.sh`, pass1–7 closed lists.
**Status:** read-only. No transactions broadcast, no keys used, no keyed URLs or `.env` contents copied. All live checks are `eth_call`/`cast call`/TronGrid constant calls at the blocks stated.

---

## 1. TL;DR

- **{{N}} named candidates** were extracted and given exactly one disposition: **{{N_README}} named in the CA2 README** (tables and prose) and **{{N_AGENT}} agent-only** (only in the 52 `.work/agents` reports, synth, promote or final files).
- **No new CRITICAL survives reconciliation.** CA2's three CRITICALs resolve as: **Affluent = prior measured $0.00** (the redeem leg CA2 did not measure), **Papertrade = escalation of our ZH3-C3 monitor** (handled), **wasmer GHSA = new advisory in the already-covered CWA-2026-006 compiler family, and an infrastructure RCE rather than a fund-drain primitive** (handled).
- **{{N_PRIOR}} candidates are prior-covered/partial** ({{N_PC}} + {{N_PP}}), **{{N_LEAD}} are agent-only leads with a closing verdict**, **{{N_NONPROTO}} are not-a-protocol** (key compromise / supply chain / CEX), **7 are README-named but not prior-covered** (BTCPay, Fearless, b14g, Vara, Hifi, Few-and-Far, Coffer — all handled by CA2 wave folders).
- **9 OPEN rows = 7 distinct targets.** None has a demonstrated unprivileged path; they are open because (a) the code is unverified and (b) in one case a prior closure rests on a balance statement that is now false. Ranked by funds × plausibility in §4.
- **The residual money is not in CA2's headline list.** It is in unverified Tron/Pharos/Stellar contracts and one BSC GMX-fork accounting defect.

### Disposition counts

| Disposition | Rows | Meaning |
|---|---:|---|
| README-CRITICAL | 0 | no README critical survives as a live, non-prior finding |
| README-HIGH | 2 | BTCPay, Fearless (new, handled; no on-chain value proof) |
| README-LOW | 5 | b14g, Vara, Hifi, Few-and-Far, Coffer (new, handled; sub-bar) |
| README-REJECTED | 0 | README rejects are either prior-covered or not-a-protocol |
| AGENT-ONLY-LEAD | {{N_LEAD}} | named only in agent reports; closed/low/unverified |
| PRIOR-COVERED | {{N_PC}} | a dispositive prior verdict exists |
| PRIOR-PARTIAL | 10 | same protocol/class, different instance or angle |
| NOT-A-PROTOCOL | {{N_NONPROTO}} | key compromise, supply chain, CEX, or no deployed protocol |
| **OPEN** | **9** | **funded + plausible-but-unproven path + no dispositive verdict** |
| **Total** | **{{N}}** | |

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

{{OPEN_TABLE}}

### 5.2 README-named candidates (39 rows)

{{README_TABLE}}

### 5.3 Agent-only candidates ({{N_AGENT_TABLE}} rows)

{{AGENT_TABLE}}

### 5.4 Not-a-protocol / key-compromise ({{N_NONPROTO}} rows)

*Six of these are also shown in §5.2 because CA2 named them in the README; they are not double-counted in the totals.*

{{NONPROTO_TABLE}}

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
- **Confidence:** high on the disposition of the {{N_NONOPEN}} non-OPEN rows (each has a code/state/prior citation); **low** on all OPEN plausibility. The OPEN list is a *work queue*, not a value claim.
- **What would change the verdict:** verified source or a decompiler pass on R25/SunSwap/Stellar/Tron; a USDG market on BSC; a new Pharos/Stellar TVL report that isolates the Evergreen vault.

---

## 9. Files, reproduction and CI

| File | Contents |
|---|---|
| `analysis/candidates.csv` / `.json` | {{N}}-row machine-readable disposition table |
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
