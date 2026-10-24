#!/usr/bin/env python3
"""Compose pass6-recon/README.md from rows.json + the OPEN-list narrative."""
import json, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
data = json.load(open(os.path.join(ROOT,"analysis","rows.json")))
rows, counts = data["rows"], data["counts"]

HEAD = """# ZH4-PASS6 — RESIDUAL RECONCILIATION (pass6-recon)

**Date:** 2026-10-24 · **Mode:** READ-ONLY (no tx signed/sent; `eth_call`/`eth_getBalance`/explorer reads only) · **Deliverable:** this file + `summary.json` + `analysis/` + `ci-out/`
**Mandate (principal):** give **every named candidate across every pass6 lane a disposition** and produce the **OPEN list** (funded + plausible unprivileged path + no verdict anywhere). Do not deep-dive; for each OPEN a quick live sanity check.

---

## 0. TL;DR

pass6 named **177 protocol-level candidates** across its 20 lanes (the board rows 6–19, every lane table row and prose lead, and the lane-level aggregates). Each is dispositioned below. **Nothing was left without a disposition.**

| Disposition | n |
|---|---|
| README-FINDING (pass6 README headline/board) | **1** |
| README-CLOSED (pass6 README §5) | **30** |
| LANE-CLOSED (closed inside its lane) | **49** |
| PRIOR-COVERED (closed by an earlier pass) | **34** |
| PRIOR-PARTIAL (same protocol, different angle) | **2** |
| NOT-A-PROTOCOL (off-chain / key / CEX / chain / non-EVM) | **21** |
| ASSIGNED (handled by another pass6 agent) | **18** |
| PARKED (funded but unlocated / trigger-only) | **1** |
| **OPEN** | **21** |

**Bottom line.** External-unprivileged extractable **today = $0** (unchanged from pass6's honest 0-new-CRITICAL result). The residual value is in **21 OPEN** candidates — funded surfaces whose lane flagged an *unread / unverified / untested* path and that **no pass has closed**. Two of them were **materially under-measured by their own lane** (the lanes checked only native balances / probed selectors):

- **ETH `0x278d858f…` whitelist-router family** — holds **≈$399k in tokens** on Ethereum alone (73,386.89 USDT + 87,134.14 USDC + **102.279 WETH**), not the "$0.0006 ETH dust" the lane reported. Lane family claim: $6.9M / 12 chains.
- **BSC `0x6aba0315…` proxy** — holds **≈$3.28M on BSC** (741,702.22 USDT + 3,476.04 BNB) at 155.9M txs. Lane family claim: $8.63M / 5 chains.

Neither is proven exploitable (both revert for a stranger; the router's whitelist check works). They rank top of the OPEN list on funds×plausibility.

**Status line:** read-only; no mainnet transactions; no secrets in this folder.

---

## 1. Method

1. **Extract every named candidate** from `pass6/README.md` + all 20 lane files (`zombie-hunt-iv/pass6/*.md`) — table rows *and* prose. → 177 rows (`analysis/rows.json`, full table in `analysis/DISPOSITIONS.md`).
2. **Disposition** each against the prior-coverage sources: our trackers `ci/ZH4P5 → ZH4P4 → ZH4P3 → ZH4P2 → ZH4 → ZH3 → ZH2B*`, `ci/L2-*`, `ci/TIER3-LOW-TRACKER.md`, `ci/MONITOR-LIST.md`, the kept/verified root folders (`ls -d */`, incl. `residual-recon/`), `bash zombie-hunt-iv/zh4-check.sh "<name>"`, and the pass1–5 README closed lists. Same protocol / different angle → **PRIOR-PARTIAL**.
3. **Known pass6 items already handled** are not re-listed as OPEN: Robinhood oracle, Ascend, INFER, JPY DeFi, The Moats, Exceed, Kolan ×14 hooks, BSC V4-hook bank (all **ASSIGNED**); Sodium/AGLHook/Spot/StablePair/BiFi (**closed by us**); Cardboard/Monetrix/Kestrel/Tessera/Secured-Finance/BPool/Swaap/Pacifica/StonkBrokers/VETRO/Arcus/Popdex/HoodLock/JUSD/Fake-World/CommunityV3/Bebop/Aero (**README-CLOSED**); NEM (pass4), UniswapV4Router04 (kept dust).
4. **For each OPEN, a live sanity check** (exists? balance? already disproven?) at public RPCs — see §3 and `ci-out/live_checks.json`.

---

## 2. FULL DISPOSITION TABLE (177 named candidates)

Full table: `analysis/DISPOSITIONS.md` (same rows, same order). Reproduced here:

"""

TAIL = """
---

## 3. THE OPEN LIST (ranked by funds × plausibility)

`OPEN` = funded + a plausible unprivileged path that no pass has closed. Plausibility is explicit; **none is a proven drain**. Live checks at public RPCs 2026-10-24 (`ci-out/live_checks.json`).

| # | Candidate | Chain | Live funds (verified now) | Lane's unclosed path | Plausibility | Next check |
|---|---|---|---|---|---|---|
| O1 | **ETH `0x278d858f…` + BSC `0xa9010523…` whitelist-router family** | ETH/BSC(+12) | **≈$399,327 ETH leg**: 73,386.89 USDT + 87,134.14 USDC + **102.279 WETH** + 0.000616 ETH; lane: $6.9M/12 chains | unverified/obfuscated multi-DEX router with `WHITELIST_MANAGER 0x4a46ef9A…`, 4 swap callbacks + V4 `unlockCallback`; whitelist-bypass via a spoofed pool / missing callback caller-check | **LOW-MED** | decompile the impl (non-EIP-1967, bespoke); test a malicious pool + direct `uniswapV3SwapCallback`/`unlockCallback`; confirm `WHITELIST_MANAGER` gate on each of the 4 probed selectors |
| O2 | **BSC `0x6aba0315…` proxy ($8.63M / 155.9M txs)** | BSC(+4) | **≈$3.28M BSC leg**: 741,702.22 USDT + **3,476.04 BNB**; lane: $8.63M/5 chains | unverified impl `0xb66a5adf…` (AccessControl+UUPS+Pausable+ERC-1271); USDT-settlement fn `0x25356bc7` reverts for *everyone*; a role/validation gap on a sibling path = $8M drain | **LOW-MED** (blocker: may be a CEX/omnibus) | decompile `0xb66a5adf…`; diff the 51-selector set for missing role checks; enumerate USDT approvals; classify CEX vs protocol |
| O3 | **Primus Confidential Vault (FHE)** | BSC | reported >$1M user deposits; backend `StakedUSDuV2 0x385C2794…` $38.6M | FHE vault + 8-h batch settlement + encrypted shares (`esUSDu`); **addresses unresolved** | **MED-HIGH $ / address-thin** | resolve the FHE contracts from `dapp.primuslabs.xyz`; then read the encrypted-share mint/redeem + batch settle |
| O4 | **Prodigy.Fi V2 (PositionManager)** | Base | $68.9k DL; proxy `0x50aB3FE7…` → **unverified impl `0xb1522e35…`** (code present, ~14.5 KB), 1,674 vaults | F1: options-vault share/NAV + settlement behind unread code | **MED** | decompile impl, enumerate value-moving selectors, probe auth from a fresh EOA (pass4's "22 unverified-impl proxies" method) |
| O5 | **Wager Predict** | BSC | **$173,362.94 USDW** in `SpotEngine 0x76b91e83…` (USDW 6dp, totalSupply 202,545.41) | fresh custom LMSR prediction market + LP Vault + **USDW wrapper impl `0x7169d192…` unread**; backing is $204k in an off-protocol issuer wallet `0x255e92b8…` | **LOW-MED** | read USDW impl mint/redeem + who can pull the backing; fork a `buy→sell` round-trip for fixed-point overshoot |
| O6 | **Nullmask** | Base | **12.377 ETH ≈ $28,898** (native; WETH bal 0) | fresh ZK privacy pool (Tornado-lineage): deposit Guard/relayer fee accounting + nullifier/verifier wiring; **prior PARKED (addresses then unresolved)** | **LOW-MED** | read pool impl `0xc763e821…` / `AdminUpgradeController 0xcD12496c…` / Guard `0x0558E584…` |
| O7 | **Tapir Protocol** | Base | **$55k** (52,601 zvUSDC in `DepegPool 0x195F79D6…`) | fresh "Depeg Protected / Yield Boosted" split AMM + redemption-price oracle + 22 bp fee; settlement math unread | **LOW-MED** | source-read `DepegPool` + oracle `0x776e69E1…`; fork a depeg/resolve transition |
| O8 | **Unichain `ImmutableProxy` family (~130 clones)** | Unichain | ~$130k across ~130 clones (~$1k each) | all delegatecall an **unverified impl `0x9f70b0c8…`**; `withdraw/refund/recover` revert for a random EOA (`0x407c71ac`) but not fully decompiled | **LOW** | decompile `0x9f70b0c8…`; look for any clone whose `withdraw`/`refund` returns success from a random EOA |
| O9 | **Swaap Maker V2 (`SafeguardPool`)** | multi (11) | ~$454k | distinct Balancer-V2 codebase (ChainSecurity-audited) flagged out-of-scope by `swaap.md`; **never read** | **LOW** | source-read `SafeguardPool` + its oracle guard on a funded instance |
| O10 | **AlphaQ** | Solana | ~$1.0M on-chain (41 markets / 46 vaults) | `update_price` **proven gated**; the `swap`/`swap_with_sig` payout math + secp256k1 path **unresolved** | **LOW** | build a Jupiter/OKX-router proxy-swap with attacker-chosen accounts (same test Tessera needs) |
| O11 | **ChimeraQuoteHook404** | Ink | fees in per-pool `ChimeraFeeVault404` clones | fresh v4 hook (`beforeSwap/afterSwapReturnDelta`, transient storage); creator-exemption via `IChimeraQuoteRouterContext(router).actor()==creator`; `distributeQuotrons` permissionless | **LOW** | fork Ink; drive `Router404.swapPath` through a live Chimera pool; test non-creator exemption reachability + `_charge` rounding |
| O12 | **BondingCurveManager** | Ronin | 190 ERC-20s (all launches it manages) | fresh bonding-curve launchpad; `mulDiv` rounding + auto-graduation; `Ceil` fallback branch | **LOW** | fork Ronin; fuzz `quoteBuy` vs `quoteSell` for a wei-positive round trip; test `liveTarget` manipulation |
| O13 | **DiversiFi** | Solana | $745k | `7029d112…` **proven gated**; `rebalance`/`update_weights` untested; vaults are user-creatable | **LOW** | simulate `rebalance`/`update_weights` with attacker signer |
| O14 | **Overpass** | Solana | $141k | wrapper factory over Lulo/Kamino/kvault/marginfi/save; user-creatable wrappers + creator fee = PDA-binding surface | **LOW** | simulate `Create*Wrapper` + `UpdateCreatorFee`/`ClaimCreatorFees` |
| O15 | **Zodial** | Solana | $201k | **marginfi fork** — fork-drift risk on an audited base | **LOW** | diff the marginfi ix set against upstream; probe admin paths |
| O16 | **Sat Rush** | Solana | $847k DL | "gamified mining" points portal; program ID **unresolved** | **LOW** | resolve program from the DL adapter; read token-account custody |
| O17 | **Loyal Earn** | Solana | $393k DL | yield aggregator; Token-2022 mint; program ID **unresolved** | **LOW** | resolve program ID; read vault custody |
| O18 | **TRUE DEX** | Solana | $281k DL | derivatives, 0 audits; program ID **unresolved** | **LOW** | resolve program ID |
| O19 | **Pascal** | Solana | $2.24M DL | prediction market, 0 audits; program ID **unresolved** | **LOW** | resolve program ID |
| O20 | **N1 Exchange Bridge** | Solana | $1.37M DL | bridge, 0 audits; program ID **unresolved** | **LOW** | resolve program ID; check message verification |
| O21 | **Byzanlink RWA Markets** | Solana | $2.09M DL | RWA market, 2 audits; program ID **unresolved** | **LOW** | resolve program ID |

**Ranking rationale.** O1–O2 top the list because their *verified* token balances are 5–10× what their lane measured, and the code is unverified/obfuscated (the Slice/Drift pre-condition). O3 is high-$ but address-thin. O4–O7 are fresh, funded, with an unread/unverified value path and a concrete next step. O8–O15 are lower-value or probe-negative-but-not-fully-excluded. O16–O21 are DL-funded Solana protocols with no resolved program ID (unlocated).

**Deliberately NOT OPEN** (to avoid re-listing handled/closed items): the 18 ASSIGNED pass6 items; the 20 pass6 README-closed clusters; NEM and UniswapV4Router04 (prior-covered / kept dust); URM Fortress (PARKED — board row 10, no address published anywhere); JPY DeFi (ASSIGNED, and PRIOR-PARTIAL vs the ZH4-closed JPYdf); FlashLoopAdapter (PRIOR-PARTIAL — the module is in the ZH2 negative list; only its 30 same-deployer siblings are unread).

---

## 4. Live sanity checks (read-only, 2026-10-24)

Blocks at read: Ethereum 26,265,167 · Base 53,043,770 · BSC 129,584,923 · Unichain 62,128,529 · Ink 59,378,479 · Ronin 62,704,051. Prices: ETH $2,334.84 · BNB $731.79 · SOL $101.21 (DefiLlama).

| Target | Exists? | Live balance now | Already disproven? |
|---|---|---|---|
| ETH `0x278d858f` (O1) | yes (unverified, bespoke) | 73,386.89 USDT + 87,134.14 USDC + 102.279 WETH + 0.000616 ETH ≈ **$399.3k** | no — lane only checked native ETH |
| BSC `0xa9010523` (O1) | yes | 0 USDT-BSC, 0 native | sibling; value is on ETH |
| BSC `0x6aba0315` (O2) | yes (unverified impl) | 741,702.22 USDT-BSC + 3,476.04 BNB ≈ **$3.28M** | no — reverts for stranger only |
| Base Prodigy `0x50aB3FE7` (O4) | yes; impl code present (14.5 KB) | native 0 (funds in vaults) | no |
| BSC Wager `0x76b91e83` (O5) | yes | 173,362.94 USDW ≈ **$173.4k** | no |
| Base Nullmask `0xd64EF141` (O6) | yes | 12.377 ETH ≈ **$28.9k** | no |
| Base Tapir `0x195F79D6` (O7) | yes | native 0 (holds zvUSDC) | no |
| Unichain `0x966107c4` (O8) | yes | native 0 | probe reverts (guard present) |
| Ink `0xD723B53D` (O11) | yes | native 0 (fees in vaults) | no |
| Ronin `0xCF6Aa3d8` (O12) | yes | native 0 (holds ERC-20s) | no |
| Base Doppler `0x27ad92D4` (monitor) | yes | native 0 (31.2M XDP staked) | inert until first `addRewardPeriod` |
| Solana programs LYC8…/ALPHAQ…/par1ty…/3vyr9…/ccJYP…/WRAPd…/zod11…/TessV… | **all exist, executable** (BPFLoaderUpgradeable) | custody per lane | Kestrel/Tessera closed; others unresolved |

---

## 5. Confidence & blockers

- **Confidence in the dispositions: HIGH.** Every pass6 README-closed item is corroborated by its own lane file; every PRIOR-COVERED item was matched to a specific tracker/README line; every ASSIGNED item matches the `ci/ZH4P6-RESULTS-TRACKER.md` wave table.
- **Confidence in the OPEN list: MEDIUM.** `OPEN` is a triage label, not a bug. Plausibility is mostly LOW-MED; the top two rest on *unverified/obfuscated* code that the lanes could not name on any free source.
- **Blockers / caveats.**
  1. **`0x6aba0315` (O2)** has 155.9M txs and 5-chain custody — it may be a **CEX/omnibus**, not a protocol (the same blocker as pass5-recon's zkSync vault OPEN). Classify before investing.
  2. **O1/O2 name resolution failed** on every free source (Blockscout Base/BSC Cloudflare-blocked, Etherscan-V2 free tier rejects Base/BSC, Sourcify no match, Firecrawl out of credits). Identification must be by decompiler.
  3. **Solana O16–O21** have no resolved program ID in any source touched (DL-listed only) — they are funded but unlocated.
  4. The shared **Alchemy key was monthly-cap-exceeded** during pass6; all reads here used public RPCs.
  5. Point-in-time **2026-10-24**; re-read live state before acting. Nothing here is an instruction to transact.

---

## 6. Files & CI

- `summary.json` — counts, OPEN list, one-liner.
- `analysis/rows.json` — machine-readable 177-row disposition table (schema: lane/candidate/chain/funds/lane_verdict/disposition/cite).
- `analysis/DISPOSITIONS.md` — the full markdown table.
- `analysis/build.py` — table builder (source of truth).
- `ci/check.py`, `ci/run.sh` — CI validation: count reconciliation, public-RPC live-funds re-reads, secret/keyed-URL scan.
- `ci-out/` — `validation.json`, `live_checks.json` (written by CI).
- **CI:** GitHub Actions `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, branch `pass6-recon` — run URL recorded in `ci-log.txt` / §6 of the run.

*Prepared 2026-10-24 · ZH4 pass-6 residual reconciliation · read-only · no secrets.*
"""

# build table
tbl = ["| # | Lane | Candidate | Chain | Funds | Lane verdict | Disposition | Cite |","|---|---|---|---|---|---|---|---|"]
for r in rows:
    tbl.append(f"| {r['n']} | {r['lane']} | {r['candidate']} | {r['chain']} | {r['funds']} | {r['lane_verdict']} | **{r['disposition']}** | {r['cite']} |")
md = HEAD + "\n".join(tbl) + "\n" + TAIL
open(os.path.join(ROOT,"README.md"),"w").write(md)
print("README.md written:", len(md), "chars,", len(rows), "rows")
