#!/usr/bin/env bash
# read-only: resolve PositionManager NFTs owned by Spot FRLMs -> PoolKeys
set -u
K=$(grep '^ETHERSCANV2_API_KEY=' /home/heisenberg/CA/.env | cut -d= -f2- | tr -d '"')
U=${UNI_RPC:-https://mainnet.unichain.org}
PM=0x4529A01c7A0410167c5740C487A8DE60232617bf
T0=$(cast keccak "Transfer(address,address,uint256)")
for f in 0xa7b3e2306a0B46dbdE3B533c4e2C3Be6a24352a3 0xA7ce35E886e58926Ad0C149f4cc558e27D458a2c; do
  pad=0x000000000000000000000000${f:2}
  curl -s -m 40 "https://api.etherscan.io/v2/api?chainid=130&module=logs&action=getLogs&address=$PM&topic0=$T0&topic0_2_opr=and&topic2=$pad&fromBlock=0&toBlock=latest&apikey=$K" > logs_t_$f.json
  echo "== FRLM $f"
  python3 - "$f" "$U" <<'PY'
import sys,json,subprocess
f,U=sys.argv[1],sys.argv[2]
d=json.load(open(f"logs_t_{f}.json"))
res=d.get("result",[])
ids=[]
for l in res:
    t=l["topics"]
    if int(t[1],16)==0:  # mint
        ids.append(int(t[3],16))
print("minted tokenIds:", ids)
for tid in ids:
    out=subprocess.run(["cast","call","0x4529A01c7A0410167c5740C487A8DE60232617bf",
        "getPoolAndPositionInfo(uint256)(((address,address,uint24,int24,address),uint256))",str(tid),
        "--rpc-url",U],capture_output=True,text=True)
    print(tid, out.stdout.strip() or out.stderr.strip())
PY
done
