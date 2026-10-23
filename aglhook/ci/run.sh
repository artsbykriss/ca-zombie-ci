#!/usr/bin/env bash
# AGLHook — CI evidence job. Read-only RPC reads; writes ci-out/live-state.json.
# Never prints or stores an RPC URL or any secret.
set -uo pipefail
cd "$(dirname "$0")/.."

RPC="${FORK_RPC_URL:-${RPC_URL:-${NODEREAL_ETH_RPC_URL:-https://ethereum-rpc.publicnode.com}}}"
H=0xA61d74D6362699B76b21ef3016649A58D27bE0CC
PM=0x000000000004444c5dc75cB358380D2e3dE08A90
AGL=0x63401cDd577478F9389A1683e866A937f072D1C2
BB=0x8CCf65a2d5edFF1AAF865e6D75e70077a0e0bce5
PID=0x02a13b057643e001f9436fa86e3c28945b6c4475a34e068df5c6ab4d42ff93bf

mkdir -p ci-out
B=$(cast block-number --rpc-url "$RPC" 2>/dev/null || echo 0)
echo "[aglhook] block $B"

call() { cast call "$1" "$2" "${@:3}" --rpc-url "$RPC" --block "$B" 2>/dev/null | head -1 | awk '{print $1}'; }

STATE=$(cast keccak "$(cast concat-hex $PID 0x0000000000000000000000000000000000000000000000000000000000000006)")
LIQ_SLOT=$(python3 -c "print(hex(int('$STATE',16)+3))")

cat > ci-out/live-state.json <<JSON
{
  "block": $B,
  "hook": "$H",
  "requiredFlags": "$(call $H 'REQUIRED_FLAGS()(uint160)')",
  "bound": "$(call $H 'bound()(bool)')",
  "boundPool": "$(call $H 'boundPool()(bytes32)')",
  "owed": "$(call $H 'owed()(uint256)')",
  "erc6909EthClaim": "$(call $PM 'balanceOf(address,uint256)(uint256)' $H 0)",
  "feeBpsBuy": "$(call $H 'feeBps(bool)(uint24)' true)",
  "feeBpsSell": "$(call $H 'feeBps(bool)(uint24)' false)",
  "feeExemptBuyback": "$(call $H 'feeExempt(address)(bool)' $BB)",
  "xautFundWallet": "$(call $H 'xautFundWallet()(address)')",
  "aglLaunchTs": "$(call $AGL 'launchTs()(uint256)')",
  "aglTotalSupply": "$(call $AGL 'totalSupply()(uint256)')",
  "poolSlot0": "$(call $PM 'extsload(bytes32)(bytes32)' $STATE)",
  "poolLiquidity": "$(call $PM 'extsload(bytes32)(bytes32)' $LIQ_SLOT)",
  "pmAglBalance": "$(call $AGL 'balanceOf(address)(uint256)' $PM)",
  "buybackOperator": "$(call $BB 'isOperator(address)(bool)' 0x69797731508079240Ef42b6F3235656fB3E6e119)"
}
JSON

echo "[aglhook] wrote ci-out/live-state.json"
python3 analysis/decode_pool.py > ci-out/reserves.txt 2>&1 || true
cat ci-out/reserves.txt
ls -la ci-out
