#!/usr/bin/env bash
RPC="$1"; POOL="$2"; OUT="$3"; BLK="${4:-latest}"
TUP='(uint256,uint128,uint128,uint128,uint128,uint128,uint40,uint16,address,address,address,address,uint128,uint128,uint128)'
echo "BLOCK=$(cast block-number --rpc-url $RPC 2>/dev/null)"
for A in $(cast call $POOL "getReservesList()(address[])" --rpc-url $RPC --block $BLK 2>/dev/null | tr -d '[]' | tr ',' ' '); do
  SYM=$(cast call "$A" "symbol()(string)" --rpc-url $RPC --block $BLK 2>/dev/null)
  DEC=$(cast call "$A" "decimals()(uint8)" --rpc-url $RPC --block $BLK 2>/dev/null)
  RD=$(cast call $POOL "getReserveData(address)$TUP" "$A" --rpc-url $RPC --block $BLK 2>/dev/null | tr -d '[],')
  CONF=$(echo "$RD" | awk '{print $1}')
  LI=$(echo "$RD" | awk '{print $2}' | sed 's/\[.*//')
  LR=$(echo "$RD" | awk '{print $3}' | sed 's/\[.*//')
  ATK=$(echo "$RD" | awk '{print $9}')
  VDT=$(echo "$RD" | awk '{print $11}')
  ATS=$(cast call "$ATK" "totalSupply()(uint256)" --rpc-url $RPC --block $BLK 2>/dev/null | sed 's/\[.*//')
  VDS=$(cast call "$VDT" "totalSupply()(uint256)" --rpc-url $RPC --block $BLK 2>/dev/null | sed 's/\[.*//')
  UTS=$(cast call "$A" "totalSupply()(uint256)" --rpc-url $RPC --block $BLK 2>/dev/null | sed 's/\[.*//')
  echo "{\"asset\":\"$A\",\"symbol\":\"$SYM\",\"decimals\":\"$DEC\",\"config\":\"$CONF\",\"liqIndex\":\"$LI\",\"liqRate\":\"$LR\",\"aToken\":\"$ATK\",\"aTokenSupply\":\"$ATS\",\"varDebt\":\"$VDT\",\"varDebtSupply\":\"$VDS\",\"underlyingSupply\":\"$UTS\"}"
done
