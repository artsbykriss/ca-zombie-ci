#!/usr/bin/env bash
set -u
ARB=https://arb1.arbitrum.io/rpc
USDC=0xaf88d065e77c8cC2239327C5EDb3A432268e5831
USDCe=0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8
WETH=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
ARBTOK=0x912CE59144191C1204E64559FE8253a0e49E6548
for a in 0x9215748657319B17fecb2b5D086A3147BFBC8613 0x818074b77cd95215df23a8402f5e4fdca0ac4d17 0x7b8b944ab2f24c829504a7a6d70fce5298f2147c 0x06a61E55d4d4659b1A23C0F20AEdfc013C489829 0x68a154fB3e8ff6e4DA10ECd54DEF25D9149DDBDE; do
  echo "== $a =="
  echo " USDC=$(cast call $USDC 'balanceOf(address)(uint256)' $a --rpc-url $ARB)"
  echo " USDCe=$(cast call $USDCe 'balanceOf(address)(uint256)' $a --rpc-url $ARB)"
  echo " WETH=$(cast call $WETH 'balanceOf(address)(uint256)' $a --rpc-url $ARB)"
  echo " ARB=$(cast call $ARBTOK 'balanceOf(address)(uint256)' $a --rpc-url $ARB)"
done
