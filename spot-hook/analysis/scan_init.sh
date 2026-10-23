#!/usr/bin/env bash
# read-only: enumerate v4 PoolManager Initialize logs, keep those whose hooks == target
set -u
K=$(grep '^ETHERSCANV2_API_KEY=' /home/heisenberg/CA/.env | cut -d= -f2- | tr -d '"')
PM=0x1F98400000000000000000000000000000000004
T0=$(cast keccak "Initialize(bytes32,address,address,uint24,int24,address,uint160,int24)")
echo "T0=$T0"
# first probe: single call 0..latest
curl -s -m 60 "https://api.etherscan.io/v2/api?chainid=130&module=logs&action=getLogs&address=$PM&topic0=$T0&fromBlock=0&toBlock=latest&apikey=$K" > init_probe.json
head -c 200 init_probe.json; echo
python3 - <<'PY'
import json
d=json.load(open("init_probe.json"))
print("status",d.get("status"),"msg",d.get("message"),"n",len(d.get("result",[])) if isinstance(d.get("result"),list) else d.get("result"))
PY
