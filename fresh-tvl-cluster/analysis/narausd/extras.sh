#!/usr/bin/env bash
RPC=${RPC:-https://ethereum-rpc.publicnode.com}
NARAUSD=0x5C6263904CCFD3Bcf1aAa6e7063dDd29743b3Bb7
NARAUSDPLUS=0x1aa23CDFC941f6b54251C72012A9Bfa4bF5394D6
EXTRA="NaraUSDComposer1=0xd1a574389D78841a173127485044BF254dF7Bcb7
NaraUsdComposer2=0x4e777F5A30ea1766ebB400E855855557EcB21459
NaraUsdOFT=0x5A31B17100692B6580b50D0Cb54Bc3A0B63Ab5aD
NaraUsdOFTAdapter=0x19BE18BF9a2CC44c126B3051eE36eD16Bd63e05d
PlusAprPair=0x11059Cd5306293E5835A8EC9ee64e2c62eF46960
PlusComposer=0xb9d7f9973A4770Ced92a6bD9C9F014b767dfF9cd
PlusCooldownImpl=0x7Af00E1f9A73e6F9b2BD1fFa373A1c878f6fE4bD
PlusOFTAdapter=0x9eBE68D706A82a78A5c1Afc118B287Dba91e1C32
PlusStrategy=0x9d6Edc81a314A92fe1C50F62a2a5292d4296c0ae
PlusSilo2=0x086c61bCbB5766b244235b7c10C5B49143960369
RedeemSilo2=0x27fd785F5767E3443D3A726d9715f64956539a71
SwapAdapter=0x4231eA42f8b148321bB055f3eCD34b3E76C1078A
StrataJunior=0xAf2C2B0348DcACbA014989Cc63eF9864bc42ECb6
StrataSenior=0x23bCF479A7d90c13dA9F6ec64BA2Ba52086e6471"
echo "block=$(cast block-number --rpc-url $RPC)"
for pair in $EXTRA; do
  n=${pair%%=*}; a=${pair##*=}
  code=$(cast code $a --rpc-url $RPC | wc -c)
  nar=$(cast call $NARAUSD 'balanceOf(address)(uint256)' $a --rpc-url $RPC 2>/dev/null || echo "?")
  narp=$(cast call $NARAUSDPLUS 'balanceOf(address)(uint256)' $a --rpc-url $RPC 2>/dev/null || echo "?")
  echo "$n $a codesize=$code NaraUSD=$nar NaraUSDPlus=$narp"
done
