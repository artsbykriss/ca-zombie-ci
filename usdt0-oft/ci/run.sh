#!/usr/bin/env bash
# Heavy-job hook for the USDT0 OFT finding. Records live config into ci-out/ (artifact).
# Keyless public RPC only; no secrets.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p ci-out
RPC="${FORK_RPC_URL:-https://ethereum-rpc.publicnode.com}"
PROXY=0x6C96dE32CEa08842dcc4058c14d3aaAD7Fa41dee
USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7
{
  echo "# USDT0 OFT adapter live state @ $(date -u +%FT%TZ)"
  echo "rpc=$RPC"
  echo "block=$(cast block-number --rpc-url "$RPC" 2>&1)"
  echo "escrow_USDT=$(cast call $USDT 'balanceOf(address)(uint256)' $PROXY --rpc-url "$RPC" 2>&1)"
  for eid in 30109 30165 30214 30375 30243; do
    echo "peers($eid)=$(cast call $PROXY 'peers(uint32)(bytes32)' $eid --rpc-url "$RPC" 2>&1)"
  done
} > ci-out/live_state.txt 2>&1
cat ci-out/live_state.txt
