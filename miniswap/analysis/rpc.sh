#!/usr/bin/env bash
# Echo the first Ethereum RPC URL that answers BOTH eth_blockNumber and a real eth_call. Keys from env; never persisted.
set -uo pipefail
ENVF=/home/heisenberg/CA/.env
getk(){ grep "^$1=" "$ENVF" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"'; }
# fast path: cached working URL (outside the synced folder)
CACHE=/tmp/opencode/.miniswap_rpc
if [ -f "$CACHE" ]; then
  cu=$(cat "$CACHE")
  if timeout 10 cast block-number --rpc-url "$cu" >/dev/null 2>&1; then echo "$cu"; exit 0; fi
fi
CAND=()
U=$(getk ALCHEMY_API_KEY); [ -n "$U" ] && CAND+=("https://eth-mainnet.g.alchemy.com/v2/$U")
U=$(getk ANKR_API_KEY); [ -n "$U" ] && CAND+=("https://rpc.ankr.com/eth/$U")
U=$(getk INFURA_API_KEY); [ -n "$U" ] && CAND+=("https://mainnet.infura.io/v3/$U")
U=$(getk DRPC_API_KEY); [ -n "$U" ] && CAND+=("https://lb.drpc.org/ogrpc?network=ethereum&dkey=$U")
U=$(getk NODEREAL_ETH_RPC_URL); [ -n "$U" ] && CAND+=("$U")
U=$(getk BLOCKPI_RPC_URL); [ -n "$U" ] && CAND+=("$U")
CAND+=("https://ethereum-rpc.publicnode.com" "https://eth.drpc.org" "https://1rpc.io/eth" "https://rpc.ankr.com/eth")
# USDC symbol() call as the eth_call probe
DATA=0x95d89b41
for u in "${CAND[@]}"; do
  [ -z "$u" ] && continue
  bn=$(timeout 15 cast block-number --rpc-url "$u" 2>/dev/null) || continue
  [ -z "$bn" ] && continue
  sym=$(timeout 15 cast call --rpc-url "$u" 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48 "$DATA" 2>/dev/null) || continue
  if [ -n "$sym" ]; then echo "$u"; exit 0; fi
done
echo "NO_RPC" >&2; exit 1
