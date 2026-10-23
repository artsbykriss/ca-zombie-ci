# Escape Techniques for Wasmer Singlepass Miscompilations
## Research notes for local testing of CWA-2026-006 (wasmvm 1.5.5 / Wasmer 4.2.2)

- **Date:** 2026-10-06
- **Target environment:** Archway (`archway-1`) node, wasmvm **v1.5.5** → cosmwasm-vm **v1.5.8** → Wasmer **4.2.2** (`singlepass` + `cranelift` features; Singlepass is the production engine).
- **Scope:** read-only public research. No blockchain interaction, no node contact, no exploit delivery. This document is a test-planning input, not a PoC.
- **Confidence legend:** `[V]` verified against primary source (code/advisory fetched); `[S]` secondary source; `[U]` unverified/not found.

---

## 0. Executive summary

1. **CWA-2026-006 is a real, public CosmWasm advisory** `[V]`: "Sandbox escape in the Wasmer Singlepass compiler", Critical / fund loss, reported 2026-08-18, disclosed 2026-09-28. It states a crafted contract can escape the Wasm boundary and run native instructions in the node process, permitting unauthorized minting of native tokens. The advisory withholds the trigger ("More detail will be added here once chains have had a chance to upgrade") and the fix is a consensus-breaking upgrade to Wasmer 7 (`wasmvm 2.2.9 / 2.3.5 / 3.0.8`).
2. **The deployed Wasmer 4.2.2 contains the exact defect publicly documented by Hexens as "WASMageddon"** `[V]` (published 2026-09-29, the day after the CWA disclosure): `release_locations_value()` in `lib/compiler-singlepass/src/codegen.rs` calls `machine.adjust_stack()` (**`sub rsp`**) instead of `machine.restore_stack()` (**`add rsp`**). It is reached from the `Operator::Else` code path. Repeated result-bearing `if/else` cleanup inside a loop drifts the native `rsp` downward (~16 bytes/iteration in the observed shape), turning Singlepass output into an attacker-controlled qword write stream. In Wasmer's corosensei fiber model this can cross a guard page and corrupt a live return slot on an adjacent coroutine stack, yielding control-flow hijack and host-process RCE. Affected range: **Wasmer >= 2.1.0 and < 7.0.0**, which includes 4.2.2.
3. **RustLand (2021) could not be verified** `[U]`. Despite an extensive search (search engines, DEF CON/OffensiveCon/Black Hat/HITB archives, Talos blog sitemap + Wayback CDX, GitHub code/commit/repo search, SpeakerDeck, InfoconDB, YouTube, archive.org), **no public record of a talk titled "RustLand: A JIT Bug to Escape the WebAssembly Sandbox", or of a Wasmer/WebAssembly talk by Connor McGarr and/or Lilith Wyatt, was found.** Do not rely on remembered RustLand details. The actionable public equivalent for CWA-2026-006 is the Hexens research summarized in §3. (If the team holds non-public RustLand slides, add them to this file; the search evidence is listed in §1 so it is not repeated.)
4. **Recommended local approach** (§6–§9): a differential harness `Singlepass vs Cranelift` (same Wasmer 4.2.2) plus an interpreter oracle, fed by (a) a hand-built WAT pattern corpus ordered by likelihood and (b) `wasm-smith` fuzzing; confirm the `rsp` drift with an in-guest host-import probe that records native `rsp` per iteration; minimize with `wasm-tools shrink`; then replay through cosmwasm-vm 1.5.8 (with its Gatekeeper + Metering middlewares) to match production. All of it runs headless in GitHub Actions (§7).

---

## 1. RustLand — verification status

### 1.1 Claimed reference (as stated in the task)

> "RustLand: A JIT Bug to Escape the WebAssembly Sandbox", Lilith Wyatt / Connor McGarr, DEF CON 2021 / OffensiveCon 2021 — a Wasmer Singlepass bug allowing sandbox escape.

### 1.2 Search result: no public record found `[U]`

| Source searched | Query / scope | Result |
|---|---|---|
| Firecrawl Search, `websearch` | `"RustLand" WebAssembly/Wasmer/singlepass/JIT`, exact title phrase | No matching talk, slides, video, paper, or blog post |
| DuckDuckGo HTML/lite | `"A JIT Bug to Escape the WebAssembly Sandbox"` | "No results found" for the exact phrase |
| Bing, Brave, Google (multiple proxies/UAs) | same | No relevant result (bot walls or no match) |
| `media.defcon.org` DC29/DC30/DC31/DC32 presentation listings | full filename listings | No Wasm/Wasmer/RustLand/McGarr/Wyatt talk. DC30 has an adjacent talk: *Solana JIT: Lessons from fuzzing a smart-contract compiler* (Thomas Roth) |
| `defcon.org` DC29 speakers page | `mcgarr`, `wyatt`, `wasmer`, `webassembly` | No match |
| OffensiveCon archive | agenda 2019–2025 | **No OffensiveCon 2021 edition exists**; no RustLand in any archive |
| Black Hat US/EU/Asia 2021 briefings; HITB 2021 | wasm/wasmer/singlepass/rustland | No match |
| Cisco Talos blog | sitemap-posts.xml, Wayback CDX (2021-01→2022-06) | No RustLand / Wasm / Wasmer post |
| GitHub | code search `"RustLand"`, `"JIT Bug to Escape..."`, repo/commit search, `connormcgarr/*`, `Cisco-Talos/*` | Only unrelated projects (Wayland compositor, `scx_rustland` scheduler, etc.). Connor McGarr's public work is Windows kernel/browser exploitation; no Wasmer work |
| Wayback CDX | `connormcgarr.github.io` (1,839 URLs) | No RustLand path |
| SpeakerDeck, InfoconDB, HN Algolia, Reddit, Mastodon, media.ccc.de, archive.org | `RustLand` | No matching talk. Lilith Wyatt's indexed talks are Azure Sphere/IoT, not Wasm |
| Wasmer advisories/CHANGELOG/releases | 2021-era | No RustLand credit; no 2021 Wasmer JIT CVE (Wasmer CVEs are filesystem-sandbox issues: CVE-2023-51661, CVE-2024-38358) |

### 1.3 Conclusion and replacement source

- **No sourced summary of "RustLand" can be provided.** Any details circulating about it (bug, trigger pattern, exploitation) should be treated as unverified until primary materials are produced. It is possible the talk was never recorded/published, was at a non-indexed venue, or is being conflated with a different research effort.
- The **only public, technical, primary-source description of a Wasmer Singlepass sandbox escape** located by this research is **Hexens "WASMageddon"** (2026) — a later finding that matches the CWA-2026-006 shape and is directly actionable for local testing. It is summarized in §3.
- For general 2021-era Wasm JIT miscompilation methodology, the verifiable period sources are Wasmtime/Cranelift advisories (CVE-2021-32629) and the Wasm VM fuzzing literature in §4–§5.

---

## 2. CWA-2026-006 and the deployed stack

### 2.1 Advisory facts `[V]`

Source: <https://github.com/CosmWasm/advisories/blob/main/CWAs/CWA-2026-006.md> (commit `82e39dc7`, 2026-09-29).

- **Title:** "CWA-2026-006: Sandbox escape in the Wasmer Singlepass compiler"; Severity **Critical, fund loss**.
- **Affected:** wasmd ≤ v0.70.3, ≤ v0.61.14, ≤ v0.60.8, ≤ v0.54.9; wasmvm ≤ v3.0.7, ≤ v2.3.4, ≤ v2.2.8 (and, per the advisory, "versions outside the maintained lines are affected and will not be patched" — this covers 1.5.5).
- **Patched:** wasmd v0.70.4/v0.61.15/v0.60.9/v0.54.10 with wasmvm v3.0.8/v2.3.5/v2.2.9.
- **Description (quoted):** "A code generation defect in the Wasmer Singlepass compiler, which wasmvm embeds to execute CosmWasm contracts, allows a specially crafted contract to escape the WebAssembly execution boundary and run controlled native instructions inside the node process. On an affected chain this permits unauthorized minting of native tokens and permanent loss of user funds."
- **Delivery:** "store and instantiate a contract they control"; reachable by any funded account where `code_upload_access` / `instantiate_default_permission` allow it; "A contract already stored on chain by an attacker remains a path even where those parameters are restricted."
- **No configuration-only mitigation.** Restricting upload/instantiate raises the bar; only the patch removes the defect.
- **Patch:** "upgrades the Wasmer dependency to a version that no longer contains the defective code generation path"; Cosmos Labs holds a Wasmer 7 Singlepass license; patch is consensus-breaking.
- **Timeline:** report 2026-08-18 (Cosmos bug bounty, reporter `w3tm` via Immunefi); chains notified 2026-09-03; private patch 2026-09-10; updated patch 2026-09-16; public release/disclosure 2026-09-28.
- **Trigger:** deliberately withheld in the advisory `[V]`.

### 2.2 Deployed version mapping `[V]`

- Live Archway build deps: wasmvm v1.5.5 (hash-matched), wasmd v0.51.0 (Archway fork), cosmwasm-vm v1.5.8, Wasmer 4.2.2 (per the hash-matched module zip; see `analysis/version-evidence.md`).
- cosmwasm v1.5.8 `packages/vm/Cargo.toml`: `wasmer = { version = "=4.2.2", default-features = false, features = ["cranelift", "singlepass"] }` `[V]`.
- cosmwasm-vm 1.5.8 engine setup (`packages/vm/src/wasm_backend/engine.rs`) `[V]`:
  - `#[cfg(not(feature = "cranelift"))] let mut compiler = Singlepass::default();` — **Singlepass is the production/default engine**; `cranelift` is a build feature ("required for development on Windows").
  - `compiler.canonicalize_nans(true);`
  - Middlewares pushed in order: `Gatekeeper` (deterministic/feature gate), then `Metering` (gas).
  - Default memory limit: `MEMORY_LIMIT = 512` pages (32 MiB) via `LimitingTunables`.
- wasmer-vm 4.2.2 depends on `corosensei 0.1.2` `[V]` — Wasmer 4.x executes Wasm on corosensei fiber stacks, which is the stack geometry the Hexens exploit relies on.

### 2.3 The defect is present in Wasmer 4.2.2 (source-level proof) `[V]`

`lib/compiler-singlepass/src/codegen.rs` @ `v4.2.2`:

- **Call site — `Operator::Else`** (line ~2990–2993):

```rust
let frame = &self.control_stack.last_mut().unwrap();
let stack_depth = frame.value_stack_depth;
let fp_depth = frame.fp_stack_depth;
self.release_locations_value(stack_depth)?;   // <-- buggy cleanup
self.value_stack.truncate(stack_depth);
```

- **Buggy function — `release_locations_value`** (lines 363–416). The final lines:

```rust
let delta_stack_offset = self.machine.round_stack_adjust(delta_stack_offset);
if delta_stack_offset != 0 {
    self.machine.adjust_stack(delta_stack_offset as u32)?;   // BUG: sub rsp, delta
}
```

- **Correct sibling — `release_locations`** ends with the opposite:

```rust
if delta_stack_offset != 0 {
    self.machine.restore_stack(delta_stack_offset as u32)?;  // correct: add rsp, delta
}
```

- **x86_64 machine implementation** (`lib/compiler-singlepass/src/machine_x64.rs`, lines ~2158–2173):

```rust
fn adjust_stack(&mut self, delta_stack_offset: u32) -> Result<(), CompileError> {
    self.assembler.emit_sub(Size::S64, Location::Imm32(delta_stack_offset),
                            Location::GPR(GPR::RSP))      // rsp -= delta
}
fn restore_stack(&mut self, delta_stack_offset: u32) -> Result<(), CompileError> {
    self.assembler.emit_add(Size::S64, Location::Imm32(delta_stack_offset),
                            Location::GPR(GPR::RSP))      // rsp += delta
}
```

- `round_stack_adjust` is the identity on x86_64 (line 2154), so drift per released memory-backed slot is exactly **8 bytes**.
- `local_pointer()` is `RBP` (machine_x64.rs line 2213), i.e. spilled values are addressed RBP-relative while `rsp` is the register that drifts.

**Version comparison** `[V]`:

| Version | `release_locations_value` | Status |
|---|---|---|
| 4.2.2 (deployed) | present, ends with `adjust_stack` | vulnerable |
| 5.0.6 / 6.1.0 | present, ends with `adjust_stack` | vulnerable (matches Hexens range `< 7.0.0`) |
| 7.0.0 | function removed; replaced by `release_locations` → `release_stack_locations` using `truncate_stack` | fixed path (CWA patch goes further, to 7.4.2) |

Related upstream activity `[V]`:
- PR **#6881** "fix(Singlepass): fix releasing of many stack slots" (2026-08-13, cherry-picked from `wasmer-internal#10`), plus regression test `nested_blocks_with_large_br_table` (4,096 nested blocks + 10,000-entry `br_table`) in `tests/compilers/issues.rs`; merged 2026-08-18 — the same day the CWA report was received. Commit `87c38c04a8`.
- Wasmer 7.4.2 (2026-09-16) is the CWA patch target; it contains both the v7 refactor and these later stack-release fixes.

> **Note:** the Hexens article says the upstream remediation was published 2026-04-30 and that affected versions are `< 7.0.0`; the CWA patch ships 7.4.2. Treat "fixed in Wasmer 7.x (use the patched wasmvm release pair)" as the operational statement; do not assume every 7.0.x is clean for every stack-release sub-bug.

---

## 3. Hexens "WASMageddon" — detailed summary of the public Wasmer Singlepass escape `[V]`

- **Source:** <https://hexens.io/research/wasmer-sandbox-escape-rce> — "WASMageddon", Hexens, **published 2026-09-29**; author **Vahe Karapetyan** (`@kemmio`); credits SEAL911 and pcaversaccio for coordinated disclosure.
- **Affected:** Wasmer **>= 2.1.0 and < 7.0.0** (`codegen.rs`). Severity: Critical, sandbox escape / host-process RCE. Ecosystem: 200+ blockchain networks and forks by the article's estimate; delivery via committed transactions (all nodes) or RPC simulation (single node).
- **Public boundary:** the article intentionally omits contract emitters, exact offsets, gadget addresses, launch scripts, and PoC bundles; downstream end-to-end RCE PoCs were shared privately with affected vendors. Everything below is the level of detail that is public.

### 3.1 Root cause

Singlepass miscompiles a **result-bearing `if/else` cleanup path**:

1. At the Wasm `else` transition, the compiler calls `release_locations_value(stack_depth)` (codegen.rs).
2. For each released **memory-backed** (spilled) value slot, it correctly decrements its logical `stack_offset` bookkeeping (`self.stack_offset.0 -= 8; delta_stack_offset += 8;`).
3. It must then **restore** native stack space (`restore_stack` → `add rsp, delta`), as the non-value `release_locations` path does.
4. Instead it calls **`adjust_stack`** → `sub rsp, delta`. The native stack moves **down** by 8 bytes per released memory slot.

Result: repeated `else` cleanups inside a loop produce a deterministic **downward `rsp` drift**; the observed proof shape drifts **16 bytes per iteration** (2 released slots). Granularity is a property of the generated code shape: changing the import, adding preamble stores, or changing local pressure changes the phase.

**Minimal exploit-relevant shape (as published):**

```
loop:
    push controlled i64 values            ;; keep registers busy so the if-result spills to memory
    enter if (result i64)
    take then branch                       ;; result value is memory-backed
    reach else-transition cleanup with live result
    release_locations_value()
        -> BUG: native stack adjusted downward
    drop values
    call a host import                     ;; suspension point / frame churn
    repeat
```

This is **native stack corruption caused by code generation** — not a Wasm linear-memory bounds bug and not an application-level contract bug.

### 3.2 From miscompilation to a qword write stream

- The primitive is not only a moving `rsp`: the generated code **stores/pushes attacker-chosen qwords while `rsp` moves**.
- Conceptually, each iteration writes `ATTACK_VALUE0..ATTACK_VALUE7` (guest-controlled) at successively lower native addresses; `release_locations_value` then moves `rsp` down again.
- Landing model (target/build dependent): `landing(i) = trigger_stack_hi - base_frame - phase - (16 * i)`.
- After enough iterations the write stream exits the trigger fiber stack, **crosses a guard page**, and lands in a neighboring stack.

### 3.3 Coroutine stack geometry and the two-role choreography

Wasmer/corosensei executions use separate fiber stacks; the useful observed shape is a **1 MiB writable stack with a guard page**, stacks growing high→low. Required adjacency:

```
higher addresses   +----------------------------------+
                   | trigger fiber stack              |
                   | active Singlepass drift loop     |
                   | qword stream = pivot gadget      |  rsp drifts down
                   +----------------------------------+
                   | guard page                       |
                   +----------------------------------+
                   | holder fiber stack               |
                   | suspended host-import frame      |
                   | live return slot  <-- overwrite  |
                   | holder locals (ROP chain)        |
lower addresses    +----------------------------------+
```

Two guest-execution roles:

- **holder:** initializes ROP constants in its locals, calls a host import, and **suspends** on a fiber stack, later resuming through a return slot.
- **trigger:** runs the Singlepass drift loop on the **adjacent upper** fiber stack; its qword stream crosses into the holder and overwrites the holder's live return slot.

The holder must still be suspended when the trigger crosses into it.

### 3.4 Exploit engineering

1. **Allocator grooming** — the hard part is getting the runtime to hand out the pair `[lower holder stack][guard][upper trigger stack]`. The article uses Wasmer's coroutine stack pool/reuse, concurrent executions, host-import suspensions, warmup calls, and staggered phases ("armed holders", tapering population, waves, depth, barrier) to bias adjacency. Organic load can improve reliability.
2. **Race** — three events: holder suspended with a live return frame; trigger scheduled on the adjacent upper stack; drift reaches the holder's return slot before that frame disappears.
3. **Calibration** — per-target measurement of drift iteration count, qword-stream phase, live return-slot offset, safe pre-return corruption window, and post-pivot recovery. The pivot should land on the return slot as early as possible in the useful overwrite window.
4. **Control-flow impact** — the cross-stack overwrite is narrow: it changes **one return slot** to a first-stage control value; execution then pivots `rsp` into the holder's **locals**, which already contain the staged native control-flow chain. It does not try to lay a full payload with the write stream.
5. **ASLR** — some downstream proofs used non-PIE targets; the general two-stage design leaks JIT/text/heap/guard pointers from corrupted locals, derives bases (`base = leak - delta`, `stack_top = guard + size`), relays computed qwords through the embedder's ordinary call surface, and has the trigger load them from linear memory for the drift stream.
6. **Stability** — signal wrapping and post-write recovery keep the process alive long enough to observe a proof marker; the public success condition is "proof marker written + node remains healthy + runtime identity matches the intended binary."

### 3.5 Delivery surfaces (why CosmWasm is exposed)

- **RPC simulation:** a request that never goes on-chain; runs on one RPC node.
- **Block propagation:** a normal transaction included in a block; every validator/full node executes it as part of block processing.
- Mitigation recommendation in the article: `release_locations_value()` must restore stack space; upgrade to a fixed Wasmer release / Wasmer 7.x.

---

## 4. Catalogue of Singlepass / Wasmer miscompilation bug classes and trigger patterns

### 4.1 Wasmer Singlepass — direct evidence `[V]`

| # | Class | Root cause / trigger | Impact | Evidence |
|---|---|---|---|---|
| 1 | **Stack-release direction** (the CWA-2026-006 class) | `release_locations_value()` uses `adjust_stack` (`sub rsp`) instead of `restore_stack` (`add rsp`); reached at `Operator::Else`; needs memory-backed (spilled) result values and a loop | Native stack drift → cross-stack qword writes → control-flow hijack / host RCE | Hexens WASMageddon; codegen.rs v4.2.2/v6.1.0 |
| 2 | **Stack-slot release batching** | Deeply nested control flow + huge `br_table` caused one stack-truncation instruction per released slot (code size / release behavior); fixed by emitting a single `truncate_stack` for the total | Codegen correctness/size; same stack-release subsystem as #1 | PR #6881, commit `87c38c04a8`; test `nested_blocks_with_large_br_table` |
| 3 | **`call_indirect` miscompilation** | Indirect call to host functions from guest crates produced garbage `WasmerEnv`/env pointers on the host side (memory became `None`, fields pointed at garbage) | Host-side type confusion/crash; potential memory corruption | Issue #2329 (thedavidmeister), fix commit `9ecedc3925` (2021-07-29); older `Operator::CallIndirect` miscompile fix `ee9ddb18fc` (2020-02-06) |
| 4 | **`GetLocal` miscompile** | Register/location handling for `local.get` in certain shapes | Wrong values | Commit `c67405ffe5` "workaround for singlepass miscompilation on GetLocal" (2019-07-01) |
| 5 | **`release_locations` bug** | Location release bookkeeping/stack handling | Wrong codegen | Commit `a8b68bf8a7` "Fix singlpass release_locations function" (2021-12-15) |
| 6 | **Stack probing** | Function prologue stack probing (large frames) | Guard-page/probe miss | Commit `054e524001` "Fix stack probing in the singlepass compiler" (2022-02-25) |
| 7 | **Memory bounds / offset overflow** | Offset calculation overflow, dynamic memory bounds, guard-page skipping in memory traps | OOB access risk | Commits `510b56a31e` "Check memory offset calculation overflow", `ab3580fb0f` "Fix memory trap", `83a50a560e` "Fix stack guard page skipping" (2020) |
| 8 | **Null table entries** | `call_indirect` through a null/uninitialized table entry | Crash / wrong trap | Commit `27d715e7b3` "Fix call to null table entries" (2020-05-18) |
| 9 | **Multi-value handling** | Multi-value loops with no return type; multi-value returns not implemented in 4.2.2 (the Wasmer equivalence fuzzer explicitly skips "multi-value returns not yet implemented") | Rejected or miscompiled modules | Commit `6749487a83` (2026-03-23); `fuzz/fuzz_targets/equivalence.rs` skip list |
| 10 | **NaN canonicalization** | Missing NaN canonicalizations in Singlepass | Cross-engine result divergence (determinism), not directly an escape | Commit `bd5ac07acd` (2026-10-05) |
| 11 | **Compiler panic on odd modules** | e.g. `f32`-typed import/`f64` const shapes panicking in codegen | DoS (compile-time panic) | Issue #2347, fix `dc0dcd01d2` (2021-06-05) |
| 12 | **WASI/filesystem sandbox advisories** (not JIT) | Symlink/path traversal in Wasmer's WASI implementation | Host filesystem read/write outside preopen | CVE-2023-51661 / GHSA-4mq4-7rw3-vm5j (patched 4.2.4); GHSA-55f3-3qvg-8pv5 / CVE-2024-38358 |

> Wasmer's own fuzz suite (on `main`) contains targets named `singlepass.rs`, `equivalence.rs`, `deterministic.rs`, `metering.rs`, `misc.rs`, `cranelift.rs`, `llvm.rs` — evidence that singlepass-vs-cranelift differential testing is an established upstream practice. The `equivalence.rs` target asserts Singlepass/Cranelift/LLVM produce identical results for no-arg exports of `wasm-smith`-generated modules and supports `DUMP_TESTCASE=path`. (Verify target availability at tag 4.2.2; the `fuzz/` directory exists there, but the target set may need backporting.)

### 4.2 Adjacent Wasm JIT miscompilation classes (Wasmtime/Cranelift, for methodology) `[V]`

| Class | Advisory / CVE | Trigger | Consequence |
|---|---|---|---|
| Wrong extension (sign vs zero) of a stack-loaded value | CVE-2021-32629 / GHSA-hpqh-2wqx-7qp5 | Cranelift x64 new backend, specific load shape | Access up to 2 GiB before the heap; sandbox escape depending on heap impl |
| Address-mode arithmetic width | CVE-2023-26489 / GHSA-ff4p-7xrq-q5r8 | 35-bit effective address instead of Wasm's 33-bit | Guest-controlled OOB read/write up to ~34 GiB from linear memory |
| Divergent address computations | CVE-2026-34971 / GHSA-jhxm-h53p-jm7w (RUSTSEC-2026-0096) | aarch64 Cranelift miscompiles `load(iadd(base, ishl(index, amt)))` with constant `amt`; requires 64-bit memories (or memory64) and disabled spectre/signals-trap mitigations | Bounds check and load use different addresses → arbitrary host read/write; critical sandbox escape |
| Over-wide load | CVE-2026-34944 (f64x2.splat), CVE-2026-24116 (f64.copysign) | x86-64 Cranelift without SSE3/AVX loads 16 B instead of 8 B | Uncaught segfault or unused out-of-sandbox load |
| Winch baseline backend OOB | CVE-2026-34987 / GHSA-xx5w-cvp6-jv83 | aarch64 Winch address computation (PoC observed) | Access up to 32 KiB before/after linear memory |
| SIMD constant-shift bug | CVE-2023-41880 / GHSA-gw5p-q8mj-p7gh | `i64x2.shr_s` with constant shift > 32 | Wrong result (explicitly *not* a sandbox escape) |
| SIMD shuffle off-by-one | CVE-2023-27477 / GHSA-xm67-587q-r2vw | `i8x16.select` with same inputs, selected indices > 16 | Wrong result (not an escape) |
| Race → CFI/type-safety violation | CVE-2024-47813 / GHSA-7qmx-3fpx-r45m | Concurrent compilation/instantiation | CFI/type-safety violation |
| Pooling-allocator data leakage | CVE-2026-34988 / GHSA-6wgr-89rj-399p | Reused linear-memory slot / OOB load that no longer faults | Cross-instance data leak |
| Instruction-lowering correctness | GHSA-jhxm-h53p-jm7w + Bytecode Alliance 2026-04-09 batch | 11 of 12 advisories found with an LLM-based multi-agent harness targeting native codegen (Cranelift/Winch) | Multiple critical escapes |

**Lessons from the catalogue:**

- The highest-severity class is **address/bounds divergence**: a miscompiled value is used to compute an address that is bounds-checked, while the actual load/store uses a different address (or an address with more bits). This directly yields host arbitrary read/write.
- The second class is **native stack corruption** (the CWA-2026-006/Hexens class): the JIT emits wrong `rsp` arithmetic, and the host stack below the guest frame is corrupted.
- Pure wrong-result miscompiles (SIMD shifts, selects) do **not** escape by themselves; they matter when the wrong value feeds an address, a length, or a type tag.
- Modern discovery increasingly mixes differential fuzzing with LLM/agent-assisted code review (Wasmtime's April 2026 batch), but differential execution remains the ground-truth oracle.

---

## 5. General JIT-miscompilation exploitation methodology

### 5.1 Finding miscompilations

1. **Differential testing / equivalence oracles.** Compile the same Wasm with two (or more) engines or backends and compare observable behavior: return values (bit-exact for floats), traps, and side effects. Practical oracle pairs:
   - `Singlepass` vs `Cranelift` vs `LLVM` within the same Wasmer version (Wasmer's `equivalence` fuzz target does exactly this).
   - Wasmer Singlepass vs an interpreter (`wasmi`) or the Wasm spec interpreter (`wasmtime`'s differential target runs `wasmtime`, `wasmi`, `spec`, `v8`, `winch`, `pulley`; env var `ALLOWED_ENGINES=wasmi,spec`).
   - Wasmer Singlepass vs Wasmtime Cranelift (different implementations catch different bugs).
   - `canonicalize_nans(true)` on the oracle to avoid false positives on NaN payloads.
2. **Structure-aware fuzzing.** `wasm-smith` generates syntactically valid, semantically plausible modules from a byte seed; with `cargo-fuzz`/libFuzzer this gives coverage-guided search over valid Wasm. Extend it with custom `wasm_smith::Config` (instruction count, types, memory, etc.).
3. **Pattern/grammar-based trigger generation.** When the suspected root cause is a specific codegen path (e.g. `else` cleanup), enumerate the shapes that reach it: `loop × {if/else with result, br_table, select, call_indirect}` × spill pressure (live values/register exhaustion) × value types (i32/i64) × host-import call presence. This is far more effective than random Wasm for a known-suspect code path.
4. **Transformations that preserve validity but shift codegen.** Wasm-to-Wasm mutations that keep stack semantics but change register pressure/control flow (`wasm-tools mutate`, custom stack-invariant transformations à la Waltzz) are effective at hitting allocator/spill bugs.
5. **Root-cause triage.** Once a differential failure is found, disassemble the emitted code (`wasmer` has a `--compiler-debug-dir` / debug facilities; `wasm-tools objdump`; `objdump`/`gdb` on the JIT buffer) and minimize the module (`wasm-tools shrink`) before deciding whether the divergence is security-relevant.
6. **LLM/agent-assisted review** of codegen paths is now a practical complement (Wasmtime's April 2026 advisories), but must be validated with a concrete differential/repro harness.

### 5.2 Converting a wrong-computation bug into a sandbox escape

Common conversion routes, in order of observed severity:

1. **Bounds-check/address divergence → OOB host access.** A miscompiled value participates in address computation such that the checked address and the accessed address differ (or the address has extra bits). If guard pages do not cover the range, the guest gets read/write outside linear memory. Wasmtime's CVE-2023-26489 and CVE-2026-34971 are textbook cases. Exploitation: OOB read to leak JIT code pointers / host pointers / heap addresses; OOB write to corrupt a pointer or vtable; then ROP/JOP to an RWX JIT region or a chosen function pointer.
2. **Native stack corruption → control-flow hijack.** Wrong `rsp` arithmetic (Hexens) or stack-slot bookkeeping lets generated code write below the intended frame. In a fiber model, cross the guard page into an adjacent stack and overwrite a return slot; pivot into attacker-controlled data staged in another guest's frame. This is the route that matches CWA-2026-006.
3. **Type/signature confusion → wrong callee.** If a call/call_indirect or function-reference type check is miscompiled, the guest can invoke a function with the wrong signature/callee (e.g. V8's `WasmIndirectFunctionTable` sandbox bypass CVE-2023-2033; SpiderMonkey CVE-2026-2796 signature type confusion; the Wasmer #2329 env corruption). Exploitation: call a host function pointer with controlled arguments or corrupt a table entry.
4. **Validation/JIT disagreement.** The validator and the JIT consume different views of the same module (e.g. V8's wasm-streaming ReadableStream TOCTOU), so code runs that validation would reject. Exploitation depends on the disagreement.
5. **Data-only leaks.** Cross-instance leakage (pooling allocators) or OOB reads of host data can bootstrap ASLR bypass for one of the above.

### 5.3 Practical exploitation notes for the Singlepass class

- The drift is deterministic per code shape but the **useful landing point is target-specific** (embedder, compiler version, build flags, host-call path, coroutine stack layout).
- In CosmWasm, the compiled module is **not** the uploaded module: the `Gatekeeper` and `Metering` middlewares rewrite/validate it first. Any trigger must survive instrumentation. `Metering` inserts gas checks (globals + branches) at operator boundaries but does not change block types; `Gatekeeper` rejects disallowed features (§8).
- Gas limits bound loop iterations on-chain; the exploit must either reach the corruption within the gas budget or use simulation/RPC paths. For local testing, cap iterations yourself.
- The host is x86_64 Linux for Archway validators (the drift bug is generic; the Hexens article focuses on x86_64).

---

## 6. Candidate WASM patterns to test, ordered by likelihood

> All patterns below are **candidates to test**, not confirmed triggers. The #1 pattern is the published Hexens shape adapted to CosmWasm; the others are ranked by proximity to known Singlepass bug classes (§4). Build them as `.wat` files, run them through `Singlepass` and an oracle, and diff results *and* native-stack behavior (§7/§9).

### P1 — Result-bearing `if/else` with spilled result inside a loop (HIGHEST)

This is the Hexens shape: memory-backed value slots released at `Operator::Else` drive `adjust_stack` instead of `restore_stack`.

```wat
(module
  ;; a host import gives a suspension/frame-churn point each iteration
  (import "env" "db_read" (func $host (param i32 i32 i32) (result i32)))
  (memory 1)

  (func (export "run") (param $iters i32) (result i32)
    (local $i i32)
    (block $exit
      (loop $l
        ;; 1) live i64 values to exhaust GPRs, so the if-result below spills to memory.
        ;;    Tune the count upward until spills occur (Singlepass has a finite GPR pool).
        i64.const 0x1111111111111111
        i64.const 0x2222222222222222
        i64.const 0x3333333333333333
        i64.const 0x4444444444444444
        i64.const 0x5555555555555555
        i64.const 0x6666666666666666
        i64.const 0x7777777777777777
        i64.const 0x8888888888888888

        ;; 2) result-bearing if; the then-result should be memory-backed at the Else cleanup
        i64.const 1
        if (result i64)
          i64.const 0xAAAAAAAAAAAAAAAA
        else
          i64.const 0xBBBBBBBBBBBBBBBB
        end
        drop

        ;; 3) release the live values
        drop drop drop drop drop drop drop drop

        ;; 4) host call (suspension point in the cross-stack exploit)
        i32.const 0
        i32.const 0
        i32.const 0
        call $host
        drop

        ;; loop control
        local.get $i
        i32.const 1
        i32.add
        local.tee $i
        local.get $iters
        i32.lt_u
        br_if $l
      )
    )
    local.get $i
  )
)
```

**Variants to sweep:** number of live i64s (6–16); i32 vs i64 result; multiple results/`block (result i64)` nested around the `if`; `if` without `else` (no Else cleanup); `else` on both paths; host import before/after the `if`; loop nesting depth; `local.tee` instead of constants (to change allocator state); values produced by loads (to force different location kinds).

### P2 — `call_indirect` shapes (HIGH)

Historical Singlepass miscompiles involved `Operator::CallIndirect` and indirect calls to host functions (#2329, `ee9ddb18fc`). Test: tables with holes/nulls; `call_indirect` to imported host functions; type-identical but distinct signatures; `call_indirect` with arguments that require spilling; table index computed by i32 arithmetic near bounds; `call_indirect` inside `if`/`loop` with result values live.

### P3 — Local pressure / spills (`local.get`/`set`/`tee`) (HIGH)

The `GetLocal` workaround (2019) and `release_locations` fix (2021) show this area is fragile. Test: functions with many locals of mixed i32/i64; `local.tee` chains that force spill/reload; locals live across `if/else` and `br`; parameters spilled and reloaded; alternating `local.get`/`drop` to churn the location allocator.

### P4 — `br_table` and deeply nested control flow (MEDIUM-HIGH)

`br_table` was implicated in the 2026 stack-release fix (#6881). Test: large `br_table` (thousands of targets) in nested blocks; `br_table` with a result-bearing target; `br_table` inside `if` inside `loop`; many nested `block (result i64)` (the regression test uses 4,096); branch targets with different stack depths.

### P5 — `select` and mixed-width operands (MEDIUM)

`select` with spilled operands, i32 vs i64 select, select inside loops with live values, select feeding an address computation. (Cranelift's `i8x16.select` bug shows select lowering is error-prone; SIMD is not reachable in CosmWasm, but scalar `select` is.)

### P6 — Memory ops with large/edge offsets, `memory.grow`/`memory.size` (MEDIUM)

Historical fixes: offset-overflow check, memory trap, guard-page skipping. Test: loads/stores with `offset=0xFFFFFFFF` and computed addresses; `memory.grow` in a loop with `memory.size` checks; `memory.grow` returning -1; loads/stores immediately around the 512-page limit; unaligned accesses; `i64.load32_u`/`i32.load8_s` variants.

### P7 — i64 arithmetic edge cases (MEDIUM)

Shifts (`i64.shl/shr_s/shr_u`) with shift counts ≥ 64, rotates, `i64.div_s`/`rem_s` (`INT64_MIN / -1`), `i64.extend_i32_s/u`, `i32.wrap_i64`, `clz/ctz/popcnt`, comparisons feeding `select`/addresses.

### P8 — `unreachable` / `return` / dead code (LOW-MEDIUM)

Trap tracking and stack-state resets after `unreachable`/`return`; values left on the stack in unreachable code; `return` inside result-bearing blocks; `br` to function level.

### P9 — Multi-value blocks/loops (LOW, mostly rejected in 4.2.2)

`block (param i64) (result i64 i64)`, multi-value returns. Singlepass 4.2.2 reports "multi-value returns not yet implemented" in some paths; test whether the module is rejected, accepted-and-miscompiled, or accepted-and-correct. Not reachable from rustc today, but reachable from a hand-written module if validation allows.

### P10 — Bulk memory / SIMD / reference types / threads / EH (NOT reachable on-chain)

`memory.copy`, `memory.fill`, `table.*`, `v128` ops, atomics, exceptions are rejected by CosmWasm's `Gatekeeper` (§8). Keep them in the raw-Wasmer differential corpus only (to catch compiler bugs generally), not in the on-chain candidate list.

### P11 — Floats (LOW for escape, useful as differential canary)

`f32/f64` arithmetic, conversions (`i64.trunc_f64_s`), NaN handling. `canonicalize_nans(true)` is set in cosmwasm-vm; float miscompiles are mostly wrong-result class, but a wrong float→int conversion can feed an address/length. Useful for differential testing, low probability of a direct escape.

---

## 7. Recommended differential-testing setup (runs headless in GitHub Actions)

### 7.1 Tooling inventory

| Tool | What it does | How to use it here | Headless CI |
|---|---|---|---|
| **wasm-smith** (crate) | Structure-aware, valid Wasm generator; designed for `cargo-fuzz`/libFuzzer. `wasm_smith::Module` from a byte seed; configurable | Differential fuzz target: generate module → run both backends → compare | Yes (`cargo fuzz`) |
| **wasm-tools** (CLI) | `smith` (generate), `mutate` (valid module mutation), `shrink` (minimize a failing input), `validate`, `parse`/`print` (wat↔wasm), `objdump` | `wasm-tools smith --seed N -o m.wasm`; `wasm-tools mutate m.wasm -t`; `wasm-tools shrink crash.wasm -o min.wasm`; `wasm-tools validate --features=-simd` | Yes |
| **cargo-fuzz / libFuzzer** | Coverage-guided fuzzing harness for Rust | `cargo +nightly fuzz run equivalence --features=singlepass,cranelift` | Yes (nightly Rust) |
| **Wasmer `fuzz/fuzz_targets/equivalence.rs`** | Upstream differential target: Singlepass vs Cranelift vs LLVM on `wasm-smith` modules; `DUMP_TESTCASE=path` writes the generated wasm | Template for our harness; backport to a local crate pinned to `wasmer =4.2.2` if the target is not at tag 4.2.2 | Yes |
| **Wasmer `fuzz/fuzz_targets/singlepass.rs`** | Singlepass-only fuzz target | Regression fuzzing of the target backend | Yes |
| **wasmtime `differential` fuzz target** | Cross-engine oracle: `wasmtime`, `wasmi`, `spec` interpreter, `v8`, `winch`, `pulley` (`ALLOWED_ENGINES`, `ALLOWED_MODULES`) | Use Wasmtime's harness concepts; or run Wasmer Singlepass as the “engine under test” and `wasmi` as oracle in our own crate | Yes |
| **wasmtime `cranelift-fuzzgen`** | Generates Cranelift IR-level functions to hit codegen paths | Not directly applicable to Singlepass; useful for cross-checking Wasmtime only | Yes |
| **wasmi** (interpreter) | Fast, simple interpreter; good oracle | `wasmi` crate in the differential harness | Yes |
| **Spec testsuite (`wast`)** | Official semantics tests | `wasm-tools`/`wast` runner; Wasmtime `wast_tests` fuzz target as reference | Yes |
| **Waltzz** (USENIX Sec 2025) | Greybox Wasm runtime fuzzer with **stack-invariant transformations** and instruction-combination mutators; 20 bugs/17 CVEs | Ideas/code for mutators that preserve stack semantics while changing codegen | Yes (research prototype) |
| **RGFuzz** (2025) | Rule-guided differential fuzzer; uses compiler rules from one runtime to guide generation against another | Methodology reference for Singlepass-vs-Cranelift rule harvesting | Yes |
| **WRTester** (arXiv 2312.10456) | Differential testing via disassembly/reassembly of real-world Wasm binaries; root-cause location | Methodology reference | Yes |
| **OSS-Fuzz** | Continuous fuzzing service; Wasmer is an integrated project (`wasmer:universal_llvm` issues exist on `issues.oss-fuzz.com`) | Submit the differential target upstream or run `infra/helper.py` locally with Docker | Cloud, not GH Actions |
| **BH USA 2022 — “A Journey Into Fuzzing WebAssembly Virtual Machines”** (P. Ventuzelo) | Practical harness patterns across Wasm VMs | Reference deck | n/a |
| **DC30 — “Solana JIT: Lessons from fuzzing a smart-contract compiler”** (T. Roth) | Closest domain analogue: fuzzing a blockchain JIT compiler | Reference deck (media.defcon.org) | n/a |

### 7.2 Harness layout (suggested)

```
cwa-2026-006-lab/
├─ Cargo.toml                  # wasmer =4.2.2 (singlepass+cranelift), wasmi, wasm-smith, libfuzzer-sys
├─ src/
│  ├─ lib.rs                   # run_module(engine, wasm) -> {values|trap|panic}
│  ├─ engines.rs               # Singlepass (target), Cranelift (oracle), wasmi (oracle)
│  └─ probe.rs                 # host import that records native rsp (inline asm / frameaddress)
├─ fuzz/
│  ├─ Cargo.toml
│  └─ fuzz_targets/equivalence.rs   # adapted from Wasmer upstream
├─ corpus/                     # .wat/.wasm pattern corpus (P1..P11)
├─ tests/
│  ├─ patterns.rs              # runs corpus through both engines, asserts equality
│  └─ drift.rs                 # runs P1 with a probe import, asserts rsp does not drift
└─ .github/workflows/fuzz.yml
```

**The probe** is the key local detector for the CWA-2026-006 class: implement a host import (e.g. `env.probe`) that captures the native stack pointer on every call (`core::arch::asm!("mov {}, rsp", out(reg) rsp)` on x86_64, or `llvm.frameaddress`), returns it to the guest, and have the guest accumulate the per-iteration value. A vulnerable Singlepass run shows `rsp` decreasing monotonically inside the loop; Cranelift/wasmi show it stable. (The function epilogue may restore `rsp` at the call boundary, so measure *inside* the loop via the host import, not only before/after the exported call.) Also record whether the process survives a large iteration count, and run under `RUST_BACKTRACE=1`.

### 7.3 Commands

```bash
# 0) prerequisites
rustup toolchain install nightly
cargo install --locked wasm-tools cargo-fuzz

# 1) differential fuzz (target vs oracle), time-boxed
cd cwa-2026-006-lab
cargo +nightly fuzz run equivalence --features=singlepass,cranelift \
  -- -max_total_time=900 -rss_limit_mb=4096 -artifact_prefix=artifacts/

# 2) replay one failing seed and dump the wasm (wasmer upstream convention)
DUMP_TESTCASE=/tmp/crash.wasm cargo +nightly fuzz run equivalence artifacts/crash-...

# 3) minimize
wasm-tools shrink /tmp/crash.wasm -o /tmp/min.wasm
wasm-tools print /tmp/min.wasm

# 4) pattern corpus regression (no fuzzer)
cargo test --release --test patterns -- --nocapture
cargo test --release --test drift   -- --nocapture

# 5) corpus generation / mutation (optional, for CI)
wasm-tools smith --seed 1 -o corpus/gen-0001.wasm
wasm-tools mutate corpus/gen-0001.wasm -o corpus/mut-0001.wasm
wasm-tools validate corpus/mut-0001.wasm
```

### 7.4 GitHub Actions workflow (sketch)

```yaml
name: singlepass-differential
on: [push, pull_request, workflow_dispatch]
jobs:
  differential-fuzz:
    runs-on: ubuntu-latest            # x86_64 Linux == validator arch
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@nightly
      - run: cargo install --locked cargo-fuzz wasm-tools
      - uses: actions/cache@v4
        with:
          path: |
            fuzz/corpus
            fuzz/artifacts
          key: fuzz-${{ github.sha }}
          restore-keys: fuzz-
      - run: cargo fuzz build equivalence --features=singlepass,cranelift
      - run: cargo fuzz run equivalence --features=singlepass,cranelift
             -- -max_total_time=600 -rss_limit_mb=4096 -artifact_prefix=artifacts/
      - uses: actions/upload-artifact@v4
        if: failure()
        with: { name: fuzz-artifacts, path: artifacts/ }

  pattern-regression:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: cargo test --release --test patterns --test drift

  corpus-sweep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: cargo install --locked wasm-tools
      - run: |
          for f in corpus/*.wat; do
            wasm-tools parse "$f" -o "${f%.wat}.wasm"
            wasm-tools validate "${f%.wat}.wasm"
            ./target/release/diff-runner "${f%.wat}.wasm" || exit 1
          done
```

**CI notes**

- All of the above is headless; no display, no network, no chain access. Use `ubuntu-latest` (x86_64) to match Archway validators; add an ARM job (`ubuntu-24.04-arm` or QEMU) if you want to cover aarch64.
- `cargo-fuzz` needs nightly; keep the rest stable.
- Pin `wasmer = "=4.2.2"` and `wasmi` to known versions; commit `Cargo.lock`.
- Run fuzz jobs under a container/VM: a successful trigger is native memory corruption by design. `RUSTFLAGS="-Cdebug-assertions=on"` for the harness build, and consider a nightly ASan job (`-Zsanitizer=address`) — note JIT-emitted code is not instrumented, but host-side corruption is still detected.
- If a differential mismatch is found, **do not** immediately label it security-relevant: wrong-result bugs are common (see CVE-2023-41880). Check whether the wrong value reaches an address/length/type tag or the native stack (probe, guard-page crash, return-address corruption), then minimize.
- Optional: run the same corpus through cosmwasm-vm 1.5.8 (with `cranelift` feature as oracle vs default Singlepass) to validate that the trigger survives `Gatekeeper` + `Metering`.

---

## 8. CosmWasm contract perspective — what is expressible, and what exercises complex Singlepass codegen

### 8.1 The upload/validation path `[V]`

Source: cosmwasm v1.5.8 `packages/vm/src/compatibility.rs` and `wasm_backend/`.

- `StoreCode` parses the module and enforces:
  - **Supported imports** (only these): `env.abort`, `env.db_read`, `env.db_write`, `env.db_remove`, `env.addr_validate`, `env.addr_canonicalize`, `env.addr_humanize`, `env.secp256k1_verify`, `env.secp256k1_recover_pubkey`, `env.ed25519_verify`, `env.ed25519_batch_verify`, `env.debug`, `env.query_chain`, plus `env.db_scan`, `env.db_next`, `env.db_next_key`, `env.db_next_value` when the `iterator` feature is on (it is, in wasmvm 1.5.5).
  - **Required exports:** `allocate`, `deallocate`, `instantiate` (optional: `execute`, `query`, `migrate`, etc.), plus exactly one `interface_version_*` marker export (`interface_version_8`; `interface_version_7` only with the `allow_interface_version_7` feature).
  - A memory limit of 512 pages (32 MiB) is enforced through `LimitingTunables`; tables are limited as well.
- **A hand-written Wasm binary can be uploaded** if it satisfies the above. `MsgStoreCode` accepts raw bytes; Archway's live params are `code_upload_access = Everybody`, `instantiate_default_permission = Everybody` (`analysis/advisory-analysis.md`). So the full space of Gatekeeper-allowed Wasm constructs is reachable on-chain — subject to gas metering.
- **Middleware instrumentation happens before Singlepass compilation.** The final compiled code differs from the uploaded module:
  - `Gatekeeper` (deterministic feature gate) — allows the MVP instruction set and rejects: bulk memory ops, reference types, SIMD (`v128`), exception handling, threads/atomics. **Floats are allowed by default** (`allow_floats: true` in v1.5.8, despite the doc comment) and `canonicalize_nans(true)` is set.
  - `Metering` (gas) — injects gas accounting globals and checks around operators, adding branches/calls and changing register pressure. Any trigger must survive this rewrite; test through cosmwasm-vm, not only raw Wasmer, for on-chain fidelity.
- Because `Singlepass` is the default compiler and `cranelift` is only a build feature, **the same wasmvm code built with `--features cranelift` is a natural oracle** (but note it changes the production path; use only for testing).

### 8.2 Constructs expressible from Rust (`cosmwasm-std`) and from hand-written Wasm

| Construct | From Rust cosmwasm-std? | From hand-written Wasm? | Singlepass codegen path exercised |
|---|---|---|---|
| `loop`, `block`, `if/else`, `br`, `br_if` | Yes (every contract) | Yes | Control-flow lowering, label/stack-depth bookkeeping, **`Else` cleanup (P1)** |
| `br_table` | Yes (`match`, jump tables) | Yes | Branch table emission, label resolution, stack release (P2/P4) |
| `i32`/`i64` arithmetic, shifts, div/rem | Yes (`u32/u64/i32/i64`, overflow-checked ops) | Yes | ALU emission, width handling, trap paths |
| `select` | Rarely (LLVM may emit) | Yes | Select lowering, spill handling (P5) |
| `memory.grow`, `memory.size` | Yes (allocator growth) | Yes | Bounds/tunables, stack and register state (P6) |
| `call`, `call_indirect` | Yes (`call_indirect` for `dyn Trait`/fn pointers) | Yes | Trampolines, table/type checks, host-call env setup (P2) |
| `memory.copy`/`memory.fill` (bulk memory) | No (not enabled by default; rejected) | No (Gatekeeper rejects) | n/a on-chain |
| SIMD (`v128`) | Not by default; rejected | No (Gatekeeper rejects) | n/a on-chain |
| Reference types, threads, exceptions | No | No (Gatekeeper rejects) | n/a on-chain |
| Multi-value returns | Not emitted by rustc today | Yes (if accepted by validation) | Singlepass 4.2.2 reports "not yet implemented" in some paths (P9) |
| Floats (`f32/f64`) | Yes (allowed by default) | Yes | Float lowering, conversions (P11; mostly wrong-result class) |

### 8.3 Which constructs are the best use of testing time

Ordered by "complexity of Singlepass codegen × reachability from a CosmWasm contract":

1. **`if/else` with results + spills in loops** — the exact CWA-2026-006 class; trivially expressible from Rust and hand-written Wasm.
2. **`call_indirect`** — historically fragile, expressible from Rust (`dyn Trait`), and central to the host-boundary security model.
3. **Local-heavy functions with spills** — register allocator/spill logic is where Singlepass differs most from optimizing compilers.
4. **`br_table` + deep nesting** — control-flow/label/stack bookkeeping, implicated in 2026 fixes.
5. **Memory ops at edge offsets + `memory.grow`** — bounds/address computation, historically fixed bugs.
6. **i64 edge-case arithmetic** — cheap to test, feeds addresses/selects.

---

## 9. Concrete local test plan for CWA-2026-006

> Goal: reproduce the *codegen defect* (rsp drift / wrong stack cleanup) locally and determine whether the P1 pattern reaches native-stack corruption in the wasmvm 1.5.5 / Wasmer 4.2.2 stack. Do this in a disposable container with no network access; a successful trigger is native memory corruption by design.

1. **Build the differential harness** (§7.2) pinned to `wasmer = "=4.2.2"` with `features = ["singlepass", "cranelift"]`, plus `wasmi` as a third oracle. Confirm `Singlepass::default()` and `Cranelift::default()` both compile a hello-world module and agree.
2. **Add the `rsp` probe host import** and a guest loop that calls it each iteration. Run P1 with the probe under Singlepass and Cranelift. Expected result if the bug is present: Singlepass `rsp` decreases monotonically inside the loop (≈8 bytes per spilled released slot per iteration; 16 bytes in the published shape), Cranelift stays stable. This is a **safe, non-destructive confirmation** of the miscompilation.
3. **Run the P1 sweep** (live-value count, types, nesting, host call placement) and record drift per shape. Then run the P2–P8 corpus through the differential harness and log any result/trap mismatch.
4. **Escalate to stack-corruption observation**: increase iterations until Singlepass crashes with SIGSEGV (guard page) or corrupts a canary placed on the host stack below the JIT call. Correlate the crash address with the drift model. Keep Cranelift/wasmi controls.
5. **Replay through cosmwasm-vm 1.5.8** (crates.io `cosmwasm-vm = "=1.5.8"`, default features = Singlepass; a second build with `--features cranelift` as oracle). Feed the candidate as a stored contract (checksum + `Instantiate`) in the Rust test harness, or via the Go `wasmvm` API (`archway/harness/`). Verify the trigger survives `Gatekeeper` + `Metering` and respects the gas cap.
6. **Minimize** any confirmed trigger with `wasm-tools shrink`, print the WAT, and save it under `corpus/confirmed/`.
7. **Document the primitive**: which register/stack location is corrupted, what the attacker-controlled write stream contains, and whether the corosensei fiber adjacency assumption holds for wasmvm 1.5.5 (check `corosensei` version and stack pool behavior).
8. **Do not** build or run an end-to-end RCE against a live node. The scope here is codegen confirmation and defensive understanding; any weaponization work belongs to the vendor/chain remediation process.

**Success criteria:** (a) differential mismatch or probe-measured drift reproduced on 4.2.2 and absent on Cranelift/wasmi and on Wasmer 7.x; (b) minimized wasm artifact + WAT; (c) a written statement of whether the artifact survives cosmwasm-vm 1.5.8 instrumentation.

---

## 10. References

**CWA-2026-006 / CosmWasm**
- CWA-2026-006 advisory — <https://github.com/CosmWasm/advisories/blob/main/CWAs/CWA-2026-006.md> (commit `82e39dc7`)
- wasmvm v1.5.5 Cargo pins — `analysis/wasmvm155_Cargo.toml`; version evidence — `analysis/version-evidence.md`
- cosmwasm v1.5.8: `packages/vm/Cargo.toml`, `packages/vm/src/compatibility.rs`, `packages/vm/src/wasm_backend/{engine.rs,gatekeeper.rs,metering.rs,limiting_tunables.rs}`

**Wasmer / Singlepass**
- Hexens, "WASMageddon" (2026-09-29) — <https://hexens.io/research/wasmer-sandbox-escape-rce>
- Wasmer 4.2.2 vulnerable code — <https://github.com/wasmerio/wasmer/blob/v4.2.2/lib/compiler-singlepass/src/codegen.rs> (function at ~363–416; `Else` call at ~2993) and `machine_x64.rs` (~2154–2173)
- Wasmer 6.1.0 (still vulnerable) — <https://github.com/wasmerio/wasmer/blob/v6.1.0/lib/compiler-singlepass/src/codegen.rs>
- Wasmer 7.0.0 refactor (function removed) — <https://github.com/wasmerio/wasmer/blob/v7.0.0/lib/compiler-singlepass/src/codegen.rs>
- PR #6881 "fix releasing of many stack slots" — <https://github.com/wasmerio/wasmer/pull/6881>; commit `87c38c04a8`
- Singlepass history: `c67405ffe5` (GetLocal workaround, 2019), `ee9ddb18fc` (CallIndirect, 2020), `9ecedc3925` / issue #2329 (env corruption via call_indirect), `dc0dcd01d2` / issue #2347 (panic), `a8b68bf8a7` (release_locations, 2021), `054e524001` (stack probing, 2022), `6749487a83` (multi-value loops, 2026), `bd5ac07acd` (NaN canonicalization, 2026)
- Wasmer fuzz suite — <https://github.com/wasmerio/wasmer/tree/main/fuzz> (`singlepass.rs`, `equivalence.rs`, …)
- Wasmer advisories — <https://github.com/wasmerio/wasmer/security/advisories> (GHSA-4mq4-7rw3-vm5j / CVE-2023-51661; GHSA-55f3-3qvg-8pv5 / CVE-2024-38358)

**Wasmtime / Cranelift miscompilations (methodology analogues)**
- CVE-2021-32629 / GHSA-hpqh-2wqx-7qp5 — <https://github.com/bytecodealliance/wasmtime/security/advisories/GHSA-hpqh-2wqx-7qp5>
- CVE-2023-26489 / GHSA-ff4p-7xrq-q5r8 — <https://github.com/bytecodealliance/wasmtime/security/advisories/GHSA-ff4p-7xrq-q5r8>
- CVE-2023-41880 / GHSA-gw5p-q8mj-p7gh; CVE-2023-27477 / GHSA-xm67-587q-r2vw
- CVE-2026-34971 / GHSA-jhxm-h53p-jm7w / RUSTSEC-2026-0096 — <https://github.com/bytecodealliance/wasmtime/security/advisories/GHSA-jhxm-h53p-jm7w>
- CVE-2026-34944 / GHSA-qqfj-4vcm-26hv; CVE-2026-24116 / GHSA-vc8c-j3xm-xj73; CVE-2026-34987 / GHSA-xx5w-cvp6-jv83; CVE-2024-47813 / GHSA-7qmx-3fpx-r45m; CVE-2026-34988 / GHSA-6wgr-89rj-399p
- Bytecode Alliance, "Wasmtime's April 9, 2026 Security Advisories" — <https://bytecodealliance.org/articles/wasmtime-security-advisories>
- Wasmtime fuzzing docs — <https://docs.wasmtime.dev/contributing-fuzzing.html>; `fuzz/fuzz_targets/differential.rs`, `cranelift-fuzzgen.rs`, `wast_tests.rs`

**Tooling & fuzzing research**
- wasm-smith — <https://docs.rs/wasm-smith>
- wasm-tools — <https://github.com/bytecodealliance/wasm-tools> (`smith`, `mutate`, `shrink`, `validate`, `parse`, `print`)
- cargo-fuzz / Rust Fuzz Book — <https://rust-fuzz.github.io/book/cargo-fuzz.html>
- Waltzz (USENIX Security 2025) — <https://www.usenix.org/conference/usenixsecurity25/presentation/zhang-lingming>
- RGFuzz (2025) — <https://insuyun.github.io/pubs/2025/park:rgfuzz.pdf>
- WRTester (arXiv:2312.10456) — <https://arxiv.org/abs/2312.10456>
- P. Ventuzelo, "A Journey Into Fuzzing WebAssembly Virtual Machines", Black Hat USA 2022 — <https://i.blackhat.com/USA-22/Wednesday/US-22-Ventuzelo-A-Journey-Into-Fuzzing-WebAssembly-Virtual-Machines.pdf>
- T. Roth, "Solana JIT: Lessons from fuzzing a smart-contract compiler", DEF CON 30 — `media.defcon.org/DEF CON 30/DEF CON 30 presentations/Thomas Roth - Solana JIT Lessons from fuzzing a smart-contract compiler.pdf`
- Wasmer OSS-Fuzz presence (example issue) — <https://issues.oss-fuzz.com/478376814>

**RustLand search (negative result)**
- Searched: DDG/Bing/Brave/Google/Firecrawl, `media.defcon.org` DC29–32, defcon.org speakers, OffensiveCon archive (no 2021 edition), Black Hat 2021, HITB 2021, Talos blog sitemap + Wayback CDX, GitHub code/commit/repo/user search, Wayback CDX `connormcgarr.github.io`, SpeakerDeck, InfoconDB, HN Algolia, Reddit, Mastodon, media.ccc.de, YouTube. No primary or secondary record found (2026-10-06).
