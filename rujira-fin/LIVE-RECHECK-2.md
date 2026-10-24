# Rujira FIN — LIVE RE-CHECK #2 (post-unhalt) — ZH4

**Date:** 2026-10-24 (re-check at **12:48–13:02 UTC**) · **Chain:** THORChain app layer (`thorchain-1`, CosmWasm) · **Status:** read-only; no transaction signed or sent.
**Scope:** *status verification only.* The exploit path was reconstructed in [`EXPLOIT-PATH.md`](EXPLOIT-PATH.md) (ZH4-PASS3, PoC 4/4) and is **not** redone. This document answers: **the v3.21.0 upgrade has executed and `HALTWASMGLOBAL = 0` — is the FIN bug now live?**

---

## 1. TL;DR — the decisive question

| Question | Answer (2026-10-24 ~12:58 UTC) | Evidence |
|---|---|---|
| **Did v3.21.0 execute?** | **YES.** `current = 3.21.0`; upgrade height **28,366,100** passed (now ~28,378,160). | `/thorchain/version`, `/thorchain/block` |
| **Is the wasm halt lifted?** | **YES.** `HALTWASMGLOBAL = 0`; the App Layer is executing again (first wasm tx at height **28,366,103**, 2026-10-23T14:44:47Z — 3 blocks after the upgrade). | `/thorchain/mimir`; post-unhalt scan |
| **Has the FIN code migrated?** | **NO.** **58** pairs still on code **196** (`5CC7E136…E071`, fin v2.2.2, **unpatched**), **1** on code **194**. Max code id on chain = **198**; no new `rujira-fin` code. | `/thorchain/contracts`, `/cosmwasm/wasm/v1/code/{…}` |
| **Is the exploit path live?** | **NOT DEMONSTRABLE.** The vulnerable primitive is present verbatim on-chain and the App Layer executes — **but** the v3.21 fix is a **private base-layer binary** (`thornode-private`, "DO NOT build from source") that cannot be read; the public tag/develop carry **no `TxSignedBy` guard**. 24 h of live operation shows **zero `range.transfer`** and **no range owner changes**. | §3–§5 |
| **Evidence of exploitation post-unhalt?** | **None.** 12,064 blocks scanned: 15,638 wasm execs, 119 FIN `range.*` messages, **0 `range.transfer`**; CCL book intact (1,199 ranges, $1.578 M). | §3 |

> **Verdict: the bug is NOT demonstrably live — and NOT confirmably patched.** The halt is **lifted**, FIN runs the **unpatched** contract (196), and the base-layer fix is **unverifiable from outside**. An unprivileged attacker **cannot be shown** to be able to drain the CCL ranges right now, and **no exploitation is observed** in the 24 h since unhalt; but because the fix is a private binary this **cannot be excluded**. Classification: **`UNVERIFIABLE — unhalted + unpatched code; fix is a private base-layer binary`.**

---

## 2. Live state (exact)

Snapshots: local height **28,378,158** (12:58:27Z); CI height **28,378,160** (12:58:39Z); live-recheck height **28,378,162** (12:58:52Z).

### 2.1 Version / upgrade
| Item | Value |
|---|---|
| `current` / `next` | **3.21.0** / 3.21.0 |
| Upgrade 3.21.0 @ height 28,366,100 | **executed** (`/thorchain/upgrade_proposals` now returns `null`) |
| App-layer resumed | **height 28,366,103** (2026-10-23T14:44:47Z), 3 blocks after upgrade |

### 2.2 Halt state (authoritative: Mimir)
| Key | Value | Contract | Meaning |
|---|---:|---|---|
| **`HALTWASMGLOBAL`** | **0** | — | **CosmWasm executions ENABLED** |
| `HALTTHORCHAIN` | 0 | — | base layer live |
| `HALTTRADING` | 0 | — | base-layer swaps live |
| `HALTSECUREDGLOBAL` | 0 | — | secured assets live |
| `HALTWASMCONTRACT-YEVLEC` | **0** | `rujira-fin` (2.2.2) | FIN **not** individually halted |
| `HALTWASMCONTRACT-27DUYT` | **1** | `rujira-ghost-credit` (1.0.4) | **still halted** — the credit-account / liquidation path (24 h grace period) |
| `HALTWASMCONTRACT-JY3TQX` | 0 | `rujira-brune` (3.2.1) | lifted |
| `HALTWASMCONTRACT-D5A6R5` | 0 | `liquidy-swap` | lifted |
| `HALTWASMCONTRACT-PTRU2G` | 0 | `rujira-staking` (2.1.0) | lifted |

* The **only** remaining app-layer halt is `27DUYT = rujira-ghost-credit` — consistent with Rujira's published plan to leave the Credit-Account contract paused for a 24 h liquidation grace period. The §3.5 *credit-account liquidation* vector of `EXPLOIT-PATH.md` is therefore **blocked**; the direct FIN path is **open**.

### 2.3 FIN code state — unchanged / unpatched
| Code id | data_hash | FIN pairs | Note |
|---|---|---:|---|
| **196** | **`5CC7E1368AEE0E5A7877502CA6A090CA7AA4DFB10CAF3453AADCD035E1F2E071`** | **58** | fin **v2.2.2**, commit `3114257` — **byte-identical to the deployed exploit target; no patch** |
| 194 | `2CD5DC97B5DA032DCB35A0AC08E02A255BA5EFE8188D3298CDC8F69BD509B606` | 1 | the unattested `rujira-fin:btc-btc:tron-usdt` pair |

* **No contract migration.** Enumerating every code on chain (`/cosmwasm/wasm/v1/code`, full pagination) gives **198 codes total, max id 198**; only **194** and **196** match a FIN data_hash. The Rujira multisig (`thor1hmfs…jw022`) owns codes 69–198; **no new FIN code id** was instantiated after the incident.
* Upstream `gitlab.com/thorchain/rujira` `rujira-fin` is **still v2.2.2** (`3114257`, 2026-09-07) — no contract-level patch exists upstream either.

### 2.4 Live value
| Item | USD (CI, h=28,378,160) | USD (local, h=28,378,158) |
|---|---:|---:|
| FIN TVL (59 pairs) | **1,800,656.85** | 1,800,571.90 |
| **CCL range deposits (the transferable set)** | **1,578,051.57** | 1,578,008.57 |
| — of which contract-owned (8 owners, 123 ranges) | — | 123 ranges |
| Credit Accounts (459 contracts, 111 funded) | 905,194.84 | 904,803.50 |

*The App Layer is live, so the CCL book now **trades**; the mark moved from $1.694 M (2026-10-23, halted) to $1.578 M on price/trading, **not** on a drain — range count went **1,198 → 1,199** (one range created), see §3. `ci-out/rujira-state.json`.*

---

## 3. Post-unhalt activity scan — evidence of exploitation

Full block-by-block scan of the **entire post-unhalt window** (CI, `analysis/scan_postunhalt.py`):

| Metric | Value |
|---|---:|
| Window | **28,366,100 → 28,378,163** (12,064 blocks, ~24 h) |
| Transactions | 162,719 |
| `MsgExecuteContract` txs | **15,638** (6,614 blocks) — app layer is fully executing |
| Blocks with a FIN-targeted execute | 4,183 |
| FIN messages by key | `arb` 2,867 · `swap` 2,488 · `order` 407 · **`range` 119** |
| **`range.transfer` events** | **0 (none)** |

**Range-ownership diff** vs the 2026-10-21 snapshot (`analysis/range_owners_2026-10-21.json` → `range_owners.json`):
* ranges **1,198 → 1,199** (2 added, 1 closed by its owner); **0 owner changes**; distinct owners 147 → 146.
* **No position was transferred** to any new address; the book is intact.

**Interpretation.** FIN is processing normal flow (arb / swap / order / range create-claim-deposit-withdraw) at scale, and in ~24 h of open execution **no `range.transfer` occurred and no range changed owner**. There is **no on-chain evidence of the exploit being used** after the unhalt.

---

## 4. Is the exploit path live? (code + base-layer fix)

The primitive is **code-level**: `RangeMsg::Transfer` authorises on `sender == range.owner`, and `sender` is filled with `info.sender` (`ranges/execute.rs:184`, `contract.rs:87`/`190`). Its liveness depends on (a) the deployed code hash, and (b) whether the App Layer can execute a forged caller.

1. **Deployed code unchanged** → code 196 `data_hash` = `5CC7E136…E071`, **identical** to the PoC's vendored v2.2.2 build. The vulnerable primitive is still present **verbatim** on-chain. **PoC re-ran 4/4** in CI against that exact code (§5).
2. **Execution enabled** → `HALTWASMGLOBAL = 0`; 15,638 wasm execs observed. Nothing at the wasm layer blocks a `Range(Transfer)` dispatch any more.
3. **The base-layer fix is NOT verifiable.** The v3.21 deployable image is a **private build**: MR !5226 states *"This release will use a private binary including additional security patches — DO NOT build from source"*; the public `v3.21.0` tag tree is identical to `mainnet-3.21.0` and its `x/thorchain/handler_wasm_execute_contract.go` is **byte-identical to `develop`** — **no `TxSignedBy` / `assertContractSender` guard** anywhere in the public source. The fix therefore lives only in `thornode-private`.
4. **Reachable-vector nuance.** `EXPLOIT-PATH.md` §3.5 (contract-owned positions driven via execute-as-self) is *not* freely attacker-reachable for the 8 contract owners (4 DAO-DAO-governed, 3 shielded sub-wallets behind their immutable proxy, 1 sub-wallet) — and the **credit-account** route is currently **halted** (`27DUYT`). The **direct caller-forgery** path is what v3.21 was meant to close, and it is exactly what cannot be read.

**Conclusion:** the path is **intact in the contract** and the layer is **open**, so liveness reduces entirely to whether the private v3.21 build closes the caller-forgery. We **cannot verify that from outside**, and we **cannot (read-only) construct a live proof** — a replay would require sending a transaction, which is forbidden.

---

## 5. Verdict & classification

| Category | USD | Basis | Confidence |
|---|---:|---|---|
| **E-U now (demonstrable)** | **0.00** | no live path proven; **0 `range.transfer`** and **0 owner changes** in 24 h of open execution | **medium** |
| **E-U residual / latent** | **1,578,051.57** | the full CCL book (1,199 ranges) **if** the private v3.21 base-layer fix is incomplete — **unverifiable** | — |
| H-O | 0.00 | n/a (no lock) | — |
| P | 1,800,656.85 | node operators (halt) / FIN admin 3-of-4 multisig `thor1hmfs…jw022` | — |
| S | 2,705,851.69 | FIN + Credit Accounts while `27DUYT` halted | — |

**Status label: `UNVERIFIABLE (unhalted + unpatched code; v3.21 fix is a private base-layer binary)`.** Do not sum the categories.

**Plainly:** an unprivileged attacker **cannot be shown to be able to drain the CCL ranges right now** — there is no proof, and there is no evidence anyone is doing so — but because the v3.21 patch is a **private binary** we **cannot confirm the path is dead**. The E-U headline stays **$0 (medium confidence)**; the **$1.58 M** CCL book remains a **residual risk** that flips to live **only if the private fix is incomplete**, which is only knowable by replaying the primitive on a fork of live state.

**What would change the verdict:** (a) a public post-mortem / patch diff showing the `TxSender` guard; (b) any `range.transfer` on-chain to a non-owner; (c) a fork replay that still forges a caller after v3.21.

---

## 6. CI re-check

* Job `ci/run.sh`: [1] read-only state collector (`analysis/collect_rujira.py`), [1b] `analysis/live_recheck.py`, **[1c] full post-unhalt scan (`analysis/scan_postunhalt.py`)**, [2] `cargo test -p rujira-fin exploit_poc` against v2.2.2.
* **CI run: [40096156847](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40096156847)** — conclusion **success**, branch `rujira-fin`.
  * PoC: **4 passed / 0 failed** (`cargo test exit=0`).
  * State at height **28,378,160** (12:58:39Z): version **3.21.0**, `HALTWASMGLOBAL=0`, FIN **59 pairs (196×58, 194×1)**, FIN **$1,800,656.85**, CCL **$1,578,051.57 / 1,199 ranges**, accounts **$905,194.84**.
  * live-recheck at height **28,378,162** (12:58:52Z): `upgrade_executed=true`, `wasm_halted=false`, `code_unchanged_vs_v2_2_2=true`, `ghost_credit_halted=true` → `classification = "E-U UNVERIFIABLE …"`.
  * Scan window **28,366,100–28,378,163**: 15,638 wasm execs, 119 FIN `range.*`, **0 `range.transfer`**.
* Results in `ci-out/`: `rujira-state.json`, `live-recheck.json`, `postunhalt-scan.json`, `*-console.txt`, `fin-poc.log`; raw log `ci-log.txt`; artifacts `ci-artifacts/`.
* Prior runs: [40095622223](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40095622223) (first post-unhalt probe, PoC 4/4), [39956741969](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39956741969) (pre-upgrade), [39664417601](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39664417601) (exploit reconstruction).

---

## 7. Caveats / blockers

* **The fix is unverifiable.** The v3.21 security patch ships only in the private `thornode-private` image; the public tag/develop contain no wasm sender-auth guard. On-chain we can prove only: (i) the upgrade executed, (ii) the halt is lifted, (iii) FIN code is unchanged, (iv) no exploitation is visible.
* **No read-only proof of the primitive is possible** — a live replay requires a transaction (forbidden). The PoC is a message-level reproduction against the deployed code, not a replay of the base-layer bug.
* **Scan limitation:** the scan decodes top-level tx messages; a `range.transfer` nested inside a call to another contract would not appear as a top-level FIN message. It is nevertheless caught indirectly by the range-owner diff (0 changes) and the intact CCL book.
* **Residual scope:** the 2026-09-26 incident hit **one team-owned** position; $1.578 M is the CCL-range book ceiling, not a per-range proof.
* **Prices move and the book now trades** (App Layer live), so TVL is no longer frozen; only marks/flow move it, not a drain.
* **Registry scope:** the code check covers the **59 registered** `rujira-fin` pairs.

*Read-only research; no mainnet transactions. Prepared 2026-10-24.*
