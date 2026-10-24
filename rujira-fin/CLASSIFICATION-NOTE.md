# Classification note — Rujira FIN (ZH4-PASS2)

**Live E-U today: $0.00.** `HALTWASMGLOBAL=1` at THORChain height 28,315,097 (base layer live); all 59 FIN pairs still code 196/194 with no patch migration. FIN **$1.88M**, CCL ranges **$1.69M/1,198**, Credit Accounts **$0.92M** — all frozen.

**E-U-conditional: up to ~$1.69M (medium confidence).** Trigger:
1. `HALTWASMGLOBAL` → 0 **before** the v3.21.0 upgrade (approved at height **28,366,100**, ~Oct 23 13:40–16:15 UTC), **or**
2. unhalt after v3.21 if the private binary's undisclosed security patches are incomplete.

**Caveats:** no public exploit tx/post-mortem; user-range reach unproven; the patch is a private binary with no FIN item in the public changelog. Keep as a conditional/monitor.

**ZH4-PASS3 (2026-10-21):** the exploit path is now reconstructed in [`EXPLOIT-PATH.md`](EXPLOIT-PATH.md). The owner check reduces to `info.sender == range.owner` (`ranges/execute.rs:184`, `contract.rs:87/190`); the bypass is app-layer caller authenticity (no second unchecked path in FIN). PoC 4/4 (CI [39664417601](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39664417601)). Numbers and trigger unchanged.

**ZH4-PASS5 live re-check (2026-10-23 ~12:55 UTC):** see [`LIVE-RECHECK.md`](LIVE-RECHECK.md). **v3.21.0 had not executed** (height 28,365,056 vs upgrade height 28,366,100, ~1,044 blocks / ~1.8 h away); **`HALTWASMGLOBAL=1` still up** (no node votes to unhalt); **FIN code unchanged** — 58 pairs on code 196 (`5CC7E136…E071`, unpatched), 1 on 194. **E-U now $0; E-U-conditional $1,693,670.69** (1,198 CCL ranges; FIN book $1,884,097.15). PoC re-ran 4/4, CI [39956741969](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/39956741969). Not patched, not live — same E-U-conditional, now hours from the upgrade window.

**ZH4-PASS6 post-unhalt live check (2026-10-24 ~12:58 UTC):** see [`LIVE-RECHECK-2.md`](LIVE-RECHECK-2.md). **v3.21.0 has EXECUTED and `HALTWASMGLOBAL=0`** — the App Layer is live again (resumed height **28,366,103**, 2026-10-23T14:44:47Z). **FIN code is UNCHANGED** — 58 pairs on code **196** (`5CC7E136…E071`, unpatched), 1 on 194; no new FIN code id (max code 198). The v3.21 fix is a **private base-layer binary** (`thornode-private`; public tag v3.21.0/develop carry **no `TxSignedBy` guard**) → **not verifiable from outside**. Full post-unhalt scan (12,064 blocks): 15,638 wasm execs, 119 FIN `range.*` messages, **0 `range.transfer`**, 0 range-owner changes. **E-U now $0 (medium confidence); residual $1,578,051.57** (1,199 CCL ranges; FIN book $1,800,656.85; Credit Accounts $905,194.84). `rujira-ghost-credit` (27DUYT) still halted. **Status: `UNVERIFIABLE — unhalted + unpatched code; fix is a private base-layer binary`.** PoC 4/4, CI [40096156847](https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40096156847).

---

## POST-UNHALT UPDATE (2026-10-24) — halt LIFTED; UNVERIFIABLE (not demonstrably live, not confirmably patched)

- **v3.21.0 EXECUTED**; **`HALTWASMGLOBAL = 0`** — the App Layer resumed at height **28,366,103 (2026-10-23T14:44:47Z)**, 3 blocks after the upgrade.
- **FIN code NOT migrated:** **58 pairs still on code 196** (fin v2.2.2, hash `5CC7E136…E071`, **unpatched**), 1 on code 194; full enumeration = 198 codes, max id 198, **no new `rujira-fin` code**.
- **The fix is a private base-layer binary** (MR !5226, "DO NOT build from source"); the public tag **v3.21.0** and `develop` carry **no `TxSignedBy`/`assertContractSender` guard** in `handler_wasm_execute_contract.go` ⇒ patch completeness **cannot be verified from outside**.
- **NO EXPLOITATION OBSERVED** in the full post-unhalt window (12,064 blocks, 28,366,100→28,378,163): **15,638 wasm execs, 119 FIN `range.*` messages, ZERO `range.transfer`**; range-ownership diff vs 2026-10-21 = **0 owner changes**. CCL book intact at **$1,578,051.57** (1,199 ranges).
- **Also:** `HALTWASMCONTRACT-27DUYT` (rujira-ghost-credit) **remains halted = 1** (24 h liquidation grace) ⇒ the credit-account liquidation vector is blocked; `rujira-fin` (YEVLEC) = 0.
- **Verdict: `UNVERIFIABLE` — E-U now $0; residual $1,578,051.57.** An unprivileged attacker **cannot be shown** to drain the CCL ranges right now, and **no drain has occurred in 24 h of live operation** (a meaningful negative signal that the private fix works) — but the fix itself can't be read.
- **Monitor:** any `range.transfer` event, range-owner change, FIN code migration, or CCL-book outflow.
