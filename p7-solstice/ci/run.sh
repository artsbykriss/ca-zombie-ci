#!/usr/bin/env bash
# Heavy/recorded job for p7-solstice (Solana, non-EVM). Read-only simulateTransaction probes.
# No secrets: uses keyless public Solana RPCs only.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
export SOLANA_RPC="${SOLANA_RPC:-https://api.mainnet-beta.solana.com,https://solana-rpc.publicnode.com}"
echo "[p7-solstice] SOLANA_RPC endpoints: $(echo "$SOLANA_RPC" | sed 's/,/ , /g')"
python3 -u ci/collect.py 2>&1 | tee ci-out/solstice_ci.log
echo "[p7-solstice] done; ci-out/solstice_ci.json:"
ls -la ci-out/ || true
