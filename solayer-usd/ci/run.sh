#!/usr/bin/env bash
# Heavy job for the Solayer USD (sUSD) deep-dive.
#
# Everything here is READ-ONLY against keyless public Solana JSON-RPC:
#   getAccountInfo / getMultipleAccounts / getTokenAccountBalance / getTokenSupply /
#   getSlot / getSignaturesForAddress / getTransaction /
#   simulateTransaction(sigVerify=false, replaceRecentBlockhash=true)
# Nothing is signed or broadcast. No secrets / keyed RPC URLs are used.
set -uo pipefail

echo "[solayer-usd] start $(date -u +%FT%TZ)"
python3 --version
cd "$(dirname "$0")"
mkdir -p ../ci-out

python3 sim_matrix.py 2>&1 | tee ../ci-out/solayer_sim.log
rc=${PIPESTATUS[0]}
echo "[solayer-usd] python exit=$rc"

ls -la ../ci-out
echo "[solayer-usd] done $(date -u +%FT%TZ)"
exit $rc
