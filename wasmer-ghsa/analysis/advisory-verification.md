# GHSA-v2h8-j899-r676 — independent verification record

All reads 2026-11-03 UTC. GitHub via `api.github.com` (authenticated read-only), source via
`raw.githubusercontent.com`, public LCD via keyless HTTP. No keys stored, no transaction signed.

## 1. Advisory (GitHub Security Advisory API)

`GET /repos/wasmerio/wasmer/security-advisories/GHSA-v2h8-j899-r676` → HTTP 200.

| Field | Value |
|---|---|
| `ghsa_id` | GHSA-v2h8-j899-r676 |
| `cve_id` | **null** (no CVE assigned as of this read) |
| `summary` | "Singlepass implicit-else miscompilation allows native stack corruption and sandbox escape" |
| `severity` | **critical** |
| `cvss` | **10.0** — `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H` |
| `cwe_ids` | `["CWE-787"]` (out-of-bounds write) |
| `published_at` | **2026-11-02T12:02:10Z** |
| `updated_at` | 2026-11-02T12:02:11Z |
| `state` | `published` |
| package | `wasmer-compiler-singlepass` (ecosystem `rust`) |
| `vulnerable_version_range` | `>= 7.0.0-alpha.1, <= 7.4.2` |
| `patched_versions` | **`""` (empty — no patched release)** |

### Root cause (advisory text, verbatim substance)

> WebAssembly permits an `if` with matching parameter and result types to omit its `else`; the
> implicit false arm must preserve the input values. Singlepass reserves result locations separately
> from the original block-parameter locations. In the vulnerable lowering, the false-arm label is
> bound after stack cleanup, so a false condition can bypass the cleanup required for spilled block
> parameters while the compiler's stack model assumes that cleanup occurred.
>
> Repeated execution can make the native stack pointer drift away from the compiler's tracked stack
> position. In the reported x86-64 case, each affected execution leaves an additional eight-byte slot
> on the native stack. Subsequent native stack accesses can corrupt memory outside the intended stack
> frame. The trigger is valid WebAssembly and does not require a WebAssembly linear-memory
> out-of-bounds access.

Introduced by PR #5869 ("Singlepass: add multivalue support", merged **2025-11-18T09:06:48Z**), first
shipped in `7.0.0-alpha.1`. `6.1.0` rejects the required parameterized block signatures.

### Advisory's own statements about exploit maturity

- "The reporter demonstrated native code execution in a Linux x86-64 CosmWasm/wasmvm deployment."
- "**The compiler defect has also been reproduced on ARM64; the complete native-code-execution
  exploit was not independently reproduced during maintainer validation.**"
- "Applications exposing unpermissioned contract upload and execution can therefore be remotely
  exploitable."
- "A fix has been prepared in the private security branch; **the patched release version is pending
  confirmation**."
- Post-fix: "invalidate and recompile cached or serialized native-code artifacts produced by vulnerable
  Singlepass versions. Updating the compiler does not repair code that has already been compiled."

So: **defect verified by maintainers; controlled NCE claimed by one reporter, not reproduced by
maintainers, and not public.**

## 2. Fix PR #7128

`GET /repos/wasmerio/wasmer/pulls/7128`:

| Field | Value |
|---|---|
| title | `fix(Singlepass): lower implicit else through existing else handling` |
| state | closed, **merged = true** |
| `merged_at` | **2026-11-02T12:01:47Z** (25 s before advisory publication) |
| base | `main` |
| merge commit | `e5ca9b93809d744af8b33488a748a284d3d41955` |
| files | `lib/compiler-singlepass/src/codegen.rs` (+62/−69), `tests/compilers/issues.rs` (+73/−0) |
| body | "Backport from the internal repository." |

**What it actually demonstrates.** The added test `implicit_else_reclaims_inputs` builds a WAT module
with a loop of 400 000 iterations over a typed `if` with 0/1/2 block parameters and an omitted `else`,
across register and spilled layouts, then calls a `$probe` function each iteration. On a vulnerable
build the leaked native stack slots accumulate until the next stack access hits the guard page → trap.
The test is a **regression test for native-stack drift / memory corruption**. It does **not**
demonstrate a controlled escape, native code execution, or a sandbox-escape primitive.

## 3. The 7.5.0 question — resolved: **7.5.0 is vulnerable**

`lib/compiler-singlepass/src/codegen.rs`:

| ref | bytes | md5 | vulnerable block | `emit_if_block_end` |
|---|---|---|---|---|
| `v7.4.2` | 253,340 | `d0b168fd67bcb0e2f651ea08e259981b` | present | absent |
| `v7.5.0` | 253,340 | `d0b168fd67bcb0e2f651ea08e259981b` | present | absent |
| `main` | 255,927 | `491df67a37cb89536728f8d821eecdbb` | replaced | **present** |

**v7.4.2 and v7.5.0 are byte-identical.** `diff -q` returns no differences. Therefore every build
pinning `wasmer-compiler-singlepass 7.5.0` contains the defect.

Concrete code evidence:

- v7.5.0 `Operator::If` (line 2576) contains the special case
  `if param_types.len() == return_types.len()` (line 2588) that pre-copies inputs into return slots,
  with the comment "We might hit a situation where an Operator::If is missing an Operator::Else".
- v7.5.0 `Operator::End` (line 3766) pops the frame, releases and truncates the value stack to
  `value_stack_depth_after()`, and only then executes
  `if let ControlState::If { label_else, .. } = frame.state { emit_label(label_else) }` (line 3798).
  The false arm therefore lands **after** cleanup — exactly the advisory's root cause.
- `main` replaces both paths: `emit_if_block_end` (line 1146) restores the inputs and stack offset
  **before** result placement/cleanup, is called from `Operator::Else` (line 2674) and from
  `Operator::End` when the frame is `ControlState::If` (lines 3774–3778), and clears
  `was_unreachable` so the implicit false arm is treated as reachable.

**Consequence:** the advisory's `<= 7.4.2` range is understated. `7.5.0` is affected, and so is every
downstream build that pins it.

### Downstream version mapping (verified from each tag's `libwasmvm/Cargo.lock`)

| wasmvm | cosmwasm-vm | wasmer-compiler-singlepass | status |
|---|---|---|---|
| v2.2.9 | 2.2.10 | **7.4.2** | vulnerable |
| v2.3.5 | 2.3.5 | **7.4.2** | vulnerable |
| v3.0.8 | 3.0.10 | **7.4.2** | vulnerable |
| v2.2.10 | 2.2.11 | **7.5.0** | **vulnerable** (advisory range says otherwise) |
| v2.3.6 | 2.3.6 | **7.5.0** | **vulnerable** |
| v3.0.9 | 3.0.11 | **7.5.0** | **vulnerable** |
| wasmvm `main` | 3.0.11 | **7.5.0** | **vulnerable** |

Latest published versions as of 2026-11-03: wasmer crate **7.5.0 (2026-10-01)**, wasmvm **v3.0.9
(2026-10-09)**. Both predate the fix (2026-11-02). `CosmWasm/wasmd@main` pins wasmvm **v3.0.9**.
There is **no released fixed version anywhere in the stack**.

Also: `CosmWasm/advisories/CWAs` contains CWA-2025-004…CWA-2026-006 and **no CWA for this defect**
(re-checked 2026-11-03). Downstream chains therefore have no CosmWasm-level advisory for it.

## 4. Reachability in wasmvm (why the precondition is met)

From `CosmWasm/cosmwasm` at `v3.0.10` (the cosmwasm-vm version pinned by wasmvm v3.0.8):

- `packages/vm/src/wasm_backend/engine.rs:53-55`:
  `pub fn make_compiler_config() -> impl CompilerConfig + Into<Engine> { wasmer::sys::Singlepass::new() }`
  — Singlepass is used unconditionally; no feature restriction is applied.
- `Singlepass::supported_features_for_target` returns `Features::default()`; in wasmer-types 7.5.0
  `Features::default()` has **`multi_value: true`** (asserted by the crate's own unit test).
- `packages/vm/src/parsed_wasm.rs:82-89` builds the wasmparser validator with
  `WasmFeatures::MULTI_VALUE` enabled.

So both layers (validation and codegen) accept the parameterized block signature the trigger needs.
The advisory's suggested workaround (disable multi-value in trusted validation) is **not applied** by
CosmWasm, and applying it would reject otherwise-valid contracts.

Delivery on a permissionless chain is `MsgStoreCode` + `MsgInstantiateContract`; the module is compiled
by Singlepass on every validator at instantiation/first execution, and contract execution is
consensus-replicated, so the miscompiled code runs in **every validator's** node process.
