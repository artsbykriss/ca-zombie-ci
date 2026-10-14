#!/usr/bin/env bash
# Bril Finance (BSC) — CI heavy job.
# 1) re-scan the live "ready to rebalance" set at the fork block (all 77 strategy clones)
# 2) run the fork PoC suite with full traces
# Writes results to ci-out/ (uploaded as artifacts). Never prints secrets.
set -uo pipefail
cd "$(dirname "$0")/.."   # folder root
mkdir -p ci-out

# pick a working keyless BSC RPC for the fork (probe; never prints secrets)
pick() {
  for u in "$@"; do
    [ -z "$u" ] && continue
    r=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
          --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$u" 2>/dev/null)
    case "$r" in *result*) echo "$u"; return 0;; esac
  done
  return 1
}
BRIL_RPC=$(pick "$BSC_RPC_URL" "https://bsc-rpc.publicnode.com" "https://1rpc.io/bnb" "https://bsc.drpc.org" || true)
export BRIL_RPC
echo "[bril] fork rpc selected: $(echo "$BRIL_RPC" | sed -E 's#(dkey=|/v2/)[A-Za-z0-9_-]+#\1REDACTED#')"

echo "[bril] python ready-scan"
python3 ci/scan_ready.py > ci-out/ready-scan.log 2>&1 || echo "[bril] scan failed (see log)"

echo "[bril] python module-scan (all Safe modules)"
python3 ci/scan_modules.py > ci-out/modules-scan.log 2>&1 || echo "[bril] module scan failed (see log)"

echo "[bril] forge test -vvvv"
cd poc
forge test -vvvv --match-contract BrilLiveTest > ../ci-out/forge-bril.log 2>&1
RC=$?
echo "[bril] forge exit code: $RC"
tail -n 120 ../ci-out/forge-bril.log
cd ..
exit $RC
