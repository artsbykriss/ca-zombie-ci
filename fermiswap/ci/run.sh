#!/usr/bin/env bash
# FermiSwap Z3-H16 — CI logging job. Runs the fork suite with full verbosity and captures a
# live-state snapshot into ci-out/ (uploaded as artifacts). Never prints RPC URLs/secrets.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
mkdir -p "$ROOT/ci-out"
cd "$ROOT/poc"

RPC="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"

# 1) detailed test log (the main workflow also runs forge test as the gate)
forge test -vvv --fork-url "$RPC" > "$ROOT/ci-out/forge_test_vvv.log" 2>&1
echo "forge test exit: $? (details in ci-out/forge_test_vvv.log)"
tail -n 150 "$ROOT/ci-out/forge_test_vvv.log" || true

# 2) live-state snapshot (public reads only)
SNAP="$ROOT/ci-out/live_snapshot.txt"
{
  echo "=== FermiSwap live snapshot ==="
  echo "utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  BLK=$(cast block-number --rpc-url "$RPC")
  echo "block=$BLK"
  echo "block_ts=$(cast block "$BLK" --rpc-url "$RPC" --field timestamp)"
  VAULT=0x585d44727129B9C69791B10238Ca605932938B4F
  E4=0x0109AA912B58508886a2a707204B0F8C8b164CCc
  WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
  USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
  USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7
  WBTC=0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
  CBBTC=0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf
  SWAP2=0x5979458912F80B96d30D4220af8E2e4925A33320
  ARB1=0xB4723899a492330fedACcf22ec12F53A06e3B659
  ARB2=0xeff407D968de7d312Fd5e036AEf8837b3679d777
  for tok in "$WETH WETH" "$USDC USDC" "$USDT USDT" "$WBTC WBTC" "$CBBTC cbBTC"; do
    set -- $tok
    echo "vault_$2=$(cast call $1 'balanceOf(address)(uint256)' $VAULT --rpc-url "$RPC" 2>/dev/null)"
  done
  for sp in "$SWAP2 swap2" "$ARB1 arb1" "$ARB2 arb2"; do
    set -- $sp
    echo "allow_WETH_$2=$(cast call $WETH 'allowance(address,address)(uint256)' $VAULT $1 --rpc-url "$RPC" 2>/dev/null)"
    echo "allow_USDC_$2=$(cast call $USDC 'allowance(address,address)(uint256)' $VAULT $1 --rpc-url "$RPC" 2>/dev/null)"
  done
  echo "engine4_unlocked_WETH_USDC=$(cast call $E4 'unlocked(address,address)(bool)' $WETH $USDC --rpc-url "$RPC" 2>/dev/null)"
  echo "engine4_unlocked_WETH_USDT=$(cast call $E4 'unlocked(address,address)(bool)' $WETH $USDT --rpc-url "$RPC" 2>/dev/null)"
} > "$SNAP" 2>&1
cat "$SNAP" || true
exit 0
