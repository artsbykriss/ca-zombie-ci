#!/usr/bin/env bash
# morpho-wspyx heavy job: run the fork PoC and persist results to ci-out/ (uploaded as artifacts).
set -uo pipefail
cd "$(dirname "$0")/.."          # -> morpho-wspyx/
mkdir -p ci-out
export FORK_RPC_URL="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
echo "fork rpc set: $([ -n "${FORK_RPC_URL:-}" ] && echo yes || echo no)" > ci-out/env.txt

cd poc
forge test -vv > ../ci-out/forge-test.log 2>&1
rc=$?
grep -E "^\[PASS|^\[FAIL|Suite result" ../ci-out/forge-test.log > ../ci-out/results.txt 2>/dev/null || true
echo "forge test exit code: $rc" >> ../ci-out/results.txt
cat ../ci-out/results.txt
exit $rc
