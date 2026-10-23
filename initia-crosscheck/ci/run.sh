#!/usr/bin/env bash
# initia-crosscheck — CI job.
#   Section 1: bridge-lockbox exit re-assessment (Cosmos par-drain bound) + Initia EVM verify
#   Section 2: CWA-2026-006 deployed-engine verification on the exact versions our chains run
#   Section 3: advisory-freshness check (has the withheld trigger detail been published?)
# Read-only; public endpoints only; optional ALCHEMY_API_KEY from the workflow secrets.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
echo "=== initia-crosscheck $(date -u +%FT%TZ) ===" | tee ci-out/runner.log

echo "--- [1/3] bridge-exit enumeration ---" | tee -a ci-out/runner.log
python3 ci/bridge_exit.py 2>&1 | tee -a ci-out/runner.log
echo "[1] exit=$?" | tee -a ci-out/runner.log

echo "--- [2/3] CWA-2026-006 engine verification ---" | tee -a ci-out/runner.log
bash ci/cwa006_check.sh 2>&1 | tee -a ci-out/runner.log
echo "[2] exit=$?" | tee -a ci-out/runner.log

echo "--- [3/3] advisory freshness ---" | tee -a ci-out/runner.log
bash ci/advisory_check.sh 2>&1 | tee -a ci-out/runner.log
echo "[3] exit=$?" | tee -a ci-out/runner.log

ls -la ci-out/ | tee -a ci-out/runner.log
exit 0
