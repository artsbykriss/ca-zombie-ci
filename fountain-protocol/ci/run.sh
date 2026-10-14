#!/usr/bin/env bash
# Fountain Protocol (Oasis) — custom CI job.
# 1) build the fork's legacy sources (solc 0.5.16) for bytecode verification
# 2) compare compiled runtime bytecode against deployed Emerald code
# 3) enumerate live positions (Nexus tx history + Emerald RPC) for E-U/H-O/S accounting
# 4) run the fork PoC against a LOCAL anvil fork (pinned block) and leave anvil running
#    so the workflow's `forge test` step also executes the suite.
set -uo pipefail
mkdir -p ci-out

echo "=== [1/4] legacy build (solc 0.5.16) ==="
( cd verify && forge build ) > ci-out/verify-build.log 2>&1 || { echo "verify build FAILED"; tail -25 ci-out/verify-build.log; }

echo "=== [2/4] bytecode comparison vs Emerald deployed code ==="
python3 ci/verify_bytecode.py --dir verify --out ci-out/bytecode-verify.json || true

echo "=== [3/4] live enumeration ==="
python3 ci/enumerate.py --out ci-out/enumeration.json --max-pages 40 || true

echo "=== [4/4] fork PoC: local anvil fork of Emerald @ block 22380248 ==="
anvil --fork-url "${OASIS_FORK_SOURCE:-https://emerald.oasis.dev}" \
      --fork-block-number 22380248 \
      --port 8545 --host 127.0.0.1 \
      --fork-retry-backoff 3000 --retries 10 \
      > ci-out/anvil.log 2>&1 &
ANVIL_PID=$!
READY=0
for i in $(seq 1 60); do
  if cast block-number --rpc-url http://127.0.0.1:8545 >/dev/null 2>&1; then READY=1; echo "anvil ready (pid $ANVIL_PID)"; break; fi
  sleep 2
done
if [ "$READY" = "1" ]; then
  ( cd poc && OASIS_RPC=http://127.0.0.1:8545 forge test -vvv ) 2>&1 | tee ci-out/fork-tests.log || echo "fork tests FAILED (see ci-out/fork-tests.log)"
  echo "(anvil left running for the workflow's forge-test step: pid $ANVIL_PID)"
else
  echo "anvil did not become ready; see ci-out/anvil.log"; tail -20 ci-out/anvil.log
fi

echo "=== ci-out contents ==="
ls -la ci-out/ | head -20
