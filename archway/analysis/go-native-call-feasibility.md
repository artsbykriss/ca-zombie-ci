# Calling Go code from a hijacked Wasmer/corosensei fiber — feasibility notes

Scope: archwayd-class node, **Go 1.23**, cgo enabled (wasmvm v1.5.5 / Wasmer 4.2.2), statically-linked
non-PIE amd64. Attacker state: RIP + a few GPRs + several controlled qwords on a 1 MiB mmap'd
corosensei fiber (~0x7f...), executing inside a cgo call (C/Rust → host import).
Sources: local toolchain is go1.25.0 (`/usr/local/go/VERSION`); mechanics below are identical in 1.23.
Offsets marked "1.23" are computed from release-branch.go1.23 sources and were cross-checked against a
locally built cgo probe binary (go1.25) by disassembly. Confidence: **[H]/[M]/[L]**.

**Bottom line:** calling an arbitrary bank-keeper method directly is **not** practical. But re-entering
Go through the existing *cgo callback machinery* is, and the binary already contains C-ABI wrappers
(`cSet`, …) that write application state. Direct Go calls from the fiber only work for code that never
touches `g` beyond the prologue.

## 1. Register ABI and prologue codegen

- `g` lives in **R14** (`REGG`); integer args/results in **AX, BX, CX, DI, SI, R8, R9, R10, R11**
  (`cmd/internal/obj/x86/a.out.go:266-268`, `runtime/asm_amd64.s:630-656`). `R12/R13` are entry
  scratch, `R15` is a normal allocatable register. **[H]**
- ABIInternal callees do **not** load `g` in their prologue; they *assume* R14 already holds it
  (`cmd/internal/obj/x86/obj6.go:992-997`: `loadG` returns `REGG` immediately for AMD64+ABIInternal).
  Only ABI0 entry wrappers load it: `MOVQ -8(FS), R14` (observed disasm; see §5). **[H]**
- Stack-split check, emitted by the assembler unless the symbol is NoSplit (`obj6.go:1033+`), comparing
  against **`0x10(R14)` = `g.stackguard0`** (and `0x18(R14)` = `g.stackguard1` for `//go:systemstack`
  funcs, `obj6.go:1104,1131`). `AJLS` = JBE (0x76/0x86; `cmd/internal/obj/x86/asm6.go:1145`), unsigned:
    - frame ≤ 128 (`StackSmall`): `CMPQ SP, 0x10(R14); JLS morestack` (`obj6.go:1095-1111`).
    - 128 < frame ≤ 4096 (`StackBig`): `LEAQ -(framesize-128)(SP), R12; CMPQ R12, 0x10(R14); JLS …`
      (`obj6.go:1115-1135`).
    - frame > 4096: `MOVQ SP, R12; SUBQ $(framesize-128), R12; JCS stub; CMPQ R12, 0x10(R14); JLS …`
      (`obj6.go:1140-1183`). Underflow guard only.
  The JLS target is a stub at the **end** of the function that spills arg registers and
  `CALL runtime.morestack{,_noctxt}` then jumps back after the check (`obj6.go:1187-1235`; verified in
  disassembly of a locally built binary). Pass ⇒ body runs on the current SP with R14 assumed valid.
  Fail ⇒ `morestack` reads **TLS**, not R14 (§4). **[H]**
- Small leaf functions (frame < 128, no calls except zero-arg runtime calls) are auto-marked NoSplit —
  they have **no check at all** (`obj6.go:646-671`). `//go:nosplit` functions likewise. **[H]**

## 2. If R14 is garbage

- First access is the stack check: read of `[R14+0x10]` (and `[R14+0x18]` for CFunc). Unmapped ⇒ SIGSEGV
  in the prologue. Mapped ⇒ the 8-byte value there is used as `stackguard0`; if `SP <= guard` (unsigned)
  you go to morestack, else execution continues with the garbage R14. **[H]**
- Code paths that dereference `g` (directly via R14 or via `getg()` which lowers to R14):
  stack split; `runtime.morestack` (TLS); GC write barrier body `g_m(R14)` (§3); allocation
  (`mallocgc`→`getMCache`: `mp.p.ptr().mcache`, `runtime/mcache.go:128`); `mcall`/`systemstack`;
  `deferproc`/`deferreturn` (`g._defer` at +0x28); `gopanic` (+0x20); map internals that call `fastrand`
  (`g.m`); scheduler/channel/`gopark`; `newproc`; traceback/sigpanic. **[H]**
- Classes that can run fully without touching `g`: nosplit/leaf functions, pure assembly helpers
  (`memmove`, `memequal`, `duffzero`, math/hash), simple compute, non-pointer stores. Anything calling
  Go runtime services is out. **[H]**
- R14 is freely controllable: pointing it at a **fake `g` you stage on the fiber stack** works if
  `[fake+0x10]` is below the fiber SP (set it to 0) and `[fake+0x18]=0` for CFunc checks. The fake `g`
  only satisfies the prologue; first real runtime use reads fake `g.m` (+0x30) etc. A **valid `g0`**
  (`*(FS-8)`, §5) is also loadable and its fields are real, but see §4 for its guard. **[H]** for the
  prologue bypass; **[L]** for surviving runtime calls with a fake/foreign `g`.

## 3. Write barriers

- The compiler instruments `OpStore/OpMove/OpZero` when the destination may be heap (or is a global) and
  the value may be a heap pointer (`cmd/compile/internal/ssa/writebarrier.go:84-148`). Store-local slots
  and non-pointer stores are never instrumented; runtime `//go:nowritebarrier*` code has no checks. **[H]**
- At each instrumented store the compiler emits an **unconditional 32-bit load of the global**
  `runtime.writeBarrier.enabled` and a branch: `CMPL $0, runtime.writeBarrier(SB); JEQ dowrite`
  (`writebarrier.go:151-224`; `runtime/mgc.go:237-258`) — **no `g` is required for the check**, and it is
  present even when disabled (`setGCPhase` only sets it during `_GCmark/_GCmarktermination`). **[H]**
- The enabled path calls `gcWriteBarrier1..8`, which starts `MOVQ g_m(R14), R13; MOVQ m_p(R13), R13`
  (`runtime/asm_amd64.s:1735-1746`, call site stub 1791). Bulk barriers (`wbZero/wbMove`,
  `typedmemmove`, `typedmemclr`) also check the global and then use `getg().m.p.ptr().wbBuf`
  (`runtime/mbarrier.go:154,250,317`; `runtime/mwbbuf.go:166-181`). **[H]**
- During a cgo call `m.p == 0` (entersyscall released it, `runtime/proc.go:4560+`), so **any enabled
  barrier from the fiber faults at a nil P**. When GC is off (the common case) the branch is not taken
  and R14 is never read by stores — a ROP target can exploit this window, but it is race-dependent.
  **[H]** mechanics, **[M]** exploitability.

## 4. Stack growth (`morestack`) and guard values

- `runtime.morestack` (`runtime/asm_amd64.s:579`) does **not** use R14: it loads `g` from TLS
  (`get_tls; MOVQ g(CX), DI`), writes the interrupted PC/SP/BP/ctxt into `g.sched` (+0x38..+0x60), then
  compares DI with `m.g0` (+0x0). During cgo, TLS `g == m.g0` ⇒ `CALL badmorestackg0; CALL abort`
  (asm_amd64.s:594-599). Garbage in TLS faults at the g.sched writes. **[H]**
- Even if it reached `newstack` (`runtime/stack.go:1015`), the fiber SP is outside the goroutine stack:
  `sp` would exceed `stack.hi`, the size math underflows, and it throws
  `"runtime: split stack overflow"` (`stack.go:1099-1100`) or loops to `"stack overflow"`
  (`stack.go:1140-1159`). **[M-H]**
- Guard contents for a *random* R14: undefined; `0x10(R14)` is just `stackguard0`
  (`runtime/runtime2.go:402-404`, "offset known to liblink"). For the interesting valid values:
  - `curg` (the goroutine that entered cgo): `reentersyscall` sets `stackguard0 = stackPreempt`
    (`runtime/proc.go:4572`; value `0xfffffffffffffade`, `runtime/stack.go:131`) and it stays until
    `exitsyscall` resets it (`proc.go:4841-4844`). Fiber SP (~0x7f...) < stackPreempt unsigned ⇒ check
    **fails** ⇒ abort. So **curg is a bad R14 during the cgo window**. **[H]**
  - `g0`: in cgo builds `allocm` uses `malg(-1)` and `mstart0` sets g0 stack bounds to ~16 KiB at the top
    of the OS thread stack (`runtime/proc.go:2332-2334`, `proc.go:1855-1878`). Whether
    `g0.stackguard0` is below the fiber mmap is an address-space question: fiber stacks are allocated
    *later* and top-down mmap usually puts them below thread stacks ⇒ check likely **fails** too.
    **[M]** (verify at runtime by reading both).
  - `m.gsignal` (`m+0x48`) / heap-stack goroutines: guard ≈ 0xc0... (Go heap) ⇒ check **passes** on a
    fiber stack, but these `g`s still have `m.p == 0`. **[H]**
  - fake `g` on the fiber with `stackguard0=0`: always passes. **[H]**

## 5. cgo state: a live `g`/`m` is reachable from TLS

- On Linux/amd64 `g` is at **`FS-8`** (`MOVQ %fs:-8, R14` in ABI0 wrappers; `cmd/link/internal/ld/sym.go:88-93`,
  `runtime/go_tls.h`, `settls` sets FS to `&m.tls+8`, `runtime/sys_linux_amd64.s:637-648`). **[H]**
- During the cgo call, `asmcgocall` switched TLS `g` to **`m.g0`** and saved the real goroutine:
  `runtime/asm_amd64.s:885-930` (TLS set at 911, old `g` pushed at 8(SP) at 917). So from the fiber:
  `g0 = *(FS-8)`; `m = *(g0+0x30)`; `curg = *(m+curg_off)`. **Offsets (1.23):** `m.g0=0x0`,
  `m.gsignal=0x48`, `m.tls=0x78`, `m.curg=0xb0`, `m.p=0xc0`, `m.oldp=0xd0`, `m.incgo=0x108`;
  `g.m=0x30`, `g.stackguard0=0x10`, `g.sched.sp=0x38`. (go1.25: `m.curg=0xb8`, everything after +8.)
  Confirm on archwayd via DWARF or by disassembling `runtime.cgocallback` (it loads `m_curg`).
  **[H]** source, **[M]** exact target offsets.
- Symbols to look for in the non-PIE binary (all present in a wasmvm-1.5.5 cgo build, verified via
  `nm` on `/home/heisenberg/CA/archway/harness/harness`): `runtime.cgocallback` / `.abi0` (asm
  `runtime/asm_amd64.s:965`), `runtime.cgocallbackg` (`runtime/cgocall.go:301`), `crosscall2`
  (`runtime/cgo/asm_amd64.s:29`, kept alive/exported by `//go:cgo_export_static`), `runtime.needm` /
  `needAndBindM`, and the wasmvm exports `cGet/cSet/cDelete/cScan/cNext*/cQueryExternal/cHumanAddress/
  cCanonicalAddress` plus `_cgoexp_<hash>_*` wrappers. **[H]**
- Caveat: all of this holds only if the hijacked fiber is running on the **same OS thread** that called
  into C (corosensei stack-switching does; a Rust-created execution thread would not). On a foreign
  thread `FS-8` is glibc TLS and `cgocallback` would misinterpret it. **[M]** (prerequisite).

## 6. Decision tree: what to do with one RIP + a few qwords

**Option A — direct Call with R14 = g0 / real g.**
Prologue may pass or fail depending on the g0-guard vs fiber-SP ordering (§4) and gives no P.
Blockers: `m.p==0` ⇒ allocation nil-deref (`mallocgc`→`mcache0==nil`, `runtime/proc.go:5952`,
`runtime/mcache.go:128`), enabled write barrier nil-deref, g0/curg mixups in runtime calls.
Works only for allocation-free, barrier-free code. **[L]** for any keeper/state write.

**Option B — direct Call with a fake g staged on the fiber (guard=0).**
Prologue always passes; same `m.p==0` blockers, plus fake `g` poisons any runtime service that reads
it. Useful only for nosplit/pure helpers (memcpy-style writes). **[L]** for state writes.

**Option C — re-enter Go via `runtime.cgocallback` (`crosscall2` ABI).** **[H] mechanics / [M] target fit**
Call `crosscall2(fn, frame, 0, ctxt)` with the C ABI (RDI=fn, RSI=frame, RDX=n, RCX=ctxt). It spills
C regs, calls `runtime.cgocallback` (`asm_amd64.s:965-1000`), which reads `g0`/`m` from TLS, switches to
`m.curg`'s real stack, and runs `cgocallbackg(fn, frame, ctxt)` (`cgocall.go:301`): `exitsyscall`
reacquires a P, then `cb(frame)` invokes `fn` as `func(unsafe.Pointer)` (`cgocall.go:382-442`), and on
return `reentersyscall` restores the cgo state before returning to the fiber. This gives correct g, P,
mcache, barriers, GC stack maps — all of §3/§4 stop being blockers. Limitation: `fn` must be an
ABIInternal entry of shape `func(one pointer)`; other registers are not attacker-controlled, so
multi-arg methods cannot be invoked. **[H]**

**Option D — call an existing cgo export wrapper (best practical path).** **[H] presence / [M] args**
wasmvm v1.5.5 compiles `//export cSet` etc. (`internal/api/callbacks.go:187`); the node binary contains
the C-ABI function `cSet` plus `_cgoexp_..._cSet`. Calling `cSet(db, gas_meter, used_gas, key, val,
errOut)` from the fiber runs `crosscall2`→`cgocallback`→Go `api.cSet`, which resolves `db` as
`(*DBState)(unsafe.Pointer(ptr))` (`callbacks.go:248`) and performs `state.Store.Set(key, val)` — i.e.,
a **write into the live contract KV store** (which for wasmd sits over the application multistore) with
full runtime machinery. The `db_t*` is the `*DBState` (`callbacks.go:117-130`) already live in the
suspended execution; `key/val` are simple `U8SliceView{ptr,len}`; `errOut` can point at scratch memory
on the fiber. Same route reaches `cQueryExternal` (query callback) and the rest. This is the realistic
way to get a state write, rather than a bank-keeper method. **[H]** that the route exists and is
runtime-safe; **[M]** that a valid db/querier/gas-meter pointer is recoverable from the hijacked
context (they live in C frames/registers and Go-heap objects of the suspended execution).

**Option E — manual `exitsyscall` / `reentersyscall` sandwich.** Set R14=curg, call `runtime.exitsyscall`
(gets a P; `proc.go:4787`), call any ABIInternal Go function with arbitrary register args on the fiber,
then `reentersyscall(savedpc, savedsp, savedbp)` before returning to C. This is Option C reimplemented
with full signature freedom. Risks: `exitsyscall` may park the goroutine (sched.sp=fiber ⇒ GC/traceback
hazards), GC scans `curg` using stale `sched.sp` (fiber frames unscanned ⇒ live-pointer loss),
preemption can set `stackguard0=stackPreempt` and any later morestack aborts via TLS-g0. **[M-L]**,
complex.

**Option F — patch `m.p = m.oldp` (or steal an idle P from `runtime.allp`) then direct-call.** Allocation
and barriers would work, but this P belongs to `_Psyscall` bookkeeping and can be stolen concurrently;
double-attach corrupts the scheduler. Last resort. **[L]**

Not usable: `runtime.debugCallV2` (needs debugger INT3 two-phase protocol, `_Grunning`, and
`debugCallCheck`); ordinary multi-arg keeper methods (no trampoline accepts arbitrary Go signatures —
only `func(unsafe.Pointer)`).

## Prerequisite checks before betting on C/D

1. Confirm the fiber runs on the Go thread: read `*(FS-8)`; it must be a plausible `*g` with
   `[[g+0x30]] == m`, `m.g0 == g` (`g0` path) and `m.curg != 0`. If not, C/D are unavailable. **[M]**
2. Confirm `cSet`/`_cgoexp_*`/`crosscall2`/`cgocallback` symbol addresses in the target ET_EXEC (fixed,
   non-PIE). **[H]** expected.
3. Recover a live `db_t*` (and gas-meter/querier) for the in-flight execution; candidates: registers or
   C stack of the suspended host call, or the Go-heap `DBState`/`C.Db` built by `buildDB`
   (`callbacks.go:126`). **[M]**.
4. If a raw bank-keeper call is still required, the only general mechanism is Option E (arbitrary args)
   or first re-entering Go and bootstrapping a second-stage call from known Go code — both strictly
   riskier than Option D.
