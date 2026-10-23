#!/usr/bin/env bash
set -u
ARB=https://arb1.arbitrum.io/rpc
USDC=0xaf88d065e77c8c2239327c5edb3a432268e5831
USDCe=0xff970a61a04b1ca14834a43f5de4533ebddb5cc8
WETH=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
for a in 0x7b8b944ab2f24c829504a7a6d70fce5298f2147c 0x4b748969Ab77C9d09AE07b4282A151B82F96311B 0xef299c799ccB9b322078148636683DDE5C50cA96 0xF0Dc8188FCbCaB732628b69dDDBFcc2a803afeDA 0xb79714634895f52a4f6a75ecEb58C96246370149; do
  u=$(cast call $USDC "balanceOf(address)(uint256)" $a --rpc-url $ARB 2>/dev/null)
  ue=$(cast call $USDCe "balanceOf(address)(uint256)" $a --rpc-url $ARB 2>/dev/null)
  w=$(cast call $WETH "balanceOf(address)(uint256)" $a --rpc-url $ARB 2>/dev/null)
  cs=$(cast codesize $a --rpc-url $ARB 2>/dev/null)
  echo "$a code=$cs USDC=$u USDCe=$ue WETH=$w"
done
