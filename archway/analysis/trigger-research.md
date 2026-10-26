# CWA-2026-006 Trigger Research — Wasmer Singlepass sandbox escape

**Prepared:** 2026-10-06 · **Scope:** public, read-only research to narrow the private trigger so a local harness can test candidate WASM patterns.
**Advisory:** CosmWasm CWA-2026-006 (disclosed 2026-09-28), Critical / fund loss.
**Deployed target (Archway):** wasmvm v1.5.5 → cosmwasm-vm v1.5.8 → **Wasmer 4.2.2**, Singlepass, unpatched.

> **Headline finding.** The strongest public match for the CWA-2026-006 defect is Wasmer PR
> **#6879 “fix(security): add missing bounds check for static linear [memory]”** (merged
> 2026-08-13, cherry-picked from `wasmerio/wasmer-internal#5`). Its own description states:
> *“For `MemoryStyle::Static`, the compiler omits runtime bounds checks and relies on memory
> mappings to mark out-of-bounds addresses as `PROT_NONE`. Previously, only a 2 GiB guard
> region was allocated. With zero-extended offsets, addresses in the `[6 GiB, 8 GiB)` range
> could still be accessed.”* The fix doubles the static guard (2 GiB → 4 GiB; total protected
> region 8 GiB), and #6921 (internal#13) then made the “8 GiB + 1 page” reservation explicit.
> This is a memory-corruption → native-code-execution primitive of exactly the shape the
> advisory describes, and it was fixed in the Wasmer 7.3.0/7.4.x line that wasmvm 2.2.9/
> 2.3.5/3.0.8 pin (7.4.2).
>
> **Empirical confirmation (local harness, 2026-10-06).** On x86_64 Linux with a static memory
> (`(memory 1 512)`), the five public patterns behave as follows:
>
> | Target | 4.3.7 Singlepass | 4.3.7 Cranelift | 7.4.2 Singlepass | 7.4.2 Cranelift |
> |---|---|---|---|---|
> | base + 4 GiB | TRAP | TRAP | TRAP | TRAP |
> | base + 5 GiB | TRAP | TRAP | TRAP | TRAP |
> | base + 6 GiB | TRAP | **OK, reads host memory (`0x7f…0030`)** | TRAP | TRAP |
> | base + 7 GiB | TRAP | **OK, reads the placed sentinel page** | TRAP | TRAP |
> | base + 8 GiB − 2 | TRAP | TRAP (page-crossing) | TRAP | TRAP |
>
> On 4.3.7 Cranelift the +6 GiB page was already occupied by a host mapping (`mmap` returned
> `EEXIST`), so the guest **read live host memory outside the sandbox** — a direct,
> deterministic reproduction of the #6879 escape; +7 GiB read a harness-placed sentinel.
> On 7.4.2 **every sentinel mmap fails with `EEXIST`** because Wasmer now reserves the whole
> 8 GiB + 1 page range, and all ten runs trap. **Singlepass traps on every target in both
> versions**: its 32-bit `add` + carry trap prevents the [6,8 GiB) window, confirming the
> static analysis below. Harness source and raw outputs:
> `archway/harness/cwa006/`, `archway/analysis/cwa006-harness-{437,742}.txt`.
>
> **Caveat that the harness must resolve:** the advisory attributes the defect to *Singlepass*,
> but the public fix and the local differential reproduction show the escape on **Cranelift**
> (and LLVM by code inspection), while Singlepass x86_64/AArch64 traps. Either the advisory’s
> compiler attribution is imprecise (the version-range policy still made wasmvm “affected”),
> or the real wasmvm trigger is a different Singlepass defect fixed in the same 7.4.x upgrade
> (stack-slot / VMOffsets / table candidates below). The harness should test both.

---

## 1. Version chain and patch evidence

| Layer | Affected (CosmWasm lines) | Patched |
|---|---|---|
| wasmvm | ≤ 2.2.8 / ≤ 2.3.4 / ≤ 3.0.7 | 2.2.9 / 2.3.5 / 3.0.8 (2026-09-28) |
| cosmwasm-vm | 2.2.9 / 2.3.4 / 3.0.7 | 2.2.10 / 2.3.5 / 3.0.10 |
| **Wasmer** | **4.3.7** (2.2.x, 2.3.x) and **5.0.6** (3.0.x) | **7.4.2** |
| Archway deployed | wasmvm 1.5.5 → cosmwasm-vm 1.5.8 → **Wasmer 4.2.2** | no patch for 1.x line |

Evidence (all public):

- `CosmWasm/wasmvm@v2.2.9/libwasmvm/Cargo.toml` → `cosmwasm-vm = "=2.2.10"`;
  `CosmWasm/cosmwasm@v2.2.10/packages/vm/Cargo.toml` → `wasmer = "=7.4.2"`.
- `CosmWasm/cosmwasm@v2.2.9/packages/vm/Cargo.toml` → `wasmer = "=4.3.7"` (vulnerable side).
- `CosmWasm/cosmwasm@v3.0.7` → `wasmer = "=5.0.6"`; `v3.0.10` → `=7.4.2`.
- CosmWasm v2.2.9 has **no `[patch.crates-io]`**; wasmvm 2.2.9’s `Cargo.lock` checksums for
  `wasmer 7.4.2` (`91f52ac6…`) and `wasmer-compiler-singlepass 7.4.2` (`7df502a8…`) match
  crates.io exactly → **stock public Wasmer 7.4.2**, no private fork.
- Wasmer v7.4.2 diff vs v7.4.1 contains only the libunwind liveness fix — so the security fix
  is in **≤ 7.4.1**, most plausibly the 7.3.0/7.4.0 codegen/tunables fixes.

Releases/timeline:
- wasmvm 2.2.9/2.3.5/3.0.8 released 2026-09-28; CWA-2026-006 same day.
- CWA timeline: report 2026-08-18; chains notified 2026-09-03; private patch 2026-09-10;
  updated private patch 2026-09-16 (libunwind liveness fix); public 2026-09-28.
- Reporter: `w3tm` (Immunefi profile). No public write-up, PoC, or post found.
- Cosmos Hub: v28.1.0 interim (upload/instantiate restriction), v28.2.0 full fix via Prop 1055
  (2026-09-21). No exploitation reported on any chain.

---

## 2. Ranked candidate defects to test

### R1 — #6879: missing static linear-memory guard (internal#5) — **primary candidate**

- **PR:** https://github.com/wasmerio/wasmer/pull/6879
- **Commit:** https://github.com/wasmerio/wasmer/commit/1e62ffbf29 (2026-08-13)
- **Fix:** `lib/compiler/src/engine/tunables.rs` — `static_memory_offset_guard_size`
  2 GiB (`0x8000_0000`) → 4 GiB (`0x1_0000_0000`); bound → `WASM_MAX_PAGES` (65536 pages =
  4 GiB). Total protected VA: **6 GiB → 8 GiB**. Internal follow-up #6921
  (https://github.com/wasmerio/wasmer/pull/6921, internal#13) removed custom bound/guard
  values entirely and requires **8 GiB + 1 page** per static memory
  (`lib/vm/src/memory.rs`).
- **Mechanism:** `MemoryStyle::Static` memories omit runtime bounds checks and rely on
  `Mmap::accessible_reserved(current_size, bound + guard)` mapping the reserved tail
  `PROT_NONE`. A wasm32 effective address is `zero_extended(u32 index) + zero_extended(u32
  offset)`, i.e. up to `2^33 − 2 ≈ 8 GiB`. With a 6 GiB reservation, addresses in
  **[6 GiB, 8 GiB)** are outside the mapping: if any host allocation lives there (other wasm
  memories, heap, stacks, JIT code), the guest reads/writes host memory → sandbox escape →
  controlled native execution. Fix comment: *“negative base values for operations such as
  `i64.load` are zero-extended during expansion, making the full 4 GiB accessible.”*
- **Backend-level confirmation (public source):**
  - **LLVM (definitely vulnerable):** `lib/compiler-llvm/src/translator/code.rs`
    `resolve_memory_ptr` computes `offset = zext(var_offset) + zext(memarg.offset)` in i64
    (up to 8 GiB − 2) and, for `MemoryCache::Static`, emits **no bounds check at all** —
    just `getelementptr(base_ptr, offset)`. Protection is only the PROT_NONE reservation.
  - **Cranelift:** v7.3.0's static path (`bounds_checks.rs`) omits checks only when
    `u32::MAX <= bound + guard − offset_and_size`, which with 6 GiB already bounds the
    effective address ≤ 6 GiB; its explicit-check path is also sound. (The fix was still
    applied to shared tunables, and #6921 later removed Cranelift's static checks entirely.)
  - **Singlepass (x86_64/AArch64, 4.2.2/4.3.7/5.0.6/7.4.2):** `memory_op` zero-extends the
    index (`mov Rd, Rd`), then, if `memarg.offset != 0`, does a **32-bit `add Rd, imm32`
    followed by `jmp Carry → heap_access_oob`**. Carry means `index+offset ≥ 2^32` → trap;
    no carry means the effective address is < 4 GiB, inside the 4 GiB bound region. **On
    these targets the [6,8 GiB) window appears unreachable through Singlepass memory ops**
    — the harness must confirm this empirically before treating #6879 as the wasmvm trigger.
- **Why it may relate:** only commit in the window labelled `fix(security)`, cherry-picked
  from the private internal repo, timing fits (fix Aug 13; report Aug 18; upgrade-only patch
  Sep 10–16; public Sep 28), and it is the only fix that literally removes a
  sandbox-escape primitive by enlarging memory protection.
- **Caveat:** Singlepass x64/AArch64 32-bit-add + carry trap caps addresses at 4 GiB
  (see §4). On Singlepass the [6,8 GiB) window appears unreachable; Cranelift/LLVM are the
  demonstrably affected backends. Test both, and test whether any Singlepass opcode path
  bypasses the carry trap.
- **Patched-side confirmation (7.4.2, `lib/types/src/memory.rs`):**
  `MemoryStyle::static_bound() = Pages::max_value()` (4 GiB) and
  `static_offset_guard_size() = 4 GiB + WASM_PAGE_SIZE` — total reservation
  **8 GiB + 1 page**, so every possible wasm32 effective address (`≤ 8 GiB − 2`) is inside
  the PROT_NONE-protected reservation and must fault rather than reach a foreign mapping.
- **Concrete WASM patterns** (from the public regression test
  `tests/wast/wasmer/memory-load-offset-overflow.wast`, adjusted to force *static* style by
  adding a maximum, as CosmWasm’s `LimitingTunables` does):

```wat
(module
  (memory 1 512)                      ;; static style in Wasmer 4.x (max <= 4 GiB)
  (func (export "load-at-4gib") (result i64)
    (local $base i32) (local.set $base (i32.const -2147483648))
    (i64.load offset=2147483648 (local.get $base)))      ;; eff = 0x1_0000_0000
  (func (export "load-at-5gib") (result i64)
    (local $base i32) (local.set $base (i32.const -1073741824))
    (i64.load offset=2147483648 (local.get $base)))      ;; eff = 0x1_4000_0000
  (func (export "load-at-6gib") (result i64)
    (local $base i32) (local.set $base (i32.const -2147483647))
    (i64.load offset=4294967295 (local.get $base)))      ;; eff = 0x1_8000_0000
  (func (export "load-at-7gib") (result i64)
    (local $base i32) (local.set $base (i32.const -1073741823))
    (i64.load offset=4294967295 (local.get $base)))      ;; eff = 0x1_C000_0000
  (func (export "load-at-8gib") (result i64)
    (local $base i32) (local.set $base (i32.const -1))
    (i64.load offset=4294967295 (local.get $base)))      ;; eff = 0x1_FFFF_FFFE
  (func (export "store-at-7gib") (param i64)             ;; write variant
    (local $base i32) (local.set $base (i32.const -1073741823))
    (i64.store offset=4294967295 (local.get $base) (local.get 0)))
)
```

Harness procedure (differential, deterministic):
1. Instantiate with Singlepass on 4.2.2/4.3.7 and on 7.4.2.
2. Read the linear-memory base (`Memory::view(&store).data_ptr()`).
3. `mmap(MAP_FIXED_NOREPLACE|PROT_READ|WRITE)` a sentinel page at `base + 6 GiB`,
   `base + 7 GiB`, `base + 8 GiB − 2` (outside the 6 GiB reservation) and fill it with a
   magic value.
4. Call each function. **Escape = OK + magic value; fixed = trap.** (Unmapped windows trap on
   both builds, so the sentinel is essential; the upstream test alone cannot distinguish the
   versions.)
5. Repeat with Cranelift/LLVM to confirm the mechanism, and with two instances whose
   reservations are adjacent to model the real multi-contract node.
6. CosmWasm-shaped variant: use `LimitingTunables` (max = 512 pages or the wasmvm limit) so
   the module declares `(memory 1)` and still gets Static style.

### R2 — internal#10 / #6895: Singlepass stack-slot rounding (internal batch, report-day merge)

- **PRs:** https://github.com/wasmerio/wasmer/pull/6895 (fix, 2026-08-18),
  https://github.com/wasmerio/wasmer/pull/6881 (test, cherry-pick from `wasmer-internal#10`,
  2026-08-18); precursor #5918 (2025-11-27).
- **Fix:** `codegen.rs` stack-slot acquire/release now adjusts the native stack by the delta
  of *aligned* offsets, emitting one `extend/truncate_stack` per release. #6895 body:
  *“Previously, we rounded each stack allocation and so our stack usage got 2x bigger than
  necessary on platforms with 16B stack alignment requirement (AArch64 and RISC-V).”*
- **Why it may relate:** a stack-slot bookkeeping error is a direct route to corrupting the
  native frame/return address (“run controlled native instructions”). The internal test is
  precisely a stress pattern for many slots released at once (see §5). On x86_64 the old
  rounding was identity, so impact is expected on AArch64/RISC-V; a chain with ARM
  validators would still be critical.
- **Patterns to test:** 4096 nested blocks + a `br_table` with 10,000 targets (public test
  `nested_blocks_with_large_br_table`), plus a `br_table` placed after thousands of live
  stack slots; compare native RSP/RBP deltas and artifact sizes on 4.3.7 vs 7.4.2. Also test
  deep `if/else` with many values released per branch merge.

### R3 — #6880: wrong constant-folding flags in `emit_cmp` (x86_64)

- **PR:** https://github.com/wasmerio/wasmer/pull/6880 · **Issue:**
  https://github.com/wasmerio/wasmer/issues/6334 (wrong `CF` for unsigned comparisons;
  `AboveEqual` effectively always true). Merged 2026-08-13 → first in 7.3.0.
- **Why it may relate:** wrong comparison flags can miscompile control flow, including
  unsigned bounds/`br_table` dispatch. Public regression test:
  `tests/wast/wasmer/br_table.wast` (index `-1` must take the default).
- **Patterns:** `i32.const a; i32.const b; i32.lt_u/gt_u/le_u/ge_u` with both constants;
  `i32.const -1; br_table …`; `br_if` on constant comparisons. Expect wrong results on
  ≤7.2.x, correct on 7.3.0+. Escape potential: indirect only (no native primitive shown).

### R4 — #6904 / #7030: VMOffsets `u32→i32` overflow and table limits (internal batch)

- **PRs:** https://github.com/wasmerio/wasmer/pull/6904 (VMOffsets, 2026-08-20),
  https://github.com/wasmerio/wasmer/pull/7030 (cherry-pick of internal#16: `table.grow`
  boundary + local-table resource tracking; **not in 7.4.2**, landed in 7.5.0).
- **Why it may relate:** VMContext offsets ≥ `i32::MAX` used to wrap silently; wrong offsets
  in generated code are arbitrary read/write in the node process. Internal#16 is explicitly
  “properly communicated” (private-first) security work.
- **Reachability:** CosmWasm `WasmLimits` does not cap globals/tables counts, but contract
  size limits make a >2 GiB VMContext implausible; `table.grow`/`table.set`/`table.get` are
  rejected by the Gatekeeper (reference types). Low priority for CosmWasm, keep for
  completeness.

### R5 — Post-disclosure public Singlepass fix batch (not in 7.4.2; informs the audit)

- #7066 (atomics narrowing), #7069 (NaN canonicalization), #7079 (`value_size` for memory
  ops), issue #7080 (cmpxchg stack-slot overwrite), issue #7031 (narrow atomic RMW with wide
  immediate). All 2026-09-25…10-05. These are the *public* continuation of Singlepass
  hardening after CWA-2026-006; **none is in wasmvm 7.4.2**, and all require threads/atomics
  or SIMD, which CosmWasm’s Gatekeeper rejects — useful as negative controls, not as the CWA
  trigger.

### R6 — Multi-value / branch-handler miscompiles (older, lower)

- #6335/#6339 “branch handlers are off” (loops with params but no results skip
  `emit_loop_params_store`), #5884 “wrong code connected to multivalue”, #5918 (pre-stack
  fix). Wrong-value / potential infinite-loop classes; not an escape primitive by
  themselves. Multi-value blocks are reachable (engine has `multi_value = true`; only
  function results are limited to 1 by CosmWasm).

---

## 3. Advisory cross-reference (what is public)

- CWA-2026-006 text: https://github.com/CosmWasm/advisories/blob/main/CWAs/CWA-2026-006.md
  - “code generation defect in the Wasmer Singlepass compiler… escape the WebAssembly
    execution boundary and run controlled native instructions inside the node process…
    unauthorized minting of native tokens and permanent loss of user funds.”
  - “More detail will be added here once chains have had a chance to upgrade.” — **still not
    added as of 2026-10-06** (the file fetched still ends with that line).
  - Patch: “upgrades the Wasmer dependency to a version that no longer contains the
    defective code generation path”; “consensus breaking”.
- wasmvm changelogs only say “Bump cosmwasm to version 2.2.10 / 3.0.10” (no security
  details); cosmwasm-vm changelog says “Upgrade Wasmer to version v7.4.2 for maintenance
  line … (#2707/#2708/#2709)”. **No commit message anywhere says “fix Singlepass security”
  for the CosmWasm side.**
- Cosmos Hub weekly update (2026-10-01) repeats the advisory wording, adds nothing technical:
  https://forum.cosmos.network/t/hub-weekly-update-18-october-1-2026/17397

---

## 4. CosmWasm execution specifics (what the harness can reach)

- Engine: `wasmer::sys::Singlepass::new()`, `canonicalize_nans(true)`, Gatekeeper +
  Metering middlewares (`cosmwasm-vm …/wasm_backend/engine.rs`).
- **Memory style:** `LimitingTunables` (cosmwasm-vm) always sets a maximum (defaults it if
  absent) and delegates to `BaseTunables`; `limit_to_pages` caps at 65536 pages (4 GiB).
  With Wasmer 4.x defaults (`static_memory_bound = 4 GiB`), `maximum <= bound` ⇒
  **`MemoryStyle::Static` for every contract memory** ⇒ Singlepass emits **no bounds
  checks** (`codegen.rs`: `need_check = Static => false`) and relies on the PROT_NONE
  guard. (After #6921 all memories are static and reserve 8 GiB + 1 page.)
- **Gatekeeper (v1.5.8) rejects at the operator level:** floats, SIMD, relaxed SIMD, threads
  (atomics/shared memory), reference types (`table.get/set/grow`, `ref.*`), bulk memory
  (`memory.copy/fill/init`, `data.drop`), exceptions. Allowed: integer i32/i64 arithmetic,
  loads/stores (all widths, large `offset` allowed), `memory.size/grow`, locals/globals,
  `block/loop/if/br/br_if/br_table/return`, `call`, `call_indirect`, `select`, `drop`,
  `unreachable`, `nop`. ⇒ **The trigger must be an integer/control-flow/memory/call_indirect
  pattern.**
- Singlepass x86_64/AArch64 address math in 4.2.2/4.3.7/5.0.6 (`machine_x64.rs`,
  `machine_arm64.rs`): `emit_mov(S32, addr → tmp)` (zero-extend), then if `memarg.offset != 0`
  a **32-bit add + carry trap**, then 64-bit `base + tmp`; final access `[addr + 0]`. With
  `need_check=false` the bound compare is skipped, but the carry trap remains. Effective
  addresses are therefore capped at `4 GiB − 1` in these versions, i.e. inside the 4 GiB
  bound region (PROT_NONE beyond current size). **This is why the R1 [6,8 GiB) window may not
  be reachable via Singlepass on x64/ARM64 — verify empirically.**
- `call_indirect` (4.2.2/4.3.7): 32-bit `table_count` compare (`jbe` → trap), null check,
  signature check; conditions map correctly (`jbe/jae/ja`) — no obvious inversion found.
- `Mmap::accessible_reserved(accessible, reserved)`: maps `reserved` with `PROT_NONE` and
  `mprotect`s only the first `accessible` bytes RW; grow mprotects more. So the protected
  region = `bound + guard` and everything in it is either RW (current size) or faulting.

---

## 5. Known test cases / reproducers found

| Source | Content | Use |
|---|---|---|
| `wasmerio/wasmer` `tests/wast/wasmer/memory-load-offset-overflow.wast` (PR #6879) | 5 × `i64.load` patterns hitting 4/5/6/7/8 GiB with negative i32 bases + large offsets; `assert_trap` | **Primary R1 trigger** |
| `tests/compilers/issues.rs` `nested_blocks_with_large_br_table` (PR #6881) | 4096 nested blocks + 10,000-target `br_table`, asserts artifact < 1 MiB | R2 stress; exercises “many stack slots released” |
| `tests/wast/wasmer/br_table.wast` (PR #6880) | `br_table` unsigned index (`-1` → default), indices 0/1/2/42 | R3 |
| Issue #7031 WAT | `i32.atomic.rmw8.add_u` with `300` immediate; `i64` variant | R5 negative control (Gatekeeper rejects) |
| Issue #7080 | `i32.atomic.cmpxchg_8u` stack-slot/`emit_push` overwrite | R5 negative control |
| Issue #6239 | fuzzed multi-value import crash (assertion `left:4 right:1`) | crash class, not escape |
| `tests/wast/wasmer/loop-nan-canonicalization.wast`, `f32-abs-neg-nan-canonicalization.wast` | NaN canonicalization in loops / abs-neg | R5; floats rejected by Gatekeeper |

Prior Wasmer advisories/CVEs (all non-codegen, for completeness):
- CVE-2024-38358 / GHSA-55f3-3qvg-8pv5 — symlink bypasses filesystem sandbox.
- CVE-2023-51661 / GHSA-4mq4-7rw3-vm5j — filesystem sandbox not enforced (≤4.2.3).
- No GHSA/OSV entry exists for `wasmer-compiler-singlepass` or any Singlepass codegen bug.
  Wasmer has no public security-advisory process for codegen defects (pre-2026); this is why
  #6879’s `fix(security)` label and internal-repo cherry-pick are the key signals.

Historical Singlepass bug classes worth testing as negative controls:
- #2782 “OOB table access with singlepass backend” (2022), #2329 “Corruption of WasmerEnv
  when using call indirect to host fn from Wasm with Singlepass” (2021), #2721 static-data
  pointer corruption (2021), #6122/#6389 host-builtin signature/ABI mismatches
  (`wasmer_vm_memory32_copy`, `wasmer_vm_x` I64→I32 types, fixed Apr 2026), #6230
  `memory32_atomic_notify` signature, #6351 strict-boundary-checks config (RISC-V),
  #6334/#6880 wrong `emit_cmp` flags, #6335/#6339 loop params, #5918 stack dealloc rounding.

---

## 6. Wasmtime analogues (canonical miscompilation → escape patterns)

- **CVE-2023-41880 / GHSA-gw5p-q8mj-p7gh** (RUSTSEC-2023-0091): Cranelift on x86_64
  miscompiled `i64x2.shr_s` when the shift amount is a constant > 32. The low 32 bits of the
  second 64-bit lane were taken from the low instead of high half. Not a sandbox escape
  (Wasmtime explicitly notes memory sandboxing unaffected) but the canonical wrong-value JIT
  bug; found by fuzzing; fixed in 10.0.2/11.0.2/12.0.2. Pattern:
  `v128.const i64x2 a b; i64x2.shr_s (const >32)` — SIMD, not reachable in CosmWasm.
- **CVE-2026-34971 / GHSA-jhxm-h53p-jm7w** (Apr 2026): Wasmtime Cranelift aarch64
  miscompiled `load(iadd(base, ishl(index, amt)))` with constant `amt`; the bounds-check
  address and the load address diverged → guest passes a bounds check then loads a different
  address → **arbitrary host read/write, sandbox escape**. Conditions: aarch64, 64-bit wasm
  memory (memory64, default on), Spectre mitigations/signals-based traps disabled.
- **CVE-2026-34987** (Apr 2026): Wasmtime Winch aarch64 (x86-64 theoretical) assumes a 32-bit
  memory offset stored in a 64-bit register has its upper bits cleared when it may not →
  access before/after linear memory (up to ~4 GiB past start), “potentially arbitrary RCE
  with a write”. This is the closest public analogue to R1: *zero-extension of a 32-bit
  offset feeding a 64-bit address computation*.
- “WASM Was Not the Boundary: Sandcastles, Not Sandboxes”, DEF CON 34 (2026-08-07) — general
  argument that wasm sandboxes are weaker boundaries than assumed; no Wasmer Singlepass PoC.
- **The “RustLand” talk could not be confirmed.** No DEF CON/CON talk by that name about
  Wasmer or Singlepass exists in the searchable record; “RustLand” is a Linux scheduler
  project (scx_rustland) and an unrelated webcomic. Treat this reference as unverified.

---

## 7. Explicit uncertainty / what could NOT be found publicly

1. **Exact trigger is private.** CWA-2026-006 still ends with “More detail will be added once
   chains have had a chance to upgrade.” No PoC, no Wasmer advisory/CVE, no GHSA/OSV entry,
   no write-up by the reporter (`w3tm`), no technical detail in wasmvm/wasmd/Cosmos forum.
2. **Singlepass vs Cranelift attribution is unresolved — now empirically narrowed.** The
   advisory says Singlepass; the best-matching fix (#6879) is in shared tunables and
   demonstrably matters for the 33-bit address paths. The local harness (2026-10-06) shows:
   4.3.7 Cranelift escapes at +6/+7 GiB, 7.4.2 traps at every target, and **Singlepass traps
   on all five patterns both before and after the fix**. So the public fix is confirmed as a
   Cranelift (and LLVM-by-inspection) sandbox escape, but a Singlepass reproduction was not
   obtained with the public patterns. If CWA-2026-006 is genuinely Singlepass-only, its
   trigger is still private and must be sought in the other Singlepass candidates (R2–R6) or
   an unknown path not covered by the carry trap.
3. **Private Wasmer internal repo (`wasmerio/wasmer-internal`) is not readable.** Only the
   public cherry-picks reveal internal PRs #5 (#6879), #10 (#6881/#6895), #13 (#6921), #16
   (#7030). Internal PRs #1–4, 6–9, 11–12, 14–15 are unknown; one of them could be the true
   Singlepass fix.
4. **7.4.2 contains no visible Singlepass codegen change**, so the patch is an
   upgrade-to-a-version-that-already-contains-fixes, not a new fix. Which exact commit the
   CWA refers to cannot be proven from the public diff alone.
5. **The upstream regression test is weak**: it asserts a trap, which also happens pre-fix
   when the [6,8 GiB) window is unmapped. A real reproducer needs a sentinel mapping (or
   allocator adjacency) — the harness must place one.
6. **Archway’s exact exposure** (Wasmer 4.2.2) depends on whether the trigger is the guard
   bug (then Singlepass carry trap may save x86_64 while ARM validators remain at risk) or a
   different Singlepass defect (then x86_64 too).
7. **Atomic/SIMD/table candidates are unreachable in CosmWasm** (Gatekeeper), so the many
   post-disclosure atomic fixes cannot be the CWA trigger even though they are Singlepass
   codegen defects.

---

## 8. Harness plan (summary)

Working differential harness created during this research (Rust, local only), preserved at
`archway/harness/cwa006/` (`wasmer437/`, `wasmer742/`) with raw outputs at
`archway/analysis/cwa006-harness-{437,742}.txt`. It runs the five
`memory-load-offset-overflow` patterns on **Singlepass and Cranelift**, one target per process
(so an unmapped-page SIGSEGV cannot abort the matrix), with sentinel `mmap`s at
`base + {6,7,8} GiB`. Completed result: **4.3.7 Cranelift escapes at +6 GiB (live host
memory) and +7 GiB (sentinel); 7.4.2 traps on all 10 combinations; Singlepass traps on all
targets in both versions.** Extend with an LLVM build (`features = ["llvm"]`) to confirm the
public mechanism on the second affected backend, and with ARM64 CI for the stack-slot
candidate.

1. Differential runner: Wasmer **4.2.2** (Archway), **4.3.7** (2.2.x/2.3.x), **5.0.6**
   (3.0.x) vs **7.4.2**; Singlepass and Cranelift; static memory (`max = 512` or
   `LimitingTunables`); sentinel `mmap`s at `base + {6,7,8} GiB`; assert trap vs magic read.
2. Run the five `memory-load-offset-overflow` patterns plus `i64.store`/`i32.load` variants
   and offset-zero/high-index variants (`i32.const -1; i32.load`).
3. Run the `nested_blocks_with_large_br_table` pattern on ARM64 emulation/CI if available,
   and measure RSP deltas on x86_64.
4. Run `br_table`/constant-compare patterns for R3.
5. Confirm the deployed 4.2.2 behavior specifically (Archway is the unpatched target) —
   the carry-trap logic is identical to 4.3.7, but run it to be sure.
