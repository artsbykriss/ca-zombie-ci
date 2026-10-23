#!/usr/bin/env bash
# Read-only live-state dump for the MUX deep-dive (keyless public RPC; no secrets).
set -uo pipefail
R="${ARB_RPC_URL:-https://arb1.arbitrum.io/rpc}"
OUT="$(dirname "$0")/live-state.json"

OB=0xa19fD5aB6C8DCffa2A295F78a5Bb4aC543AAF5e3          # MUX v1 OrderBook (TransparentProxy)
OB_IMPL=0xFD92e0b7107488b095cA98E50BE128fee2a35879     # OrderBook impl
LP=0x3e0199792Ce69DC29A0a36146bFa68bd7C8D6633          # MUX v1 LiquidityPool (chained proxy)
LP_HOP1=0x9588535Df27aEAD7BBf2520892852B220ec36F15
LP_HOP2=0xad367F665AeEb1D57764BbDcBFAB5Be5327632dA
MYX=0x45de6f4Ddc91B4353e9e0fF5d714bd1F8C113851        # pass5 "MUX Pool" -> actually MYX Pool impl
MUX3=0x85c8F4a67F4f9AD7b38e875c8FeDE7F4c878bFAc        # MUX3 core diamond
MUX3_OB=0x8ec387586a709ECE1a9Ea83c6163c3616D8E16b4    # MUX3 OrderBook proxy
MUX3_CP=0x13BB10542Aa9C0792d6FFe56bf123cE20A159A20    # MUX3 CollateralPool beacon proxy #1
CBREG=0xd2Df81619E20C6699B7f2153f8A2395e5Bb2C74C      # CallbackRegister
ATT=0xBAd0000000000000000000000000000000000Bad
USDCE=0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8
WETH=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
ARB=0x912CE59144191C1204E64559FE8253a0e49E6548

blk=$(cast block-number --rpc-url "$R")
j() { cast call "$1" "$2" ${3:+$3} --rpc-url "$R" 2>/dev/null | head -1; }
size() { cast codesize "$1" --rpc-url "$R"; }

cat > "$OUT" <<JSON
{
  "chain": "arbitrum",
  "block": $blk,
  "mux_v1_orderbook": {
    "address": "$OB", "codesize": $(size $OB),
    "impl_eip1967": "$(cast storage $OB 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url $R)",
    "owner": "$(j $OB 'owner()(address)')",
    "maintainer": "$(j $OB 'maintainer()(address)')",
    "getOrderCount": $(j $OB 'getOrderCount()(uint256)'),
    "brokers_attacker": "$(j $OB 'brokers(address)(bool)' $ATT)",
    "isPositionOrderPaused": "$(j $OB 'isPositionOrderPaused()(bool)')",
    "isLiquidityOrderPaused": "$(j $OB 'isLiquidityOrderPaused()(bool)')",
    "callbackWhitelist_attacker": "$(j $OB 'callbackWhitelist(address)(bool)' $ATT)"
  },
  "mux_v1_liquiditypool": {
    "address": "$LP", "codesize": $(size $LP),
    "impl_hop1": "$LP_HOP1", "hop2": "$LP_HOP2",
    "usdce_raw": "$(j $USDCE 'balanceOf(address)(uint256)' $LP | awk '{print $1}')",
    "weth_raw": "$(j $WETH 'balanceOf(address)(uint256)' $LP | awk '{print $1}')",
    "arb_raw": "$(j $ARB 'balanceOf(address)(uint256)' $LP | awk '{print $1}')"
  },
  "pass5_named_pool": {
    "address": "$MYX", "codesize": $(size $MYX),
    "identity": "MYX Protocol contracts/pool/Pool.sol (myx-protocol/myx-contracts) - NOT MUX",
    "positionManager": "$(j $MYX 'positionManager()(address)')",
    "feeCollector": "$(j $MYX 'feeCollector()(address)')",
    "pairsIndex": $(j $MYX 'pairsIndex()(uint256)'),
    "lifetime_tx": 1
  },
  "mux3": {
    "core": "$MUX3", "orderbook": "$MUX3_OB",
    "orderbook_fillPositionOrder_nonbroker": "revert (missing BROKER_ROLE)",
    "collateral_pool_sample": "$MUX3_CP",
    "collateral_pool_addLiquidity_nonorderbook": "revert onlyOrderBook",
    "callbackRegister_isCallbackRegistered_attacker": "$(j $CBREG 'isCallbackRegistered(address)(bool)' $ATT)"
  }
}
JSON
echo "wrote $OUT"
cat "$OUT"
