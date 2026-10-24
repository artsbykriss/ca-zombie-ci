#!/usr/bin/env bash
# ci/run.sh — read-only live-state snapshot for Venus Flux (Instadapp Fluid) on BSC (chainId 56).
# Keyless public RPC only. No secrets, no keyed URLs, no transactions. Best-effort (never fails CI).
# Writes ci-out/live-recheck.json.
set -uo pipefail
cd "$(dirname "$0")/.." 2>/dev/null || true
mkdir -p ci-out
OUT="ci-out/live-recheck.json"

R="${BSC_RPC_URL:-https://bsc-rpc.publicnode.com}"
LIQ=0x52Aa899454998Be5b000Ad077a46Bbe360F4e497
LR=0xca13A15de31235A37134B4717021C35A3CF25C60
ORACLE_WSTUSR=0xc0767760627E88Eef7f653bce49e660a351E95eD
DEX_WSTUSR_USDT=0x3C0441B42195F4aD6aa9a0978E06096ea616CDa7
T1_USDT=0x3996464c0fCCa8183e13ea5E5e74375e2c8744Dd
USDT=0x55d398326f99059fF775485246999027B3197955

have_cast=0; command -v cast >/dev/null 2>&1 && have_cast=1
c() { local a="$1" s="$2"; shift 2; [ "$have_cast" = 1 ] && cast call "$a" "$s" "$@" --rpc-url "$R" 2>/dev/null | tr -d '\n'; }
BLK=$([ "$have_cast" = 1 ] && cast block-number --rpc-url "$R" 2>/dev/null)

{
  echo "{"
  echo "  \"note\": \"read-only re-check; keyless public RPC; no tx\","
  echo "  \"block\": ${BLK:-null},"
  echo "  \"listedTokens\": \"$(c $LR 'listedTokens()(address[])')\","
  echo "  \"wstUSR_oracle_getExchangeRate\": \"$(c $ORACLE_WSTUSR 'getExchangeRate()(uint256)')\","
  echo "  \"T1_wstUSR_USDT_getUserBorrowData\": \"$(c $LR 'getUserBorrowData(address,address)(uint256,uint256,uint256,uint256)' $T1_USDT $USDT)\","
  echo "  \"dex_wstUSR_USDT_dexVariables2Raw\": \"$(c 0xAf572EfC84d905926F7b05C1B7bE04e4E89542B0 'getDexVariables2Raw(address)(uint256)' $DEX_WSTUSR_USDT)\","
  echo "  \"dex_wstUSR_USDT_supplySharesRaw\": \"$(c 0xAf572EfC84d905926F7b05C1B7bE04e4E89542B0 'getTotalSupplySharesRaw(address)(uint256)' $DEX_WSTUSR_USDT)\","
  echo "  \"dex_wstUSR_USDT_borrowSharesRaw\": \"$(c 0xAf572EfC84d905926F7b05C1B7bE04e4E89542B0 'getTotalBorrowSharesRaw(address)(uint256)' $DEX_WSTUSR_USDT)\","
  echo "  \"liquidity_codesize\": \"$([ "$have_cast" = 1 ] && cast codesize $LIQ --rpc-url "$R" 2>/dev/null)\","
  echo "  \"resolver_codesize\": \"$([ "$have_cast" = 1 ] && cast codesize $LR --rpc-url "$R" 2>/dev/null)\""
  echo "}"
} > "$OUT" 2>/dev/null
echo "[run] wrote $OUT (block ${BLK:-?})"
cat "$OUT"
