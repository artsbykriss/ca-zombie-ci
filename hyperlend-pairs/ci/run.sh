#!/usr/bin/env bash
# Heavy/state job for hyperlend-pairs. Keyless public RPC only (no secrets written anywhere).
set -uo pipefail
export PATH="$HOME/.foundry/bin:$PATH"
H="${HYPEREVM_RPC_URL:-https://rpc.hyperliquid.xyz/evm}"
OUT="ci-out"; mkdir -p "$OUT"
LOG="$OUT/hyperlend_state.txt"

PAIRS=(
  "0x06Fd9D03b3d0F18E4919919b72D30c582f0a97E5|WHLP/USDT0|0x70f27F1a21E7116F76a3AF17577157c6B743619E|0x5e21f6530f656A38caE4F55500944753F662D184|0x190897a08371bE59f309dB2377832a462f003D76"
  "0xb8fEC5F81Bc7bE9dd5f9bc6De8E34E244A726d2F|xHYPE/USDT0|0xd8adb3287c37053F3265a4c5f521428f7c018AB2|0x5d5EE47c6bCf6B05B2a3F65c4e37312Dc978d30D|0x81D7FcFC2289fb137e85739ceE90E90cC5DAF206"
  "0x78DD09e369f35D033a1d4ec1df39BC8a51c8B6fd|xHYPE/USDC|0x896970EB7FB914eFcDfaDA4CFFC3E3C31497Da5a|0x4C89968338b75551243C99B452c84a01888282fD|0x81D7FcFC2289fb137e85739ceE90E90cC5DAF206"
  "0x9465c9218668b54939A7e09467d1DFf9d8704882|kmHYPE/WHYPE|0x8CBa4384Be277467E5955eCf1185154b867eD634|0xa8a94Da411425634e3Ed6C331a32ab4fd774aa43|0xfeb9167a6cD3F6509401fB97dd5c4E3582231611"
)
BLK=$(cast block-number --rpc-url "$H" 2>/dev/null || echo "?")
{
  echo "=== HyperLend isolated pairs — live state ==="
  echo "chain=hyperevm(999) block=$BLK utc=$(date -u +%FT%TZ) rpc=<keyless public>"
  for row in "${PAIRS[@]}"; do
    IFS='|' read -r pair name oracle mult div <<< "$row"
    echo
    echo "--- PAIR $pair ($name)"
    echo "asset            $(cast call "$pair" 'asset()(address)' --rpc-url "$H" 2>&1)"
    echo "collateral       $(cast call "$pair" 'collateralContract()(address)' --rpc-url "$H" 2>&1)"
    echo "maxLTV           $(cast call "$pair" 'maxLTV()(uint256)' --rpc-url "$H" 2>&1)"
    echo "borrowLimit      $(cast call "$pair" 'borrowLimit()(uint256)' --rpc-url "$H" 2>&1)"
    echo "totalAsset       $(cast call "$pair" 'totalAsset()(uint128,uint128)' --rpc-url "$H" 2>&1)"
    echo "totalBorrow      $(cast call "$pair" 'totalBorrow()(uint128,uint128)' --rpc-url "$H" 2>&1)"
    echo "totalCollateral  $(cast call "$pair" 'totalCollateral()(uint256)' --rpc-url "$H" 2>&1)"
    echo "exchangeRateInfo $(cast call "$pair" 'exchangeRateInfo()(address,uint32,uint184,uint256,uint256)' --rpc-url "$H" 2>&1 | tr '\n' ' ')"
    echo "ORACLE $oracle"
    echo "  maxOracleDelay $(cast call "$oracle" 'maxOracleDelay()(uint256)' --rpc-url "$H" 2>&1)"
    echo "  getPrices      $(cast call "$oracle" 'getPrices()(bool,uint256,uint256)' --rpc-url "$H" 2>&1 | tr '\n' ' ')"
    echo "  multiply feed  $mult : $(cast call "$mult" 'latestRoundData()(uint80,int256,uint256,uint256,uint80)' --rpc-url "$H" --json 2>&1 | tr -d '\n ')"
    echo "  divide feed    $div : $(cast call "$div" 'latestRoundData()(uint80,int256,uint256,uint256,uint80)' --rpc-url "$H" --json 2>&1 | tr -d '\n ')"
    echo "  now            $(date +%s)"
  done
} | tee "$LOG"
echo "wrote $LOG"
