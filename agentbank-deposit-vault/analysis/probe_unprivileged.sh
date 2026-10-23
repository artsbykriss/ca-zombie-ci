#!/usr/bin/env bash
# Read-only eth_call probes from a random unprivileged EOA against the LIVE World Chain vault.
# No transactions are sent. Keyless public RPC.
set -uo pipefail
R="${RPC:-https://worldchain-mainnet.g.alchemy.com/public}"
V=0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1
ATK=0x1111111111111111111111111111111111111111
BLK=$(cast block-number --rpc-url "$R")
echo "probe_from=$ATK  block=$BLK  rpc=$R"
probe() {
  local sig="$1"; shift
  local out
  out=$(cast call --from "$ATK" --rpc-url "$R" "$V" "$sig" "$@" 2>&1 | head -2 | tr '\n' ' ')
  printf '%-52s %s\n' "$sig" "$out"
}
echo "--- value-moving entry points ---"
probe "deposit(uint256,address)" 1000000000000000000 "$ATK"
probe "mint(uint256,address)" 1000000000000000000 "$ATK"
probe "withdraw(uint256,address,address)" 1000000000000000000 "$ATK" "$ATK"
probe "redeem(uint256,address,address)" 1000000000000000000 "$ATK" "$ATK"
probe "transfer(address,uint256)" "$ATK" 1000000000000000000
probe "transferFrom(address,address,uint256)" "$ATK" "$ATK" 1000000000000000000
probe "approve(address,uint256)" "$ATK" 1000000000000000000
probe "allocate(address,bytes,uint256)" "$ATK" 0x 1000000000000000000
probe "deallocate(address,bytes,uint256)" "$ATK" 0x 1000000000000000000
probe "forceDeallocate(address,bytes,uint256,address)" "$ATK" 0x 1000000000000000000 "$ATK"
probe "setLiquidityAdapterAndData(address,bytes)" "$ATK" 0x
probe "setMaxRate(uint256)" 1000000000000000000
probe "accrueInterest()"
echo "--- owner-only ---"
probe "setOwner(address)" "$ATK"
probe "setCurator(address)" "$ATK"
probe "setIsSentinel(address,bool)" "$ATK" true
probe "setName(string)" "x"
probe "setSymbol(string)" "x"
echo "--- curator timelocked ---"
probe "setIsAllocator(address,bool)" "$ATK" true
probe "setReceiveSharesGate(address)" "$ATK"
probe "setSendSharesGate(address)" "$ATK"
probe "setReceiveAssetsGate(address)" "$ATK"
probe "setSendAssetsGate(address)" "$ATK"
probe "setAdapterRegistry(address)" "$ATK"
probe "addAdapter(address)" "$ATK"
probe "removeAdapter(address)" "$ATK"
probe "increaseTimelock(bytes4,uint256)" 0x12345678 1000000000000000000
probe "decreaseTimelock(bytes4,uint256)" 0x12345678 0
probe "abdicate(bytes4)" 0x12345678
probe "setPerformanceFee(uint256)" 1
probe "setManagementFee(uint256)" 1
probe "setPerformanceFeeRecipient(address)" "$ATK"
probe "setManagementFeeRecipient(address)" "$ATK"
probe "increaseAbsoluteCap(bytes,uint256)" 0x 1000000000000000000
probe "increaseRelativeCap(bytes,uint256)" 0x 1000000000000000000
probe "setForceDeallocatePenalty(address,uint256)" "$ATK" 1
probe "decreaseAbsoluteCap(bytes,uint256)" 0x 0
probe "decreaseRelativeCap(bytes,uint256)" 0x 0
probe "submit(bytes)" 0x
probe "revoke(bytes)" 0x
