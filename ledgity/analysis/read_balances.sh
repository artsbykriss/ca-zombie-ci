#!/usr/bin/env bash
# Read vault buffer + manager balances (read-only, public RPCs).
set -uo pipefail
cd "$(dirname "$0")/.."
declare -A R=(
 [ethereum]="https://ethereum-rpc.publicnode.com"
 [base]="https://mainnet.base.org"
 [arbitrum]="https://arbitrum-one-rpc.publicnode.com"
 [linea]="https://rpc.linea.build"
 [sonic]="https://rpc.soniclabs.com"
)
# vault|chain|asset|atoken|lm
ROWS=(
 "ethereum_lyUSD|ethereum|0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48|0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c|0xE7616e98d2506E571E8f6E38e7Bfd0b55642ACac|0x3C769d0e8D21d380228dFB7918c6933bb6ecB6D4"
 "ethereum_lyEUR|ethereum|0x1aBaEA1f7C830bD89Acc67eC4af516284b1bC33c|0xAA6e91C82942aeAE040303Bf96c15a6dBcB82CA0|0xF25a516CAF56895032b3f3eE842b45462Ff491c3|0x20968165B7d2cDF33aF632aAB3e0539848d44BC8"
 "base_lyUSD|base|0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913|0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB|0xE7616e98d2506E571E8f6E38e7Bfd0b55642ACac|0x916f179D5D9B7d8Ad815AC2f8570aabF0C6a6e38"
 "base_lyEUR|base|0x60a3E35Cc302bFA44Cb288Bc5a4F316Fdb1adb42|0x90DA57E0A6C0d166Bf15764E03b83745Dc90025B|0xF25a516CAF56895032b3f3eE842b45462Ff491c3|0xFaA1e3720e6Ef8cC76A800DB7B3dF8944833b134"
 "arbitrum_lyUSD|arbitrum|0xaf88d065e77c8cC2239327C5EDb3A432268e5831|0x724dc807b04555b71ed48a6896b6F41593b8C637|0xE7616e98d2506E571E8f6E38e7Bfd0b55642ACac|0x283F35b6406a0e19a786ed119869eF2c0fE157Ee"
 "linea_lyUSD|linea|0x176211869cA2b568f2A7D4EE941E073a821EE1ff|0x374D7860c4f2f604De0191298dD393703Cce84f3|0xE7616e98d2506E571E8f6E38e7Bfd0b55642ACac|0x43b3c64dbc95F9eD83795E051fc00014059e698F"
 "sonic_lyUSD|sonic|0x29219dd400f2Bf60E5a23d13Be72B486D4038894|0x578Ee1ca3a8E1b54554Da1Bf7C583506C4CD11c6|0xE7616e98d2506E571E8f6E38e7Bfd0b55642ACac|0x65f75c675Cc76474662DfBF7B6e8683764223001"
)
OUT=analysis/balances.json
RAW=analysis/balances.raw
: > "$RAW"
for row in "${ROWS[@]}"; do
  IFS='|' read -r name chain asset atoken lm vault <<< "$row"
  rpc="${R[$chain]}"
  ( vb=$(cast call --rpc-url "$rpc" "$asset" "balanceOf(address)(uint256)" "$vault" 2>/dev/null | sed 's/ \[.*//')
    ab=$(cast call --rpc-url "$rpc" "$atoken" "balanceOf(address)(uint256)" "$vault" 2>/dev/null | sed 's/ \[.*//')
    lb=$(cast call --rpc-url "$rpc" "$asset" "balanceOf(address)(uint256)" "$lm" 2>/dev/null | sed 's/ \[.*//')
    echo "$name|$chain|$asset|$atoken|$lm|$vault|$vb|$ab|$lb" > "analysis/bal_$name.txt"
    echo "DONE $name" ) &
done
wait
for row in "${ROWS[@]}"; do IFS='|' read -r name _ _ _ _ _ <<< "$row"; cat "analysis/bal_$name.txt" >> "$RAW"; done
jq -R -s 'split("\n") | map(select(length>0) | split("|") | {vault:.[0], chain:.[1], asset:.[2], atoken:.[3], lm:.[4], vault_addr:.[5], vault_asset_bal:.[6], vault_atoken_bal:.[7], lm_asset_bal:.[8]})' "$RAW" > "$OUT"
jq . "$OUT" >/dev/null 2>&1 && echo "valid" || echo "invalid"
