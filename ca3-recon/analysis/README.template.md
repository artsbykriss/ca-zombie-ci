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

{{TABLE_A}}

**README disposition summary:** 9 prior-assigned (the live CA3 agents), 31 prior-covered, 5 prior-partial, 0 research-only, 0 not-a-protocol, 0 OPEN. The README contains **no unassigned live candidate**.

---

## 4. Disposition table — research-file-sourced candidates (42)

{{TABLE_B}}

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

**CI run:** `{{CI_URL}}`

**Prior dossiers cited:** `zombie-hunt-iv/wave2/v14-popdex.md`, `pass6/pacifica-bridge.md`, `wave1/r4-non-evm.md`, `wave2/v10-startale.md`, `pass7/wsnet.md` + `wsnet-verify.md`, `pass7/gov-params.md`, `ci/ZH2B6-RESULTS-TRACKER.md` (H2-05), `ci/ZH4-RESULTS-TRACKER.md` (ZH4-03/04/05/06/07), `ci/ZH4P7-RESULTS-TRACKER.md`, `ci/MONITOR-LIST.md`, `ci/CA2-RESULTS-TRACKER.md` (CA2-OPEN-1/2/4/6), `ci/CA3-V2-TRACKER.md`.
