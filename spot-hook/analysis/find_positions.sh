#!/usr/bin/env bash
# read-only: find PositionManager NFTs owned by the Spot FRLMs on Unichain
U=${UNI_RPC:-https://mainnet.unichain.org}
PM=0x4529A01c7A0410167c5740C487A8DE60232617bf
T0=$(cast keccak "Transfer(address,address,uint256)")
for f in 0xa7b3e2306a0B46dbdE3B533c4e2C3Be6a24352a3 0xA7ce35E886e58926Ad0C149f4cc558e27D458a2c; do
  pad=0x000000000000000000000000${f:2}
  echo "== FRLM $f"
  curl -s -m 40 -X POST -H 'content-type: application/json' -A 'Mozilla/5.0' \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_getLogs\",\"params\":[{\"address\":\"$PM\",\"fromBlock\":\"0x0\",\"toBlock\":\"latest\",\"topics\":[\"$T0\",null,\"$pad\"]}]}" \
    $U > logs_$f.json
  python3 - "$f" <<'PY'
import sys,json
f=sys.argv[1]
d=json.load(open(f"logs_{f}.json"))
r=d.get('result',[])
print("n logs",len(r))
for l in r:
    print(l['blockNumber'], int(l['topics'][3],16))
PY
done
