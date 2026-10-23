#!/usr/bin/env bash
# read-only: for each poolId, fetch PM Initialize log (topic1=poolId) -> decode key, filter hooks
set -u
K=$(grep '^ETHERSCANV2_API_KEY=' /home/heisenberg/CA/.env | cut -d= -f2- | tr -d '"')
PM=0x1F98400000000000000000000000000000000004
T0INIT=$(cast keccak "Initialize(bytes32,address,address,uint24,int24,address,uint160,int24)")
> keys1.txt
while read -r pid; do
  [ -z "$pid" ] && continue
  curl -s -m 40 "https://api.etherscan.io/v2/api?chainid=130&module=logs&action=getLogs&address=$PM&topic0=$T0INIT&topic0_1_opr=and&topic1=$pid&fromBlock=0&toBlock=latest&apikey=$K" > /tmp/opencode/init_$pid.json
  python3 - "$pid" <<'PY' >> keys1.txt
import sys,json
pid=sys.argv[1]
try:
    d=json.load(open(f"/tmp/opencode/init_{pid}.json"))
except Exception as e:
    print("ERR",pid,e); sys.exit()
r=d.get("result",[])
if not isinstance(r,list) or not r:
    print("NONE",pid); sys.exit()
l=r[0]
data=l["data"][2:]
# data = fee(32) tickSpacing(32) hooks(32) sqrtPrice(32) tick(32)
fee=int(data[0:64],16); ts=int(data[64:128],16); hooks="0x"+data[128:192][24:]; sq=int(data[192:256],16); tick=int(data[256:320],16)
c0="0x"+l["topics"][2][26:]; c1="0x"+l["topics"][3][26:]
print(pid,c0,c1,fee,ts,hooks,sq,tick,l["blockNumber"])
PY
done < poolids.txt
echo "--- hook#1 pools (hooks=0x88C9fF9F...):"
grep -i "0x88c9ff9f" keys1.txt || echo none
echo "--- all:"
cat keys1.txt
