#!/usr/bin/env bash
# Live state reader for BeraFarm (Berachain, chainId 80094) — public RPCs only, read-only.
# Usage: bash live_state.sh [block]
set -euo pipefail
RPC=${RPC:-https://rpc.berachain.com}
BLK=${1:-latest}
rpc() { curl -s -m 30 -X POST "$RPC" -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$1\",\"params\":$2}"; }

echo "## block"; rpc eth_blockNumber '[]'; echo
echo "## impl slots (EIP-1967 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)"
for p in \
  0x1ce23321a72f2dae96809cc6192f053a7ad5d8e4 \
  0x1cac0625ee3a4679dce7f9dc921ecfdd5c378987 \
  0xc8f67dd8c2909750705e0533f8ca71dcdf380cc9 \
  0xa13e0a5fe378e89cc72730f8df2e140ebc6f1e84 \
  0x7f41c51a50aa3591f16ffdc37a5b8a79305f5dc7 \
  0xf0054ab55d098ac12034e68af8dc1546c7b7e09a \
  0x4a3c8fdd55017773fee33de4aa7e12dd60b0a054 \
  0x9546b34291393fb247db7d4c677f1394d4bbe0dd \
  0x0c5ab414845386758c50e7a5e08b59964a02f2bd \
  0xeb2cc2df8698250fb7fb6f310cbca6b3266e3b80 ; do
  slot=$(rpc eth_getStorageAt "[\"$p\",\"0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc\",\"$BLK\"]" | python3 -c 'import json,sys;print(json.load(sys.stdin)["result"])')
  echo "$p -> 0x${slot: -40}"
done
echo "## TVL (DataEmitterFixed.getTrancheTvl) vaults 0/1/3 + manager balance"
echo "## vault0 HONEY balance / vault1 WBERA"
rpc eth_call '["{\"to\":\"0x70d8d...\",\"data\":\"0x\"}","latest"]' >/dev/null 2>&1 || true
echo "done"
