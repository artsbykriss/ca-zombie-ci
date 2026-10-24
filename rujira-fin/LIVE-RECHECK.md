# Rujira FIN — LIVE RE-CHECK (ZH4-PASS5)

**Date:** 2026-10-23 (re-check at **12:35–12:50 UTC**) · **Chain:** THORChain app layer (`thorchain-1`, CosmWasm) · **Status:** read-only; no transaction signed or sent.
**Scope:** *status verification only.* The exploit path was reconstructed in [`EXPLOIT-PATH.md`](EXPLOIT-PATH.md) (ZH4-PASS3, PoC 4/4) and is **not** redone here. This document answers: **is the bug live right now — did v3.21.0 execute, is the wasm halt lifted, has the FIN code migrated?**

---

## 1. TL;DR — the three questions

| Question | Answer (at 2026-10-23 ~12:50 UTC) | Evidence |
|---|---|---|
| **Did v3.21.0 execute?** | **NO.** Height **28,364,946–28,365,015** vs upgrade height **28,366,100** → **~1,085 blocks (~1.9 h) away**. Version still **3.20.3**; upgrade **3.21.0 approved** (71.17%). | `/thorchain/version`, `/thorchain/block`, `/thorchain/upgrade_proposals` |
| **Is the wasm halt lifted?** | **NO — still halted.** `HALTWASMGLOBAL = 1` (since 2026-09-26). Base layer live (`HALTTHORCHAIN=0`, `HALTTRADING=0`). **No node Mimir votes** for `HALTWASMGLOBAL` → no unhalt in flight. | `/thorchain/mimir`, `/thorchain/mimir/nodes_all` |
| **Has the FIN code migrated?** | **NO.** **58** pairs on code **196** (`5CC7E136…E071` = fin v2.2.2, **unpatched**), **1** on code **194** (`2CD5DC97…B606`). No new FIN code id. | `/thorchain/contracts`, `/cosmwasm/wasm/v1/code/{194,196}` |

> **Verdict: the bug is NOT live right now, and it is NOT patched.** It is in the same **E-U-conditional** state as the prior snapshot: frozen by the node-operator wasm halt, running the pre-exploit code, with the fix (v3.21.0, private binary) still ~2 hours from activation and not independently verifiable.

---

## 2. Live state (exact)

Snapshot height **28,364,946** (2026-10-23T12:42:43Z), re-confirmed at height **28,365,015** (12:49:51Z).

### 2.1 Version / upgrade
| Item | Value |
|---|---|
| `current` / `next` | **3.20.3** / 3.20.3 |
| Upgrade proposal | **3.21.0**, height **28,366,100**, **approved: true** (71.17%) |
| Blocks remaining | **~1,085** (≈ **1.9 h** at ~6.2 s/block) → ETA ≈ **14:35 UTC** (public window 13:40–16:15 UTC) |
| Executed? | **No** — height < 28,366,100 and version ≠ 3.21.0 |

### 2.2 Halt state (authoritative: Mimir)
| Key | Value | Meaning |
|---|---:|---|
| **`HALTWASMGLOBAL`** | **1** | **All CosmWasm executions disabled** (FIN, Credit Accounts, Ghost, Staking, Merge) |
| `HALTTHORCHAIN` | 0 | base layer live |
| `HALTTRADING` | 0 | base-layer swaps live |
| `HALTSECUREDGLOBAL` | 0 | secured-asset deposits/withdrawals live |
| `HALTWASMCONTRACT-YEVLEC` | **0** | the FIN pair `thor1vk6trz…yevlec` — **not** individually halted (covered by the global flag) |
| `HALTWASMCONTRACT-JY3TQX` | 1 | `rujira-brune` (not FIN) |
| `HALTWASMCONTRACT-27DUYT` | 1 | `rujira-ghost-credit` (not FIN) |
| `HALTWASMCONTRACT-D5A6R5` | 0 | `liquidy-swap` |

**No active node votes to change `HALTWASMGLOBAL`.** `/thorchain/mimir/nodes_all` (7,262 entries) contains **zero** `HALTWASMGLOBAL` (or any `HALTWASM*`) votes — so the unhalt is not currently in flight; it can only happen after the v3.21.0 activation is coordinated.

### 2.3 FIN code state — unchanged / unpatched
| Code id | data_hash | FIN pairs | Note |
|---|---|---:|---|
| **196** | **`5CC7E1368AEE0E5A7877502CA6A090CA7AA4DFB10CAF3453AADCD035E1F2E071`** | **58** | fin **v2.2.2**, commit `3114257` — **byte-identical to the deployed exploit target; no patch** |
| 194 | `2CD5DC97B5DA032DCB35A0AC08E02A255BA5EFE8188D3298CDC8F69BD509B606` | 1 | the unattested `rujira-fin:btc-btc:tron-usdt` pair |

* The code 196 hash is **unchanged** vs the ZH4-PASS3 check → the wasm-layer patch has **not** been deployed via contract migration.
* Codes **197** (`5D694784…`) and **198** (`52D400BC…`) exist (same creator, the Rujira multisig `thor1hmfs…jw022`) but are **not** `rujira-fin`; **no new FIN code id** has been instantiated.
* **The v3.21 fix, if any, is therefore a base-layer (private-binary) change, not a contract migration** — consistent with `EXPLOIT-PATH.md` §3.

### 2.4 Live value (unchanged scope)
| Item | USD (local 12:42Z) | USD (CI 12:53Z) |
|---|---:|---:|
| FIN TVL (59 pairs) | **1,885,804.67** | 1,884,097.15 |
| **CCL range deposits (the transferable set, 1,198 ranges)** | **1,695,224.27** | 1,693,670.69 |
| Credit Accounts (459 contracts, 111 funded) | 915,747.92 | 913,983.52 |

*Priced at THOR pool prices + DefiLlama. The CCL book is frozen (no wasm execution since 2026-09-26), so only price marks moved. `analysis/state-live.json`, `ci-out/rujira-state.json`.*

---

## 3. Re-test of the forged-caller primitive — as far as tooling allows

The exploit primitive is **code-level**: `RangeMsg::Transfer` authorises on `sender == range.owner`, and `sender` is filled with `info.sender` (`ranges/execute.rs:184`, `contract.rs:87`/`190`). Its liveness depends **only** on (a) the deployed code hash and (b) whether the wasm layer can execute.

1. **Deployed code unchanged** → code 196 `data_hash` = `5CC7E136…E071`, **identical** to the PoC's vendored v2.2.2 build. The vulnerable primitive is still present verbatim on-chain.
2. **Execution blocked** → `HALTWASMGLOBAL = 1` disables every `MsgExecuteContract`, so no `Range(Transfer)` can be dispatched by anyone (unprivileged or not). **No live replay is possible** (and would violate the read-only rule).
3. **PoC re-run in CI** against the same v2.2.2 code (`ci/run.sh` → `cargo test -p rujira-fin exploit_poc`): the 4 tests (direct transfer blocked; owner transfer works; forged caller transfers+drains; contract-owned position transferred via execute-as-self) re-confirm the primitive and its impact. See §5.

**Result:** the primitive is **intact and reachable in principle**, but **not live** — gated solely by the halt and, after the upgrade, by the private-binary fix.

---

## 4. Classification

| Category | USD | Basis |
|---|---:|---|
| **E-U now** | **0.00** | `HALTWASMGLOBAL = 1` (high confidence) |
| **E-U-conditional** | **1,695,224.27** | CCL ranges if unhalted before the v3.21 fix is effective (medium confidence on reach) |
| H-O | 0.00 | no user self-service while halted |
| P | 1,885,804.67 | node operators control the unhalt; FIN admin = 3-of-4 multisig `thor1hmfs…jw022` |
| S | 2,801,552.59 | FIN + Credit Accounts frozen while halted |

**Status label: `E-U-conditional (still halted; code unpatched; upgrade pending)`.** Do not sum the categories (they overlap).

**What the on-chain state shows about the fix.** The v3.21.0 patch is a **private binary** ("DO NOT build from source", MR !5226); the public changelog lists no FIN item and `x/thorchain/handler_wasm_execute_contract.go` at tag `v3.21.0` still has **no `TxSignedBy` guard**. On-chain we can verify only that (i) the upgrade has **not** executed, (ii) the halt is **still up**, and (iii) the FIN contract code is **unchanged**. **Patch completeness cannot be verified from outside.** If v3.21 unhalts the App Layer with the FIN contract still on code 196 and the private base-layer fix is incomplete, the E-U-conditional **survives** the upgrade.

---

## 5. CI re-check

* Job: `ci/run.sh` → [1] read-only state collector (`analysis/collect_rujira.py`), [1b] `analysis/live_recheck.py` (halt votes / code ids / upgrade status), [2] `cargo test -p rujira-fin exploit_poc` against v2.2.2.
* **CI run: [39956741969](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39956741969)** — conclusion **success**, branch `rujira-fin`.
  * PoC: **4 passed / 0 failed** (`cargo test exit=0`) — the forged-caller primitive and contract-owner vector still reproduce against the unchanged deployed code.
  * State at CI height **28,365,049** (2026-10-23T12:53:23Z): version **3.20.3**, upgrade **3.21.0 @ 28,366,100 approved**, **`HALTWASMGLOBAL=1`**, FIN **59 pairs (196×58, 194×1)**, FIN **$1,884,097.15**, CCL **$1,693,670.69 / 1,198 ranges**, accounts **$913,983.52**.
  * Live re-check at height **28,365,056** (12:54:05Z): **`upgrade_executed = false`**, **`blocks_to_upgrade = 1,044`**, **`wasm_halted = true`**, **`code_unchanged_vs_v2_2_2 = true`**, **`node HALTWASM* votes: none`** → `classification = "E-U-conditional (still halted, unpatched code)"`.
* Results written to `ci-out/`: `rujira-state.json`, `live-recheck.json`, `live-recheck-console.txt`, `fin-poc.log`, `state-console.txt`; raw log in `ci-log.txt`; artifact copy in `ci-artifacts/`.

---

## 6. Trigger and monitoring (unchanged, now imminent)

1. **Primary:** `GET /thorchain/mimir` → **`HALTWASMGLOBAL` becomes `0`** (or `HALTWASMCONTRACT-YEVLEC` is lifted while global is 0).
2. **Version:** `GET /thorchain/version` → `current` becomes **`3.21.0`** (upgrade height **28,366,100**, ~1,085 blocks away at this check).
3. **Early warning:** any node vote for `HALTWASMGLOBAL=0` in `/thorchain/mimir/nodes_all` (none at this check), or a Rujira/THORChain restart announcement.
4. **Post-upgrade:** re-read the FIN pair code ids; if still **196/194** and the private-binary fix cannot be verified, treat the E-U-conditional as **open until a replay shows the path is dead**. Fork the unhalt height and replay the transfer path against a small CCL range (read-only; do not touch live contracts).

---

## 7. Caveats / blockers

- **Upgrade not yet executed** at the time of this check; the FIN fix cannot be verified from outside (private binary, no public exploit tx, no post-mortem).
- **No live replay possible** while halted; the PoC is a message-level reproduction of the primitive/impact, not an on-chain replay of the base-layer bug.
- **At-risk scope:** the 2026-09-26 incident hit **one team-owned** position; the $1.695M is the CCL-range book ceiling, not a per-range proof.
- **Prices move**; the CCL book is frozen (no wasm execution since 2026-09-26), so only the price marks changed since the prior snapshot.
- **Registry scope:** the code check covers the **59 registered** `rujira-fin` pairs.

*Read-only research; no mainnet transactions. Prepared 2026-10-23.*
