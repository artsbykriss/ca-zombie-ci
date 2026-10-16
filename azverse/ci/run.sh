#!/usr/bin/env bash
# AZverse CI heavy job: bytecode verification + live-state dump + history census.
# Runs from the folder root on the GitHub runner. No secrets are printed.
set -u
cd "$(dirname "$0")/.."
mkdir -p ci-out
export PATH="$PATH:$HOME/.foundry/bin"

RPC="${ARB_RPC_URL:-}"
if [ -z "$RPC" ]; then RPC="https://arbitrum-one-rpc.publicnode.com"; fi

echo "== forge build (artifact for bytecode check)"
(cd poc && forge build --skip test >/dev/null 2>&1 || forge build >/dev/null 2>&1) || echo "build failed (continuing)"

echo "== bytecode verification"
python3 ci/verify_bytecode.py "$RPC" || echo "bytecode check failed (continuing)"

echo "== live state dump"
bash ci/dump_state.sh || echo "state dump failed (continuing)"

echo "== tx + approval census"
python3 ci/scan_txs.py || echo "tx scan failed (continuing)"

echo "== ci-out contents"
ls -la ci-out
