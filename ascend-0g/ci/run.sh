#!/usr/bin/env bash
# Heavy CI job for ascend-0g (ZH4-PASS6 P6-02).
# Runs on the GitHub Actions runner (artsbykriss/ca-zombie-ci, public).
# - picks a working *keyless public* 0G RPC (chainId 16661)
# - writes a live-state snapshot to ci-out/
# - runs the Foundry fork PoC and tees the output to ci-out/
# NEVER writes any keyed RPC URL or secret here.
set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$HERE"
mkdir -p ci-out

RPC=""
for u in https://evmrpc.0g.ai https://0g-rpc.publicnode.com https://0g.drpc.org; do
  r=$(curl -s -m 15 -X POST -H 'Content-Type: application/json' \
        --data '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' "$u" 2>/dev/null)
  case "$r" in *0x4115*) RPC="$u"; break;; esac
done
if [ -z "$RPC" ]; then echo "ERROR: no working public 0G RPC"; exit 1; fi
echo "[ci] 0G RPC selected: $RPC" | tee ci-out/og-rpc.txt

# let the subsequent `forge test` step inherit the working RPC
echo "OG_RPC_URL=$RPC" > poc/.env

BLK=$(cast block-number --rpc-url "$RPC")
{
  echo "chain_id=16661"
  echo "block=$BLK"
  echo "timestamp=$(cast block "$BLK" --rpc-url "$RPC" --field timestamp)"
  echo "vault=0x4B3c2f55fa67679b382c979A082Df1B32079B4cB"
  echo "vault_impl=$(cast storage --rpc-url "$RPC" 0x4B3c2f55fa67679b382c979A082Df1B32079B4cB 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)"
  echo "vault_totalAssets=$(cast call --rpc-url "$RPC" 0x4B3c2f55fa67679b382c979A082Df1B32079B4cB 'totalAssets()(uint256)')"
  echo "vault_totalSupply=$(cast call --rpc-url "$RPC" 0x4B3c2f55fa67679b382c979A082Df1B32079B4cB 'totalSupply()(uint256)')"
  echo "vault_W0G_liquid=$(cast call --rpc-url "$RPC" 0x1Cd0690fF9a693f5EF2dD976660a8dAFc81A109c 'balanceOf(address)(uint256)' 0x4B3c2f55fa67679b382c979A082Df1B32079B4cB)"
  echo "oracle_value=$(cast call --rpc-url "$RPC" 0x8f7b85432F7BB3534ca34E42c215146Db47a4Eab 'value()(uint256)')"
  echo "oracle_lastUpdated=$(cast call --rpc-url "$RPC" 0x8f7b85432F7BB3534ca34E42c215146Db47a4Eab 'lastUpdated()(uint256)')"
  echo "oracle_maxAge=$(cast call --rpc-url "$RPC" 0x8f7b85432F7BB3534ca34E42c215146Db47a4Eab 'maxAge()(uint256)')"
  echo "queue=0x10A98a5344742308744Bd59829786584A12C1146"
  echo "queue_totalShares=$(cast call --rpc-url "$RPC" 0x10A98a5344742308744Bd59829786584A12C1146 'totalShares()(uint256)')"
  echo "queue_currentEpoch=$(cast call --rpc-url "$RPC" 0x10A98a5344742308744Bd59829786584A12C1146 'currentEpoch()(uint256)')"
  echo "queue_epochIterator=$(cast call --rpc-url "$RPC" 0x10A98a5344742308744Bd59829786584A12C1146 'epochIterator()(uint256)')"
  echo "queue_withdrawalDelay=$(cast call --rpc-url "$RPC" 0x10A98a5344742308744Bd59829786584A12C1146 'withdrawalDelay()(uint256)')"
  echo "oftAdapter=0x28eCbDbf7AA257A42D786409c7a27B9CE92aA1fF"
  echo "oft_W0G_locked=$(cast call --rpc-url "$RPC" 0x1Cd0690fF9a693f5EF2dD976660a8dAFc81A109c 'balanceOf(address)(uint256)' 0x28eCbDbf7AA257A42D786409c7a27B9CE92aA1fF)"
  echo "oft_peer_30101=$(cast call --rpc-url "$RPC" 0x28eCbDbf7AA257A42D786409c7a27B9CE92aA1fF 'peers(uint32)(bytes32)' 30101)"
  echo "oft_owner=$(cast call --rpc-url "$RPC" 0x28eCbDbf7AA257A42D786409c7a27B9CE92aA1fF 'owner()(address)')"
  echo "oft_sourceCore=$(cast call --rpc-url "$RPC" 0x28eCbDbf7AA257A42D786409c7a27B9CE92aA1fF 'sourceCore()(address)')"
} | tee ci-out/ascend0g-state.txt

export OG_RPC_URL="$RPC"
( cd poc && forge test -vvv 2>&1 | tee ../ci-out/ascend0g-forge.txt )
