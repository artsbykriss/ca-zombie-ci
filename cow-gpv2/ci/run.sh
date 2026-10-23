#!/usr/bin/env bash
# CI heavy job: dump the GPv2Settlement live-state evidence (buffer + approvals) to ci-out/.
# Read-only. Never prints the RPC URL (secrets).
set -uo pipefail
R="${FORK_RPC_URL:-${RPC_URL:-https://ethereum-rpc.publicnode.com}}"
OUT="ci-out"; mkdir -p "$OUT"
S=0x9008d19f58aabd9ed0d60971565aa8510560ab41
BN=$(cast block-number --rpc-url "$R" 2>/dev/null || echo "?")
{
  echo "{"
  echo "  \"block\": \"$BN\","
  echo "  \"settlement\": \"$S\","
  echo "  \"codesize\": \"$(cast codesize $S --rpc-url "$R" 2>/dev/null)\","
  echo "  \"eth_wei\": \"$(cast balance $S --rpc-url "$R" 2>/dev/null)\","
  echo "  \"balances\": {"
  first=1
  for kv in WETH:0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 DAI:0x6B175474E89094C44Da98b954EedeAC495271d0F USDC:0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 USDT:0xdAC17F958D2ee523a2206206994597C13D831ec7 COW:0xDEf1CA1fb7FBcDC777520aa7f396b4E015F497aB GNO:0x6810e776880C02933D47DB1b9fc05908e5386b96 USDe:0x4c9EDD5852cd905f086C759E8383e09bff1E68B3 USDS:0xdC035D45d973E3EC169d2276DDab16f1e407384F sDAI:0x83F20F44975D03b1b09e64809B757c47f942BEeA; do
    k=${kv%%:*}; a=${kv##*:}
    v=$(cast call "$a" 'balanceOf(address)(uint256)' "$S" --rpc-url "$R" 2>/dev/null)
    [ $first -eq 0 ] && echo ","
    first=0
    printf '    "%s": "%s"' "$k" "$v"
  done
  echo ""
  echo "  },"
  echo "  \"allowances_USDC\": {"
  first=1
  for sp in 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F 0x11111112542D85B3EF69AE05771c2dCCff4fAa26 0x1111111254fb6c44bAC0beD2854e76F90643097d 0xDef1C0ded9bec7F1a1670819833240f027b25EfF 0xb70Bc06D2c9Bf03b3373799606dc7d39346c06B3 0x216B4B4Ba9F3e719726886d34a177484278Bfcae 0xBA12222222228d8Ba445958a75a0704d566BF2C8; do
    v=$(cast call 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 'allowance(address,address)(uint256)' "$S" "$sp" --rpc-url "$R" 2>/dev/null)
    [ $first -eq 0 ] && echo ","
    first=0
    printf '    "%s": "%s"' "$sp" "$v"
  done
  echo ""
  echo "  }"
  echo "}"
} > "$OUT/live_state.json"
echo "wrote $OUT/live_state.json"; head -c 2000 "$OUT/live_state.json"
