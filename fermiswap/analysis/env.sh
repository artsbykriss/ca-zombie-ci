#!/usr/bin/env bash
# Safe env loader: exports RPC vars from /home/heisenberg/CA/.env without printing them.
# Usage: source /home/heisenberg/CA/fermiswap/analysis/env.sh
set -a
while IFS='=' read -r k v; do
  case "$k" in
    RPC_URL|NODEREAL_ETH_RPC_URL|BLOCKPI_RPC_URL|ALCHEMY_API_KEY|INFURA_API_KEY|ANKR_API_KEY|DRPC_API_KEY|ETHERSCANV2_API_KEY|GOLD_RUSH_API_KEY|DUNE_API_KEY)
      # strip surrounding quotes
      v="${v%\"}"; v="${v#\"}"
      export "$k=$v"
      ;;
  esac
done < /home/heisenberg/CA/.env
set +a
# pick a working eth rpc: prefer NODEREAL, then BLOCKPI, then public
if cast chain-id --rpc-url "$NODEREAL_ETH_RPC_URL" >/dev/null 2>&1; then
  export ETH_RPC="$NODEREAL_ETH_RPC_URL"
elif cast chain-id --rpc-url "$BLOCKPI_RPC_URL" >/dev/null 2>&1; then
  export ETH_RPC="$BLOCKPI_RPC_URL"
else
  export ETH_RPC="https://ethereum-rpc.publicnode.com"
fi
