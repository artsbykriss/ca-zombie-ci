#!/usr/bin/env bash
# Stake DAO Curator / MorphoStrategyWrapper — C-02 live-state capture (keyless RPC).
# Heavy work (fork tests) is run by the workflow's `forge test` step.
set -euo pipefail
RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
OUT="ci-out"; mkdir -p "$OUT"

W_OLD=0x95B2b136eb0Bf075072D0c759e475453711A33f5   # older generation (frxUSD/OUSD)
W_V3=0x3009e8e60Ee13Eccc3234406571E33664C2ECad7    # v3 generation (USD3/frxUSD)
RV_OLD=0x715AAAc9b7c35b88299376147eE7B0c09A0F1B22
MID_OLD=0xb7d1981ca0657c42bf003aca966f6a873ade2ae55d472d019a4ea03bc74f29f0
MORPHO=0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb

BLK=$(cast block-number --rpc-url "$RPC")
{
  echo "fork_block=$BLK"
  echo "rpc=$(echo "$RPC" | sed -E 's#(https?://[^/]+).*#\1/<redacted>#')"
  echo "--- W_OLD ($W_OLD) ---"
  echo "lendingMarketId=$(cast call --rpc-url "$RPC" $W_OLD 'lendingMarketId()(bytes32)')"
  echo "REWARD_VAULT=$(cast call --rpc-url "$RPC" $W_OLD 'REWARD_VAULT()(address)')"
  echo "MAIN_REWARD_TOKEN=$(cast call --rpc-url "$RPC" $W_OLD 'MAIN_REWARD_TOKEN()(address)')"
  echo "totalSupply=$(cast call --rpc-url "$RPC" $W_OLD 'totalSupply()(uint256)')"
  echo "transfer_reverts_for_fresh_eoa=$(cast call --rpc-url "$RPC" $W_OLD 'transfer(address,uint256)(bool)' 0x000000000000000000000000000000000000dEaD 1 2>&1 | head -c 60 || true)"
  echo "--- W_V3 ($W_V3) ---"
  echo "version=$(cast call --rpc-url "$RPC" $W_V3 'version()(uint256)')"
  echo "totalSupply=$(cast call --rpc-url "$RPC" $W_V3 'totalSupply()(uint256)')"
  echo "--- market $MID_OLD ---"
  echo "collateralToken=$(cast call --rpc-url "$RPC" $MORPHO 'idToMarketParams(bytes32)(address,address,address,address,uint256)' $MID_OLD | head -1)"
} > "$OUT/live-state.txt" 2>&1

echo "wrote $OUT/live-state.txt"; cat "$OUT/live-state.txt"
