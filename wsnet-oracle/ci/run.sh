#!/usr/bin/env bash
# wsnet-oracle — CI pre-job for the LoopbackOracle / wsNET-USDG Morpho-Blue finding (Robinhood Chain 4663).
#
# Picks a reachable keyless Robinhood RPC, pins a fork block (RH_BLOCK), exports RH_RPC_URL/RH_BLOCK
# for the forge step, and writes two read-only artefacts to ci-out/:
#   - live_state.json   (market / oracle / pair / token state at the pinned block)
#   - oracle_scan.json  (every 4663 Morpho market + oracle classified for thin-pool spot reads)
#
# No secrets, no keyed RPC URLs, no transactions.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

pick() {
  for u in "$@"; do
    [ -z "$u" ] && continue
    r=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
          --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$u" 2>/dev/null)
    case "$r" in *result*) echo "$u"; return 0;; esac
  done
  return 1
}

RH=$(pick "https://robinhood.drpc.org" "https://robinhood-chain.rpc.thirdweb.com" "https://4663.rpc.thirdweb.com" || true)
if [ -z "$RH" ]; then
  echo "WARNING: no Robinhood Chain RPC reachable; skipping snapshot"
  echo '{"error":"no rpc"}' > ci-out/live_state.json
  exit 0
fi
echo "using keyless RPC host: $(echo "$RH" | sed -E 's#(https://[^/]+).*#\1#')"

# Pin the fork block so the Foundry run is reproducible.
BLK=$(curl -s -m 15 -X POST -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$RH" | sed -E 's/.*"result":"(0x[0-9a-fA-F]+)".*/\1/')
echo "pinned fork block: $BLK ($((BLK)))"
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "RH_RPC_URL=$RH" >> "$GITHUB_ENV"
  echo "RH_BLOCK=$((BLK))" >> "$GITHUB_ENV"
fi
export RH_RPC_URL="$RH"
export RH_BLOCK="$((BLK))"

echo "[wsnet-oracle] live snapshot..."
python3 analysis/live_snapshot.py > ci-out/live_state.json && echo "  wrote ci-out/live_state.json"
echo "[wsnet-oracle] oracle classification scan..."
python3 analysis/scan_oracles.py > ci-out/oracle_scan.json && echo "  wrote ci-out/oracle_scan.json"

echo "--- live_state.json (head) ---"
head -c 2200 ci-out/live_state.json
echo
echo "--- oracle_scan.json (head) ---"
head -c 2200 ci-out/oracle_scan.json
echo
echo "[wsnet-oracle] pre-job done"
