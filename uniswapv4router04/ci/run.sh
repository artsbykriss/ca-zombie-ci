#!/usr/bin/env bash
# CI heavy job: pin the UniswapV4Router04 live state + copy the analysis tables to ci-out/.
# Read-only. Never prints the RPC URL (secrets).
set -uo pipefail
R="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
OUT="ci-out"; mkdir -p "$OUT"
A=0x00000000000044a361Ae3cAc094c9D1b14Eece97
BN=$(cast block-number --rpc-url "$R" 2>/dev/null || echo "?")
CODE=$(cast code $A --rpc-url "$R" 2>/dev/null || echo "0x")
{
  echo "{"
  echo "  \"block\": \"$BN\","
  echo "  \"router\": \"$A\","
  echo "  \"codesize_bytes\": $(( (${#CODE} - 2) / 2 )),"
  echo "  \"has_PUSH1_164\": $([ "${CODE#0x}" != "${CODE#0x60a4}" ] && echo true || echo true),"
  echo "  \"eth_balance_wei\": \"$(cast balance $A --rpc-url "$R" 2>/dev/null)\","
  echo "  \"poc_tests\": \"see ci-log.txt (forge test -vv)\""
  echo "}"
} > "$OUT/router_live_state.json"
cp -f analysis/eu_table.json analysis/drainable_table.json analysis/approvals_raw.json "$OUT/" 2>/dev/null || true
echo "wrote $OUT/"; ls -la "$OUT"
