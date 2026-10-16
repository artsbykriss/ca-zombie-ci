#!/usr/bin/env bash
# Lane-updater gate matrix v2: raw ABI encoding (avoid fallback false-success).
cd "$(dirname "$0")" && source ./env.sh
RPC="https://ethereum-rpc.publicnode.com"
E4=0x0109AA912B58508886a2a707204B0F8C8b164CCc
DEAD=0x000000000000000000000000000000000000dEaD
U1=0x14e870f0a7c764ca71289952006d6bf130058927
U2=0xfc42be9494f1af6b03adad71811c62ada2d6f3c3
L1=2eec03b8999af9793df60f1395a1b41c29e22b324ea3200ca21bc692979b9d46
L2=1f160fb6b5eff44c72397d5a5dca127da716ebbf5efe6a024a6a09031fb359f4
# manual encode: selector + uint256 lane + uint256 price
enc() { printf '0xacee8aab%064x%064x' "$1" "$2"; }
call() { # from lane price label
  local data=$(enc "$2" "$3")
  echo -n "  from ${1:0:12} lane=${2:0:12} price=$3 -> "
  timeout 12 cast call $E4 $data --from $1 --rpc-url "$RPC" 2>&1 | head -1 | cut -c1-80
}
echo "== from dead (unprivileged) =="
call $DEAD 0x$L1 1
call $DEAD 0x$L1 241709515164
call $DEAD 0x$L2 241934539240
call $DEAD 1 1
echo "== from lane1 provider u1 =="
call $U1 0x$L1 241709515164
call $U1 0x$L2 241934539240
call $U1 1 1
echo "== from lane2 provider u2 =="
call $U2 0x$L2 241934539240
call $U2 0x$L1 241709515164
