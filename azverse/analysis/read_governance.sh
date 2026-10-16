#!/bin/bash
# Multi-chain custody + governance reads (keyless public RPCs).
set -u
arb=https://arbitrum-one-rpc.publicnode.com
eth=https://ethereum-rpc.publicnode.com
bsc=https://bsc-dataseed.binance.org
bera=https://rpc.berachain.com
echo "### codesizes of custody wallets + role contracts"
for chain in "arb:$arb" "eth:$eth" "bsc:$bsc" "bera:$bera"; do
  name=${chain%%:*}; rpc=${chain#*:}
  echo "-- chain=$name block=$(cast block-number --rpc-url $rpc 2>/dev/null || echo NA)"
  for a in 0x03a7e58745874d49b3acc770c40261a3ce206608 0xc2a290eceac480f057b6e7b45a7a949535e478ce 0xdc379823a9a3a2ca9d77c33299551ecdbabf7a41; do
    echo "  $a size=$(cast codesize $a --rpc-url $rpc 2>/dev/null) bal=$(cast balance $a --rpc-url $rpc 2>/dev/null)"
  done
done
echo "### governance contracts on Arbitrum"
for tl in 0x7a1b6891269ed1699f93e25296a6e23d6f4f7386 0x92996ea56590b0e659d695d9736db62cae843b51 0x383a6439f966d67edc6140d12024334616ddc276; do
  echo "-- timelock $tl"
  echo "   minDelay=$(cast call $tl 'getMinDelay()(uint256)' --rpc-url $arb 2>/dev/null)"
  for r in PROPOSER_ROLE EXECUTOR_ROLE CANCELLER_ROLE DEFAULT_ADMIN_ROLE TIMELOCK_ADMIN_ROLE; do
    echo "   $r(zero)=$(cast call $tl 'hasRole(bytes32,address)(bool)' "$(cast keccak "$r")" 0x0000000000000000000000000000000000000000 --rpc-url $arb 2>/dev/null)"
  done
done
echo "-- Safe 0x4a335bb7f44fc27bf4fbb5705e71014bace924ec"
S=0x4a335bb7f44fc27bf4fbb5705e71014bace924ec
echo "   threshold=$(cast call $S 'getThreshold()(uint256)' --rpc-url $arb 2>/dev/null)"
echo "   owners=$(cast call $S 'getOwners()(address[])' --rpc-url $arb 2>/dev/null | tr '\n' ' ')"
echo "   singleton=$(cast storage $S 0 --rpc-url $arb 2>/dev/null)"
echo "   version=$(cast call $S 'VERSION()(string)' --rpc-url $arb 2>/dev/null)"
