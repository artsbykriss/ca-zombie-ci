#!/usr/bin/env bash
# Live state dump for FermiSwap at latest block. Read-only. Uses public RPC (faster).
cd "$(dirname "$0")" && source ./env.sh
RPC="https://ethereum-rpc.publicnode.com"
BLOCK=$(cast block-number --rpc-url "$RPC")
SWAP=0xb1076fE3AB5e28005C7c323Bac5AC06a680d452e
VAULT=0x585d44727129B9C69791B10238Ca605932938B4F
ENGINE=0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f

echo "block=$BLOCK"
echo "--- ERC20 balances ---"
while read -r sym addr dec; do
  vb=$(cast call "$addr" 'balanceOf(address)(uint256)' "$VAULT" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
  sb=$(cast call "$addr" 'balanceOf(address)(uint256)' "$SWAP" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
  echo "$sym vault_raw=$vb swapper_raw=$sb"
done <<'EOF'
WETH 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 18
USDT 0xdAC17F958D2ee523a2206206994597C13D831ec7 6
USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 6
cbBTC 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf 8
WBTC 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599 8
EOF
echo "--- allowances vault->swapper ---"
for t in 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 0xdAC17F958D2ee523a2206206994597C13D831ec7 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; do
  a=$(cast call "$t" 'allowance(address,address)(uint256)' "$VAULT" "$SWAP" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}')
  echo "$t allowance=$a"
done
