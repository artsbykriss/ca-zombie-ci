#!/usr/bin/env bash
set -u
ARB=https://arb1.arbitrum.io/rpc
P=0x9215748657319B17fecb2b5D086A3147BFBC8613
FROM=0x0000000000000000000000000000000000001111
echo "== trade(pairId=2,...) from random EOA =="
cast call $P "trade((uint256,uint256,int256,int256,bytes),bytes)" "(2,0,0,0,0x)" 0x --from $FROM --rpc-url $ARB 2>&1 | head -4
echo "== withdraw(2,true,1) from random EOA =="
cast call $P "withdraw(uint256,bool,uint256)" 2 true 1 --from $FROM --rpc-url $ARB 2>&1 | head -4
echo "== supply(2,true,1) from random EOA =="
cast call $P "supply(uint256,bool,uint256)" 2 true 1 --from $FROM --rpc-url $ARB 2>&1 | head -4
echo "== take(true,0x1111,1) from random EOA =="
cast call $P "take(bool,address,uint256)" true $FROM 1 --from $FROM --rpc-url $ARB 2>&1 | head -4
echo "== createVault(2) from random EOA =="
cast call $P "createVault(uint256)" 2 --from $FROM --rpc-url $ARB 2>&1 | head -4
echo "== reallocate(2,0x) from random EOA =="
cast call $P "reallocate(uint256,bytes)" 2 0x --from $FROM --rpc-url $ARB 2>&1 | head -4
echo "== execLiquidationCall? abi funcs =="
jq -r '.[]|select(.type=="function")|.name+"("+([.inputs[].type]|join(","))+")"' /home/heisenberg/CA/predy-v2/analysis/impl_abi.json | grep -i liquid