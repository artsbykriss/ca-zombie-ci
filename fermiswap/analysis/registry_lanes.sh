#!/usr/bin/env bash
# Read all 8 lanes on PrioUpdateRegistry as engine3.
cd "$(dirname "$0")" && source ./env.sh
RPC="https://ethereum-rpc.publicnode.com"
REG=0xDa7AfeeD01fe625CF15d187a19f94B45f00b8C5F
E3=0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f
LANES="2eec03b8999af9793df60f1395a1b41c29e22b324ea3200ca21bc692979b9d46 1f160fb6b5eff44c72397d5a5dca127da716ebbf5efe6a024a6a09031fb359f4 8572bdba86a20264869c9ba9a80466276690132a91547b719314a1ebea354863 9ea518776184c510b4464eeade9b627198cc588b96331825ddfcac9bed2c762e ea14b3e894601578a31df225a23a15bdd1e6a539f7e4a84df4ce1a4605e21f99"
for l in $LANES; do
  echo "lane 0x${l:0:16}..."
  timeout 15 cast call $REG 'getState(uint256,uint32,uint32)(uint32,uint256[])' 0x$l 0 4294967295 --from $E3 --rpc-url "$RPC" 2>&1 | head -4
done
