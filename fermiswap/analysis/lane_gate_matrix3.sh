#!/usr/bin/env bash
# Lane-updater gate matrix v3: python-built calldata.
cd "$(dirname "$0")" && source ./env.sh
RPC="https://ethereum-rpc.publicnode.com"
E4=0x0109AA912B58508886a2a707204B0F8C8b164CCc
DEAD=0x000000000000000000000000000000000000dEaD
U1=0x14e870f0a7c764ca71289952006d6bf130058927
U2=0xfc42be9494f1af6b03adad71811c62ada2d6f3c3
L1=2eec03b8999af9793df60f1395a1b41c29e22b324ea3200ca21bc692979b9d46
L2=1f160fb6b5eff44c72397d5a5dca127da716ebbf5efe6a024a6a09031fb359f4
enc() { python3 -c "import sys; lane=int(sys.argv[1],16); price=int(sys.argv[2]); print('0xacee8aab'+format(lane,'064x')+format(price,'064x'))" "$1" "$2"; }
call() { # from lanehex price label
  local data=$(enc "$2" "$3")
  echo -n "  from ${1:0:12} lane=${2:0:12} price=$3 -> "
  timeout 12 cast call $E4 $data --from $1 --rpc-url "$RPC" 2>&1 | head -1 | cut -c1-80
}
echo "== from dead =="
call $DEAD $L1 241709515164
call $DEAD $L1 1
call $DEAD 1 1
echo "== from u1 (provider of L1) =="
call $U1 $L1 241709515164
call $U1 $L2 241934539240
call $U1 1 1
echo "== from u2 (provider of L2) =="
call $U2 $L2 241934539240
call $U2 $L1 241709515164
