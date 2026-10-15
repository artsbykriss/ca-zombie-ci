#!/usr/bin/env bash
# Parallel state reader for Segment opBNB. Read-only cast call. No secrets.
# Input file lines: <target> <signature> [args...]
RPC="${RPC:-https://opbnb-mainnet-rpc.bnbchain.org}"
BLOCK="${BLOCK:-latest}"
JOBS="${JOBS:-12}"
IN="${IN:-/tmp/opencode/segment-calllist.txt}"
OUT="${OUT:-/tmp/opencode/segment-calls.txt}"
: > "$OUT.new"

run_one() {
  local target="$1"; shift
  local sig="$1"; shift
  local res
  res=$(cast call "$target" "$sig" "$@" --rpc-url "$RPC" --block "$BLOCK" 2>&1 | tr '\n' ' ' | head -c 400)
  printf '%s | %s %s | %s\n' "$target" "$sig" "$*" "$res" >> "$OUT.new"
}
export -f run_one
export RPC BLOCK OUT

# split each line into words; first word target, second sig, rest args
while IFS= read -r line; do
  [ -z "$line" ] && continue
  set -- $line
  printf '%s\0' "$*" >/dev/null
  echo "$line"
done < "$IN" | awk 'NF' | xargs -d '\n' -P "$JOBS" -I@ bash -c 'set -- @; run_one "$@"'
sort "$OUT.new" -o "$OUT"
cat "$OUT"
