#!/usr/bin/env bash
# Light live-state snapshot for the CI artifact. The heavy work (fork tests)
# is run by the workflow's `forge test -vvv` step; this script only does RPC
# reads and must never fail the job.
set -uo pipefail
mkdir -p ci-out

ETH_RPC="${FORK_RPC_URL:-${BLOCKPI_RPC_URL:-https://ethereum-rpc.publicnode.com}}"
SCROLL_RPC="${SCROLL_RPC_URL:-https://rpc.scroll.io}"

USDC_SCROLL=0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4
USX=0x3b005fefC63Ca7c8d25eE21FbA3787229ba4CF03
TREASURY=0x9F3d4b0C9E930Ca3957eCD3DEdb7417f8e0e4c35
AM=0xd16909Ecc9c71d481ee3b2Cb1968C0dAdCf0d300
STRATEGY=0x340F07c2736f5022EA5e1afa8d09B04CEB7378EA
GATEWAY=0x6272597fc1Cc23c9E932E670156866FdD4782A30

VAULT=0xBB03549117e38103589774AE1D6338D1B237FFA2
NAV=0x9994BC2eCdFd7BDeB5423f5e48E285b91e6a69A7
MZUSD=0x1BBa049d3869E8d467F38E52AcA8E99D64E310a6
JUNIOR=0x6F5d94Dc0c8bBf052aBF024259d087dA45AD96A1
SENIOR=0x0e246e5FA94E90ab784b03961C35AaD9999b6649

SCROLL_BLOCK=35666678
eth_block=$(cast block-number --rpc-url "$ETH_RPC" 2>/dev/null || echo 0)
scroll_head=$(cast block-number --rpc-url "$SCROLL_RPC" 2>/dev/null || echo 0)

# `cast call` prints "123 [1.23e2]"; keep the raw integer only.
read_val() { "$@" 2>/dev/null | awk '{print $1}'; }

treasury_usdc=$(read_val cast call "$USDC_SCROLL" 'balanceOf(address)(uint256)' "$TREASURY" --block "$SCROLL_BLOCK" --rpc-url "$SCROLL_RPC")
am_usdc=$(read_val cast call "$USDC_SCROLL" 'balanceOf(address)(uint256)' "$AM" --block "$SCROLL_BLOCK" --rpc-url "$SCROLL_RPC")
strategy_usdc=$(read_val cast call "$USDC_SCROLL" 'balanceOf(address)(uint256)' "$STRATEGY" --block "$SCROLL_BLOCK" --rpc-url "$SCROLL_RPC")
gateway_usdc=$(read_val cast call "$USDC_SCROLL" 'balanceOf(address)(uint256)' "$GATEWAY" --block "$SCROLL_BLOCK" --rpc-url "$SCROLL_RPC")
asset_manager_usdc=$(read_val cast call "$TREASURY" 'assetManagerUSDC()(uint256)' --block "$SCROLL_BLOCK" --rpc-url "$SCROLL_RPC")
usx_supply=$(read_val cast call "$USX" 'totalSupply()(uint256)' --block "$SCROLL_BLOCK" --rpc-url "$SCROLL_RPC")

mz_supply=$(read_val cast call "$MZUSD" 'totalSupply()(uint256)' --rpc-url "$ETH_RPC")
junior_assets=$(read_val cast call "$JUNIOR" 'totalAssets()(uint256)' --rpc-url "$ETH_RPC")
senior_assets=$(read_val cast call "$SENIOR" 'totalAssets()(uint256)' --rpc-url "$ETH_RPC")
veto=$(read_val cast call "$NAV" 'vetoPeriod()(uint32)' --rpc-url "$ETH_RPC")

cat > ci-out/live-state.json <<EOF
{
  "ethereum_block": ${eth_block:-0},
  "scroll_block": $SCROLL_BLOCK,
  "scroll_head": ${scroll_head:-0},
  "usx_scroll": {
    "treasury_usdc_6d": "${treasury_usdc:-0}",
    "asset_manager_usdc_6d": "${am_usdc:-0}",
    "strategy_safe_usdc_6d": "${strategy_usdc:-0}",
    "gateway_usdc_6d": "${gateway_usdc:-0}",
    "assetManagerUSDC_6d": "${asset_manager_usdc:-0}",
    "usx_supply_18d": "${usx_supply:-0}"
  },
  "mezzanine": {
    "mzusd_supply_18d": "${mz_supply:-0}",
    "junior_total_assets_18d": "${junior_assets:-0}",
    "senior_total_assets_18d": "${senior_assets:-0}",
    "nav_veto_period_s": "${veto:-0}"
  }
}
EOF

echo "wrote ci-out/live-state.json"
cat ci-out/live-state.json
exit 0
