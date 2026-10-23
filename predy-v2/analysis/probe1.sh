#!/usr/bin/env bash
set -u
ARB=https://arb1.arbitrum.io/rpc
P=0x9215748657319B17fecb2b5D086A3147BFBC8613
SIG='registerPair((address,address,address,address,bool,uint8,(uint128,uint128,int24,int24,uint64,uint64),(uint256,uint256,uint256,uint256),(uint256,uint256,uint256,uint256)))'
ARGS='(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,0x0000000000000000000000000000000000001111,0xC6962004f452bE9203591991D15f6b388e09E8D0,0x0000000000000000000000000000000000001111,false,0,(100000001,0,1000,500,1005000,1050000),(10000000000000000,900000000000000000,500000000000000000,1000000000000000000),(10000000000000000,900000000000000000,500000000000000000,1000000000000000000))'
echo "== selector =="; cast sig "$SIG"
echo "== eth_call from random EOA =="
cast call "$P" "$SIG" "$ARGS" --from 0x0000000000000000000000000000000000001111 --rpc-url "$ARB" 2>&1 | head -6
echo "== eth_call from operator =="
cast call "$P" "$SIG" "$ARGS" --from 0x4f071924D66BBC71A5254217893CC7D49938B1c4 --rpc-url "$ARB" 2>&1 | head -6
echo "== raw getPairStatus(1) =="
cast call "$P" "getPairStatus(uint256)" 1 --rpc-url "$ARB" 2>&1 | head -3
echo "== raw getPairStatus(2) =="
cast call "$P" "getPairStatus(uint256)" 2 --rpc-url "$ARB" 2>&1 | head -3
echo "== globalData() raw len =="
cast call "$P" "globalData()" --rpc-url "$ARB" 2>&1 | head -2 | cut -c1-80
