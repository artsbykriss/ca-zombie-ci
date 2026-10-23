#!/usr/bin/env bash
# AGLHook — read-only live-state snapshot. No secrets are stored here; the RPC
# endpoint comes from the environment (RPC_URL / NODEREAL_ETH_RPC_URL) with a
# keyless public fallback. Prints eth_call / eth_getCode results only.
set -uo pipefail

RPC="${RPC_URL:-${NODEREAL_ETH_RPC_URL:-https://ethereum-rpc.publicnode.com}}"
H=0xA61d74D6362699B76b21ef3016649A58D27bE0CC
PM=0x000000000004444c5dc75cB358380D2e3dE08A90
AGL=0x63401cDd577478F9389A1683e866A937f072D1C2
BB=0x8CCf65a2d5edFF1AAF865e6D75e70077a0e0bce5
XAUT=0x06fbfb283bCA0d109bFB5Fd9CFb02B974D705998

B=$(cast block-number --rpc-url "$RPC")
echo "block: $B"
echo "-- hook --"
for s in "REQUIRED_FLAGS()(uint160)" "bound()(bool)" "boundPool()(bytes32)" "poolManager()(address)" \
         "agl()(address)" "xautFundWallet()(address)" "owed()(uint256)"; do
  printf "%-26s %s\n" "$s" "$(cast call $H "$s" --rpc-url "$RPC" --block "$B")"
done
echo "uint160(hook)&0x3FFF: $(( 0x$(cast call $H 'REQUIRED_FLAGS()(uint160)' --rpc-url "$RPC" --block "$B" | sed 's/^0x//' | cut -c1-40) & 0x3FFF ))"
echo "ERC-6909 ETH claim (must equal owed): $(cast call $PM 'balanceOf(address,uint256)(uint256)' $H 0 --rpc-url "$RPC" --block "$B")"
echo "-- token --"
for s in "name()(string)" "symbol()(string)" "totalSupply()(uint256)" "launchTs()(uint256)" "hook()(address)" "owner()(address)"; do
  printf "%-26s %s\n" "$s" "$(cast call $AGL "$s" --rpc-url "$RPC" --block "$B")"
done
echo "-- pool (ETH/AGL, fee=0, tickSpacing=60) --"
PID=0x02a13b057643e001f9436fa86e3c28945b6c4475a34e068df5c6ab4d42ff93bf
STATE=$(cast keccak "$(cast concat-hex $PID 0x0000000000000000000000000000000000000000000000000000000000000006)")
echo "stateSlot: $STATE"
echo "slot0:     $(cast call $PM 'extsload(bytes32)(bytes32)' $STATE --rpc-url "$RPC" --block "$B")"
echo "liquidity: $(cast call $PM 'extsload(bytes32)(bytes32)' "$(cast to-uint256 "$(python3 -c "print(hex(int('$STATE',16)+3))")")" --rpc-url "$RPC" --block "$B")"
echo "AGL held by PoolManager: $(cast call $AGL 'balanceOf(address)(uint256)' $PM --rpc-url "$RPC" --block "$B")"
echo "-- fee-exempt buyback --"
echo "isOperator(0x6979..e119): $(cast call $BB 'isOperator(address)(bool)' 0x69797731508079240Ef42b6F3235656fB3E6e119 --rpc-url "$RPC" --block "$B")"
echo "xautFundWallet native balance: $(cast balance $XAUT --rpc-url "$RPC" --block "$B")"
