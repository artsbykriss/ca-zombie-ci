#!/usr/bin/env bash
# Current allowances from the traderVault to all known spenders. Read-only.
cd "$(dirname "$0")" && source ./env.sh
RPC="$ETH_RPC"
VAULT=0x585d44727129B9C69791B10238Ca605932938B4F
echo "block=$(cast block-number --rpc-url $RPC)"
SPENDERS="0xb4723899a492330fedaccf22ec12f53a06e3b659 0xb1076fe3ab5e28005c7c323bac5ac06a680d452e 0x5979458912f80b96d30d4220af8e2e4925a33320 0x2b03909525e4443b7203ac6e6f5a38b3465c6cfa 0xeff407d968de7d312fd5e036aef8837b3679d777"
TOKENS="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 0xdAC17F958D2ee523a2206206994597C13D831ec7 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
for sp in $SPENDERS; do
  echo "== spender $sp code=$(cast codesize $sp --rpc-url $RPC)"
  for tok in $TOKENS; do
    a=$(cast call "$tok" 'allowance(address,address)(uint256)' "$VAULT" "$sp" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
    echo "   $tok -> $a"
  done
done
