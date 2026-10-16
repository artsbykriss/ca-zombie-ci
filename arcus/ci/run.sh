#!/usr/bin/env bash
# Z3-H12 Arcus — CI job: probe Robinhood Chain RPC, record live headline state.
# Writes results to ci-out/ (uploaded as artifact). No secrets, keyless public RPC only.
set -uo pipefail
mkdir -p ci-out
RPC="${RH_RPC:-https://rpc.mainnet.chain.robinhood.com}"
PT=0x4472C69d299382F8847ebCE4FC6Ed8e295510E3e
FACTORY=0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB
USDG=0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168

echo "[arcus-ci] probing Robinhood Chain RPC"
RESP=$(curl -s -m 25 -X POST -H 'Content-Type: application/json' -H 'User-Agent: Mozilla/5.0' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' "$RPC" 2>/dev/null)

if echo "$RESP" | grep -q '"result"'; then
  HEX=$(echo "$RESP" | sed -E 's/.*"result":"0x([0-9a-fA-F]+)".*/\1/')
  BLK=$((16#$HEX))
  echo "[arcus-ci] RPC OK at block $BLK"
  echo "RPC_OK block=$BLK" > ci-out/rpc_status.txt
  if [ -n "${GITHUB_ENV:-}" ]; then echo "RH_RPC=$RPC" >> "$GITHUB_ENV"; fi
  {
    echo "block=$BLK"
    echo "totalAssets=$(cast call $PT 'totalAssets()(uint256)' --rpc-url "$RPC" 2>/dev/null)"
    echo "totalSupply=$(cast call $PT 'totalSupply()(uint256)' --rpc-url "$RPC" 2>/dev/null)"
    echo "convertToShares(1e6)=$(cast call $PT 'convertToShares(uint256)(uint256)' 1000000 --rpc-url "$RPC" 2>/dev/null)"
    echo "convertToAssets(1e18)=$(cast call $PT 'convertToAssets(uint256)(uint256)' 1000000000000000000 --rpc-url "$RPC" 2>/dev/null)"
    echo "depositFeeBps=$(cast call $PT 'depositFeeBps()(uint16)' --rpc-url "$RPC" 2>/dev/null)"
    echo "depositsPaused=$(cast call $PT 'depositsPaused()(bool)' --rpc-url "$RPC" 2>/dev/null)"
    echo "pTokenCount=$(cast call $FACTORY 'pTokenCount()(uint256)' --rpc-url "$RPC" 2>/dev/null)"
    echo "pToken_USDG_balance=$(cast call $USDG 'balanceOf(address)(uint256)' $PT --rpc-url "$RPC" 2>/dev/null)"
  } | tee ci-out/live_state.txt
  echo "[arcus-ci] live state captured; forge fork tests will run next"
else
  echo "[arcus-ci] WARNING: Robinhood Chain RPC unreachable from this runner"
  echo "RPC_UNREACHABLE" > ci-out/rpc_status.txt
  # Disable the foundry fork tests so the workflow skips them gracefully (documented blocker).
  if [ -f poc/foundry.toml ]; then mv poc/foundry.toml poc/foundry.toml.disabled; fi
  echo "[arcus-ci] poc/foundry.toml disabled; see analysis/blockers.md"
fi
exit 0
