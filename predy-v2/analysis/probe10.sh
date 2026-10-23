#!/usr/bin/env bash
set -u
ARB=https://arb1.arbitrum.io/rpc
for a in 0xc7ec02AEeCdC9087bf848c4C4f790Ed74A93F2AF 0xAdBAeE9665C101413EbFF07e20520bdB67C71AB6; do
  echo "== market $a =="
  echo "owner=$(cast call $a 'owner()(address)' --rpc-url $ARB 2>&1|head -1)"
  echo "hedger=$(cast call $a 'hedger()(address)' --rpc-url $ARB 2>&1|head -1)"
  echo "feeRecepient=$(cast call $a 'feeRecepient()(address)' --rpc-url $ARB 2>&1|head -1)"
  echo "quoteAsset=$(cast call $a 'quoteAsset()(address)' --rpc-url $ARB 2>&1|head -1)"
  echo "underlyingAsset=$(cast call $a 'underlyingAsset()(address)' --rpc-url $ARB 2>&1|head -1)"
  echo "paused=$(cast call $a 'paused()(bool)' --rpc-url $ARB 2>&1|head -1)"
  echo "isSystemPaused=$(cast call $a 'isSystemPaused()(bool)' --rpc-url $ARB 2>&1|head -1)"
  echo "getLPTokenPrice(0)=$(cast call $a 'getLPTokenPrice(int256)(uint256)' 0 --rpc-url $ARB 2>&1|head -1)"
  echo "getTradePrice(0,100)=$(cast call $a 'getTradePrice(uint256,int128)(int256,int256,int256,int256,int256)' 0 100 --rpc-url $ARB 2>&1|head -1)"
done
echo "== last tx to markets (via arbiscan not available; skip) =="