#!/usr/bin/env bash
# Custom CI job: independent re-verification of the pSTAKE stkBNB StakePool
# live claim accounting on BSC. Runs from the finding folder root.
# Results -> ci-out/ (uploaded as artifact). No secrets are written to files.
set -euo pipefail

mkdir -p ci-out

RPC=""
if [ -n "${ANKR_API_KEY:-}" ]; then
  RPC="https://rpc.ankr.com/bsc/${ANKR_API_KEY}"
elif [ -n "${BSC_RPC_URL:-}" ]; then
  RPC="$BSC_RPC_URL"
else
  RPC="https://bsc-rpc.publicnode.com"
fi
export BSC_RPC="$RPC"
echo "[ci] BSC RPC selected (redacted)"

python3 ci/scan.py
echo "[ci] done; results in ci-out/"
