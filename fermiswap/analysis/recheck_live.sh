#!/usr/bin/env bash
# Re-check live state: balances + unlocked + recent activity.
cd "$(dirname "$0")" && source ./env.sh
RPC="https://ethereum-rpc.publicnode.com"
VAULT=0x585d44727129B9C69791B10238Ca605932938B4F
SWAP2=0x5979458912F80B96d30D4220af8E2e4925A33320
E4=0x0109AA912B58508886a2a707204B0F8C8b164CCc
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7
WBTC=0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
CBBTC=0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf
echo "block=$(cast block-number --rpc-url $RPC) ts=$(cast block latest --rpc-url $RPC --field timestamp)"
for t in "$WETH WETH" "$USDC USDC" "$USDT USDT" "$WBTC WBTC" "$CBBTC cbBTC"; do
  set -- $t
  echo "vault $2: $(cast call $1 'balanceOf(address)(uint256)' $VAULT --rpc-url $RPC)"
done
echo "unlocked(WETH,USDC) = $(cast call $E4 'unlocked(address,address)(bool)' $WETH $USDC --rpc-url $RPC)"
