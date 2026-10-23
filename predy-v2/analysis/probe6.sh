#!/usr/bin/env bash
set -u
ARB=https://arb1.arbitrum.io/rpc
USDC=0xaf88d065e77c8c2239327c5edb3a432268e5831
WETH=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
ARBTOK=0x912CE59144191C1204E64559FE8253a0e49E6548
bal(){ for i in 1 2 3; do r=$(cast call "$1" "balanceOf(address)(uint256)" "$2" --rpc-url $ARB 2>/dev/null); [ -n "$r" ] && { echo "$r"; return; }; sleep 1; done; echo "ERR"; }
for a in 0x7b8b944ab2f24c829504a7a6d70fce5298f2147c 0x9215748657319B17fecb2b5D086A3147BFBC8613; do
  echo "== $a =="
  echo " USDC=$(bal $USDC $a) WETH=$(bal $WETH $a) ARB=$(bal $ARBTOK $a)"
  echo " implslot=$(cast storage $a 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url $ARB 2>/dev/null)"
  echo " admin slot=$(cast storage $a 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103 --rpc-url $ARB 2>/dev/null)"
done
