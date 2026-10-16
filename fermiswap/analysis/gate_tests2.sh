#!/usr/bin/env bash
# Gate tests with correct dummy args.
cd "$(dirname "$0")" && source ./env.sh
RPC="https://ethereum-rpc.publicnode.com"
DEAD=0x000000000000000000000000000000000000dEaD
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
E4=0x0109AA912B58508886a2a707204B0F8C8b164CCc
A1=0xb4723899a492330fedaccf22ec12f53a06e3b659
A2=0xeff407d968de7d312fd5e036aef8837b3679d777
S2=0x5979458912f80b96d30d4220af8e2e4925a33320
V=0x585d44727129B9C69791B10238Ca605932938B4F
t() { echo -n "  $2 -> "; timeout 12 cast call $1 "$2" --from $DEAD --rpc-url "$RPC" 2>&1 | head -1 | cut -c1-95; }
echo "=== engine4 with args ==="
t $E4 "53b0277e(address,address,uint256)" $WETH $WETH 1
t $E4 "209d6304(address,address,uint256)" $WETH $WETH 1
t $E4 "6d106317(address,uint256)" $WETH 1
t $E4 "d6c3c9df(address,address,bool)" $WETH $WETH true
t $E4 "451a5e65(address)" $WETH
t $E4 "79d44573(address)" $WETH
t $E4 "17d01716(address,address)" $WETH $WETH
t $E4 "58e64099(uint32)" 1
t $E4 "6d43fa4d(uint256[])" "[1]"
t $E4 "7fe10158((uint256,uint256)[])" "[(1,1)]"
t $E4 "acee8aab(uint256,uint256)" 1 1
echo "=== arb1 admin ==="
t $A1 "41cda41b(address)" $WETH
t $A1 "98e29d5a(address)" $WETH
t $A1 "9b30b23d(address)" $WETH
t $A1 "34022fdb(address)" $WETH
t $A1 "1072cbea(address,uint256)" $WETH 1
echo "=== arb2 admin ==="
t $A2 "41cda41b(address)" $WETH
t $A2 "106673bd(uint256)" 1
t $A2 "10ae88c7(uint256)" 1
t $A2 "9b30b23d(address)" $WETH
t $A2 "1072cbea(address,uint256)" $WETH 1
echo "=== new swapper ==="
t $S2 "4239db68(address)" $E4
t $S2 "dbda983b(address)" $V
t $S2 "85535cc5(address)" $V
t $S2 "404177c0(address,bytes)" $WETH 0x
t $S2 "1072cbea(address,uint256)" $WETH 1
echo "=== vault ==="
t $V "1072cbea(address,uint256)" $WETH 1
t $V "404177c0(address,bytes)" $WETH 0x
t $V "67170281(address[],address[],uint256[])" "[$WETH]" "[$DEAD]" "[1]"
t $V "85535cc5(address)" $V
