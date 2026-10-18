#!/usr/bin/env bash
# CI helper: live-state snapshot for Flex at the latest block (PoC tests pin 26,217,683).
# Read-only. RPC URL comes from CI env; it is never printed or written.
set -u
R="${BLOCKPI_RPC_URL:-${RPC_URL:-${FORK_RPC_URL:-https://ethereum-rpc.publicnode.com}}}"
B=$(cast block-number --rpc-url "$R" 2>/dev/null || echo 26217683)
mkdir -p ci-out
OUT=ci-out/flex_live_state.txt
{
  echo "block=$B"
  echo "registry=0x9117440a7d03238905d1c8908157bd7a547c77c8"
  echo "registry_markets=$(cast call 0x9117440a7d03238905d1c8908157bd7a547c77c8 'markets_count()(uint256)' --rpc-url "$R" 2>&1)"
  for m in \
    0xd82DB9893751E9C90E2a6C3bE31183048E8E2e49 \
    0x484E3c28A99282Ce0682f65A5F902876f370C09D \
    0x8ee72c388aA73096338EE18CD46a39D98b8983c9 \
    0xADf4E0226d59aac20272023c04B4DcF5Ade7Fc6E \
    0x7582b47486F75F5D675f260d357972cD0DbEeA2E \
    0xEe27D81Bd4f54bA978e5dC0C335fC25C00e8334C; do
    echo "market=$m"
    echo "  total_debt=$(cast call "$m" 'total_debt()(uint256)' --rpc-url "$R" 2>&1)"
    echo "  collateral_balance=$(cast call "$m" 'collateral_balance()(uint256)' --rpc-url "$R" 2>&1)"
    echo "  price_oracle=$(cast call "$m" 'price_oracle()(address)' --rpc-url "$R" 2>&1)"
    echo "  lender=$(cast call "$m" 'lender()(address)' --rpc-url "$R" 2>&1)"
  done
  echo "yvusd_oracle_price_wad=$(cast call 0x6d8d09f18afd74e6d6d0190ccdf89de8fea54206 'get_price(bool)(uint256)' false --rpc-url "$R" 2>&1)"
  echo "siusd_oracle_price_wad=$(cast call 0x38cae071526c57f95bbbb41eb12661fbf749a15a 'get_price(bool)(uint256)' false --rpc-url "$R" 2>&1)"
  echo "ysybold_oracle_price_wad=$(cast call 0x405568114ee8058d0ca1bbe95da1f929279bae65 'get_price(bool)(uint256)' false --rpc-url "$R" 2>&1)"
  echo "min_cr_note=see forge tests (lowest CR > 1.10 at snapshot; 2% drop PoC pays positive bonus)"
} > "$OUT" 2>&1
echo "wrote $OUT"
