#!/usr/bin/env bash
# ci/run.sh — Prodigy.Fi V2 (Base) heavy job.
# Writes ci-out/live_state.json with the read-only fork state used by the PoC.
# KEYLESS public endpoint only. No secrets. No transactions.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p ci-out
RPC="${BASE_RPC_URL:-https://base-rpc.publicnode.com}"
BLOCK=53044841
PM=0x50aB3FE7d089c4F0dD8096aAeA9578f8E7B18AF7
IMPL=0xB1522E3514ADFA6CbAcd6675378FCe03e1b97dd8
POOL=0xe1303B2514755A72da4AcA9B917d96F16c842c80
POOLV1=0x864cd49392a4348b5da5337623d994151610D0a3
USDC=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
WETH=0x4200000000000000000000000000000000000006
CBBTC=0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf
IMPL_SLOT=0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
ADMIN_SLOT=0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103

call(){ cast call "$1" "$2" ${3:+$3} --rpc-url "$RPC" --block "$BLOCK" 2>/dev/null | head -1; }
bal(){ cast call "$1" "balanceOf(address)(uint256)" "$2" --rpc-url "$RPC" --block "$BLOCK" 2>/dev/null; }

OWNER=$(call "$PM" "owner()(address)")
IMPLSLOT=$(cast storage "$PM" "$IMPL_SLOT" --rpc-url "$RPC" --block "$BLOCK")
ADMINSLOT=$(cast storage "$PM" "$ADMIN_SLOT" --rpc-url "$RPC" --block "$BLOCK")
VCNT=$(call "$PM" "getDeployedVaultCount()(uint256)")
USDC_B=$(bal "$USDC" "$POOL"); WETH_B=$(bal "$WETH" "$POOL"); CBBTC_B=$(bal "$CBBTC" "$POOL")
USDC_V1=$(bal "$USDC" "$POOLV1")
# stranger probes (fresh EOA 0x..dEaD, read-only eth_call)
DEAD=0x000000000000000000000000000000000000dEaD
USDC_PAD=000000000000000000000000833589fcd6edb6e08f4c7c32d4f71b54bda02913
ONE_PAD=0000000000000000000000000000000000000000000000000000000000000001
W=$(cast call "$POOL" "0xf3fef3a3${USDC_PAD}${ONE_PAD}" --from "$DEAD" --rpc-url "$RPC" --block "$BLOCK" 2>&1 | head -1)
PU=$(cast call "$POOL" "0x1ea734b6${USDC_PAD}${ONE_PAD}" --from "$DEAD" --rpc-url "$RPC" --block "$BLOCK" 2>&1 | head -1)
RV=$(cast call "$POOL" "0x05c4fdf9${USDC_PAD}${USDC_PAD}" --from "$DEAD" --rpc-url "$RPC" --block "$BLOCK" 2>&1 | head -1)

cat > ci-out/live_state.json <<JSON
{
  "chain": "base",
  "block": $BLOCK,
  "positionManager": "$PM",
  "implSlot": "$IMPLSLOT",
  "adminSlot": "$ADMINSLOT",
  "owner": "$OWNER",
  "deployedVaultCount": "$VCNT",
  "pool_v2": "$POOL",
  "pool_v2_USDC": "$USDC_B",
  "pool_v2_WETH": "$WETH_B",
  "pool_v2_cbBTC": "$CBBTC_B",
  "pool_v1_USDC": "$USDC_V1",
  "probe_withdraw_from_dead": "$W",
  "probe_processUserDeposit_from_dead": "$PU",
  "probe_registerVault_from_dead": "$RV"
}
JSON
echo "[prodigy-fi-v2] live_state.json written"
cat ci-out/live_state.json
exit 0
