#!/usr/bin/env bash
# CI helper: live-state snapshot for JPYdf at the latest block (PoC tests pin 26,217,683).
# Read-only. RPC URL comes from CI env; it is never printed or written.
set -u
R="${BLOCKPI_RPC_URL:-${RPC_URL:-${FORK_RPC_URL:-https://ethereum-rpc.publicnode.com}}}"
B=$(cast block-number --rpc-url "$R" 2>/dev/null || echo 26217683)
mkdir -p ci-out
OUT=ci-out/jpydf_live_state.txt
{
  echo "block=$B"
  for v in \
    0x6042755eCCa71A1Be9C7091441ca5bEaA6b520e4 \
    0x087Ebaf3F1b094b2046912a5E5F0BaD78dF3eAa7; do
    echo "vault=$v"
    echo "  underlying=$(cast call "$v" 'underlying()(address)' --rpc-url "$R" 2>&1)"
    echo "  dToken=$(cast call "$v" 'dToken()(address)' --rpc-url "$R" 2>&1)"
    echo "  treasury=$(cast call "$v" 'treasury()(address)' --rpc-url "$R" 2>&1)"
    echo "  bufferBalance=$(cast call "$v" 'bufferBalance()(uint256)' --rpc-url "$R" 2>&1)"
    echo "  backstopBalance=$(cast call "$v" 'backstopBalance()(uint256)' --rpc-url "$R" 2>&1)"
    echo "  totalUnderlying=$(cast call "$v" 'totalUnderlying()(uint256)' --rpc-url "$R" 2>&1)"
    echo "  actualLiabilities=$(cast call "$v" 'actualLiabilities()(uint256)' --rpc-url "$R" 2>&1)"
    echo "  backingRatio=$(cast call "$v" 'backingRatio()(uint256)' --rpc-url "$R" 2>&1)"
    echo "  pendingWithdrawals=$(cast call "$v" 'pendingWithdrawals()(uint256)' --rpc-url "$R" 2>&1)"
    echo "  strategies=$(cast call "$v" 'getStrategiesCount()(uint256)' --rpc-url "$R" 2>&1)"
    echo "  pausedDeposit=$(cast call "$v" 'pausedDeposit()(bool)' --rpc-url "$R" 2>&1)"
    echo "  pausedRedeem=$(cast call "$v" 'pausedRedeem()(bool)' --rpc-url "$R" 2>&1)"
    echo "  pausedClaim=$(cast call "$v" 'pausedClaim()(bool)' --rpc-url "$R" 2>&1)"
  done
  echo "usdc_strategy_0=0xf91acaa3dd75044fa2abd4e9226e8d7631fe7c63"
  echo "  principal=$(cast call 0xf91acaa3dd75044fa2abd4e9226e8d7631fe7c63 'principal()(uint256)' --rpc-url "$R" 2>&1)"
  echo "  estimated=$(cast call 0xf91acaa3dd75044fa2abd4e9226e8d7631fe7c63 'estimatedTotalUnderlying()(uint256)' --rpc-url "$R" 2>&1)"
  echo "usdc_strategy_1=0x7be8e8e316827bc2dcaf0862ee234985f80c1946"
  echo "  principal=$(cast call 0x7be8e8e316827bc2dcaf0862ee234985f80c1946 'principal()(uint256)' --rpc-url "$R" 2>&1)"
  echo "  estimated=$(cast call 0x7be8e8e316827bc2dcaf0862ee234985f80c1946 'estimatedTotalUnderlying()(uint256)' --rpc-url "$R" 2>&1)"
} > "$OUT" 2>&1
echo "wrote $OUT"
