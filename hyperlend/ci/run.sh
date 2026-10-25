#!/usr/bin/env bash
# Heavy-job hook for the HyperLend finding. Runs BEFORE `forge test -vvv`.
# Records the live fork block + oracle state into ci-out/ (uploaded as an artifact).
# No secrets: uses a keyless public HyperEVM RPC only.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
RPC="${HYPEREVM_RPC_URL:-https://rpc.hyperliquid.xyz/evm}"
POOL=0x00A89d7a5A02160f20150EbEA7a2b5E4879A1A8b
ORACLE=0xC9Fb4fbE842d57EAc1dF3e641a281827493A630e
USDHL=0xb50A96253aBDF803D85efcDce07Ad8becBc52BD5
PTSUSDE=0xb7379d395F3c83952ad794896205f7E33E358735
{
  echo "# HyperLend live state @ $(date -u +%FT%TZ)"
  echo "rpc=$RPC"
  echo "block=$(cast block-number --rpc-url "$RPC" 2>&1)"
  echo "USDHL_price=$(cast call $ORACLE 'getAssetPrice(address)(uint256)' $USDHL --rpc-url "$RPC" 2>&1)"
  echo "PTSUSDE_price=$(cast call $ORACLE 'getAssetPrice(address)(uint256)' $PTSUSDE --rpc-url "$RPC" 2>&1)"
  echo "USDHL_cfg=$(cast call $POOL 'getConfiguration(address)(uint256)' $USDHL --rpc-url "$RPC" 2>&1)"
  echo "PTSUSDE_cfg=$(cast call $POOL 'getConfiguration(address)(uint256)' $PTSUSDE --rpc-url "$RPC" 2>&1)"
} > ci-out/live_state.txt 2>&1
cat ci-out/live_state.txt
