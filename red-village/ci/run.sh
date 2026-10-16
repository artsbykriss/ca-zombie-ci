#!/usr/bin/env bash
# red-village CI custom job (runs before `forge test` in the workflow).
# 1) selects a working Polygon RPC (public endpoints only; never prints keyed URLs)
# 2) dumps live on-chain state for the Z3-H4 finding to ci-out/live_state.json
# Read-only: eth_call / eth_getStorageAt / eth_getCode only. No transactions.
set -uo pipefail
mkdir -p ci-out

RPC=""
for u in "${POLYGON_RPC_URL:-}" "https://polygon.drpc.org" "https://polygon-bor-rpc.publicnode.com" "https://1rpc.io/matic"; do
  [ -z "$u" ] && continue
  r=$(curl -s -m 12 -X POST -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$u" 2>/dev/null || true)
  case "$r" in *result*) RPC="$u"; break;; esac
done
if [ -z "$RPC" ]; then
  echo "WARNING: no working Polygon RPC found"
  echo '{"error":"no working polygon rpc"}' > ci-out/live_state.json
  exit 0
fi
echo "[ci] polygon rpc selected (public)"

# make the selected RPC available to the `forge test` step
if [ -n "${GITHUB_ENV:-}" ]; then
  echo "POLYGON_RPC_URL=$RPC" >> "$GITHUB_ENV"
fi

BN=$(cast block-number --rpc-url "$RPC" 2>/dev/null || echo 0)
ROUTER=0xc97dCb0492412bFBBf47332F1B1b49e177e8f15C
SEASON=0xb172E15974FEAAe221EbC0860B578Dd7B6B06b77
ZK=0x426d27190A2DdB87f1C6235F710e159a0A3774D4
AC=0x3f0B50B7A270de536D5De35C11C2613284C4304e
WETH=0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
SLOT=0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc

router_impl=$(cast storage --rpc-url "$RPC" "$ROUTER" "$SLOT" 2>/dev/null || echo "0x0")
season_impl=$(cast storage --rpc-url "$RPC" "$SEASON" "$SLOT" 2>/dev/null || echo "0x0")
registry_impl=$(cast storage --rpc-url "$RPC" 0x6547b4A12953F70C44DF5bb57E78fce68199c5c8 "$SLOT" 2>/dev/null || echo "0x0")
zk_weth=$(cast call --rpc-url "$RPC" "$WETH" 'balanceOf(address)(uint256)' "$ZK" 2>/dev/null || echo 0)
zk_owner=$(cast call --rpc-url "$RPC" "$ZK" 'owner()(address)' 2>/dev/null || echo "0x0")
ac_owner=$(cast call --rpc-url "$RPC" "$AC" 'owner()(address)' 2>/dev/null || echo "0x0")
hr_in_now=$(cast call --rpc-url "$RPC" "$AC" 'hasRole(address,address,string)(bool)' "$SEASON" "$ZK" 'transferERC20In' 2>/dev/null || echo "?")
hr_out_now=$(cast call --rpc-url "$RPC" "$AC" 'hasRole(address,address,string)(bool)' "$SEASON" "$ZK" 'transferERC20Out' 2>/dev/null || echo "?")
hr_upg_now=$(cast call --rpc-url "$RPC" "$AC" 'hasRole(address,address,string)(bool)' "$ROUTER" "$SEASON" '_authorizeUpgrade' 2>/dev/null || echo "?")
hr_in_pre=$(cast call --rpc-url "$RPC" --block 94200340 "$AC" 'hasRole(address,address,string)(bool)' "$SEASON" "$ZK" 'transferERC20In' 2>/dev/null || echo "?")
hr_upg_pre=$(cast call --rpc-url "$RPC" --block 94200340 "$AC" 'hasRole(address,address,string)(bool)' "$ROUTER" "$SEASON" '_authorizeUpgrade' 2>/dev/null || echo "?")
mem_in=$(cast call --rpc-url "$RPC" "$AC" 'getMembersByRole(address,string)(address[])' "$ZK" 'transferERC20In' 2>/dev/null || echo "[]")

# WETH price for USD conversion (DefiLlama, keyless)
price=$(curl -s -m 15 "https://coins.llama.fi/prices/current/polygon:${WETH}" 2>/dev/null | jq -r '.coins | to_entries[0].value.price' 2>/dev/null || echo "null")

cat > ci-out/live_state.json <<EOF
{
  "chain": "polygon",
  "latest_block": $BN,
  "router_impl": "$router_impl",
  "season_impl": "$season_impl",
  "registry_impl": "$registry_impl",
  "zookeeper_owner": "$zk_owner",
  "accesscontrol_owner": "$ac_owner",
  "zookeeper_weth_wei": "$zk_weth",
  "hasRole_season_zookeeper_transferERC20In_now": "$hr_in_now",
  "hasRole_season_zookeeper_transferERC20Out_now": "$hr_out_now",
  "hasRole_router_season_authorizeUpgrade_now": "$hr_upg_now",
  "hasRole_season_zookeeper_transferERC20In_at_94200340": "$hr_in_pre",
  "hasRole_router_season_authorizeUpgrade_at_94200340": "$hr_upg_pre",
  "zookeeper_transferERC20In_members": $mem_in,
  "weth_usd_price": $price
}
EOF

echo "[ci] live_state.json written (block $BN)"
cat ci-out/live_state.json
exit 0
