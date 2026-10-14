#!/usr/bin/env bash
# Custom CI job: dump live Printr state (read-only) into ci-out/live-state.json
# Runs inside CI from the finding folder; env has FORK_RPC_URL (Ethereum).
set -uo pipefail
mkdir -p ci-out
RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
P=0xb77726291b125515d0a7affeea2b04f2ff243172
T=0x8c843012b347664caf84b907053754208a933fee
LT=0xde420c835240216198bf4fd1eda28d7ead2a1549
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
ATT=0x000000000000000000000000000000000000dEaD
PEER=0x27289e1d3b5c3af5e16600167c7463fcaa125509fc61e2de08491aece7993b5f
CH=0x69b20d727573a47a47104388af8b3772c69dc384

BLOCK=$(cast block-number --rpc-url "$RPC" 2>/dev/null)
TREASURY_PRINTR=$(cast call "$T" "printr()(address)" --rpc-url "$RPC" 2>/dev/null)
WETH_BAL=$(cast call "$WETH" "balanceOf(address)(uint256)" "$T" --rpc-url "$RPC" 2>/dev/null)
LEGACY_PRINTR=$(cast call "$LT" "printr()(address)" --rpc-url "$RPC" 2>/dev/null)
PAUSED=$(cast call "$P" "paused()(bool)" --rpc-url "$RPC" 2>/dev/null)
TRADING_FEE=$(cast call "$P" "tradingFee()(uint16)" --rpc-url "$RPC" 2>/dev/null)
OWNER=$(cast call "$P" "owner()(address)" --rpc-url "$RPC" 2>/dev/null)

# access-control probes (read-only eth_call with from=)
WDATA=$(cast calldata "withdraw(address,address,uint256)" "$WETH" "$ATT" 1)
ATT_RES=$(cast call "$T" "$WDATA" --from "$ATT" --rpc-url "$RPC" 2>&1 | head -1)
CORE_RES=$(cast call "$T" "$WDATA" --from "$P" --rpc-url "$RPC" 2>&1 | head -1)
LEG_ATT_RES=$(cast call "$LT" "$WDATA" --from "$ATT" --rpc-url "$RPC" 2>&1 | head -1)
PAUSE_RES=$(cast call "$P" "pause()" --from "$ATT" --rpc-url "$RPC" 2>&1 | head -1)

# receiveFromChannel peer gate (protocol 2)
RFC=$(cast calldata "receiveFromChannel(uint8,bytes32,bytes)" 2 "$PEER" 0x)
RFC_ATT=$(cast call "$P" "$RFC" --from "$ATT" --rpc-url "$RPC" 2>&1 | head -1)
RFC_CH=$(cast call "$P" "$RFC" --from "$CH" --rpc-url "$RPC" 2>&1 | head -1)
RFC_WRONG=$(cast call "$P" "$(cast calldata "receiveFromChannel(uint8,bytes32,bytes)" 2 0x000000000000000000000000000000000000000000000000000000000000dEaD 0x)" --from "$CH" --rpc-url "$RPC" 2>&1 | head -1)

cat > ci-out/live-state.json <<EOF
{
  "generated": "$(date -u +%FT%TZ)",
  "ethereum_block": "$BLOCK",
  "printr_proxy": "$P",
  "treasury": "$T",
  "treasury_printr": "$TREASURY_PRINTR",
  "treasury_weth_wei": "$WETH_BAL",
  "legacy_treasury_printr": "$LEGACY_PRINTR",
  "paused": "$PAUSED",
  "trading_fee_bips": "$TRADING_FEE",
  "owner": "$OWNER",
  "probe_treasury_withdraw_from_attacker": "$ATT_RES",
  "probe_treasury_withdraw_from_core": "$CORE_RES",
  "probe_legacy_withdraw_from_attacker": "$LEG_ATT_RES",
  "probe_pause_from_attacker": "$PAUSE_RES",
  "probe_receiveFromChannel_from_attacker": "$RFC_ATT",
  "probe_receiveFromChannel_from_channel_correct_peer": "$RFC_CH",
  "probe_receiveFromChannel_from_channel_wrong_peer": "$RFC_WRONG"
}
EOF
echo "wrote ci-out/live-state.json"
cat ci-out/live-state.json
