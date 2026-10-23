#!/usr/bin/env bash
# read-only: pendingFees + POL share for hook#1 and hook#2 pools
set -u
U=${UNI_RPC:-https://mainnet.unichain.org}
FRLM1=0xa7b3e2306a0B46dbdE3B533c4e2C3Be6a24352a3
FRLM2=0xA7ce35E886e58926Ad0C149f4cc558e27D458a2c
PM1=0xE072D3C7567D4B326dDdE0F77062E6758Aec0eE7
PM2=0xaaf29f2C9516062dc43c4465EF6d43cE8397CDDa
echo "== hook1 POL shares (nonzero?)"
for pid in $(awk '{print $1}' keys1.txt); do
  v=$(cast call $PM1 "getPoolPOLShare(bytes32)(uint256)" $pid --rpc-url $U 2>&1)
  pf=$(cast call $FRLM1 "getPendingFees(bytes32)(uint256,uint256)" $pid --rpc-url $U 2>&1 | tr '\n' '/')
  echo "$pid pol=$v pend=$pf"
done | sort -t= -k2 -rn | head -8
echo "== hook2 pools"
for pk in \
 "0x0000000000000000000000000000000000000000 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c 60" \
 "0x078D782b760474a361dDA0AF3839290b0EF57AD6 0x2615a94df961278DcbC41Fb0a54fEc5f10a693aE 10" \
 "0x078D782b760474a361dDA0AF3839290b0EF57AD6 0x139451953Ef1865c096F89c5e522C081DC3b5f11 10" \
 "0x078D782b760474a361dDA0AF3839290b0EF57AD6 0x12E96C2BFEA6E835CF8Dd38a5834fa61Cf723736 10" \
 "0x078D782b760474a361dDA0AF3839290b0EF57AD6 0x83f31af747189c2FA9E5DeB253200c505eff6ed2 10" \
 "0x0000000000000000000000000000000000000000 0x1EdB00ec41F4653e9D5b5487475F946DA3B8A7a2 60" \
 "0x078D782b760474a361dDA0AF3839290b0EF57AD6 0xbBeb08fD20A536938d2fD1B57b54AA2136A4e7E8 60" ; do
  set -- $pk
  pid=$(cast keccak $(cast abi-encode "f(address,address,uint24,int24,address)" $1 $2 8388608 $3 0xA0b0D2d00fD544D8E0887F1a3cEDd6e24Baf10cc))
  v=$(cast call $PM2 "getPoolPOLShare(bytes32)(uint256)" $pid --rpc-url $U 2>&1)
  pf=$(cast call $FRLM2 "getPendingFees(bytes32)(uint256,uint256)" $pid --rpc-url $U 2>&1 | tr '\n' '/')
  pos=$(cast call $FRLM2 "getPositionInfo(bytes32)(uint256,uint128,uint256,uint256)" $pid --rpc-url $U 2>&1 | tr '\n' '/')
  echo "$1 $2 ts=$3 pol=$v pend=$pf pos=$pos"
done
echo "== hook1 event history (Donation/HookFeeReinvested/FeesReinvested)"
K=$(grep '^ETHERSCANV2_API_KEY=' /home/heisenberg/CA/.env | cut -d= -f2- | tr -d '"')
for ev in "Donation(bytes32,address,uint256,uint256)" "FeesReinvested(bytes32,uint256,uint256,uint256)" "Deposit(bytes32,address,uint256,uint256,uint256)"; do
  t=$(cast keccak "$ev")
  n=$(curl -s -m 30 "https://api.etherscan.io/v2/api?chainid=130&module=logs&action=getLogs&address=$FRLM1&topic0=$t&fromBlock=0&toBlock=latest&apikey=$K" | python3 -c "import sys,json;d=json.load(sys.stdin);r=d.get('result');print(len(r) if isinstance(r,list) else r)")
  echo "$ev -> $n"
done