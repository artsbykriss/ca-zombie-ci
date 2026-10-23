#!/usr/bin/env bash
# read-only: resolve hook#1 pool keys via policyManager#1 PoolPOLShareChanged -> PM Initialize(topic1=poolId)
set -u
K=$(grep '^ETHERSCANV2_API_KEY=' /home/heisenberg/CA/.env | cut -d= -f2- | tr -d '"')
PM=0x1F98400000000000000000000000000000000004
PM1=0xE072D3C7567D4B326dDdE0F77062E6758Aec0eE7
T0INIT=$(cast keccak "Initialize(bytes32,address,address,uint24,int24,address,uint160,int24)")
T0POL=$(cast keccak "PoolPOLShareChanged(bytes32,uint256)")
echo "T0POL=$T0POL"
curl -s -m 60 "https://api.etherscan.io/v2/api?chainid=130&module=logs&action=getLogs&address=$PM1&topic0=$T0POL&fromBlock=0&toBlock=latest&apikey=$K" > polshare.json
python3 - <<'PY'
import json
d=json.load(open("polshare.json"))
r=d.get("result",[])
print("pol events:",len(r) if isinstance(r,list) else r)
ids=[l["topics"][1] for l in r] if isinstance(r,list) else []
open("poolids.txt","w").write("\n".join(ids))
print(ids)
PY
