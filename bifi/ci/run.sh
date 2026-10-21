#!/usr/bin/env bash
# ZH4-PASS3 BiFi deep-dive — CI heavy job. Read-only network reads + summary capture.
# Never prints or writes any keyed RPC URL.
set -uo pipefail
mkdir -p ci-out

ETH_RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
BSC_RPC="${BSC_RPC_URL:-https://bsc-rpc.publicnode.com}"
AVAX_RPC="${AVAX_RPC_URL:-https://api.avax.network/ext/bc/C/rpc}"
KAIA_RPC="${KAIA_RPC_URL:-https://public-en.node.kaia.io}"

{
  echo "BiFi live-state snapshot (read-only)  $(date -u +%FT%TZ)"
  echo
  echo "== latest blocks =="
  echo "ethereum $(cast block-number --rpc-url "$ETH_RPC" 2>/dev/null)"
  echo "bsc      $(cast block-number --rpc-url "$BSC_RPC" 2>/dev/null)"
  echo "avax     $(cast block-number --rpc-url "$AVAX_RPC" 2>/dev/null)"
  echo "kaia     $(cast block-number --rpc-url "$KAIA_RPC" 2>/dev/null)"
  echo
  echo "== TokenManager.getCircuitBreaker() (true = paused) =="
  echo "eth  0x913F2DEe2746CdA2ab34106c47aBC4a8f4e36fa5 $(cast call 0x913F2DEe2746CdA2ab34106c47aBC4a8f4e36fa5 'getCircuitBreaker()(bool)' --rpc-url "$ETH_RPC" 2>/dev/null)"
  echo "bsc  0x8010F9E14C8286B9312e624370fdDC07fee2Fc75 $(cast call 0x8010F9E14C8286B9312e624370fdDC07fee2Fc75 'getCircuitBreaker()(bool)' --rpc-url "$BSC_RPC" 2>/dev/null)"
  echo "avax 0x74326D2bFBF22312158850AC3B4F7AE8A0a347fD $(cast call 0x74326D2bFBF22312158850AC3B4F7AE8A0a347fD 'getCircuitBreaker()(bool)' --rpc-url "$AVAX_RPC" 2>/dev/null)"
  echo "kaia 0x2014e42d5d63b18728b30C1E3360e0B2C0e839cd $(cast call 0x2014e42d5d63b18728b30C1E3360e0B2C0e839cd 'getCircuitBreaker()(bool)' --rpc-url "$KAIA_RPC" 2>/dev/null)"
  echo
  echo "== interest model blocksPerYear (2^256-1 => frozen; ETH patched 2026-10-17) =="
  for m in 0xcBf361d934e2ac49B2C47c2910ea9489ab955829 0x29Ecabde2C57B6D4183f915eBca1A25804A60dB1 \
           0x105Ea44Ffa77f517E31f20d7c22EBEBf739bbF87 0x7560ad17E2a0b790019734bf4f9790323cD68cb6 \
           0x24231014199e0C1A8EC2D963389008d85b658f7d; do
    echo "eth $m $(cast call "$m" 'blocksPerYear()(uint256)' --rpc-url "$ETH_RPC" 2>/dev/null)"
  done
  for m in 0x18be1743efc40228879c07d55f36ae9ff5127fc3 0xca62d43e8824b02029444072c9a45bba6d4a198e \
           0x653db994ab70efe391782a265975ca0a614c6b79 0xb8621b5451e00149b3424fbb709e2de687ea23c2 \
           0x26363f6fb3a5dce8f9bdcf5ae40d772a1582184d 0xc7b7dc64ac2412bd33cb85d5c552276b66612e8b; do
    echo "bsc $m $(cast call "$m" 'blocksPerYear()(uint256)' --rpc-url "$BSC_RPC" 2>/dev/null)"
  done
  echo
  echo "== handler token balances =="
  echo "eth USDT-handler USDC  $(cast call 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 'balanceOf(address)(uint256)' 0x808C3bA97268dbF9695b1EC10729E09c7e67A9E3 --rpc-url "$ETH_RPC" 2>/dev/null)"
  echo "bsc USDT-handler USDT  $(cast call 0x55d398326f99059fF775485246999027B3197955 'balanceOf(address)(uint256)' 0x2A29598cbc17BA112C8Fd0E07Fbf5402eF57E6b8 --rpc-url "$BSC_RPC" 2>/dev/null)"
  echo "bsc USDC-handler USDC  $(cast call 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d 'balanceOf(address)(uint256)' 0xBA9De5a8FD91408826616f2d6d7470A11E34c9F0 --rpc-url "$BSC_RPC" 2>/dev/null)"
} 2>&1 | tee ci-out/live_snapshot.txt
