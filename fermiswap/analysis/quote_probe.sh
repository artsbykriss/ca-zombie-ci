#!/usr/bin/env bash
# Quote probes. Positive amountSpecified = exact input; negative = exact output (guess).
cd "$(dirname "$0")" && source ./env.sh
RPC="$ETH_RPC"
ENGINE=0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f
SENDER=0x000000000000000000000000000000000000dEaD
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7
USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
WBTC=0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
echo "block=$(cast block-number --rpc-url $RPC)"
q() { # tokenIn tokenOut amountSpecified(label)
  r=$(cast call $ENGINE 'quote(address,address,int256,address)(uint256,uint256)' $1 $2 $3 $SENDER --rpc-url $RPC 2>&1 | tr '\n' ' ')
  echo "quote($4) -> $r"
}
echo "=== WETH->USDC ==="
q $WETH $USDC 1000000000000000 "0.001 WETH in"
q $WETH $USDC 10000000000000000 "0.01 WETH in"
q $WETH $USDC 100000000000000000 "0.1 WETH in"
q $WETH $USDC 1000000000000000000 "1 WETH in"
q $WETH $USDC 10000000000000000000 "10 WETH in"
q $WETH $USDC 100000000000000000000 "100 WETH in"
echo "=== WETH->USDC exact-out ==="
q $WETH $USDC -1000000000 "-1000 USDC out"
q $WETH $USDC -100000000000 "-100k USDC out"
echo "=== USDC->USDT ==="
q $USDC $USDT 1000000000 "1000 USDC in"
q $USDC $USDT 100000000000 "100k USDC in"
q $USDC $USDT 1000000000000 "1M USDC in"
echo "=== WBTC->USDT ==="
q $WBTC $USDT 100000000 "1 WBTC in"
q $WBTC $USDT 10000000 "0.1 WBTC in"
echo "=== WETH->USDT ==="
q $WETH $USDT 1000000000000000000 "1 WETH in"
