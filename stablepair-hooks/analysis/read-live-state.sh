#!/usr/bin/env bash
# Read-only live-state reader for the StablePairHook / VolatilePairHook family.
# Public keyless RPCs only; no secrets, no transactions.
set -euo pipefail
RPC_ETH="${ETH_RPC:-https://ethereum-rpc.publicnode.com}"
RPC_ARB="${ARB_RPC:-https://arb1.arbitrum.io/rpc}"
PM_ETH=0x000000000004444c5dc75cB358380D2e3dE08A90
PM_ARB=0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32
SV_ETH=0x7fFE42C4a5DEeA5b0feC41C94C136Cf115597227
SV_ARB=0x76fd297e2d437cd7f76d50f01afe6160f86e9990
echo "eth_block=$(cast block-number --rpc-url $RPC_ETH)"
echo "arb_block=$(cast block-number --rpc-url $RPC_ARB)"
for H in 0x0000113dCf4ADd69999Fad8F20F2b63F979bfcC0 0x000022Ec4eBD6b12294396E852E4C3876b253Cc0; do
  echo "hook=$H poolManager=$(cast call $H 'poolManager()(address)' --rpc-url $RPC_ETH)"
  echo "hook=$H permissions=$(cast call $H 'getHookPermissions()((bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool,bool))' --rpc-url $RPC_ETH | tr -d '\n')"
  echo "hook=$H admin=$(cast call $H 'hasRole(bytes32,address)(bool)' 0x0000000000000000000000000000000000000000000000000000000000000000 0x1a9C8182C09F50C8318d769245beA52c32BE35BC --rpc-url $RPC_ETH)"
  echo "hook=$H cfgMgr=$(cast call $H 'hasRole(bytes32,address)(bool)' 0xbbfb55d933c2bfa638763473275b1d84c4418e58d26cf9d2cd5758237756d9f0 0x1a9C8182C09F50C8318d769245beA52c32BE35BC --rpc-url $RPC_ETH)"
  echo "hook=$H poolInit=$(cast call $H 'hasRole(bytes32,address)(bool)' 0x57040554eeb1644881e12709b5b3f4551135b4c3895f51421ab6ce98a9be00bd 0xfc43582532e90fa8726fe9cdb5fad48f4e487d27 --rpc-url $RPC_ETH)"
done
echo "stable fee USDC/USDT=$(cast call 0x0000113dCf4ADd69999Fad8F20F2b63F979bfcC0 'getFee((address,address,uint24,int24,address))(uint24,uint24)' '(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,0xdAC17F958D2ee523a2206206994597C13D831ec7,8388608,1,0x0000113dCf4ADd69999Fad8F20F2b63F979bfcC0)' --rpc-url $RPC_ETH | tr -d '\n')"
echo "stable fee USDC/USDG=$(cast call 0x0000113dCf4ADd69999Fad8F20F2b63F979bfcC0 'getFee((address,address,uint24,int24,address))(uint24,uint24)' '(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,0xe343167631d89B6Ffc58B88d6b7fB0228795491D,8388608,1,0x0000113dCf4ADd69999Fad8F20F2b63F979bfcC0)' --rpc-url $RPC_ETH | tr -d '\n')"
echo "volatile fee ETH/USDC=$(cast call 0x000022Ec4eBD6b12294396E852E4C3876b253Cc0 'getFee((address,address,uint24,int24,address))(uint24,uint24)' '(0x0000000000000000000000000000000000000000,0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,8388608,4,0x000022Ec4eBD6b12294396E852E4C3876b253Cc0)' --rpc-url $RPC_ETH | tr -d '\n')"
echo "arb stable fee USDG/USDC=$(cast call 0x630e9CaC0ffF557Bd3A01DAa111ed253c771Bcc0 'getFee((address,address,uint24,int24,address))(uint24,uint24)' '(0x004B506865409877C9fA29Bfb1eBA929984B9bBC,0xaf88d065e77c8cC2239327C5EDb3A432268e5831,8388608,1,0x630e9CaC0ffF557Bd3A01DAa111ed253c771Bcc0)' --rpc-url $RPC_ARB | tr -d '\n')"
for pid in 0x2b21c65d9a7dc6926ee330a1c6e5a8037fd81774f3dc066536f800128e39f634 0xeda62d2906d0edf26d40c793d581609552a44a87f618a98ff76ebe8dde4b7edb 0x98316e8405502774a5d0a0761276b5d26505a8195c1905169864008d5e7a3eea; do
  echo "pid=$pid slot0=$(cast call $SV_ETH 'getSlot0(bytes32)(uint160,int24,uint24,uint24)' $pid --rpc-url $RPC_ETH | tr -d '\n') liquidity=$(cast call $SV_ETH 'getLiquidity(bytes32)(uint128)' $pid --rpc-url $RPC_ETH)"
done
echo "pid=0x52b42d5f1e4a0d4bce86667bb069cf257e512d98ce617f549f6e4fbb0bee41e6 slot0=$(cast call $SV_ARB 'getSlot0(bytes32)(uint160,int24,uint24,uint24)' 0x52b42d5f1e4a0d4bce86667bb069cf257e512d98ce617f549f6e4fbb0bee41e6 --rpc-url $RPC_ARB | tr -d '\n') liquidity=$(cast call $SV_ARB 'getLiquidity(bytes32)(uint128)' 0x52b42d5f1e4a0d4bce86667bb069cf257e512d98ce617f549f6e4fbb0bee41e6 --rpc-url $RPC_ARB)"
