#!/usr/bin/env bash
# Custom CI job: capture live on-chain state (read-only) into ci-out/ as an artifact.
# Runs on the GitHub Actions runner; BASE_RPC_URL is injected as a secret env var.
# NEVER echo the RPC URL (it is keyed). Only data is written.
set -uo pipefail
cd "$(dirname "$0")/.."   # folder root
mkdir -p ci-out

RPC="${BASE_RPC_URL:-https://base-rpc.publicnode.com}"
G=0xc5C3a1882Eff9539527D88E2453cAB10d9bc1581
T=0xE05dD5B785f578337B2B8F695Fbc521669c69403
INT=0x968D6A288d7B024D5012c0B25d67A889E4E3eC19
USDC=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
WETH=0x4200000000000000000000000000000000000006
POOL=0xDEc6EadbD8eD3F655CBA4Bb4eeFF6fB43B16969d

BN=$(cast block-number --rpc-url "$RPC")
{
  echo "base_block=$BN"
  echo "base_block_timestamp=$(cast block "$BN" --rpc-url "$RPC" --field timestamp)"
  echo "governor.name=$(cast call $G 'name()(string)' --rpc-url "$RPC" --block "$BN")"
  echo "governor.votingDelay=$(cast call $G 'votingDelay()(uint256)' --rpc-url "$RPC" --block "$BN")"
  echo "governor.votingPeriod=$(cast call $G 'votingPeriod()(uint256)' --rpc-url "$RPC" --block "$BN")"
  echo "governor.proposalThreshold=$(cast call $G 'proposalThreshold()(uint256)' --rpc-url "$RPC" --block "$BN")"
  echo "governor.quorumDenominator=$(cast call $G 'quorumDenominator()(uint256)' --rpc-url "$RPC" --block "$BN")"
  echo "governor.COUNTING_MODE=$(cast call $G 'COUNTING_MODE()(string)' --rpc-url "$RPC" --block "$BN")"
  echo "governor.token=$(cast call $G 'token()(address)' --rpc-url "$RPC" --block "$BN")"
  echo "governor.timelock=$(cast call $G 'timelock()(address)' --rpc-url "$RPC" --block "$BN")"
  echo "governor.roleStore=$(cast call $G 'roleStore()(address)' --rpc-url "$RPC" --block "$BN")"
  echo "timelock.getMinDelay=$(cast call $T 'getMinDelay()(uint256)' --rpc-url "$RPC" --block "$BN")"
  echo "timelock.INT=$(cast call $INT 'balanceOf(address)(uint256)' $T --rpc-url "$RPC" --block "$BN")"
  echo "timelock.USDC=$(cast call $USDC 'balanceOf(address)(uint256)' $T --rpc-url "$RPC" --block "$BN")"
  echo "timelock.WETH=$(cast call $WETH 'balanceOf(address)(uint256)' $T --rpc-url "$RPC" --block "$BN")"
  echo "int.totalSupply=$(cast call $INT 'totalSupply()(uint256)' --rpc-url "$RPC" --block "$BN")"
  echo "pool.INT=$(cast call $INT 'balanceOf(address)(uint256)' $POOL --rpc-url "$RPC" --block "$BN")"
  echo "pool.WETH=$(cast call $WETH 'balanceOf(address)(uint256)' $POOL --rpc-url "$RPC" --block "$BN")"
  echo "pool.liquidity=$(cast call $POOL 'liquidity()(uint128)' --rpc-url "$RPC" --block "$BN")"
} | tee ci-out/live-state.txt

echo "done: ci-out/live-state.txt"
