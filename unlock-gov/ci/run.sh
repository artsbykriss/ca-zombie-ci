#!/usr/bin/env bash
# ZH4-PASS7 unlock-gov — light live-state dump (Base). No secrets written.
# Runs on the CI runner; uses BASE_RPC_URL from the CI env, falls back to a public RPC.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
RPC="${BASE_RPC_URL:-https://base-rpc.publicnode.com}"
GOV=0x65bA0624403Fc5Ca2b20479e9F626eD4D78E0aD9
TL=0xB34567C4cA697b39F72e1a8478f285329A98ed1b
UP=0xaC27fa800955849d6D17cC8952Ba9dD6EAA66187
USDC=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
WETH=0x4200000000000000000000000000000000000006
BLK=$(cast block-number --rpc-url "$RPC")
TS=$(cast block latest --field timestamp --rpc-url "$RPC")
q=$(cast call "$GOV" "quorum(uint256)(uint256)" $((TS-1)) --rpc-url "$RPC")
th=$(cast call "$GOV" "proposalThreshold()(uint256)" --rpc-url "$RPC")
vd=$(cast call "$GOV" "votingDelay()(uint256)" --rpc-url "$RPC")
vp=$(cast call "$GOV" "votingPeriod()(uint256)" --rpc-url "$RPC")
md=$(cast call "$TL" "getMinDelay()(uint256)" --rpc-url "$RPC")
upb=$(cast call "$UP" "balanceOf(address)(uint256)" "$TL" --rpc-url "$RPC")
usdcb=$(cast call "$USDC" "balanceOf(address)(uint256)" "$TL" --rpc-url "$RPC")
wethb=$(cast call "$WETH" "balanceOf(address)(uint256)" "$TL" --rpc-url "$RPC")
ethb=$(cast balance "$TL" --rpc-url "$RPC")
cat > ci-out/live-state.json <<JSON
{
  "chain": "base",
  "block": $BLK,
  "governor": "$GOV",
  "timelock": "$TL",
  "up_token": "$UP",
  "quorum_wei": "$q",
  "proposalThreshold_wei": "$th",
  "votingDelay_s": "$vd",
  "votingPeriod_s": "$vp",
  "timelock_minDelay_s": "$md",
  "timelock_UP": "$upb",
  "timelock_USDC": "$usdcb",
  "timelock_WETH": "$wethb",
  "timelock_ETH": "$ethb"
}
JSON
cat ci-out/live-state.json
