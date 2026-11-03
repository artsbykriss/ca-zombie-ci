#!/usr/bin/env bash
# Z3-C3 Papertrade — CI live re-verification job (read-only).
# Runs from the finding folder root (workflow: working-directory: papertrade).
# 2026-11 escalation: after the original ZH3-C3 snapshot, re-run the contract-set-2 checks and the
# full-cap economics, writing everything to ci-out/ (uploaded as artifacts). Read-only, keyless RPC.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "[ci] papertrade live re-verification $(date -u +%FT%TZ)"
python3 ci/snapshot_ci.py 2>&1 | tee ci-out/ci.log
rc=${PIPESTATUS[0]}
echo "[ci] snapshot_ci.py exit=$rc"

# --- 2026-11 escalation re-verification (contract set 2) ---
export ESCALATION_OUT="$PWD/ci-out"
echo "[ci] escalation: fetching public relayer state"
for i in 1 2 3; do
  curl -s -m 30 -H 'User-Agent: Mozilla/5.0' -H 'Origin: https://exchange.papertrade.xyz' \
    https://exchange.papertrade.xyz/state/trading -o ci-out/escalation_state_trading.json && break
  sleep 3
done
echo "[ci] escalation: live snapshot"
python3 analysis/escalation_snapshot.py > ci-out/escalation_snapshot.log 2>&1
rc2=$?
echo "[ci] escalation_snapshot.py exit=$rc2"
echo "[ci] escalation: live book-move cost"
python3 analysis/escalation_cost.py > ci-out/escalation_cost.log 2>&1
rc3=$?
echo "[ci] escalation_cost.py exit=$rc3"
if [ -s ci-out/escalation_state_trading.json ] && [ -f ci-out/escalation_snapshot.json ] && [ -f ci-out/escalation_cost.json ]; then
  echo "[ci] escalation: economics"
  python3 analysis/escalation_econ.py > ci-out/escalation_econ.log 2>&1
  echo "[ci] escalation_econ.py exit=$?"
  cat ci-out/escalation_econ.log
else
  echo "[ci] escalation: economics skipped (missing inputs)"
fi

# primary job result is the ZH3-C3 snapshot; escalate a failure of the new checks
if [ "$rc" -ne 0 ] || [ "$rc2" -ne 0 ] || [ "$rc3" -ne 0 ]; then exit 1; fi
exit 0
