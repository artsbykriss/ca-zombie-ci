#!/usr/bin/env bash
# Heavy job for the `moats` finding folder. Runs the fork-based negative-result PoC suite
# and writes machine-readable output to ci-out/.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/ci-out"
mkdir -p "$OUT"

echo "[moats] forge version:"; forge --version
echo "[moats] running fork PoC suite..."
cd "$ROOT/poc"

# public RPC only (no secrets)
export AVAX_RPC="${AVAX_RPC:-https://avalanche-c-chain-rpc.publicnode.com}"

forge test --match-contract MoatsForkTest -vvv 2>&1 | tee "$OUT/forge-fork-test.log"
STATUS=${PIPESTATUS[0]}

echo "[moats] forge exit status: $STATUS"
{
  echo "moats fork PoC status: $STATUS"
  echo "avax block: 98459787"
  echo "avax rpc (public): $AVAX_RPC"
  grep -E "\[PASS\]|\[FAIL\]|Suite result" "$OUT/forge-fork-test.log" || true
} > "$OUT/moats-summary.txt"

cat "$OUT/moats-summary.txt"
exit $STATUS
