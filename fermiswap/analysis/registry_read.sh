#!/usr/bin/env bash
# Read the PrioUpdateRegistry state lanes as the Fermi engine (msg.sender = engine).
cd "$(dirname "$0")" && source ./env.sh
RPC="$ETH_RPC"
REG=0xDa7AfeeD01fe625CF15d187a19f94B45f00b8C5F
ENGINE=0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f
BOT=0xff67d7211d4837607d601e65f27b97622540c47f
echo "block=$(cast block-number --rpc-url $RPC)"
echo "--- registry constants ---"
echo -n "MAX_UPDATE_AGE = "; cast call $REG 'MAX_UPDATE_AGE()(uint256)' --rpc-url $RPC
echo -n "MAX_UPDATE_LEAD_TIME = "; cast call $REG 'MAX_UPDATE_LEAD_TIME()(uint256)' --rpc-url $RPC
echo "--- isUpdater(engine, bot) ---"
cast call $REG 'isUpdater(address,address)(bool)' $ENGINE $BOT --rpc-url $RPC
echo "--- getState as engine, lanes 0..5 ---"
for i in 0 1 2 3 4 5; do
  echo "lane $i:"
  cast call $REG 'getState(uint256,uint32,uint32)(uint32,uint256[])' $i 0 4294967295 --from $ENGINE --rpc-url $RPC 2>&1 | head -6
done
