#!/usr/bin/env bash
# C2-41 Phase Stake — CI job.
#  1) chain-native (read-only) simulation of the live pool value paths (simulate.js)
#  2) F-1 conditional-path PoC on a local solana-test-validator with cloned accounts
# No secrets are used or printed. Keyless public RPC endpoints only.
# Deps are installed into temp dirs so nothing lands in the (public) repo folder.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

echo "[sim] node: $(node --version)"
DEPS="$(mktemp -d /tmp/phase-stake-deps.XXXXXX)"
( cd "$DEPS" && npm init -y >/dev/null 2>&1 && npm install --no-audit --no-fund --loglevel=error @solana/web3.js@1 >/dev/null 2>&1 )
export NODE_PATH="$DEPS/node_modules"
echo "[sim] deps installed in temp dir (not committed)"
echo "[sim] running live-state simulation..."
node ci/simulate.js 2>&1 | tee ci-out/simulation.log
rc=${PIPESTATUS[0]}
echo "[sim] exit code: $rc"

echo "[f1] running F-1 conditional-path PoC (local validator, non-fatal for the job)..."
bash ci/f1/run.sh > ci-out/f1_ci.log 2>&1
echo "[f1] exit code: $? (see ci-out/f1_ci.log, ci-out/f1_poc.log, ci-out/f1_poc_result.json)"
tail -40 ci-out/f1_ci.log 2>/dev/null || true

ls -la ci-out/
exit $rc
