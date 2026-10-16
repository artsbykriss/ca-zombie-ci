#!/usr/bin/env bash
# Live state dump for FermiSwap at latest block. Read-only.
cd "$(dirname "$0")" && source ./env.sh
BLOCK=$(cast block-number --rpc-url "$ETH_RPC")
SWAP=0xb1076fE3AB5e28005C7c323Bac5AC06a680d452e
VAULT=0x585d44727129B9C69791B10238Ca605932938B4F
ENGINE=0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f

echo "block=$BLOCK"
echo "--- ETH balances ---"
echo "vault ETH: $(cast balance $VAULT --rpc-url $ETH_RPC)"
echo "swapper ETH: $(cast balance $SWAP --rpc-url $ETH_RPC)"
echo "engine ETH: $(cast balance $ENGINE --rpc-url $ETH_RPC)"
echo "--- ERC20 balances ---"
while read -r sym addr; do
  vb=$(cast call "$addr" 'balanceOf(address)(uint256)' "$VAULT" --rpc-url "$ETH_RPC" 2>/dev/null | awk '{print $1}')
  sb=$(cast call "$addr" 'balanceOf(address)(uint256)' "$SWAP" --rpc-url "$ETH_RPC" 2>/dev/null | awk '{print $1}')
  eb=$(cast call "$addr" 'balanceOf(address)(uint256)' "$ENGINE" --rpc-url "$ETH_RPC" 2>/dev/null | awk '{print $1}')
  echo "$sym vault=$vb swapper=$sb engine=$eb"
done <<'EOF'
WETH 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
USDT 0xdAC17F958D2ee523a2206206994597C13D831ec7
USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
cbBTC 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf
WBTC 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
WSTETH 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0
USDE 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3
EOF
