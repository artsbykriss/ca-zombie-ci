#!/usr/bin/env bash
# Read-only live-state re-verification for the MUX deep-dive.
# Writes JSON to ci-out/ ; NEVER prints or writes secrets.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
R="${ARB_RPC_URL:-https://arb1.arbitrum.io/rpc}"
OB=0xa19fD5aB6C8DCffa2A295F78a5Bb4aC543AAF5e3
LP=0x3e0199792Ce69DC29A0a36146bFa68bd7C8D6633
MYX=0x45de6f4Ddc91B4353e9e0fF5d714bd1F8C113851
ATT=0xBAd0000000000000000000000000000000000Bad
USDCE=0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8
WETH=0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
ARB=0x912CE59144191C1204E64559FE8253a0e49E6548

blk=$(cast block-number --rpc-url "$R")
obcode=$(cast codesize "$OB" --rpc-url "$R")
lpcode=$(cast codesize "$LP" --rpc-url "$R")
myxcode=$(cast codesize "$MYX" --rpc-url "$R")
orders=$(cast call "$OB" "getOrderCount()(uint256)" --rpc-url "$R" 2>/dev/null)
broker=$(cast call "$OB" "brokers(address)(bool)" "$ATT" --rpc-url "$R" 2>/dev/null)
owner=$(cast call "$OB" "owner()(address)" --rpc-url "$R" 2>/dev/null)
maint=$(cast call "$OB" "maintainer()(address)" --rpc-url "$R" 2>/dev/null)
paused=$(cast call "$OB" "isPositionOrderPaused()(bool)" --rpc-url "$R" 2>/dev/null)
lp_usdce=$(cast call "$USDCE" "balanceOf(address)(uint256)" "$LP" --rpc-url "$R" 2>/dev/null | awk '{print $1}')
lp_weth=$(cast call "$WETH" "balanceOf(address)(uint256)" "$LP" --rpc-url "$R" 2>/dev/null | awk '{print $1}')
lp_arb=$(cast call "$ARB" "balanceOf(address)(uint256)" "$LP" --rpc-url "$R" 2>/dev/null | awk '{print $1}')
myx_pm=$(cast call "$MYX" "positionManager()(address)" --rpc-url "$R" 2>/dev/null)
myx_pairs=$(cast call "$MYX" "pairsIndex()(uint256)" --rpc-url "$R" 2>/dev/null)

cat > ci-out/mux-live-state.json <<JSON
{
  "chain": "arbitrum",
  "block": $blk,
  "orderBook": "$OB",
  "orderBook_codesize": $obcode,
  "liquidityPool": "$LP",
  "liquidityPool_codesize": $lpcode,
  "pass5_named_pool_0x45de": "$MYX",
  "pass5_named_pool_codesize": $myxcode,
  "pass5_named_pool_identity": "MYX Protocol Pool implementation (NOT MUX); uninitialized",
  "orderBook_getOrderCount": $orders,
  "orderBook_brokers_attacker": "$broker",
  "orderBook_owner": "$owner",
  "orderBook_maintainer": "$maint",
  "orderBook_isPositionOrderPaused": "$paused",
  "pool_usdce_raw": $lp_usdce,
  "pool_weth_raw": $lp_weth,
  "pool_arb_raw": $lp_arb,
  "myx_positionManager": "$myx_pm",
  "myx_pairsIndex": $myx_pairs
}
JSON
echo "wrote ci-out/mux-live-state.json"
cat ci-out/mux-live-state.json
