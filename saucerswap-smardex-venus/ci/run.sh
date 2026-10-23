#!/usr/bin/env bash
# ZH4-residual umbrella CI job: independent live-state re-verification of the three
# deep-dive targets (SaucerSwap V2 / Hedera, SMARDEX USDN / Ethereum, Venus Flux / BSC).
# Read-only. Keyless public RPCs only. No secrets, no keyed URLs, no transactions.
# Writes ci-out/independent-live-check.json (uploaded as artifact).
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out

H="${HEDERA_RPC:-https://mainnet.hashio.io/api}"
E="${ETH_RPC:-https://ethereum-rpc.publicnode.com}"
B="${BSC_RPC:-https://bsc-rpc.publicnode.com}"

have_cast=0
command -v cast >/dev/null 2>&1 && have_cast=1

call() { # rpc addr sig [args...]
  local rpc="$1" addr="$2" sig="$3"; shift 3
  if [ "$have_cast" = 1 ]; then
    cast call "$addr" "$sig" "$@" --rpc-url "$rpc" 2>/dev/null | tr -d '\n'
  fi
}
codesize() {
  if [ "$have_cast" = 1 ]; then cast codesize "$2" --rpc-url "$1" 2>/dev/null | tr -d '\n'; fi
}
blk() { if [ "$have_cast" = 1 ]; then cast block-number --rpc-url "$1" 2>/dev/null; else echo null; fi; }
slot() { if [ "$have_cast" = 1 ]; then cast storage "$2" 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url "$1" 2>/dev/null | tr -d '\n'; fi; }

ETH_BLK=$(blk "$E"); BSC_BLK=$(blk "$B"); HED_BLK=$(blk "$H")

OUT=ci-out/independent-live-check.json
{
echo "{"
echo "  \"note\": \"independent parent-level re-verification; read-only; keyless public RPCs; no tx\","
echo "  \"have_cast\": $have_cast,"
echo "  \"blocks\": {\"ethereum\": ${ETH_BLK:-null}, \"bsc\": ${BSC_BLK:-null}, \"hedera\": ${HED_BLK:-null}},"
echo "  \"smardex_usdn\": {"
echo "    \"protocol\": \"0x656cB8C6d154Aad29d8771384089be5B5141f01a\","
echo "    \"impl_slot\": \"$(slot "$E" 0x656cB8C6d154Aad29d8771384089be5B5141f01a)\","
echo "    \"getBalanceVault\": \"$(call "$E" 0x656cB8C6d154Aad29d8771384089be5B5141f01a 'getBalanceVault()(uint256)')\","
echo "    \"getBalanceLong\": \"$(call "$E" 0x656cB8C6d154Aad29d8771384089be5B5141f01a 'getBalanceLong()(uint256)')\","
echo "    \"getTotalLongPositions\": \"$(call "$E" 0x656cB8C6d154Aad29d8771384089be5B5141f01a 'getTotalLongPositions()(uint256)')\","
echo "    \"usdn_totalSupply\": \"$(call "$E" 0xde17a000BA631c5d7c2Bd9FB692EFEa52D90DEE2 'totalSupply()(uint256)')\""
echo "  },"
echo "  \"venus_flux\": {"
echo "    \"liquidity_proxy_codesize\": \"$(codesize "$B" 0x52Aa899454998Be5b000Ad077a46Bbe360F4e497)\","
echo "    \"liquidity_impl_slot\": \"$(slot "$B" 0x52Aa899454998Be5b000Ad077a46Bbe360F4e497)\","
echo "    \"resolver_codesize\": \"$(codesize "$B" 0xca13A15de31235A37134B4717021C35A3CF25C60)\","
echo "    \"listedTokens\": \"$(call "$B" 0xca13A15de31235A37134B4717021C35A3CF25C60 'listedTokens()(address[])')\""
echo "  },"
echo "  \"saucerswap_v2\": {"
echo "    \"factory_codesize\": \"$(codesize "$H" 0x00000000000000000000000000000000003c3951)\","
echo "    \"router_codesize\": \"$(codesize "$H" 0x00000000000000000000000000000000003c437a)\","
echo "    \"npm_codesize\": \"$(codesize "$H" 0x00000000000000000000000000000000003ddbb9)\","
echo "    \"factory_owner\": \"$(call "$H" 0x00000000000000000000000000000000003c3951 'owner()(address)')\","
echo "    \"feeAmountTickSpacing_3000\": \"$(call "$H" 0x00000000000000000000000000000000003c3951 'feeAmountTickSpacing(uint24)(int24)' 3000)\""
echo "  }"
echo "}"
} > "$OUT"

echo "[umbrella] wrote $OUT"
cat "$OUT"
exit 0
