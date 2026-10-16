#!/usr/bin/env bash
# BisonFi Z3-C4 custom CI job: run the LiteSVM PoC (clone mainnet state, execute in-process).
# Read-only: nothing is signed/sent to any network; fixtures are committed public on-chain data.
set -uo pipefail
mkdir -p ci-out
echo "== bisonfi Z3-C4 LiteSVM PoC =="
echo "rustc: $(rustc --version 2>/dev/null || echo MISSING)"
echo "cargo: $(cargo --version 2>/dev/null || echo MISSING)"
cd poc
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$PWD/target}"
cargo run --release 2>&1 | tee ../ci-out/poc-output.txt
echo "exit: $?"
echo "== done =="
ls -la ../ci-out/
