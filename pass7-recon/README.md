# ZH4-PASS7 — RESIDUAL RECONCILIATION (pass7-recon)

**Date:** 2026-10-25 · **Campaign:** ZH4 pass 7 (primitive-first) · **Mode:** READ-ONLY (no tx signed/sent; `eth_call`/`eth_getCode`/`eth_getBalance` + explorer reads only; local fork evidence is the lanes' own) · **Deliverable:** this file + `summary.json` + `analysis/` + `ci-out/`
**Mandate (principal):** give **every named candidate across every pass7 lane a disposition** and produce the **OPEN list** (funded + plausible unprivileged path + no verdict anywhere). Do **not** deep-dive; for each OPEN a quick live sanity check (exists? balance? already disproven?).

**Status line:** read-only; no mainnet transactions; no secrets in this folder; PoC/CI evidence belongs to the lane files and the assigned wave folders, not here.

---

## 0. TL;DR

pass7 named **302 protocol-level candidates** across its README (1 CRIT + 9 HIGH + 12 LOW + ~30 verified-closed + 9 corrections) and its **17 lanes** (`_child_fresh_evm_bridges`, `_child_lz_hyperlane`, `_child_sodax`, accounting, bridges, caller-target, fresh-deep, fresh-detector, gov-capture, gov-params, lst-cluster, oracle, real-time, solana-sui, unverified-impl, wsnet, wsnet-verify). Every one is dispositioned in `analysis/DISPOSITIONS.md` (same rows, same order). **Nothing was left without a disposition.**

| Disposition | n | Meaning |
|---|---|---|
| **README-FINDING** | **7** (6 unique) | pass7 README headline/board (1 CRIT + 5 HIGH; wsNET counted once per file) |
| **README-CLOSED** | **63** | pass7 README §5 verified-closed / carry-over-closed |
| **LANE-CLOSED** | **90** | closed inside its own lane (gate/fork/proof cited) |
| **PRIOR-COVERED** | **43** | closed by an earlier pass (tracker/README cited) |
| **PRIOR-PARTIAL** | **2** | same protocol, different angle (BSC router re-impl; Bitget FP) |
| **NOT-A-PROTOCOL** | **29** | off-chain / key / CEX / chain-level / non-EVM / scam template |
| **ASSIGNED** | **65** | handled by a pass7 **wave-1** (README board) or **wave-2** (lane-level funded residuals) agent |
| **OPEN** | **3** | funded + plausible unprivileged path + no verdict anywhere |

**Bottom line.** External-unprivileged extractable **today = $0** (unchanged from pass7's honest one-CRITICAL-mechanism result — and that CRITICAL, wsNET, is **assigned**). The pass7 corpus is now **almost fully dispositioned by the orchestrator's two waves**: wave-1 took the README's 1 CRIT + 9 HIGH + 12 LOW; wave-2 took the **lane-level funded residuals** the first wave missed (Solstice, Project 0, GMX Solana, Streamflow, Perena, TurboFlow, Oro Finance, Loopscale Curation, RateX, Solayer USD, Omnipair, Sui cluster, Bucket V2, Hyperbeat Earn, DexFi Vault V2, CGO Finance, Flying Tulip, Parallel V3, Sturdy V2, xALPH, Alpend, BitSafe, Wildcat, cirBTC — see `ci/ZH4P7-RESULTS-TRACKER.md` §COVERAGE AUDIT). The **residual** after both waves is thin: **3 OPEN** items, and **1 PRIOR-PARTIAL re-probe** (the upgraded BSC DEX router).

The single most material OPEN is **row 251 — the unverified-impl proxy *tail* (rows 13–22 of `unverified-impl.md`)**: ten funded proxies ($14k–$671k live each, ≈**$1.7M** total re-read today) whose implementations were **never decompiled or fork-probed** — the lane only ran a selector scan — yet the README's aggregate "$0" verdict is carried on just 11 of the 65 impls. That is exactly the Slice/Drift "unverified code holding funds" pre-condition.

---

## 1. Method

1. **Extract every named candidate** from `zombie-hunt-iv/pass7/README.md` + all 17 lane files (table rows **and** prose) → **302 rows** (`analysis/rows.json`, full table `analysis/DISPOSITIONS.md`).
2. **Disposition** each against the prior-coverage sources: our trackers `ci/ZH4P7 → ZH4P6 → ZH4P5 → ZH4P4 → ZH4P3 → ZH4P2 → ZH4 → ZH3 → ZH2B2..7 → H/H2/L1/L2-PHASE1`, `ci/TIER3-LOW-TRACKER.md`, `ci/MONITOR-LIST.md`, `ci/MASTER-EXTRACTION-TABLE.md`; the kept root folders (`ls -d */`); `bash zombie-hunt-iv/zh4-check.sh "<name>"`; and the pass1–6 README closed lists + the four prior `*-recon/README.md`. Same protocol / different angle → **PRIOR-PARTIAL**.
3. **ASSIGNED** = a pass7 wave-1 or wave-2 agent (per `ci/ZH4P7-RESULTS-TRACKER.md`); these are **not** re-listed as OPEN.
4. **For each OPEN**, a live sanity check at keyless public RPCs (2026-10-25; blocks below) — `ci-out/live_checks.json` (12/12 OK).
5. **CI** (public repo, no secrets): `bash /home/heisenberg/CA/ci/ci-run.sh pass7-recon` → count reconciliation + live re-reads + secret/keyed-URL scan (`ci/run.sh`, `ci/check.py`).

**Blocks read (2026-10-25):** Ethereum 26,271,451 · Optimism 158,676,855 · BSC 129,752,711 · zkSync 72,636,022 · Polygon (publicnode bor). Prices: ETH ≈ $2,400, USDG $1.00 (lane values; not re-priced here).

---

## 2. Full disposition table

The **complete 302-row table** (id · lane · candidate · chain · funds · lane verdict · disposition · cite) is in **`analysis/DISPOSITIONS.md`**; machine-readable in **`analysis/rows.json`**. Counts reconcile to 302 (§0). Disposition highlights by lane:

| Lane | README-FINDING | README-CLOSED | LANE-CLOSED | PRIOR | NOT-A-PROTOCOL | ASSIGNED | OPEN |
|---|---|---|---|---|---|---|---|
| README (headline/board/§5/corrections) | 6 | 20 | 2 | 3 | 2 | 22 | 0 |
| real-time | — | 5 | 5 | 6 | 9 | 0 | 0 |
| fresh-detector | — | 1 | 6 | 1 | 2 | 4 | 0 |
| fresh-deep | — | 8 | 4 | 1 | 3 | 7 | 0 |
| caller-target | — | 0 | 4 | 6 | 0 | 0 | 0 |
| accounting | — | 3 | 3 | 2 | 4 | 4 | 1 |
| oracle | 1 | 0 | 12 | 2 | 0 | 7 | 0 |
| gov-capture | — | 1 | 3 | 2 | 0 | 2 | 0 |
| gov-params | — | 0 | 16 | 4 | 0 | 3 | 0 |
| lst-cluster | — | 8 | 0 | 0 | 0 | 0 | 0 |
| solana-sui | — | 2 | 0 | 8 | 3 | 12 | 0 |
| unverified-impl | — | 1 | 8 | 0 | 1 | 0 | 2 |
| bridges | — | 1 | 16 | 5 | 2 | 2 | 0 |
| child-A (lz/hyperlane) | — | 0 | 5 | 0 | 0 | 0 | 0 |
| child-B (fresh evm bridges) | — | 0 | 6 | 3 | 1 | 1 | 0 |
| child-C (sodax) | — | 0 | 5 | 0 | 0 | 0 | 0 |
| wsnet / wsnet-verify | (dup) | — | — | — | — | — | — |

*(Rows are grouped in `analysis/DISPOSITIONS.md`; the lane buckets above are indicative of that file's `lane` column.)*

### 2.1 The two PRIOR-PARTIALs (same protocol, new angle — flagged, not OPEN)
1. **BSC DEX router `0xa331fde028e6F17425AB9333c39ae43722340d24`** — prior-corpus HIGH "no known fix"; pass7 found the **impl was upgraded** (`0x241f743e…` → **`0xc700cf8d7adf1782a53a4805d255cf17e126db7f`**). The new impl still exposes both `0x33411b5e` and `pancakeV3SwapCallback` `0x23a69e75` (live-confirmed, §3). → **PRIOR-PARTIAL** (re-probe below).
2. **Bitget omnibus** — a Blockscout-unverified false positive (Etherscan verifies it); the money path is a signer-registry no-op. → **PRIOR-PARTIAL / LANE-CLOSED**.

*(The **BitBay family** was resolved live by child-B: the victim is drained and **every** deployer sibling holds 0 DAI/USDC and is not a vault → **PRIOR-COVERED**.)*

---

## 3. THE OPEN LIST (ranked by funds × plausibility)

`OPEN` = funded **and** a plausible unprivileged path **and** no verdict anywhere (not in README §5, not lane-closed, not prior-covered, not assigned). Live checks are keyless-public-RPC reads at 2026-10-25 (`ci-out/live_checks.json`).

| # | Candidate | Chain(s) | Live funds (re-read today) | Why it is OPEN | Plausibility | Next check |
|---|---|---|---|---|---|---|
| **O1** | **Unverified-impl proxy tail — rows 13–22** (`0x5520385b…`, `0x4CA08cD9…`, `0x3cDbbC3e…`, `0xC6Ae1Db6…`, `0xA4B6D09c…`, `0x6726CA16…`, `0x7d5b0215…`, `0xB07FfFf3…`, `0xc4d45003…`) | OP / Polygon / BSC / zkSync | **≈$1.7M total**: row22 **279.56 WETH ≈ $671k** · row18 **140.99 WETH ≈ $338k** · row14 **498,617 WPOL ≈ $200k** · row16 **78.72 WETH ≈ $189k** · row13 **66.09 WETH ≈ $159k** · row17 **107,057 USDT ≈ $107k** · row19 **21.03 WETH ≈ $50k** · row20 **13,696 USDC ≈ $13.7k** | lane verdict = "**scan**" only (selector extraction); **impls never decompiled/fork-probed**; the README's aggregate "$0" rests on 11/65 impls | **LOW–MED** (unverified code + funds = the Slice/Drift pre-condition) | Decompile the 10 impls (heimdall); probe `transfer`/`withdraw`/`sweep`/`upgradeTo` from a fresh EOA on a fork; classify each as protocol vs CEX/MM |
| **O2** | **Scroll unverified-impl proxies** `0x25aB3Efd…`, `0x740a7C5E…`, `0x7BE980E3…`, `0x7ba30C4c…` | Scroll | **unvalued** (Blockscout/Etherscan V2 403 for these) | lane: "unresolved, low value"; impl unverified | **LOW** (unresolved, low $) | Fetch `eth_getCode` + token balances on Scroll; decompile if funded |
| **O3** | **Lazy Summer / FleetCommander "Ark" class** | Ethereum (Summer.fi) | $6.04M taken 2026-07-06; Summer.fi **fixed 2026-07-30** | lane: "**class open**" — other FleetCommander deployments (18 legacy Arks removed on Summer.fi) never enumerated | **LOW** (class, no specific funded sibling named) | Enumerate other `FleetCommander`/Ark deployments; diff `totalAssets()` vs active-Ark set |

**O4 (removed — closed live by child-C):** the **Hyperlane EIP-7702-delegated trusted relayer** `0x690f4e2f…` was the only genuinely novel child-A surface. Child-C proved `execute(...)` from `0x…dEaD` **reverts `NotEntryPointOrSelf`** (EntryPoint/self/signed-delegation only) → **LANE-CLOSED** (row 284). The ~30 threshold-1 `TrustedRelayerIsm` routes are **dust today** (largest VRA/eth ≈ $219) and need the relayer key (H-O/P).

### 3.1 PRIOR-PARTIAL re-probe (not OPEN, but the strongest residual action)
- **BSC DEX router `0xa331fde0…` — new impl `0xc700cf8d7adf1782a53a4805d255cf17e126db7f`** (22,857 B, live; proxy 130 B; native 0). Both vulnerable selectors are still present (`0x33411b5e` entry, `0x23a69e75` `pancakeV3SwapCallback`). The callback's **caller-validation was never probed on the new impl**. **Next check:** decompile `0xc700cf8d…`; run an `Approval`-event census for `spender = router`; test a fake Pancake-V3 pool callback from a fresh EOA.

### 3.2 Why the wave-2 "uncovered leads" are **not** OPEN
`Project 0`, `GMX Solana`, `Perena`, `Streamflow`, `TurboFlow`, `Oro Finance`, `Loopscale Curation`, `RateX`, `Solayer USD`, `Omnipair`, `Solstice`, the `Sui` cluster, `Bucket Protocol V2`, `Hyperbeat Earn`, `DexFi Aggregator Vault V2`, `CGO Finance`, `Flying Tulip Lend`, `Parallel V3`, `Sturdy V2`, `xALPH`, `Alpend`, `BitSafe CBTC`, `Wildcat`, `cirBTC` are **ASSIGNED** (wave-2, `ci/ZH4P7-RESULTS-TRACKER.md` §COVERAGE AUDIT). `NodeDAO` and the LST cluster are **README-CLOSED**. `Sat Rush / Loyal Earn / TRUE DEX / Pascal / N1 Bridge / Byzanlink` are **PRIOR-COVERED** (pass6-open-tail closed all eleven). `GrowiHF`, `Bittensor dTAO`, `Lighter LLP`, `Neutral Trade`, `Concrete`, `Felix/Liminal/Project X` are **NOT-A-PROTOCOL** (HyperCore/institutional/curator).

### 3.3 Child-A live corrections to the wave-2 leads (do not change the OPEN list)
- **TurboFlow Perps** upgrade authority `HJbtKYPE…` is **ON-CURVE with no account = a plain keypair** (P-class) over a $6.7M perp+bridge — the only live plain-key upgrade authority in the set.
- **Sui "fresh cluster" packages are versioned/upgradable** (AlphaLend v7, Kai 17 versions, Bluefin `margin_bank` 24 versions) → **not** immutable-safe; an `UpgradeCap` exists (holder unresolved).
- **AlphaFi is winding down** (ALPHA-oracle bad debt; Sui Foundation covered the shortfall; withdrawals-only) → its $2.32M is draining, not a live target.
- **Loopscale Curation is not a Loopscale program** — it is **Exponent's** strategy-vault program (`sVau1tX…`) filtered by a Loopscale curator role key; the Orca+Loopscale merger ("Formation", 2026-10-07) explains it. PRIOR-PARTIAL vs the pass5 core.
- Upgrade authorities otherwise **off-curve PDAs** (gov/multisig): Project 0 `J3oBkTk…`, GMX Solana `6qp7veAL…`, Perena `CPJo7euW…`, Streamflow `5u7o2WGg…` (STREAM mint auth revoked), RateX `AbkPd7Ms…`, Oro `iNtiXEFg…`.

### 3.4 Child-B live corrections to the EVM leads (do not change the OPEN list)
- **DexFi Aggregator Vault V2** (wave-2) — factory `0xcb34f261…` live (`vaultsCount=1895`), impl `0x2149F9c9…` (23 KB) has **no** `setFarm*`/`setFarmConnector`/`setConnector`/`setStrategy`, and `emergencyWithdraw` is caller-scoped → the lane's "unauth setFarm / swappable connector" hypothesis is **refuted** → LANE-CLOSED.
- **CGO Finance** (wave-2) — MasterChef live (43 pools, allocPoint 44,700) but the CGO reward reserve is **41.8M CGO ≈ $5.5k** → LANE-CLOSED.
- **Hyperbeat Earn** (wave-2) — `mcHYPE` MetaMorpho, owner = 2-of-3 Safe; the "unverified strategist" `0x83a80e5b…` is an **EOA (code=0)**, not a contract → LANE-CLOSED.
- **Goldilocks Goldivaults** — all 3 vaults revert every view call (inactive); the ~$527k is **HONEY in the Goldiswap AMM**, not the Goldivaults → LANE-CLOSED (correction).
- **ApeChain games** (wave-1) — APEPredicts $3.9k / CashOrCrash $2.2k / House $1.9k / GameApeVault $124, all `onlyOwner`/admin or caller-scoped; `OrbitNativeOFTAdapter` $111k owner-gated → LANE-CLOSED.
- **PendingContributions** 91.23 ETH ($214.7k) caller-scoped → **PRIOR-COVERED** (`zombie_hunt/github_stuck_funds.md` #68). **xXx_bank / MindVault / ZK Pool** caller-scoped/proof-gated → LANE-CLOSED.

### 3.5 Child-C live corrections to the bridge/framework + oracle leads (do not change the OPEN list)
- **Hyperlane `TrustedRelayerIsm` threshold-1 routes** — custody is **dust today** (USDC/base 28.35, USDC/op 28.35, USDC/arb 71, VRA/eth ≈ $219, ctUSD/eth $0); H-O/P (needs the relayer key); `Mailbox.process` forge reverts → LANE-CLOSED.
- **EIP-7702 relayer `0x690f4e2f…`** — `execute(...)` from `0x…dEaD` **reverts `NotEntryPointOrSelf`** → the novel surface is **closed** (was O4).
- **Payy `RollupV1`** — E-U $0; the pass7 "paused" is **wrong** — there is **no on-chain `paused()`**, the drain is `onlyProver`-gated; no other funded **Barretenberg < v5.0.0** verifier exists on ETH/Base/Arb (a new UltraHonk verifier set, StealthPay on 0G chain 16661, is **bb 5.x post-fix, immutable** → class-watch only).
- **Flying Tulip Lend / Parallel V3 / Sturdy V2** (wave-2) — located live: Flying Tulip **≈$9.17M** (oracle = `OracleRouterChainlink` / Chainlink `latestRoundData`); Parallel V3 **≈$0.91M** (EIP-2535 Diamond, facet impl `0xf659fac0…`); Sturdy V2 **≈$0.23M** (Mode $199.7k + ETH + Linea/Flow/OP; **Sei $0**) — Sturdy V2 is **PRIOR-PARTIAL** (pass4 closed only the Sei leg).
- **USDT0 OFT adapter** — still **$3.197B**; dormant EIDs 30165/30214/30375/30243 remain **`peer == 0`**; no new live 1-of-1 route.

---

## 4. Live sanity checks (read-only, 2026-10-25)

`ci-out/live_checks.json` — **12/12 OK**. Key reads:

| Target | Exists? | Live now | Already disproven? |
|---|---|---|---|
| O1 row22 OP `0xc4d45003…` | yes (1,648 B) | 279.557 WETH ≈ **$671k** | no — never decompiled |
| O1 row18 OP `0xA4B6D09c…` | yes (2,001 B) | 140.994 WETH ≈ **$338k** | no |
| O1 row14 Polygon `0x5520385b…` | yes (1,159 B) | 498,617.77 WPOL ≈ **$200k** | no |
| O1 row16 OP `0x3cDbbC3e…` | yes (289 B) | 78.716 WETH ≈ **$189k** | no |
| O1 row13 OP `0x5520385b…` | yes (1,159 B) | 66.092 WETH ≈ **$159k** | no |
| O1 row17 OP `0xC6Ae1Db6…` | yes (2,070 B) | 107,057.04 USDT ≈ **$107k** | no |
| O1 row19 OP `0x6726CA16…` | yes (2,769 B) | 21.031 WETH ≈ **$50k** | no |
| O1 row20 zkSync `0x7d5b0215…` | yes (10,080 B) | 13,696.33 USDC ≈ **$13.7k** | no |
| O1 row15 BSC `0x4CA08cD9…` | yes (170 B) | native 0 (token balance not re-read) | no |
| O1 row21 Polygon `0xB07FfFf3…` | yes (163 B) | 26.758 WETH ≈ **$64k** | no |
| §3.1 BSC router impl `0xc700cf8d…` | yes (22,857 B) | selectors `33411b5e`+`23a69e75` present | no — needs probe |
| O4 Hyperlane relayer `0x690f4e2f…` | yes | code = `0xef0100‖0x63c0c19a…` (EIP-7702) | **closed** — `execute()` reverts `NotEntryPointOrSelf` (child-C) |

**Valuation caveat (correction to the lane):** the lane's Ankr-derived figures were **overstated** for several tail rows (e.g. row20 was quoted $276k, live USDC is $13.7k; row21 quoted $702k, live WETH is $64k; row13 quoted $576k, live WETH is $159k). The lane itself warned that Ankr mislabels balances. The **live token-balance reads above supersede the lane's numbers**.

---

## 5. Confidence & blockers

- **Confidence in the dispositions: HIGH.** Every README-closed item is corroborated by its own lane; every PRIOR-COVERED item was matched to a specific tracker/README line; every ASSIGNED item matches `ci/ZH4P7-RESULTS-TRACKER.md` (wave-1 or wave-2).
- **Confidence in the OPEN list: MEDIUM.** OPEN is a **triage label, not a bug**; plausibility is LOW–MED for all three, and O1 is the only one with material live funds.
- **Blockers / caveats.**
  1. **O1 impls are unverified on every free source** (Etherscan V2 + Sourcify + Blockscout) — identification must be by decompiler. Several are plausibly **CEX/MM/bridge** custody (the same holder-ranked sweep surfaced Coinbase 10, Wintermute, Bitget first).
  2. **O2 Scroll** proxies could not be valued (explorer 403 from this host).
  3. The **second wave was launched concurrently** with this recon; some wave-2 targets (e.g. Hyperbeat Earn, Loopscale Curation, Project 0) are flagged **PRIOR-PARTIAL** in the tracker and their folders may supersede this table.
  4. **Alchemy/GoldRush** keys are capacity-exceeded (pass-6/7 note) → all reads here used **keyless public RPCs**.
  5. Point-in-time **2026-10-25**; re-read live state before acting. Nothing here is an instruction to transact.

---

## 6. Files & CI

- `summary.json` — counts, OPEN list, one-liner.
- `analysis/DISPOSITIONS.md` — the full 302-row markdown table (source of truth).
- `analysis/rows.json` — machine-readable 302-row table + counts + OPEN.
- `analysis/build.py` — table → rows.json/counts builder.
- `analysis/childA-solana.md`, `childB-evm.md`, `childC-bridges.md` — 3 child live-check notes.
- `ci/run.sh`, `ci/check.py` — CI validation: count reconciliation, keyless public-RPC live re-reads, secret/keyed-URL scan.
- `ci-out/validation.json`, `ci-out/live_checks.json` — CI outputs.
- **CI:** GitHub Actions `artsbykriss/ca-zombie-ci`, workflow `poc.yml`, branch `pass7-recon` — **final run URL: https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40229376356** (`conclusion=success`; `custom CI script` → `[pass7-recon] validation exit=0`; `ok:true`, candidate_count 302, OPEN 3, live_checks 12/12, `secret_scan_hits=0`). Earlier runs: `…/runs/40228261880`, `…/runs/40225065464`. Artifacts: `ci-artifacts/result-pass7-recon/ci-out/{validation.json,live_checks.json}`, log `ci-log.txt`.
  *(Note: a full `git clone` of the CI repo hung on this host — the helper was re-run with a pre-seeded `--depth 1` work dir at `/tmp/opencode/ca-zombie-ci-pass7-recon`; the push/dispatch/watch flow then ran normally. GitLab fallback was not needed.)*

*Prepared 2026-10-25 · ZH4 pass-7 residual reconciliation · read-only · no secrets.*
