#!/usr/bin/env bash
# Custom CI job for the sbcwrapper finding. Writes a live state snapshot to ci-out/.
# Uses the CI-provided GNOSIS_RPC_URL when present, else a keyless public endpoint.
# NEVER prints the RPC URL or any secret.
set -uo pipefail
cd "$(dirname "$0")/.."   # -> folder root

RPC="${GNOSIS_RPC_URL:-}"
[ -z "$RPC" ] && RPC="https://gnosis-rpc.publicnode.com"

mkdir -p ci-out
W=0x647507A70Ff598F386CB96ae5046486389368C66
MGNO=0x722fc4DAABFEaff81b97894fC623f91814a1BF68
GNO=0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb
PAIR_MGNO_ELK=0x71DE7EA9Cf04eec0530373494544FA57d4dc7a0e
PAIR_MGNO_SUSHI=0xA7B76d37bEEEffc0185DcF4629568194AA151c95

B=$(cast block-number --rpc-url "$RPC" 2>/dev/null || echo 0)
{
  echo "gnosis_block=$B"
  echo "utc=$(date -u +%FT%TZ)"
  echo "wrapper_GNO_balance=$(cast call "$GNO" 'balanceOf(address)(uint256)' "$W" --rpc-url "$RPC" 2>/dev/null)"
  echo "mgno_totalSupply=$(cast call "$MGNO" 'totalSupply()(uint256)' --rpc-url "$RPC" 2>/dev/null)"
  echo "wrapper_paused=$(cast call "$W" 'paused()(bool)' --rpc-url "$RPC" 2>/dev/null)"
  echo "tokenStatus_GNO=$(cast call "$W" 'tokenStatus(address)(uint8)' "$GNO" --rpc-url "$RPC" 2>/dev/null)"
  echo "tokenRate_GNO=$(cast call "$W" 'tokenRate(address)(uint256)' "$GNO" --rpc-url "$RPC" 2>/dev/null)"
  echo "tokenStatus_mGNO=$(cast call "$W" 'tokenStatus(address)(uint8)' "$MGNO" --rpc-url "$RPC" 2>/dev/null)"
  echo "mgno_elk_pool_reserves=$(cast call "$PAIR_MGNO_ELK" 'getReserves()(uint112,uint112,uint32)' --rpc-url "$RPC" 2>/dev/null)"
  echo "mgno_sushi_pool_reserves=$(cast call "$PAIR_MGNO_SUSHI" 'getReserves()(uint112,uint112,uint32)' --rpc-url "$RPC" 2>/dev/null)"
  echo "deposit_contract_GNO_balance=$(cast call "$GNO" 'balanceOf(address)(uint256)' 0x0B98057eA310F4d31F2a452B414647007d1645d9 --rpc-url "$RPC" 2>/dev/null)"
} > ci-out/state_snapshot.txt
cat ci-out/state_snapshot.txt
