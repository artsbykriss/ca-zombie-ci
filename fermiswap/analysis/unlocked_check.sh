#!/usr/bin/env bash
# Check unlocked() for all 8 pairs on engine4 and engine3's registry lanes.
cd "$(dirname "$0")" && source ./env.sh
RPC="https://ethereum-rpc.publicnode.com"
E4=0x0109AA912B58508886a2a707204B0F8C8b164CCc
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7
USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
CBBTC=0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf
WBTC=0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
echo "block=$(cast block-number --rpc-url $RPC) ts=$(cast block latest --rpc-url $RPC --field timestamp)"
echo "=== engine4 unlocked(pair) ==="
for p in "$WETH $USDC" "$WETH $USDT" "$WBTC $USDT" "$WBTC $USDC" "$USDC $USDT" "$CBBTC $USDC" "$CBBTC $USDT" "$WBTC $CBBTC"; do
  set -- $p
  r=$(timeout 12 cast call $E4 'unlocked(address,address)(bool)' $1 $2 --rpc-url "$RPC" 2>&1 | head -1)
  echo "unlocked($1,$2) = $r"
done
