#!/usr/bin/env bash
set -u
ARB=https://arb1.arbitrum.io/rpc
USDC=0xaf88d065e77c8cc2239327c5edb3a432268e5831
WETH=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
for a in 0x9215748657319B17fecb2b5D086A3147BFBC8613 0x4006A8840F8640A7D8F46D2c3155a58c76eCD56e 0x68a154fB3e8ff6e4DA10ECd54DEF25D9149DDBDE 0x06a61E55d4d4659b1A23C0F20AEdfc013C489829 0x818074b77cd95215df23a8402f5e4fdca0ac4d17 0x4f071924D66BBC71A5254217893CC7D49938B1c4; do
  u=$(cast call $USDC "balanceOf(address)(uint256)" $a --rpc-url $ARB 2>/dev/null)
  w=$(cast call $WETH "balanceOf(address)(uint256)" $a --rpc-url $ARB 2>/dev/null)
  cs=$(cast codesize $a --rpc-url $ARB 2>/dev/null)
  echo "$a codesize=$cs USDC=$u WETH=$w"
done
