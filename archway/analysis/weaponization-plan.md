# CWA-2026-006 — weaponization plan (Phase 2, after trigger confirmation)

**Status 2026-10-06 (overnight):** the trigger is reproduced **end-to-end through stock
wasmvm 1.5.5** (Archway-exact): CosmWasm contract `p1drift` → `call stack exhausted` at
~65,373 iterations (16 B/iteration rsp drift); wasmvm 3.0.8 (patched) runs the same contract
cleanly for 300k iterations. What remains is converting the drift into a controlled write
primitive and a control-flow pivot (the part Hexens withheld from the article).

## What we know (measured, not assumed)

| Fact | Evidence |
|---|---|
| Drift = 16 B/iteration, deterministic | lab: trap at exactly 65,508 calls (1 MiB / 16); wasmvm: ~65,373 iters at 903.8e9 gas |
| **Write stream confirmed**: attacker-controlled qwords at addresses stepping −16 B/iteration | E1 (CI 37401168405): k0 `…1dbe98`→`…1bbe98`→`…19be98`, Δ=−131,072/8,192 iters; 7.4.2 constant |
| Shape: ≥6 live **computed** i64 + computed then-result + result-bearing `if` + host call + loop | 96-variant sweep; constants never spill (no GPR) |
| Drift survives Gatekeeper + Metering rewrite | p1drift runs through stock wasmvm 1.5.5 |
| Host imports run via `on_host_stack()` (stack switch) | wasmer-4.2.2 `function.rs:426` — probe blindness discovery |
| Fiber stacks: 1 MiB, pooled globally (`STACK_POOL: SegQueue<DefaultStack>`) | wasmer-vm `traphandlers.rs:898` |
| Pool layout: consecutive 1 MiB stacks contiguous with 4 KiB `PROT_NONE` guards | E2 (CI 37401168405) maps: 5× `[rw 1M][gap 4K]`; corosensei `DefaultStack` = `[guard][stack]` |
| Guard crossing: **sparse** write batches jump the guard | E3 hypothesis (CI 37402571943, in flight): call every K iters → batch step `16*K` ≥ guard → batches skip PROT_NONE |
| Trap on stack exhaustion is **clean** (`call stack exhausted`), not a process crash | harness exit=0 with error string |

## The exploitation model (public part)

1. Each iteration the generated code writes guest-controlled qwords at drifting rsp-relative
   addresses (the "write stream"); `release_locations_value` then moves rsp down 16 B.
2. Landing: `landing(i) = trigger_stack_hi - base_frame - phase - (16 * i)`.
3. Goal geometry: `[lower holder fiber][guard][upper trigger fiber]`; the stream crosses into
   the holder's **live return slot** and replaces it with a first-stage control value.
4. Pivot: `rsp` lands in the holder's **locals**, which contain the staged native chain.
5. The holder must be *suspended* (blocked on a host import) while the trigger drifts.
6. ASLR: the general design leaks JIT/text/heap/guard pointers; some proofs used **non-PIE**
   targets. Archway's node is a Go binary — Go defaults to **non-PIE** (`ET_EXEC`), which, if
   true for archwayd, fixes main-binary text addresses and makes a first-stage pivot to a
   fixed-address gadget viable without a leak.

## Phase-2 experiment ladder (CI-first, using the existing labs)

### E1 — Prove the write stream exists (wasmer lab) — ✅ DONE (CI 37401168405)
- Host callback scans the fiber stack for the controlled live values `(i<<32)|K`.
- **Result**: addresses step down exactly −16 B/iteration on 4.2.2 (k0 drift
  `0x…1dbe98 → 0x…1bbe98 → 0x…19be98`), constant on 7.4.2. The qword stream is real and
  calibrated: `landing(i) = k0_at(i0) − 16*(i − i0)`.

### E2 — Map the stack geometry (wasmer lab) — ✅ DONE (same run)
- 5 candidate mappings: five 1 MiB rw regions contiguous with 4 KiB gaps.
- wasmer `STACK_POOL` (global `SegQueue<DefaultStack>`) + corosensei `DefaultStack`
  (`[guard 4K PROT_NONE][stack 1M rw]`, stacks grow down) ⇒ `[lower][guard][upper]` is the
  natural adjacency of consecutive pool allocations.

### E3 — Guard-crossing semantics — ✅ DONE (CI 37408546733)
- Dense streams fault on the trigger's own guard → caught (`call stack exhausted`).
  **Phase-offset sparse streams skip the guard** (fault addresses in v4 = exactly the next
  batch position below the guard), and after **pool grooming** (concurrent warm-up executions
  + a sacrificial run) the trigger runs on a stack with a mapped neighbour directly below.
- **Result (v6): controlled qwords written into the neighbour stack** — `map_hits` shows two
  mappings, e.g. `0x…caff7000-0x…cb0f7000:7` (neighbour, contains k0) and
  `0x…cb1f9000-0x…cb2f9000:10` (trigger's own spill slots); no trap; streams ran to
  i=196k–326k. 7.4.2 control clean.

### E4 — Return-slot overwrite → pivot — ✅ OVERWRITE + HIJACK DONE (CI 37411885043)
- **Deliverable without concurrency**: contract-to-contract `query` gives a nested wasm
  execution on the same thread: outer A suspended in its querier host call while inner B runs
  on another pooled stack; FIFO pool + warm-up + sacrificial run arrange
  `[A holder low][guard][B trigger high]`.
- **Lab result**: holder suspended in `env.query`; trigger's sparse stream crossed B's guard
  and wrote 7 controlled qwords per batch into A's frame; with `iters = i_call+1` the trigger
  returns right after the crossing batch. **32/67 calibrated configurations corrupted the
  holder; 2 explicit control-flow hijacks** (fault_addr `0x1` and `0x559cabe179b0` after
  `NESTED trigger ok`).
- **E5 — controlled pivot value — ✅ ACHIEVED (CI 37423603709).** Live values are computed
  arbitrary constants (`(i×0)+C`, distinct per slot); the sweep found configurations where the
  holder resumes and jumps **exactly to the planted constant**:
  `CRASH fault_addr = 0x41414141414102` (24 more runs died from redirects; 2 more explicit
  crashes at `0x0` and `0x5643804f0320`).
- **E6 (final weaponization step): aim the pivot.** Replace the marker constant with the
  address of a chosen gadget/entry in **archwayd's non-PIE text** (`ET_EXEC`, entry `0x44f889`)
  — no ASLR leak needed for stage one; stage two relays computed pointers (article's design).
  Also required: the E4/E5 choreography expressed as two CosmWasm contracts (holder with a
  `query` to the trigger), pool warm-up/grooming inside the contract calls, and phase
  calibration against wasmvm (Metering changes the instruction stream slightly — the
  depth/phase constants must be re-measured through the wasmvm harness).

### E5 — Embedder reality check (wasmvm harness / Archway node)
- **Resolved in principle:** contract-to-contract `query` re-enters wasm on the same OS
  thread (wasmd `WasmQuery::Smart` → target contract `vm.Query`), while the outer execution
  stays suspended inside its querier host call. Combined with the global FIFO stack pool,
  the E4 geometry is reachable from a single committed transaction — no concurrency needed.
  Verify this end-to-end in the wasmvm harness (nested query between two contracts).
- **archwayd v10.1.0 is non-PIE** (`ET_EXEC`, entry `0x44f889`) → fixed-address first-stage
  pivot available.

## Decision gates

- **Gate A (E1–E3):** write stream + geometry confirmed on the lab engines → proceed to E4.
- **Gate B (E4–E5):** if a pivot is demonstrated in the lab *and* the holder/trigger geometry
  is reachable via wasmvm/wasmd execution → full end-to-end weaponization on the harness.
- **Gate C (economics):** extraction bound stays **$18.4k measured / $24–30k target**; if the
  weaponization stalls at Gate B, the fallback is a documented capability (no extraction).

## Operational guardrails

- No chain interaction beyond public reads until the contract is proven end-to-end in the lab
  and the exit rehearsal is done (user instruction).
- All heavy compilation/execution on GitHub Actions; local runs only for tiny pre-flight
  checks (contract conversion, single harness invocation).
- Burner funding only after Gate B passes.
