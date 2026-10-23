#!/usr/bin/env bash
set -u
ARB=https://arb1.arbitrum.io/rpc
USDC=0xaf88d065e77c8cC2239327C5EDb3A432268e5831
USDCe=0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8
WETH=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
FROM=0x0000000000000000000000000000000000001111
for a in 0xc7ec02AEeCdC9087bf848c4C4f790Ed74A93F2AF 0xAdBAeE9665C101413EbFF07e20520bdB67C71AB6; do
  echo "======== $a ========"
  echo "codesize=$(cast codesize $a --rpc-url $ARB)"
  echo "implslot=$(cast storage $a 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url $ARB)"
  echo "USDC=$(cast call $USDC 'balanceOf(address)(uint256)' $a --rpc-url $ARB)"
  echo "USDCe=$(cast call $USDCe 'balanceOf(address)(uint256)' $a --rpc-url $ARB)"
  echo "WETH=$(cast call $WETH 'balanceOf(address)(uint256)' $a --rpc-url $ARB)"
  echo "operator=$(cast call $a 'operator()(address)' --rpc-url $ARB 2>&1 | head -1)"
  echo "registerPair from random EOA:"
  cast call $a "registerPair((address,address,address,address,bool,uint8,(uint128,uint128,int24,int24,uint64,uint64),(uint256,uint256,uint256,uint256),(uint256,uint256,uint256,uint256)))" "(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,0x0000000000000000000000000000000000001111,0xC6962004f452bE9203591991D15f6b388e09E8D0,0x0000000000000000000000000000000000001111,false,0,(100000001,0,1000,500,1005000,1050000),(10000000000000000,900000000000000000,500000000000000000,1000000000000000000),(10000000000000000,900000000000000000,500000000000000000,1000000000000000000))" --from $FROM --rpc-url $ARB 2>&1 | head -3
done
