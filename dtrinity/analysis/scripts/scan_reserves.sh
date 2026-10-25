#!/usr/bin/env bash
RPC="$1"; POOL="$2"; LABEL="$3"; BLK="${4:-latest}"
RES=$(cast call $POOL "getReservesList()(address[])" --rpc-url $RPC --block $BLK 2>/dev/null)
echo "BLOCK=$(cast block-number --rpc-url $RPC 2>/dev/null)"
echo "$RES" | tr -d '[]' | tr ',' '\n' | tr -d ' ' | while read A; do
  [ -z "$A" ] && continue
  echo "RESERVE $A"
  cast call $POOL "getReserveData(address)((uint256,uint128,uint128,uint128,uint128,uint128,uint40,address,address,address,address,uint128,uint128,uint128))" "$A" --rpc-url $RPC --block $BLK 2>/dev/null
  SYM=$(cast call "$A" "symbol()(string)" --rpc-url $RPC --block $BLK 2>/dev/null)
  echo "  symbol=$SYM"
done
