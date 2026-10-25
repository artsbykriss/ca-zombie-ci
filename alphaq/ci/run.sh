#!/usr/bin/env bash
# Heavy job for the AlphaQ (Solana) deep-dive.
#
# Everything here is READ-ONLY against keyless public Solana JSON-RPC:
#   getAccountInfo / getProgramAccounts / getMultipleAccounts /
#   getSignaturesForAddress / getTransaction /
#   simulateTransaction(sigVerify=false, replaceRecentBlockhash=true)
# Nothing is signed or broadcast. No secrets / keyed RPC URLs are used.
set -uo pipefail

echo "[alphaq] start $(date -u +%FT%TZ)"
python3 --version
cd "$(dirname "$0")"
mkdir -p ../ci-out

python3 solana_scan.py 2>&1 | tee ../ci-out/solana_scan.log
rc=${PIPESTATUS[0]}
echo "[alphaq] python exit=$rc"

ls -la ../ci-out
echo "[alphaq] done $(date -u +%FT%TZ)"
exit $rc
