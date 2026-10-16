#!/usr/bin/env bash
# Gate-test all non-view unknown functions from a random address. Read-only eth_call.
cd "$(dirname "$0")" && source ./env.sh
RPC="https://ethereum-rpc.publicnode.com"
DEAD=0x000000000000000000000000000000000000dEaD
E4=0x0109AA912B58508886a2a707204B0F8C8b164CCc
E3=0x90f73feA1Ee2dC514D4dbac0bFf7fF04B933767f
A1=0xb4723899a492330fedaccf22ec12f53a06e3b659
A2=0xeff407d968de7d312fd5e036aef8837b3679d777
S2=0x5979458912f80b96d30d4220af8e2e4925a33320
t() { # addr sig
  echo -n "  $1 $2 -> "
  timeout 12 cast call $1 "$2" --from $DEAD --rpc-url "$RPC" 2>&1 | head -1 | cut -c1-90
}
echo "=== engine4 unknown fns (expect NM) ==="
t $E4 '0e85d1e3(address[],bool)' 2>/dev/null || true
echo "  (use raw selectors with dummy args)"
# raw selector calls with zero args
for sel in 0x53b0277e 0x209d6304 0x2f598213 0x6d106317 0x6d43fa4d 0x7fe10158 0x58e64099 0x451a5e65 0x79d44573 0x17d01716 0xd6c3c9df; do
  echo -n "  $sel -> "; timeout 12 cast call $E4 $sel --from $DEAD --rpc-url "$RPC" 2>&1 | head -1 | cut -c1-80
done
echo "=== arb1 (b4723899) admin fns ==="
for sel in 0x41cda41b 0x98e29d5a 0x9b30b23d 0x34022fdb 0x1072cbea 0x519af30e; do
  echo -n "  $sel -> "; timeout 12 cast call $A1 $sel --from $DEAD --rpc-url "$RPC" 2>&1 | head -1 | cut -c1-80
done
echo "=== arb2 (eff407d9) admin fns ==="
for sel in 0x41cda41b 0x106673bd 0x10ae88c7 0x9b30b23d 0x1072cbea 0x519af30e; do
  echo -n "  $sel -> "; timeout 12 cast call $A2 $sel --from $DEAD --rpc-url "$RPC" 2>&1 | head -1 | cut -c1-80
done
echo "=== new swapper (5979458912) manager fns ==="
for sel in 0x4239db68 0xdbda983b 0x85535cc5 0x404177c0 0x519af30e 0x1072cbea; do
  echo -n "  $sel -> "; timeout 12 cast call $S2 $sel --from $DEAD --rpc-url "$RPC" 2>&1 | head -1 | cut -c1-80
done
echo "=== vault manager fns ==="
for sel in 0x1072cbea 0x519af30e 0x404177c0 0x67170281 0x85535cc5; do
  echo -n "  $sel -> "; timeout 12 cast call 0x585d44727129B9C69791B10238Ca605932938B4F $sel --from $DEAD --rpc-url "$RPC" 2>&1 | head -1 | cut -c1-80
done
