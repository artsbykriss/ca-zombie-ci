#!/usr/bin/env bash
# Custom CI job for l2-related (Serum Swap + Cega V2).
# Runs on GitHub Actions (public repo); read-only; public RPCs only; no secrets.
set -uo pipefail
cd "$(dirname "$0")/.."

mkdir -p ci-out

echo "=== [1/3] Solana: Serum Swap program verification (public RPC) ==="
timeout 1500 python3 ci/solana_verify.py 2>&1 | tee ci-out/serum-verify.log
echo "solana_verify rc=${PIPESTATUS[0]}"

echo "=== [2/3] EVM: Cega V2 vault census (both chains) ==="
timeout 2400 python3 ci/cega_vaults_pass.py 2>&1 | tee ci-out/cega-vaults.log
echo "cega_vaults rc=${PIPESTATUS[0]}"

echo "=== [3/3] EVM: Cega V2 Treasury/entry gate fork tests run by the forge test step ==="
echo "(see poc/ - executed by the workflow's forge test step)"

exit 0
