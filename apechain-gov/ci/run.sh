#!/usr/bin/env bash
# ci/run.sh — ApeChain instant-governance target: read-only state evidence.
#
# Runs on GitHub Actions (public runner). Uses ONLY the keyless public ApeChain RPC.
# Sends NO transactions. Writes results to ci-out/ (uploaded as artifacts).
# Always exits 0 so the workflow's `forge test` step still runs.

set -u
RPC="${APE_RPC_URL:-https://rpc.apechain.com/http}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/ci-out"
mkdir -p "$OUT"

APEPREDICTS=0xF609394F0882B732b287db10d1b0F53211a09f75
HOUSE_OLD=0x2054709F89F18a4CCAC6132acE7b812E32608469
CASHORCRASH=0x8c63d2a77480178868A5fd80AF23821a91fD8517
GOVMANAGER=0x8632f22e5A921C751CFbBFF92F058A3b11E96b8a
SAFE=0xb5C3a66741E21CD80eBdDa25479B10A98Ea80c52

which cast >/dev/null 2>&1 || { echo "cast not found; skipping state dump"; exit 0; }

BN=$(cast block-number --rpc-url "$RPC" 2>/dev/null || echo 0)
{
  echo "{"
  echo "  \"block\": $BN,"
  echo "  \"apepredicts_owner\": \"$(cast call $APEPREDICTS 'owner()(address)' --rpc-url "$RPC" 2>/dev/null)\","
  echo "  \"apepredicts_paused\": \"$(cast call $APEPREDICTS 'paused()(bool)' --rpc-url "$RPC" 2>/dev/null)\","
  echo "  \"apepredicts_balance_wei\": \"$(cast balance $APEPREDICTS --rpc-url "$RPC" 2>/dev/null)\","
  echo "  \"house_old_migrator\": \"$(cast call $HOUSE_OLD 'migrator()(address)' --rpc-url "$RPC" 2>/dev/null)\","
  echo "  \"house_old_balance_wei\": \"$(cast balance $HOUSE_OLD --rpc-url "$RPC" 2>/dev/null)\","
  echo "  \"house_old_totalShares\": \"$(cast call $HOUSE_OLD 'totalShares()(uint256)' --rpc-url "$RPC" 2>/dev/null)\","
  echo "  \"cashorcrash_owner\": \"$(cast call $CASHORCRASH 'owner()(address)' --rpc-url "$RPC" 2>/dev/null)\","
  echo "  \"cashorcrash_balance_wei\": \"$(cast balance $CASHORCRASH --rpc-url "$RPC" 2>/dev/null)\","
  echo "  \"govmanager_owner\": \"$(cast call $GOVMANAGER 'owner()(address)' --rpc-url "$RPC" 2>/dev/null)\","
  echo "  \"govmanager_house\": \"$(cast call $GOVMANAGER 'house()(address)' --rpc-url "$RPC" 2>/dev/null)\","
  echo "  \"safe_threshold\": \"$(cast call $SAFE 'getThreshold()(uint256)' --rpc-url "$RPC" 2>/dev/null)\""
  echo "}"
} > "$OUT/state_ci.json" 2>/dev/null

echo "[ci] wrote $OUT/state_ci.json"
cat "$OUT/state_ci.json"
exit 0
