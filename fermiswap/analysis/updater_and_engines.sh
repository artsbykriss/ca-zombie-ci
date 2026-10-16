#!/usr/bin/env bash
# Check engine3 updaters still authorized + old engines' links + engine4 config decode prep.
cd "$(dirname "$0")" && source ./env.sh
RPC="https://ethereum-rpc.publicnode.com"
REG=0xDa7AfeeD01fe625CF15d187a19f94B45f00b8C5F
E3=0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f
echo "=== isUpdater(engine3, X) live ==="
for u in 0x69939a6c590c9cd0bf8efbe9b3df2cdac4a4906b 0xa048e0c08b7acb48363711800ac9d49de8e58d13 0xfcb4150a75485727203ac1f18a78bbb929175b03 0x5c4c7ac6295490cd476995f1a454e783099b4792 0xc91d122bfb912ce29d4740242e3af3fae91170b0 0x09a37b96019568787fe88f90f34e1ee489cc48e7 0xe5544cc733419454129ef3e425bdc89af27ba690 0x4b93764ba956434abd739beb975fcb44e6c290ca 0x000000000000000000000000000000000000dEaD; do
  r=$(timeout 12 cast call $REG 'isUpdater(address,address)(bool)' $E3 $u --rpc-url "$RPC" 2>&1 | head -1)
  echo "  $u -> $r"
done
echo "=== old engines links ==="
for e in 0x0Ba5665583a4593A86cDC935eA2c8Ff378c11317 0xe514a3c48da8B233f65B5D15bA1905d6d35bFE48; do
  echo "engine $e:"
  echo "  swapper: $(timeout 12 cast call $e 'swapper()(address)' --rpc-url $RPC 2>&1 | head -1)"
  echo "  traderVault: $(timeout 12 cast call $e 'traderVault()(address)' --rpc-url $RPC 2>&1 | head -1)"
  echo "  VERSION: $(timeout 12 cast call $e 'VERSION()(uint256)' --rpc-url $RPC 2>&1 | head -1)"
  echo "  code: $(timeout 12 cast codesize $e --rpc-url $RPC)"
done
echo "=== engine1/2 as spender? vault allowance check ==="
for sp in 0x0Ba5665583a4593A86cDC935eA2c8Ff378c11317 0xe514a3c48da8B233f65B5D15bA1905d6d35bFE48; do
  a=$(timeout 12 cast call 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 'allowance(address,address)(uint256)' 0x585d44727129B9C69791B10238Ca605932938B4F $sp --rpc-url "$RPC" 2>/dev/null)
  echo "  WETH allowance to $sp = $a"
done
