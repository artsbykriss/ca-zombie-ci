#!/usr/bin/env bash
# ci/run.sh — Exceed Finance (Solana) recon job.
# Self-contained: stdlib Python only, PUBLIC RPC only (no keys, no secrets).
# Writes results to ./ci-out/ (uploaded as CI artifacts).
set -uo pipefail
cd "$(dirname "$0")/.."      # -> <folder>/
mkdir -p ci-out
RPC="${SOLANA_PUBLIC_RPC:-https://api.mainnet-beta.solana.com}"
export RPC
echo "[ci] python: $(python3 --version)  rpc: $RPC"
python3 ci/collect.py
echo "[ci] outputs:"; ls -la ci-out/
