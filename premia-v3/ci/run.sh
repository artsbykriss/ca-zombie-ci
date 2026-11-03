#!/usr/bin/env bash
# Premia V3 H-2 — heavy CI job.
# Runs the independent pool/vault sweep and the fork checks. Results land in ci-out/.
# Never print or write RPC URLs / API keys.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

python3 -m pip install --quiet eth-abi >/dev/null 2>&1 || true

echo "=== expiry gate (read-only eth_call) ==="
python3 analysis/expiry_gate.py 2>&1 | tee ci-out/expiry-gate.log
cp -f analysis/expiry_gate.json ci-out/expiry_gate.json 2>/dev/null || true

echo "=== pool + vault sweep ==="
python3 analysis/sweep.py --out ci-out/sweep.json 2>&1 | tee ci-out/sweep.log
echo "sweep rc=${PIPESTATUS[0]}"

echo "=== vault reachability (getQuote) ==="
python3 analysis/vault_reachability.py 2>&1 | tee ci-out/vault-reachability.log
cp -f analysis/vault_reachability.json ci-out/vault_reachability.json 2>/dev/null || true

if [ -f poc/foundry.toml ]; then
  echo "=== fork tests: latest state ==="
  ( cd poc && forge test \
      --match-test 'test_expiryGateTopPools|test_settleExpiredPaysNothing|test_largestOpenPoolSettings|test_currentPool' \
      -vvv ) 2>&1 | tee ci-out/fork-latest.log
  echo "fork-latest rc=${PIPESTATUS[0]}"

  echo "=== fork test: historical replay (needs archive RPC) ==="
  ( cd poc && ARCHIVE_REPLAY=true forge test --match-test test_archiveReplay -vvv ) \
    2>&1 | tee ci-out/archive-replay.log
  echo "archive rc=${PIPESTATUS[0]}"
fi

exit 0
