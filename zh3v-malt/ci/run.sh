#!/usr/bin/env bash
# Pick a working keyless Polygon archive RPC for the forge fork tests and export
# it to later steps via $GITHUB_ENV. All candidates are public, unauthenticated
# endpoints, so nothing sensitive is written or printed here.
# Also dumps codehashes / balances at key blocks into ci-out/diagnostics.txt.
set -uo pipefail

SLP="0xfe6C096a2871337d4f6F7DD04Ebda733E94D7A13"
CS="0xF0d314849A3Bc9270a79110F25dBA2c8325A2AAC"
RT="0x6f96483f951db6CcA759B9B032eeAF1754c7188a"
HOOK="0xf61Ab33917fD056BB7dDD4f474A237928f63d5d6"
REG="0xc7237262da9706616e737427f9aff18d1a301e1e"
DAI="0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"

CANDIDATES=(
  "https://polygon-bor-rpc.publicnode.com"
  "https://polygon.drpc.org"
  "https://1rpc.io/matic"
  "https://polygon.blockpi.network/v1/rpc/public"
  "https://polygon-mainnet.public.blastapi.io"
)

pick() {
  for u in "$POLYGON_RPC_URL" "${CANDIDATES[@]}"; do
    [ -z "$u" ] && continue
    out=$(cast call "$SLP" "getReserves()" --block 94869209 --rpc-url "$u" 2>/dev/null) || continue
    case "$out" in
      0x*) echo "$u"; return 0 ;;
    esac
  done
  return 1
}

PICK=$(pick || true)
if [ -n "$PICK" ]; then
  echo "POLYGON_RPC_URL=$PICK" >> "$GITHUB_ENV"
  if [ "$PICK" = "${POLYGON_RPC_URL:-}" ]; then
    echo "polygon archive RPC selected from env (value redacted)"
  else
    echo "polygon archive RPC selected: $PICK"
  fi
else
  echo "WARNING: no working polygon archive RPC found; tests will use built-in fallback"
  exit 0
fi

# codehash with retries across candidates (drpc sometimes rate-limits bursts)
codehash() {
  local addr="$1" blk="$2"
  local u r
  for attempt in 1 2 3; do
    for u in "$PICK" "${CANDIDATES[@]}"; do
      r=$(cast codehash "$addr" --block "$blk" --rpc-url "$u" 2>/dev/null | tail -1)
      case "$r" in 0x*) echo "$r"; return 0 ;; esac
      sleep 2
    done
  done
  echo "UNAVAILABLE"
}

mkdir -p ci-out
{
  echo "# MALT fork diagnostics — codehashes and balances at key blocks"
  for b in 94869209 95305623 95586990; do
    echo "== block $b =="
    echo "  SLP.codehash    : $(codehash "$SLP" "$b")"
    echo "  CS.codehash     : $(codehash "$CS" "$b")"
    echo "  RT.codehash     : $(codehash "$RT" "$b")"
    echo "  HOOK.codehash   : $(codehash "$HOOK" "$b")"
    echo "  REG.codehash    : $(codehash "$REG" "$b")"
    echo -n "  CS.DAI balance  : "
    cast call "$DAI" "balanceOf(address)(uint256)" "$CS" --block "$b" --rpc-url "$PICK" 2>&1 | tail -1
  done
} 2>&1 | tee ci-out/diagnostics.txt
