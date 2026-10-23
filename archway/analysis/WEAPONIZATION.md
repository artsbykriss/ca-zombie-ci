# WEAPONIZATION.md — CWA-2026-006: from cross-stack data corruption to a directed control transfer

**Folder:** `archway/` · **Engine:** wasmvm **v1.5.5** → cosmwasm-vm 1.5.8 → **Wasmer 4.2.2** (Singlepass),
the exact Archway mainnet stack · **Scope:** read-only research + local/CI harness (no chain writes,
no signing, no broadcast) · **CI:** GitHub Actions `artsbykriss/ca-zombie-ci`, workflow `poc.yml`,
branch `archway`, job = `archway/ci/run.sh` → `archway/harness/campaign_wpn.sh`.

> **One-line status.** The prior campaign proved drift → guard-skip → cross-stack write → controlled
> values consumed by the unwinder (as **reads**), but no directed `RIP ← attacker value` in 40,471 runs.
> This document derives the *exact* control-transfer slot from the Wasmer/corosensei source, explains
> why every earlier sweep missed it, and reports the new targeted campaign.

---

## 0. Report card

| Milestone | Status | Evidence |
|---|---|---|
| **M1** arbitrary read / ASLR leak | **NOT ACHIEVED** | §6.1 |
| **M2** controlled write to a chosen native slot | **PARTIAL** — attacker qwords demonstrably reach a **saved-RIP slot** on the holder fibre; but the write is a **~6-qword batch**, so it cannot be made surgical | §6.2 |
| **M3** `RIP ← attacker value` | **NOT ACHIEVED** — and the structural reason is now **proven**, not conjectured | §6.3 |
| **M4** staged ROP/SROP → mapped mint call | **NOT REACHED** (gated on M3) | §6.4 |
| Blocker | **the crossing is co-requisite with a trap**: the same 6-qword batch that lands a plant on a saved RIP also corrupts an adjacent *data* slot, which faults first; wasmvm then unwinds the holder through the libgcc DWARF unwinder, which **reads and validates** the corrupted saved RIP instead of jumping to it. | §4, §6.3 |

**What is new in this report vs. the prior campaign**
1. A **source-derived** model of the exact control-transfer slot (corosensei `stack_call_trampoline`
   frame: `[X]` = return address into `on_stack`, `[X-8]` = saved RBP) — §2.
2. The prior "alignment gap" hypothesis is **tested and disproven** by direct measurement and a
   full-phase × full-depth sweep — §4, §6.3.
3. The blocker is pinned to a concrete mechanism: **batch coarseness (6 qwords) + co-requisite
   trap + unwinder read-not-jump**, with the faulting instruction disassembled from the captured
   crash — §6.3.

---

## 1. The target stack (source-derived)

### 1.1 The coroutine fibre

wasmvm executes every wasm entry through `wasmer_vm::trap::catch_traps` →
`on_wasm_stack` (`lib/vm/src/trap/traphandlers.rs:888`), which pops a **`corosensei::stack::DefaultStack`**
from a global `SegQueue` pool (`STACK_POOL`) and runs the wasm closure on it.
`DEFAULT_STACK_SIZE = 1 MiB` (`traphandlers.rs:44`).

Each `DefaultStack` is `[ guard 4 KiB PROT_NONE ][ stack 1 MiB rw ]` (stacks grow **down**).
Because the pool is a FIFO and the nested query allocates a **second** stack, the geometry is

```
 high  +------------------------------+  <- trigger fibre top (stack base)
       | trigger wasm frame + drift   |
       |   ... qword stream ↓ ...     |
       +------------------------------+  <- trigger fibre bottom (stack_limit)
       | trigger guard (4 KiB, NONE)  |  <- CROSSED by a sparse batch (skipped)
       +------------------------------+  <- holder fibre top (stack base)
       | holder frames (LIVE, suspended in a host import)
       |   ...                        |
       +------------------------------+
 low   | holder guard (4 KiB, NONE)   |
       +------------------------------+
```

`CoroutineTrapHandler::stack_ptr_in_bounds` (`corosensei/src/trap.rs:35`) is
`stack_limit <= sp < stack_base` and **includes the guard page**. A fault whose *address* is in
bounds is reported as `TrapCode::StackOverflow` ("call stack exhausted"); a fault whose *stack
pointer* is out of bounds makes `handle_trap` **return false** (`traphandlers.rs:800`) — wasmer does
not recover it (the signal falls through to the Go runtime). This is exactly the split the campaign
observed (clean `call stack exhausted` vs. raw `SIGSEGV` in cgo).

### 1.2 The drift (the bug)

`wasmer-compiler-singlepass 4.2.2`, `lib/compiler-singlepass/src/codegen.rs`:

* `Operator::Else` (`codegen.rs:2993`) calls `self.release_locations_value(stack_depth)`.
* `release_locations_value` (`codegen.rs:363`) ends (`codegen.rs:409`) with
  **`self.machine.adjust_stack(delta)`**.
* `adjust_stack` is `sub rsp, delta` (`machine_x64.rs:2159`). The twin `release_locations`
  (`codegen.rs:310`) correctly ends with **`restore_stack` = `add rsp, delta`** (`codegen.rs:358`,
  `machine_x64.rs:2167`). **This is the CWA-2026-006 defect.**

Inside a loop whose `if (result i64)` then-result is *memory-backed*, every `else` transition
moves the native `rsp` **down** by 8 B per released slot (measured: 16 B/iteration). The function
epilogue is `mov rbp→rsp ; pop rbp` (`machine_x64.rs:2523`), so the drift is **undone at function
exit** — the trigger returns normally; the drift only matters *within* the function.

### 1.3 Which writes actually drift

`local_on_stack` is `Memory(RBP, -offset)` (`machine_x64.rs:2224`) — **locals/spills are
RBP-relative and do not drift**. The only `rsp`-relative writes are in `emit_call_native`
(`codegen.rs:761`): `push_used_gpr` (one `push` per live GPR, `machine_x64.rs:2005`), the call's
return address, and the alignment padding. So the drift becomes an *attacker-controlled qword
stream* only at host-import call sites. With a **sparse** schedule (call every `spacing`
iterations) the batches are `16·spacing` bytes apart; at `spacing = 512` that is **8 KiB**, which
**skips the 4 KiB guard** and lands in the neighbour fibre. (Full batch layout:
`analysis/singlepass-batch-layout.md`.)

---

## 2. The control-transfer slot (NEW, source-derived)

The holder is suspended inside a host import. In Wasmer 4.2.2 a host import runs via
`on_host_stack` (`traphandlers.rs:943`) → `Yielder::on_parent_stack`
(`corosensei/src/coroutine.rs:495`) → `on_stack` → the asm trampoline
`stack_call_trampoline` (`corosensei/src/arch/x86_64.rs:244-275`):

```asm
stack_call_trampoline:
    push rbp            ; [X-8] = holder's saved RBP
    mov  rbp, rsp       ; rbp = X-8
    mov  rsp, rsi       ; switch to the PARENT (host/thread) stack
    call rdx            ; run the host import
    mov  rsp, rbp       ; rsp = X-8
    pop  rbp
    ret                 ; <-- pops [X] = return address into corosensei::on_stack
```

where `X` = the holder's `rsp` when `on_stack` called the trampoline.

**`[X]` is a live, `ret`-consumed control slot on the holder's fibre stack.** If the drift stream
overwrites `[X]` with an attacker value, then when the host import returns, `ret` jumps to that
value → **`RIP ← attacker value`** (M3), and `[X-8]` (the saved RBP) is the natural second-stage
pivot. This is the *direct* lane the Hexens write-up uses ("overwrite the live return slot; pivot
`rsp` into the holder's locals").

**Critical corollary:** the `ret` at `[X]` is only reached if the holder resumes **normally**
(the nested query returns `Ok`). If the nested query returns an `Err`, wasmvm unwinds the holder
and the frame is walked by `_Unwind_*` (DWARF), which **validates** the restored RIP (FDE lookup)
before using it — that is why the 643+ labelled marker events were *reads* (`a10` =
`cmpb $0x48,(%rax)` in libgcc) and never a jump. So the exploit needs the trigger to cross **and
return normally**, so that the holder resumes through the `ret`-based trampoline epilogue.

---

## 3. Why the trigger can cross *and* return normally

* The trigger's epilogue restores `rsp` from `rbp` (§1.2) → the trigger itself returns cleanly.
* The crossing batch lands in the holder **below** the guard; the subsequent `call`'s RA and the
  trampoline's `push rbp` also land in the holder (mapped) → no fault.
* So if the trigger's **last scheduled call is the crossing batch** and the loop then exits
  (`iters = crossing + 1`), the trigger returns `Ok`, the nested query returns `Ok`, and the holder
  resumes through the trampoline epilogue.

The prior campaign *did* set `iters = 65536 + R + 1` (exit right after the crossing) but the
holder still aborted. §4 sets out the hypothesis the earlier campaign drew from that (a depth gap);
§4b reports the direct test, which **disproves** it.

---

## 4. The alignment hypothesis (tested and disproven)

The stream is **quantized**: only every `spacing`-th iteration performs an `rsp`-relative write
(the call batch). At `spacing = 512` the batches land at depths
`δ, δ+8192, δ+16384, …` below the holder top, where `δ` is set by the phase (`r`).
A live return address at depth **D** is therefore hit only if

```
D ≡ δ (mod 8192)          (phase condition), and
the stream descends at least D bytes into the holder   (depth condition)
```

The prior sweeps always used `iters = 65536 + R + 1`, i.e. the trigger **exited right after the
first crossing batch** — so only the single topmost batch (`K = 0`, depth `δ ∈ [0, 8192)`) was ever
probed. If the holder's `[X]` sits **deeper than 8 KiB** below the fibre top (plausible: the chain
is fibre-entry → corosensei closure → `Instance::call`/`catch_traps` → wasm entry trampoline →
wasm frame → import trampoline → `on_host_stack` → `on_parent_stack` → `on_stack`), **no earlier run
could ever reach it.**

**The untried lever (this campaign):** continue the drift for `K` extra sparse cycles after the
first crossing (`iters = 65536 + R + 1 + 512·K`). The stream then sweeps depths
`δ, δ+8192, …, δ+8192·K`, so the pair `(R, K)` covers **every** depth. This is the first time the
`K > 0` region is explored.

### 4b. Result — the depth hypothesis is **disproven** (CI 40025548777)

The campaign ran `K ∈ {0,1,2,4,8,16,32} × R ∈ 0..511` (3 584 marker runs + 1 536 ud2 runs).
**The marker reads occur at exactly the same three phases `R = 237/238/239` for *every* `K`**
(15 labelled reads, all `addr=0x41410000000k`). Deeper batches add nothing. Direct measurement
(`-scanchain`, §5.1) explains why: **the holder's live frame chain is only ~0x320 bytes deep**
(all pointer-classified qwords on the suspended holder fibre lie in `[top-0x320, top]`), i.e. the
entire live frame chain sits inside the *first* 8 KiB window that the `K=0`/`K=1` crossing already
covers. There is no depth gap to exploit.

The residual question was therefore not *where* to aim but *what consumes* the aimed slot.

---

## 5. Experiments (all CI, `artsbykriss/ca-zombie-ci`)

### 5.1 Measurement — locate `X` (`-scanchain`)

New harness flag `-scanchain` dumps, while the holder is suspended in its host import (the Go
querier callback runs on the host stack), every qword on each ~1 MiB fibre that points into an
executable mapping (return addresses) or into a fibre (saved RBP), **with its offset from the fibre
top**, plus a dense dump of the top 0x180 bytes. A second run uses `--call-query` so the **trigger**
is also suspended and *both* live frame chains are visible.

→ output `ci-out/wpn/measure.txt`.

### 5.2 Deep-drift sweep

`harness/contracts/nested` holder→query→trigger; sparse `spacing=512`; plants = 16 distinct
canonical markers `0x41410000000k` (a hijack shows `PC=0x4141…`, a read `addr=0x4141…`).

* `K ∈ {0,1,2,4,8,16,32}` × `R ∈ 0..511`, `iters = 65536 + R + 1 + 512·K`.
* ud2 variant (`K ∈ {0,1,2}`): all plant slots = the harness's own `ud2` gadget address → an aimed
  hijack is an unambiguous **SIGILL**.
* Fixed control: wasmvm 3.0.8 / Wasmer 7.4.2 must be clean.

→ outputs `ci-out/wpn/sw-*.stderr`, classified in `ci-out/campaign_wpn.log`.

### 5.3 CI runs

| Run | Purpose | URL | Result |
|---|---|---|---|
| 40025548777 | measurement + deep-drift sweep (markers, `K=0..32`×512 phases) + ud2 (`K=0..4`) + fixed control | https://github.com/artsbykriss/ca-zombie-ci/actions/runs/40025548777 | **SUCCESS** (5 632 harness runs) |

Artifacts: `archway/ci-artifacts/result-archway/ci-out/{campaign_wpn.log,engine_source_check.txt,version_hash_check.txt,wpn/measure.txt,wpn/sw-*.stderr,wpn/sweep.log,wpn/fixed.json}`.

---

## 6. Milestone results (CI 40025548777)

Sweep totals (**5 632 runs**: 3 584 marker × 2 048 ud2): **HIJACKS 0 · SIGILL 0 · marker-reads 15 ·
holder-side crashes 656 · trigger-side crashes 0 · wasm-caught errors 153 · clean 4 808**.
Fixed control (wasmvm 3.0.8 / Wasmer 7.4.2): clean.

### 6.1 M1 — arbitrary read / ASLR leak — NOT ACHIEVED

The only consumption of attacker values through real wasmvm is the unwinder's **candidate-PC read**,
disassembled from the captured crash (run 40025548777, `mk-K1-R238`):

```
RIP   = libwasmvm+0x1583e   (libgcc_s _Unwind frame walk)
CODE  = ... 49 8b 84 24 98 00 00 00   mov 0x98(%r12),%rax
        80 38 48                      cmpb $0x48,(%rax)          <-- faults, addr=0x414100000002
        48 ba c7 c0 0f 00 00 00 0f 05 movabs $0x50fc0c7,%rdx     ; rt_sigreturn pattern
        48 39 50 01                   cmp %rdx,0x1(%rax)
        ...
        c6 83 a2 00 00 00 01          movb $0x1,0xa2(%rbx)       ; "is signal frame" flag
```
RAX = `0x414100000002` (our k2 marker), i.e. the marker landed on a **saved RIP** and the unwinder
read it. The read value is consumed entirely by the CFI/signal-frame logic and is **never surfaced**
to the guest: with mapped plants the same slot instead feeds a **wasm-level** access and the run
ends with `RuntimeError: out of bounds memory access` (153 runs). **Structural reason:** wasmer's
trap path re-enters through `setup_trap_handler`/`switch_and_reset`
(corosensei `x86_64.rs:507`, `trap.rs:67`), which *discards* the interrupted stack; nothing on that
path copies a host word back into wasm linear memory, and the response path is a fixed pointer.
No ASLR leak is obtainable this way.

### 6.2 M2 — controlled write to a chosen native slot — PARTIAL

**Achieved:** attacker-chosen qwords from the trigger's live GPRs are written at `rsp`-relative
native addresses stepping 16 B/iteration, and they **do land on a live saved-RIP slot** on the
holder fibre (`addr=0x41410000000k` at `R=237/238/239`, labelled by slot `k`). **Not achieved:**
making the write *surgical*. `emit_call_native` (`codegen.rs:800`) pushes **one qword per live
GPR** — 6 for this trigger — contiguously (`singlepass-batch-layout.md`). A 48-byte batch that
covers a saved RIP necessarily also covers its neighbours (saved RBP, spill slots), and it is the
neighbour that faults first (§6.3). Batch size is set by the number of live GPRs at the call, and
reducing it conflicts with the register pressure the drift itself requires (the then-result must
stay memory-backed at the `else`); this is the concrete open lever (§7, step 2).

### 6.3 M3 — `RIP ← attacker value` — NOT ACHIEVED (mechanism proven)

Evidence chain:

1. **The control slot exists and is reached.** `-scanchain` shows the suspended holder's frame
   chain, including the corosensei trampoline frame; the marker demonstrably lands on a
   **saved RIP** (`addr=0x41410000000k` consumed by the unwinder's `cmpb $0x48,(%rax)`).
2. **Deeper batches change nothing** (§4b): marker reads at the identical phases for all `K`.
3. **The primary fault is data corruption, not control.** In the marker runs the *reported* fault
   is the unwinder's read (a **secondary** fault); the primary fault is an adjacent corrupted data
   slot. In the 656 holder-side crashes without markers the fault addresses are incidental
   (`0x101000`, `0x100fc`, JIT/module pointers `…ded`), i.e. the drift's own values dereferenced as
   data — the crash PC is always the fixed JIT reader (`…a10`) or the push-fault (`…dd2`), never a
   plant.
4. **No `PC=0x4141…` anywhere**, and **no SIGILL** in 1 536 aimed-ud2 runs: the aimed gadget was
   never executed.
5. **The `ret` lane is unreachable.** `stack_call_trampoline`'s `ret` at `[X]` is only reached if
   the host import returns *normally*; the crossing is co-requisite with a trap (the trigger's
   stack-limit / the corrupted holder data slot), so wasmvm unwinds the holder through libgcc,
   which **validates** the restored RIP (FDE lookup) instead of transferring control to it.

**Verdict:** through real wasmvm 1.5.5 / Wasmer 4.2.2 the drift gives a *coarse, co-requisite-with-
trap* cross-stack write. It reliably reaches a saved-RIP slot, but the same batch corrupts a
neighbouring data slot that faults first, and the resulting unwind *reads* the corrupted RIP rather
than jumping to it. This is an architectural property of the primitive in this geometry, not an
alignment accident.

### 6.4 M4 — staged ROP/SROP → mapped mint call — NOT REACHED

Gated on M3. Mint targets are mapped and ready (`archway/mint/`,
`ci-artifacts/result-archway-mint/`): `(*BaseKeeper).MintCoins @0x1cb3720`,
`BaseKeeper.MintCoins @0x1c59cc0` (the real logic at `0x1c59aa0`),
`(*BaseKeeper).SendCoinsFromModuleToAccount @0x1cb4500`, `mintbankkeeper` pass-through
`@0x2ae8a40`; PIVOT-STRONG gadgets (`0x4cd1da mov %rsi,%rsp; …`, `0x4cf020 mov %rbx,%rsp; …`,
`0x4010cd add $0x38,%rsp; …`). The cgo-reentry route (`crosscall2` → `cgocallback` → `cSet`) is
the low-friction call path once any RIP control exists
(`analysis/go-native-call-feasibility.md`, options C/D). **No staging was attempted** — the
prerequisite does not exist.

---

## 7. Verdict

**The directed control transfer (`RIP ← attacker value`) is not reachable through the real
wasmvm v1.5.5 / Wasmer 4.2.2 nested architecture with the drift primitive as characterised.**
The proof is no longer "40 471 runs found nothing"; it is a mechanism:

1. The drift reaches the holder's live frame chain (measured: ≤ ~0x320 B deep) and lands plants on
   a **saved-RIP slot** (§6.2, §6.3.1).
2. The write is a **6-qword batch** that also corrupts neighbouring data slots; the data slot
   faults first (§6.3.3).
3. The crossing is **co-requisite with a trap**; wasmvm unwinds the holder through the libgcc
   DWARF unwinder, which **reads and validates** the corrupted RIP (FDE lookup / sigreturn-pattern
   check) rather than transferring control (§6.3.5).
4. Deeper aiming does not help — the live frame chain is entirely within the first crossing window
   (§4b).

**The one remaining concrete lever** (not attempted here, because it needs a new trigger codegen
shape and a fresh campaign): shrink the batch from ~6 qwords toward 1, so a plant can land on a
saved RIP *without* collaterally corrupting the neighbouring slot that faults first. The obstacle
is that the drift requires the `if`-then-result to stay memory-backed (register pressure), while a
small batch requires few live GPRs at the host call; a shape that separates those two conditions
(large pressure at the `if`, 1–2 live values at the call) has not yet been found and must be
derived against `codegen.rs` / `machine_x64.rs` before another sweep.

**Therefore M4 (mint) is not reachable and no execution package is armed.** The honest outcome is
the documented capability: a fully characterised, reproducible cross-stack corruption + labelled
native-read primitive through the exact mainnet engine, plus the complete mint-target/gadget
package and the rehearsed exit route — a strong responsible-disclosure artefact
(`analysis/advisory-analysis.md`) and a precise map of why the class is *not* weaponisable through
wasmvm's nested execution model.

---

## 8. Sources

Wasmer 4.2.2 / corosensei 0.1.2 (fetched from the tagged releases):
`lib/compiler-singlepass/src/codegen.rs`, `machine_x64.rs`; `lib/vm/src/trap/traphandlers.rs`;
`corosensei-0.1.2/src/arch/x86_64.rs`, `src/coroutine.rs`, `src/trap.rs`.
Prior campaign: `analysis/HANDOFF.md`, `analysis/ci-status.md`, `analysis/singlepass-batch-layout.md`,
`analysis/go-native-call-feasibility.md`, `analysis/mint-call-candidates.md`.
