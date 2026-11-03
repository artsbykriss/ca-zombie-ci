# poc/ — compiler reproduction (no chain interaction)

This is a **local compiler test**, not a chain exploit. It reproduces the Singlepass lowering defect that
GHSA-v2h8-j899-r676 describes, so the claim "7.5.0 is still vulnerable" can be checked by execution as
well as by source diff.

## What it does

`src/main.rs` builds a WAT module with:

- a `(type $pass (func (param i64 …) (result i64 …)))`;
- a loop that pushes `prefix_count + param_count` values, then executes
  `local.get $condition; if (type $pass) … end` with **no `else`**;
- a non-recursive `call $probe` on every iteration (so the native stack is touched);
- N iterations (default 400 000, the upstream regression count).

The typed `if` with block parameters and an omitted `else` is the vulnerable shape. On a vulnerable
Singlepass build the false arm skips the cleanup of the spilled block parameters, the native stack pointer
drifts by 8 bytes per iteration, and the next stack access hits the guard page → trap or SIGSEGV. On a
fixed build the same module returns normally.

The run happens on a thread with a bounded stack (default **2 MiB**, `--stack`) so the cumulative drift is
observable within 400 000 iterations regardless of the process stack limit.

## Build / run

```bash
cd poc
cargo build --release        # Cargo.toml pins wasmer =7.4.2 by default
./target/release/sp-drift-poc --params 2 --prefix 31 --cond 0 --iters 400000
```

Change the `wasmer` version in `Cargo.toml` to test another release (the CI script rewrites it to `7.4.2`
and `7.5.0`). `poc/trigger.wat` is a standalone copy of the simplest trigger module.

## Cases used by `ci/sp-drift.sh`

| case | args | expected on vulnerable | purpose |
|---|---|---|---|
| spill31 | `--params 2 --prefix 31 --cond 0` | TRAP / SIGSEGV | the bug |
| spill32 | `--params 2 --prefix 32 --cond 0` | TRAP / SIGSEGV | stack-alignment parity |
| oneparam | `--params 1 --prefix 31 --cond 0` | TRAP / SIGSEGV | single block param |
| true_arm | `--params 2 --prefix 31 --cond 1` | OK | true arm does the cleanup |
| no_spill | `--params 2 --prefix 0 --cond 0` | OK | params stay in registers |
| no_params | `--params 0 --prefix 0 --cond 0` | OK | no block params → no leak |
| short_1k | `--params 2 --prefix 31 --cond 0 --iters 1000` | OK | drift too small to fault |
| explicit_else | `--params 2 --prefix 31 --body replace --explicit-else 1` | OK | explicit `else` control |
| unreachable | `--params 2 --prefix 31 --body unreachable` | OK | unreachable then-arm |

## Scope

No network, no chain access, no signing, no state change. The harness never talks to a node; it only
compiles and runs a WebAssembly module in-process with the released `wasmer` crate.
