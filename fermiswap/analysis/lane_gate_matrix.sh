#!/usr/bin/env bash
# Lane-updater gate matrix for engine4.acee8aab(lane,price).
cd "$(dirname "$0")" && source ./env.sh
RPC="https://ethereum-rpc.publicnode.com"
E4=0x0109AA912B58508886a2a707204B0F8C8b164CCc
DEAD=0x000000000000000000000000000000000000dEaD
U1=0x14e870f0a7c764ca71289952006d6bf130058927   # provider of lane 2eec (WETH/USDC)
U2=0xfc42be9494f1af6b03adad71811c62ada2d6f3c3   # provider of lane 1f16 (WETH/USDT)
L1=2eec03b8999af9793df60f1395a1b41c29e22b324ea3200ca21bc692979b9d46
L2=1f160fb6b5eff44c72397d5a5dca127da716ebbf5efe6a024a6a09031fb359f4
call() { # from lane price label
  local data=$(cast calldata "acee8aab(uint256,uint256)" "$2" "$3")
  echo -n "  [$5] from $1 lane=${2:0:10} price=$3 -> "
  timeout 12 cast call $E4 $data --from $1 --rpc-url "$RPC" 2>&1 | head -1 | cut -c1-70
}
call $DEAD 0x$L1 1 "dead, real lane"
call $DEAD 0x$L2 1 "dead, real lane2"
call $DEAD 1 1 "dead, lane=1"
call $DEAD 0 1 "dead, lane=0"
call $U1 0x$L1 1 "u1, own lane"
call $U1 0x$L2 1 "u1, other lane"
call $U1 1 1 "u1, lane=1"
call $U2 0x$L1 1 "u2, other lane"
call $U2 0x$L2 1 "u2, own lane"
