#!/usr/bin/env bash
# SMARDEX USDN — light read-only live-state re-check (keyless public RPC only).
# Writes ci-out/live-recheck.json (uploaded). No secrets, no keyed URLs, no tx.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
E="${ETH_RPC:-https://ethereum-rpc.publicnode.com}"
P=0x656cB8C6d154Aad29d8771384089be5B5141f01a
have_cast=0; command -v cast >/dev/null 2>&1 && have_cast=1
c() { [ "$have_cast" = 1 ] && cast call "$1" "$2" ${3:+"$3"} --rpc-url "$E" 2>/dev/null | tr -d '\n'; }
s() { [ "$have_cast" = 1 ] && cast storage "$1" "$2" --rpc-url "$E" 2>/dev/null | tr -d '\n'; }
BLK=$([ "$have_cast" = 1 ] && cast block-number --rpc-url "$E" 2>/dev/null)
{
echo "{"
echo "  \"note\": \"read-only re-check; keyless public RPC; no tx\","
echo "  \"block\": ${BLK:-null},"
echo "  \"impl_slot\": \"$(s $P 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)\","
echo "  \"getBalanceVault\": \"$(c $P 'getBalanceVault()(uint256)')\","
echo "  \"getBalanceLong\": \"$(c $P 'getBalanceLong()(uint256)')\","
echo "  \"getTotalLongPositions\": \"$(c $P 'getTotalLongPositions()(uint256)')\","
echo "  \"usdnPrice\": \"$(c $P 'usdnPrice(uint128)(uint256)' 3000000000000000000000)\","
echo "  \"usdn_totalSupply\": \"$(c 0xde17a000BA631c5d7c2Bd9FB692EFEa52D90DEE2 'totalSupply()(uint256)')\","
echo "  \"protocol_wstETH\": \"$(c 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0 'balanceOf(address)(uint256)' $P)\""
echo "}"
} > ci-out/live-recheck.json
echo "[smardex-usdn] wrote ci-out/live-recheck.json"; cat ci-out/live-recheck.json
exit 0
