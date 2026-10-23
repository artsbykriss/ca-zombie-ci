#!/usr/bin/env bash
set -u
ARB=https://arb1.arbitrum.io/rpc
P=0x9215748657319B17fecb2b5D086A3147BFBC8613
for t in 0xff970a61a04b1ca14834a43f5de4533ebddb5cc8:USDC.e 0xaf88d065e77c8cc2239327c5edb3a432268e5831:USDC 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1:WETH 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f:WBTC 0x912CE59144191C1204E64559FE8253a0e49E6548:ARB 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1:DAI 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9:USDT; do
  a=${t%%:*}; n=${t##*:}
  b=$(cast call "$a" "balanceOf(address)(uint256)" "$P" --rpc-url "$ARB" 2>/dev/null)
  echo "$n $a = $b"
done
echo "== supply tokens totalSupply =="
for s in 0xda97c62b1c11f925b897fa0d8c66ad90e301639b 0xd94c047483e3b421a5c5034d62e5b16cb0f9b0b1 0x5eac65969b22c39692422c8c3b0ba1ae005bc58a 0xb507218501d6788fc42e0618d6d9c163b0dd87a0; do
  ts=$(cast call "$s" "totalSupply()(uint256)" --rpc-url "$ARB" 2>/dev/null)
  nm=$(cast call "$s" "name()(string)" --rpc-url "$ARB" 2>/dev/null)
  echo "$s supply=$ts name=$nm"
done
echo "== pair 3,4 exists? =="
for i in 3 4; do echo "pair $i:"; cast call "$P" "getPairStatus(uint256)" $i --rpc-url "$ARB" 2>&1 | head -c 130; echo; done
