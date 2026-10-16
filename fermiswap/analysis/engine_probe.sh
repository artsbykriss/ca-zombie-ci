#!/usr/bin/env bash
# Read-only probes of the Fermi engine at latest block.
cd "$(dirname "$0")" && source ./env.sh
RPC="$ETH_RPC"
ENGINE=0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f
SWAP=0xb1076fE3AB5e28005C7c323Bac5AC06a680d452e
echo "block=$(cast block-number --rpc-url $RPC)"
echo "--- engine.swapper() ---"
cast call $ENGINE 'swapper()(address)' --rpc-url $RPC
echo "--- engine.traderVault() ---"
cast call $ENGINE 'traderVault()(address)' --rpc-url $RPC
echo "--- engine.VERSION() ---"
cast call $ENGINE 'VERSION()(uint256)' --rpc-url $RPC
echo "--- engine.getPairs() ---"
cast call $ENGINE 'getPairs()((address,address,bool)[])' --rpc-url $RPC
echo "--- isActive probes ---"
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7
USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
CBBTC=0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf
WBTC=0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
for pair in "$WETH $USDT" "$WETH $USDC" "$USDC $WETH" "$USDT $WETH" "$CBBTC $WETH" "$WBTC $WETH" "$CBBTC $USDT"; do
  set -- $pair
  r=$(cast call $ENGINE 'isActive(address,address)(bool)' $1 $2 --rpc-url $RPC 2>&1 | head -1)
  echo "isActive($1,$2) = $r"
done
