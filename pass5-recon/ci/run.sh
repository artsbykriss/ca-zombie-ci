#!/usr/bin/env bash
# pass5-recon — light, read-only live sanity checks for the ranked OPEN list.
# No secrets are printed. Uses CI-provided RPC env vars with keyless public fallbacks.
# Writes JSON to ci-out/.
set -uo pipefail
mkdir -p ci-out
OUT=ci-out/recon-sanity.json
ETH="${RPC_URL:-https://ethereum-rpc.publicnode.com}"
ETH_PUB="https://ethereum-rpc.publicnode.com"
BASE="${BASE_RPC_URL:-https://base-rpc.publicnode.com}"
ARB="${ARB_RPC_URL:-https://arb1.arbitrum.io/rpc}"
# prefer keyless public for determinism; never echo the keyed URL
R="$ETH_PUB"
command -v cast >/dev/null 2>&1 || { echo "cast not found"; exit 1; }

j() { python3 -c "import json,sys;print(json.dumps(json.loads(sys.stdin.read())))" 2>/dev/null; }

{
echo "{"
echo "  \"note\": \"read-only sanity checks; keyless public RPCs; no tx signed\","
echo "  \"eth_block\": $(cast block-number --rpc-url "$R" 2>/dev/null || echo null),"
echo "  \"arb_block\": $(cast block-number --rpc-url "$ARB" 2>/dev/null || echo null),"
echo "  \"base_block\": $(cast block-number --rpc-url "$BASE" 2>/dev/null || echo null),"

echo "  \"saturn_susdat\": {"
echo "    \"proxy\": \"0xD166337499E176bbC38a1FBd113Ab144e5bd2Df7\","
echo "    \"impl_slot\": \"$(cast storage 0xD166337499E176bbC38a1FBd113Ab144e5bd2Df7 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url "$R" 2>/dev/null)\","
echo "    \"totalAssets\": \"$(cast call 0xD166337499E176bbC38a1FBd113Ab144e5bd2Df7 'totalAssets()(uint256)' --rpc-url "$R" 2>/dev/null)\""
echo "  },"

echo "  \"unverified_delta_hooks\": {"
echo "    \"eth_0xfAaad5B7_codesize\": \"$(cast codesize 0xfAaad5B731F52cDc9746F2414c823eca9B06E844 --rpc-url "$R" 2>/dev/null)\","
echo "    \"eth_0xd33398d4_codesize\": \"$(cast codesize 0xd33398d46cB5749c7319AE1FABC498CdeB0F0FC0 --rpc-url "$R" 2>/dev/null)\","
echo "    \"eth_0xd33398d4_implslot\": \"$(cast storage 0xd33398d46cB5749c7319AE1FABC498CdeB0F0FC0 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url "$R" 2>/dev/null)\","
echo "    \"base_0xC90eddF5_codesize\": \"$(cast codesize 0xC90eddF51569270E06270eA98F7EfFF828dDe0CC --rpc-url "$BASE" 2>/dev/null)\""
echo "  },"

echo "  \"mux_pool_arb\": {"
echo "    \"addr\": \"0x45de6f4Ddc91B4353e9e0fF5d714bd1F8C113851\","
echo "    \"native\": \"$(cast balance 0x45de6f4Ddc91B4353e9e0fF5d714bd1F8C113851 --rpc-url "$ARB" 2>/dev/null)\","
echo "    \"codesize\": \"$(cast codesize 0x45de6f4Ddc91B4353e9e0fF5d714bd1F8C113851 --rpc-url "$ARB" 2>/dev/null)\""
echo "  },"
echo "  \"generated_utc\": \"$(date -u +%FT%TZ)\""
echo "}"
} > "$OUT"
echo "wrote $OUT"; cat "$OUT"
