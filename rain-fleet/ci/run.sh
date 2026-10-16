#!/usr/bin/env bash
# Rain white-label card fleet PoC (Z3-H11):
# LiteSVM replay of the historical Aug-28-2026 exploit transaction sequence
# against the current on-chain builds + pre-incident builds.
# READ-ONLY: all simulation is local; no chain transactions.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p ci-out

# Rust toolchain
if ! command -v cargo >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup.sh
  sh /tmp/rustup.sh -y --profile minimal --default-toolchain stable
  . "$HOME/.cargo/env"
fi
cargo --version
rustc --version

cd poc
cargo run --release -- "$ROOT" 2>&1 | tee "$ROOT/ci-out/litesvm_stdout.txt"
