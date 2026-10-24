# Rujira FIN — app-layer halt and the v3.21 patch gap (THORChain)

**Date:** 2026-10-20 · **Chain:** THORChain app layer (`thorchain-1`, CosmWasm) · **Status:** read-only; no transaction signed or sent.
**Snapshot:** THORChain height **28,315,097** (2026-10-19 23:01:41 UTC), plus the `/thorchain/mimir`, `/thorchain/version`, `/thorchain/upgrade_proposals` and CosmWasm state at that height. This is a status verification of ZH4-PASS2 Tier-3 row 3, not a new finding.

> **ZH4-PASS3 UPDATE (2026-10-21) — full exploit path reconstructed; see [`EXPLOIT-PATH.md`](EXPLOIT-PATH.md).**
> Pulled the exact deployed source (fin **v2.2.2**, commit `3114257`, wasm sha256 `5cc7e136…E071` = on-chain **code 196**). **The flaw:** `RangeMsg::Transfer` authorises on `sender == range.owner` (`ranges/execute.rs:184`), and `sender` is a plain `Addr` that FIN itself fills with **`info.sender`** (`contract.rs:87` → `Arb{then}` self-call → `DoRange` → `execute_range`). The check is sound *inside* FIN — **no second unchecked path exists** (only `Transfer` writes `owner`; every path uses the same check) — so the bypass is the **app-layer caller authenticity**, exactly as Rujira said ("fix at the base layer", private v3.21 binary). Locally reproduced **4/4** (`poc/rujira`, cw-multi-test) — CI run **[39664417601](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39664417601)** (`cargo test exit=0`, 4 passed): direct transfer blocked; owner transfer works; **forged caller transfers + drains**; **contract-owned position transferred via execute-as-self**. Live **E-U = $0** (`HALTWASMGLOBAL=1`); **E-U-conditional = $1,690,217.02** (1,198 CCL ranges; $1,744,609.63 at the 2026-10-21 re-check). Trigger: `HALTWASMGLOBAL → 0` before height 28,366,100.
>
> **ZH4-PASS5 LIVE RE-CHECK (2026-10-23 ~12:55 UTC) — [`LIVE-RECHECK.md`](LIVE-RECHECK.md).** **v3.21.0 had not executed** (height 28,365,056 vs upgrade height 28,366,100 → ~1,044 blocks / ~1.8 h away; version still 3.20.3). **`HALTWASMGLOBAL=1` still up** (no node votes to unhalt). **FIN code unchanged** — 58 pairs on code 196 (`5CC7E136…E071`, **unpatched**), 1 on 194. **E-U now $0; E-U-conditional $1,693,670.69** (1,198 CCL ranges; FIN book $1,884,097.15; accounts $913,983.52). PoC re-ran **4/4** (`cargo test exit=0`), CI **[39956741969](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39956741969)**. Not live, not patched — the same E-U-conditional, now hours from the upgrade window.

---

## TL;DR

| Question | Answer |
|---|---|
| **Live E-U now** | **$0** — `HALTWASMGLOBAL = 1`; every CosmWasm execution is disabled |
| App-layer state | **Halted since 2026-09-26** by node operators; base layer is live (`HALTTHORCHAIN=0`, `HALTTRADING=0`) |
| Credit Accounts | Halted by the same global wasm halt; **459 `rujira-account` contracts**, 111 funded, **$918,107.49** |
| FIN TVL | **$1,879,918.86** across 59 pairs (priced; legacy `thor.lqdy/auto/nami` excluded) |
| **CCL range deposits** | **$1,690,217.02** across **1,198 ranges** — the value exposed to the position-transfer bug |
| FIN code | **Unchanged**: 58 pairs on code **196** (`5CC7E1…E071`, fin v2.2.2), 1 on code **194** (unattested); no migration since the exploit |
| Patch | **v3.21.0**, approved upgrade at height **28,366,100**, ETA **2026-10-23 13:40–16:15 UTC**; current version **3.20.3** |
| Patch verifiability | **Low** — v3.21 ships a **private binary** with additional security patches; the public changelog does **not** list a FIN fix |
| Classification | **E-U-conditional (patch gap)**, not closed; **P/S** while halted |
| Trigger | **`HALTWASMGLOBAL` → 0 (FIN unhalted) before height 28,366,100**, or an unhalt after v3.21 that does not actually contain the FIN fix |
| Confidence | **high** on the halt/version/code state; **medium** on the $1.69M at-risk reach; **low** on patch completeness |

**One-line verdict:** the $1.88M FIN book is frozen, not fixed — all 59 pairs still run the pre-exploit code, and the only mitigation is a node-operator wasm halt that can be lifted before the private v3.21 patch ships. A restart before 2026-10-23 is the exact E-U-conditional window.

---

## 1. Live halt state (authoritative: Mimir)

At height 28,315,097 the effective Mimir values are:

| Key | Value | Meaning |
|---|---:|---|
| **`HALTWASMGLOBAL`** | **1** | **All CosmWasm contract executions disabled** (FIN, Credit Accounts, Ghost, Staking, Merge) |
| `HALTWASMCONTRACT-JY3TQX` | 1 | Specific contract `thor1enhmz57…qjy3tqx` = **rujira-brune 3.2.1** (not FIN) |
| `HALTTHORCHAIN` | 0 | THORChain base layer **not** halted |
| `HALTTRADING` | 0 | Base-layer swaps/trading **not** halted |
| `HALTSECUREDGLOBAL` | 0 | Secured-asset deposits/withdrawals not globally halted |
| `HALTWASMCONTRACT-*` (other) | 0 | No FIN-specific contract halt is needed; the global flag covers all |

Rujira's docs define `HALTWASMGLOBAL` as “full shutdown of whole App Layer” and the THORChain docs define it as disabling all CosmWasm contract executions. Read-only smart **queries** still work (we used them to value the ranges); **executions** are blocked. There are **no active node votes** to change any `HALTWASM*` key (`/thorchain/mimir/nodes_all` returned no such keys), so the unhalt is not currently in flight.

**Base layer is healthy:** the halt is app-layer only. This is a deliberate node-operator mitigation, not a chain failure.

---

## 2. The incident and the exact bug

- **Date:** 2026-09-26 (discovered; app layer paused the same day).
- **Product:** Rujira **FIN CCL** (Custom Concentrated Liquidity) range — a FIN range position.
- **Rujira's attribution:** a flaw in the **position transfer function**, not in the liquidity strategy's trading logic.
- **Impact:** **one CCL position, owned by the Rujira team**; Rujira states **no user funds were lost**.
- **Mechanism (public):** the attacker “transferred a custom concentrated liquidity position without holding a corresponding position” (The Defiant / Crypto Briefing, 2026-10-19). The exact transaction and a technical post-mortem have **not** been published.
- **Fix:** Rujira says the fix is at the **base layer** and ships in THORChain **v3.21**; the app layer resumes after the upgrade.

**What we could verify on-chain:** the deployed FIN contracts still contain the CCL range primitive (`RangeMsg::Transfer` asserts `sender == range.owner` in the v2.2.2 source), and **all 59 FIN pairs are still on the same code** (58 × code 196 = `5CC7E1…E071`, fin v2.2.2 / commit `3114257`; 1 × code 194, unattested, the $4.1k pair). No FIN code migration has occurred. The vulnerable build is live; only the halt prevents execution.

The public v2.2.2 source's `RangeMsg::Transfer` owner check is consistent with the official “position transfer function” description, but it does **not** by itself explain how the attacker bypassed it — which is exactly why the base-layer fix and the private binary matter. We do **not** claim to have reproduced the bug.

---

## 3. Patch status — v3.21

| Item | Value |
|---|---|
| Current version | **3.20.3** (`/thorchain/version`; `next` also 3.20.3) |
| Upgrade proposal | **3.21.0**, height **28,366,100**, **approved: true** (`/thorchain/upgrade_proposals`) |
| ETA | **2026-10-23 13:40–16:15 UTC** (release notes: p50 6.12 s/block; height is authoritative) |
| Release | `https://gitlab.com/thorchain/thornode/-/releases/v3.21.0` |
| Public changelog | Consensus/state migration, ZEC, SOL, TSS, UTXO/XMR hardening — **no FIN/Rujira item** |
| Critical caveat | The release says: **“This release will use a private binary including additional security patches — DO NOT build from source.”** The FIN fix is therefore **not independently verifiable** from the public changelog/source |
| Distance at snapshot | 51,003 blocks (~3.5 days at ~6.2 s/block) |

The upgrade is approved, so the schedule is credible. The **content** of the FIN fix is not: Rujira/THORChain state that v3.21 contains it, but the public release notes do not list it and the binary is private. That is the main reason the patch-completeness confidence is **low**.

**No early code fix:** the FIN pair code IDs are unchanged (58 × 196, 1 × 194), and no new FIN code ID has been instantiated. If the team intended a contract migration, it has not happened yet.

---

## 4. Live value at risk

All values use THORChain pool prices at 2026-10-19 23:0x UTC (BTC $82,112; ETH-USDC $1.0015; RUNE $0.6455; RUJI $0.1930). Bank balances are 1e8-scaled THORChain amounts.

**FIN (59 pairs): $1,879,918.86**

| Pair | USD | Denoms |
|---|---:|---|
| `thor1dwsn…5077sz` (btc-btc / eth-usdc) | **523,386.63** | BTC + USDC |
| `thor1j9euq…6ahwp` (ruji / rune) | 232,823.98 | RUJI + RUNE |
| `thor1tnd06…2snva` (eth / usdc) | 220,929.14 | ETH + USDC |
| `thor1g3mym…778ngf` (eth / btc) | 193,938.52 | ETH + BTC |
| `thor17caww…5l5d0a` (ruji / usdc) | 114,454.95 | RUJI + USDC |

**CCL ranges: $1,690,217.02 across 1,198 ranges.** This is the FIN subset that the position-transfer bug can reach: range `base`/`quote` deposits, valued at pool prices. The top pair alone has ~$450k in ranges. The remaining FIN value is order-book/limit-order liquidity, which is **not** transferable via the CCL position path.

**Credit Accounts: $918,107.49** across 459 `rujira-account` contracts (111 with >$1). These are frozen by the same `HALTWASMGLOBAL` flag; they are **not** part of the FIN CCL bug, but they are part of the halted app layer and the Oct-15 restart plan (a proposed 24-hour grace period for LTV>100% borrowers).

**Context:** the wider Rujira cluster is ~$14.1M (staking $8.0M, Merge $2.0M, FIN $1.88M, accounts $0.92M, Ghost $0.41M, BOW $24k) per the wave-2 reconciliation. Only the FIN CCL subset is exposed to this bug.

---

## 5. What an attacker can/cannot do

**Now (halted):**
- **Cannot** execute any FIN/CosmWasm message: `HALTWASMGLOBAL = 1` blocks `MsgExecuteContract`. There is no unprivileged bypass; the halt is enforced by the wasm module, not by the contract.
- **Cannot** unhalt: Mimir changes require node-operator consensus (2/3+), i.e. **P**.
- **Can** read state (queries) — which is how we valued the ranges. No value moves.

**If the app layer is unhalted before the fix is effective (the E-U-conditional window):**
- The attacker would use the FIN CCL **position transfer** path that took the team position on 2026-09-26. The at-risk set is the **1,198 CCL ranges = $1,690,217.02** (of the $1.88M FIN book). If the base-layer flaw is broader than CCL transfers, the ceiling is the whole app layer (~$2.8M FIN+accounts; ~$14.1M cluster), but the official description is specifically the position transfer function, so we use **$1.69M** as the defensible number.
- The attack is **unprivileged** (no admin key): it uses public FIN messages. The prior attacker needed no governance/operator role. That is why this is E-U-conditional, not merely P.
- The **only** gates are (a) the wasm halt and (b) the v3.21 fix. There is no per-position whitelist or pause in FIN.

**Why not P/S only:** the vulnerable code is live and unchanged; the halt is an operator action that can be reversed by a Mimir vote. A “P” label would understate the conditional external path. It is **E-U-conditional** with a **P-controlled trigger**.

---

## 6. Classification (USD)

| Category | USD | What |
|---|---:|---|
| **E-U now** | **0.00** | `HALTWASMGLOBAL=1`; no wasm execution |
| **E-U-conditional** | **1,690,217.02** | CCL ranges if unhalted before the v3.21 fix is effective |
| **H-O** | 0.00 | No user self-service while halted; claims resume only after unhalt |
| **P** | 1,879,918.86 | Node operators control the unhalt; FIN admin is a 3-of-4 multisig (`thor1hmfs…jw022`) that controls upgrades |
| **S** | 2,798,026.35 | FIN $1,879,918.86 + Credit Accounts $918,107.49 frozen while halted; not lost, not movable |

The E-U-conditional and S/P figures overlap by construction: the same $1.88M is frozen (S) and would be exposed (E-U-conditional) on an early unhalt. Do not sum them.

---

## 7. Monitor trigger — exact

1. **Primary:** `GET /thorchain/mimir` → **`HALTWASMGLOBAL` becomes `0`** (or a FIN-specific `HALTWASMCONTRACT-*` is lifted while global is already 0).
2. **Version check:** `GET /thorchain/version` → `current` becomes **`3.21.0`**. The upgrade height is **28,366,100**; an unhalt **before** that height is the dangerous case.
3. **Early-warning:** any node Mimir vote for `HALTWASMGLOBAL=0` (`/thorchain/mimir/nodes_all`), or a Rujira/THORChain restart announcement dated before 2026-10-23 13:40 UTC.
4. **Post-upgrade verification:** re-read the FIN pair code IDs and the CCL transfer path. If the FIN code is still 196/194 and the private binary's fix cannot be verified, treat the E-U-conditional as still open until a replay/test confirms the path is dead.
5. On trigger: fork THORChain state at the unhalt height, replay the 2026-09-26 position-transfer path against a small CCL range, and measure whether the transfer still succeeds. Do **not** touch live contracts.

**Monitoring commands:** `rujira-fin/ci/run.sh` (read-only; revalues FIN, CCL ranges, accounts and prints the halt/version/upgrade state), `analysis/collect_rujira.py`.

**CI re-check (run [39340728260](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39340728260), height 28,315,258, 2026-10-19 23:18 UTC):** `HALTWASMGLOBAL=1`, `HALTTHORCHAIN=0`, version `3.20.3`, upgrade 3.21.0 / 28,366,100 approved, FIN 59 pairs (58 × 196, 1 × 194), FIN **$1,879,402.48**, CCL **$1,689,772.46**, accounts **$917,587.80** — same verdict.

---

## 8. Evidence index

| Item | Value |
|---|---|
| Halt snapshot | `analysis/mimir.json` — `HALTWASMGLOBAL=1`, `HALTWASMCONTRACT-JY3TQX=1` (rujira-brune), `HALTTHORCHAIN=0` |
| Version | `analysis/version.json` — `3.20.3` / next `3.20.3` |
| Upgrade | `analysis/upgrade_proposals.json` — `3.21.0`, height 28,366,100, approved |
| Block | height 28,315,097, 2026-10-19T23:01:41Z (`/thorchain/block`) |
| Registry | `analysis/contracts.json` — 59 `rujira-fin`, 459 `rujira-account` |
| FIN valuation | `analysis/state-live.json` — `fin.tvl_usd = 1,879,918.86`, `ccl_ranges_usd = 1,690,217.02`, 1,198 ranges |
| Code IDs | 58 × 196 (`5CC7E1368AEE0E5A7877502CA6A090CA7AA4DFB10CAF3453AADCD035E1F2E071`), 1 × 194 |
| Collector | `analysis/collect_rujira.py`; `ci/run.sh` |
| CI | run [39340728260](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39340728260) — height 28,315,258; FIN $1,879,402.48 / CCL $1,689,772.46 / accounts $917,587.80; `HALTWASMGLOBAL=1` |

**Sources:** THORChain LCD via the public Liquify gateway (`gateway.liquify.com/chain/thorchain_api`); `/thorchain/mimir`, `/thorchain/version`, `/thorchain/upgrade_proposals`, `/thorchain/lastblock`, `/thorchain/block`, `/thorchain/contracts`, CosmWasm contract/code/smart-query endpoints, bank balances; GitLab `thorchain/thornode` release v3.21.0; Rujira docs “Understanding the App Layer”; THORChain dev docs “Network Halts”; The Defiant / Crypto Briefing (2026-10-19); ZH4 wave-2 `v27-rujira.md` and pass-2 `non-evm-incidents.md`.

---

## 9. Caveats / blockers

- **No public post-mortem or exploit tx.** The exact position-transfer call sequence and the attacker's profit are not public; we verified the official attribution and the deployed code/halt, not the bug mechanism itself. This is the main blocker to a higher-confidence at-risk number.
- **Private binary.** v3.21's FIN fix is in a private binary; the public changelog does not list it. We cannot verify the patch content. If the fix is incomplete, the E-U-conditional survives the upgrade.
- **At-risk scope.** The official impact was one **team-owned** CCL position. Whether every user CCL range is transferable by the same path is not public; $1.69M is the ceiling of the CCL range book, not a proven per-range exploit.
- **Registry scope.** The code-ID check covers the **59 registered `rujira-fin` pairs**. If the exploited CCL position lived in an unregistered/test FIN deployment, it is outside this registry check; we found no such deployment in `/thorchain/contracts`, but the registry is not exhaustive.
- **Frozen, not lost.** Bank balances are intact; no user funds were reported lost. The $1.88M is S while halted.
- **Prices move.** FIN is valued at pool prices at 23:0x UTC; RUJI/legacy `thor.lqdy/auto/nami` are excluded (no THOR pool).
- **No live transaction or fork replay was performed.** The trigger is designed for a fork replay at the unhalt height; a live test would violate the read-only rule.

*Read-only research; no mainnet transactions. Prepared 2026-10-20.*
