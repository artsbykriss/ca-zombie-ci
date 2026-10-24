#!/usr/bin/env bash
# monitor.sh — light read-only monitor for the Kolan launchpad hooks (Ethereum).
#
# Prints, for the launchpad + every LaunchHook + the main KolanHook:
#   windowCount, held().eth (wei), eth_getBalance (wei), and a RE-ARMED flag
#   when held().eth > 0 — i.e. escrowed ETH is present, so once a window is
#   expired the permissionless accept(id) drain is live.
#
# Public keyless RPC only. No keys, no writes, no transactions.
# Usage:  bash monitor.sh [rpc_url]
set -uo pipefail

RPC="${1:-${RPC:-https://ethereum-rpc.publicnode.com}}"
LAUNCHPAD="0x8F89905624E3613b3A578Ff1EC690463A33e940e"
MAIN="0x0136feCf49E0217BFd2D9551E8e7b05f174Ba8eC"

# retry a cast call a few times (public RPCs are flaky)
cc() { # cc <to> <sig> [args...]
  local out
  for _ in 1 2 3; do
    out=$(cast call --rpc-url "$RPC" "$@" 2>/dev/null) && [ -n "$out" ] && { echo "$out"; return 0; }
    sleep 1
  done
  echo ""
}
bal() { for _ in 1 2 3; do b=$(cast balance --rpc-url "$RPC" "$1" 2>/dev/null) && [ -n "$b" ] && { echo "$b"; return 0; }; sleep 1; done; echo "?"; }

BLK=$(cast block-number --rpc-url "$RPC" 2>/dev/null || echo "?")
echo "Kolan launchpad hook monitor — block ${BLK} — rpc ${RPC}"
printf '%-44s %-12s %-24s %-24s %s\n' "ADDRESS" "windowCount" "held.eth(wei)" "balance(wei)" "RE-ARMED"

check() {
  local addr="$1"
  local wc held eth b flag
  wc=$(cc "$addr" "windowCount()(uint256)"); wc=${wc:-ERR}
  held=$(cc "$addr" "held()(uint128,uint128)")
  eth=$(echo "$held" | awk 'NR==1{print $1}'); eth=${eth:-0}
  b=$(bal "$addr")
  if [ "${eth:-0}" != "0" ] && [ -n "${eth:-}" ]; then flag="RE-ARMED (held.eth>0)"; else flag="-"; fi
  printf '%-44s %-12s %-24s %-24s %s\n' "$addr" "$wc" "$eth" "$b" "$flag"
  if [ "${wc:-0}" != "0" ] && [ "${wc:-0}" != "ERR" ]; then
    for ((i=1;i<=wc;i++)); do
      local w own exp
      w=$(cc "$addr" "windows(uint256)(address,uint40,uint8,uint96,uint96,uint64)" "$i")
      own=$(echo "$w" | awk 'NR==1{print $1}'); exp=$(echo "$w" | awk 'NR==1{print $2}')
      if [ -n "${own:-}" ] && [ "$own" != "0x0000000000000000000000000000000000000000" ]; then
        echo "    window ${i}: owner=${own} expiry=${exp}"
      fi
    done
  fi
}

N=$(cc "$LAUNCHPAD" "launchCount()(uint256)"); N=${N:-0}
echo "--- launchpad (launchCount=${N}) ---"
printf '%-44s %-12s %-24s %-24s %s\n' "$LAUNCHPAD" "$N" "-" "$(bal "$LAUNCHPAD")" "-"

HOOKS=$(cc "$LAUNCHPAD" "hooksBetween(uint256,uint256)(address[])" 0 "$N")
echo "--- launch hooks ---"
echo "$HOOKS" | tr -d '[]' | tr ',' '\n' | tr -d ' ' | while read -r h; do
  [ -z "$h" ] && continue
  check "$h"
done

echo "--- main KolanHook ---"
check "$MAIN"
