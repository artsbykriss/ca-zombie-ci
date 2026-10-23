#!/usr/bin/env bash
set -u
ARB=https://arb1.arbitrum.io/rpc
P=0x9215748657319B17fecb2b5D086A3147BFBC8613
SIG=$(python3 /home/heisenberg/CA/predy-v2/analysis/sig.py)
cd /home/heisenberg/CA/predy-v2/analysis
for i in 1 2 3; do
  cast call "$P" "getPairStatus(uint256)" $i --rpc-url "$ARB" > pair_$i.hex 2>/dev/null
  echo "===== pair $i ====="
  cast decode-abi "$SIG" "$(cat pair_$i.hex)" 2>&1 | head -80
done
