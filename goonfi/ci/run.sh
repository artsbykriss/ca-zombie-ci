#!/usr/bin/env bash
# GoonFi Z3-H2 custom CI job: run the LiteSVM PoC (clone mainnet state, execute in-process).
# Read-only: nothing is signed/sent to any network; fixtures are committed public on-chain data.
set -uo pipefail
mkdir -p ci-out
echo "== goonfi Z3-H2 LiteSVM PoC =="
echo "rustc: $(rustc --version 2>/dev/null || echo MISSING)"
echo "cargo: $(cargo --version 2>/dev/null || echo MISSING)"
if ! command -v cargo >/dev/null 2>&1; then
  echo "installing rust toolchain..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
  echo "rustc now: $(rustc --version)"
fi
cd poc
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/tmp/goonfi-target}"
cargo run --release 2>&1 | tee ../ci-out/poc-output.txt
echo "exit: ${PIPESTATUS[0]}"
echo "== done =="
ls -la ../ci-out/
