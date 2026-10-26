#!/usr/bin/env bash
# Flying Tulip Lend — light pre-job for CI.
# Snapshots the live Ethereum oracle/config state into ci-out/live-state.json.
# No secrets: the RPC endpoint is taken from the environment and never written out.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
FORK_RPC_URL="$RPC" python3 analysis/snapshot.py ci-out/live-state.json

# Record only a redacted endpoint label (host is not a secret; path/query never written).
echo '{"rpc":"<redacted>"}' > ci-out/rpc-label.json
echo "snapshot complete:"; ls -la ci-out/
