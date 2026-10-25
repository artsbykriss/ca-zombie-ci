#!/usr/bin/env bash
# Read-only reserve-detail probe for HyperLend core pool (HyperEVM 999).
set -u
HP=${HP:-https://rpc.hyperliquid.xyz/evm}
POOL=0x00A89d7a5A02160f20150EbEA7a2b5E4879A1A8b
OUT="$(dirname "$0")/reserve_details.txt"
: > "$OUT"
emit(){ echo "$@" | tee -a "$OUT"; }

RESERVES=(
0x5555555555555555555555555555555555555555
0xb50A96253aBDF803D85efcDce07Ad8becBc52BD5
0xb7379d395F3c83952ad794896205f7E33E358735
0xb8CE59FC3717ada4C02eaDF9682A9e934F625ebb
0xb88339CB7199b77E23DB6E890353E22632Ba630f
0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34
0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2
)

SIG='getReserveData(address)(uint256,uint128,uint128,uint128,uint128,uint128,uint40,uint16,address,address,address,address,uint128,uint128,uint128)'
for R in "${RESERVES[@]}"; do
  emit "==== reserve $R ===="
  emit "-- getReserveData --"
  cast call "$POOL" "$SIG" "$R" --rpc-url "$HP" 2>&1 | tee -a "$OUT"
done

emit ""
emit "==== oracle feeds (USDHL + PT-sUSDe) ===="
for F in 0xa19b7fe6ffd492dd84adf38d37b974cb52f40267 0x8514d528275025ad9be6019e6e189dfef1db6c5e; do
  emit "-- feed $F --"
  emit "codesize: $(( $(cast code "$F" --rpc-url "$HP" | wc -c) / 2 ))"
  emit "description: $(cast call "$F" 'description()(string)' --rpc-url "$HP" 2>&1)"
  emit "decimals:    $(cast call "$F" 'decimals()(uint8)' --rpc-url "$HP" 2>&1)"
  emit "latestRoundData: $(cast call "$F" 'latestRoundData()(uint80,int256,uint256,uint256,uint80)' --rpc-url "$HP" 2>&1)"
done

emit ""
emit "==== eMode categories (Pool) ===="
emit "ADDRESSES_PROVIDER: $(cast call "$POOL" 'ADDRESSES_PROVIDER()(address)' --rpc-url "$HP")"
AP=0x72c98246a98bFe64022a3190e7710E157497170C
emit "ACL_ADMIN: $(cast call "$AP" 'getACLAdmin()(address)' --rpc-url "$HP" 2>&1)"
emit "POOL_ADMIN: $(cast call "$AP" 'getPoolAdmin()(address)' --rpc-url "$HP" 2>&1)"
emit "EMERGENCY_ADMIN: $(cast call "$AP" 'getEmergencyAdmin()(address)' --rpc-url "$HP" 2>&1)"
emit "PRICE_ORACLE: $(cast call "$AP" 'getPriceOracle()(address)' --rpc-url "$HP" 2>&1)"
emit "POOL_CONFIGURATOR: $(cast call "$AP" 'getPoolConfigurator()(address)' --rpc-url "$HP" 2>&1)"
