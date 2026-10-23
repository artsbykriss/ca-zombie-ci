# CWA-2026-006 — Singlepass 4.2.2 native-call "write batch": exact qword layout

Scope: `wasmer-compiler-singlepass 4.2.2`. Sources used: `/tmp/opencode/{machine_x64.rs,codegen_v4.2.2.rs}`
(md5-identical to `~/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/wasmer-compiler-singlepass-4.2.2/src/{machine_x64.rs,codegen.rs}`),
`.../src/x64_decl.rs`, `.../src/emitter_x64.rs`. Static analysis only; empirical refs at the end.

## TL;DR

- `emit_call_native` snapshots `get_used_gprs()`, then `push_used_gpr` emits one real x86 `push` per
  register in **ascending GPR-enum order**. Each `push` is `rsp -= 8; [rsp] = reg`, so **ascending
  memory order (index 0 = lowest address = rsp after the last push) is the reverse of push order**.
- Only 9 registers can ever appear: `RAX, RCX, RDX, RSI, RDI, R8, R9, R10, R11`.
  `RSP/RBP/RBX/R12–R15` are **never** in the mask (locals live in callee-saved regs saved by the
  prologue; R15 = vmctx). A register dump showing values in those regs does not make them batch qwords.
- The `call` that follows the batch pushes its own **JIT return address** at
  `batch_low − stack_offset − 8` = index **−1** (or **−2** with 8 B ABI padding), below all register
  qwords. Same downward write stream, but *not* a `push_used_gpr` qword.

## 1. Source evidence (quotes)

`/tmp/opencode/codegen_v4.2.2.rs:784` — snapshot before every native/host call:
```rust
let used_gprs = self.machine.get_used_gprs();
let mut used_stack = self.machine.push_used_gpr(&used_gprs)?;
```
`/tmp/opencode/machine_x64.rs:1946` — mask -> Vec, in enum order:
```rust
fn get_used_gprs(&self) -> Vec<GPR> {
    GPR::iterator().filter(|x| self.used_gprs & (1 << x.into_index()) != 0).cloned().collect()
}
```
`/tmp/opencode/machine_x64.rs:2005` / `:2011` — push ascending, pop reverse:
```rust
fn push_used_gpr(&mut self, used_gprs: &[GPR]) -> Result<usize, CompileError> {
    for r in used_gprs.iter() { self.assembler.emit_push(Size::S64, Location::GPR(*r))?; }
```
```rust
fn pop_used_gpr(&mut self, used_gprs: &[GPR]) -> Result<(), CompileError> {
    for r in used_gprs.iter().rev() { self.assembler.emit_pop(Size::S64, Location::GPR(*r))?; }
```
`.../src/x64_decl.rs:14` and `:76` — enum/iterator order:
`RAX=0, RCX=1, RDX=2, RBX=3, RSP=4, RBP=5, RSI=6, RDI=7, R8=8, R9=9, R10=10, R11=11, R12..R15=12..15`;
`iterator()` yields exactly this array. `.../src/emitter_x64.rs:1256` (same as `/tmp/opencode/wasmer-diff/emitter_x64_422.rs:1256`):
```rust
(Size::S64, Location::GPR(src)) => dynasm!(self ; push Rq(src as u8)),
```
Mask origin: `used_gprs: 0` per function (`machine_x64.rs:146`, fresh machine `compiler.rs:162`). Only
inserted through `reserve_gpr`/`reserve_unused_temp_gpr`/`acquire_temp_gpr` (`machine_x64.rs:2001,1995,1983`).
Callers: `codegen.rs:285` (value regs from `pick_gpr` = `RSI,RDI,R8,R9,R10,R11`, `machine_x64.rs:1962`),
`codegen.rs:814` (`reserve_unused_temp_gpr(get_grp_for_call())` = RAX, `machine_x64.rs:2641`),
`machine_x64.rs:2777/2781` (jump table, RAX/RCX/RDX). RAX is reserved **after** the snapshot.

Drift site: `codegen.rs:363` `release_locations_value` ends with `adjust_stack` (`sub rsp`, line 409)
where the twin `release_locations` (line 310) uses `restore_stack` (`add rsp`, line 358) — the CWA bug.
Reached from `Operator::Else` (`codegen.rs:2993`).

## 2. Batch table (index 0 = lowest address = post-push rsp)

Achievable set sorted ascending enum: `RAX RCX RDX RSI RDI R8 R9 R10 R11` (push order, first→last).
Memory index = reverse of push order: index of reg r = #{present regs with higher enum index}.

| idx | full set (all 9) | typical drift site (6 value regs, no live temp) |
|-----|------------------|--------------------------------------------------|
|  0  | R11              | R11 |
|  1  | R10              | R10 |
|  2  | R9               | R9  |
|  3  | R8               | R8  |
|  4  | RDI              | RDI |
|  5  | RSI              | RSI |
|  6  | RDX              | —   |
|  7  | RCX              | —   |
|  8  | RAX              | —   |
| -1  | *call RA (so=0)* | *call RA* |
| -2  | *call RA (so=8)* | *call RA* |

Address of index k: `A(k) = D0 − 8N + 8k`, `D0` = rsp at `push_used_gpr` entry (= **post-drift**),
`N` = number of used regs. `stack_offset` (`so`): `codegen.rs:836-843` adds 8-byte ABI padding when
`(frame + 8N + so) % 16 != 0` (SysV, no stack args) -> `so ∈ {0,8}`; each arg beyond 6 adds 8 more.

## 3. Which index lands on the holder return slot

Because the drift steps `D0` by −16 per loop iteration while `S` (holder slot) is fixed,
`k = (S − D0(0))/8 + 2i + N` — **a fixed slot is only ever written by indices of one parity**
(`k ≡ N + (S − D0)/8 (mod 2)`). Consequences:

- If the stream keeps running past S, the last batch qword left at S is the largest same-parity
  index ≤ N−1 (6-reg set: idx 5 = **RSI** if odd, idx 4 = **RDI** if even).
- If the trigger stops at first crossing (E4 recipe `iters = i_call+1`), S keeps the crossing
  iteration's write: a register qword, or index −1/−2 = the **call return address**.
- Observed (`ci-status.md:78`, CI 37617613356): S consistently holds a JIT pointer with fixed page
  offset `0x…a10` (tails a10×356, 909×50; 0 marker-hijacks over dummy=0..15 × r=218..302).
  Best fit: S aliases index −1/−2 (the trigger's `call` RA, JIT code address). Same-parity register
  family then is **odd: R10, R8, RSI** (`so=0`) or **even: R11, R9, RDI** (`so=8`).
  If instead a JIT pointer must be a *register* value, the only carriers would be a live temp
  (RAX/RCX/RDX holding a vmctx builtin pointer); at import sites RAX is reserved after the snapshot,
  so this is unlikely — **verify empirically**.
- E5's marker on the slot (`fault_addr = 0x41414141414102`, `ci-status.md:210`) proves a register
  qword can hit S in tuned phases; K=2 identifies the planted *live value*, not the batch index.

## 4. `emit_call_native` / drift interplay

- Sequence per call: N pushes (`D0-8N..D0`) -> `adjust_stack(so)` -> stack args (only >6 params,
  written at `[rsp + …]`, below batch) -> `call` (RA at `D0−8N−so−8`) -> host callee frames.
- After return: `restore_stack(so)`, `pop_used_simd` (if XMMs: `machine_x64.rs:2060` uses
  `adjust_stack`+`mov [rsp+i*8]`, i.e. ascending memory = list order), `pop_used_gpr` -> rsp = D0.
  The RA bytes stay in memory after the callee's `ret` pops them; S keeps the last write.
- Net rsp drift comes solely from `release_locations_value`'s `sub rsp` (16 B/iter proven); every
  call re-emits the batch+RA 16 B lower. The RA is a fixed JIT offset -> the observed constant low
  bits (`…a10`), unlike attacker values.
- Import calls use `emit_call_with_reloc` (`machine_x64.rs:4538`): plain `E8 call rel32` to a
  custom-section trampoline, so the RA is a pointer into the JIT module region (`0x7f…`).

## 5. How to shift which register lands on the return slot

1. **Holder frame shift (moves S):** ±8 B in the holder flips the index parity (odd<->even family);
   ±16 B keeps parity but changes the index by 2. (CI 37617613356 `--dummy` sweep.)
2. **Register pressure N:** add/remove a live value, or force a temp (RAX/RCX/RDX) to stay live
   across the call: changes N, the batch span, and possibly `so` -> shifts which index aliases S.
3. **Call-site stack usage:** passing >6 args (`so += 8/arg`) or landing in the 8 B padding case
   moves the RA from index −1 to −2 (and flips its parity, changing whether the RA itself can hit S).
4. **Register selection:** allocation order for values is `RSI, RDI, R8, R9, R10, R11`
   (`pick_gpr`, `machine_x64.rs:1962`); stage the marker in a register whose index parity matches the
   geometry (odd: R10/R8/RSI; even: R11/R9/RDI).
5. **Stop point (`iters`):** stop at the crossing batch vs run on decides whether S keeps the
   crossing index or the max same-parity index (RSI/RDI for N=6).

## 6. Uncertainties / verify empirically

- Exact index aliasing S must be measured at runtime (breakpoint in `push_used_gpr`; log `D0`, N,
  used list; compare `A(k)` to the holder slot address). The parity argument is exact; the phase is
  not derivable statically.
- `a10` = call RA is the best hypothesis; confirm by disassembling the trigger function and checking
  that `0xa10` matches the instruction after a `call` (or a trampoline RA).
- K=2 -> register mapping of E5 is unverified (allocation reuse can change it).
- Assumes SysV x86-64, no atomics (atomic paths additionally `push R13/R14`, `machine_x64.rs:643`),
  and the host-stack switch happening after the `call` (RA on the fiber stack).
- The "~8-16 qword batch" sometimes quoted includes `push_used_gpr` (≤9), stack args, the call RA
  and callee frames; only the ≤9 register qwords are attacker-settable via live values.
