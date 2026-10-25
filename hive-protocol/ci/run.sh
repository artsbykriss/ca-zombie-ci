#!/usr/bin/env bash
# ci/run.sh — heavy job for the Hive Protocol (BSquared 223) target.
# Runs inside GitHub Actions from the hive-protocol/ folder.
#   * enumerates native-BTC deposit/withdraw activity for the staking contract + vault
#     via eth_getLogs (1000-block windows; the BSquared public RPC caps the range)
#   * writes machine-readable results to ci-out/
# Never prints secrets. Only keyless public RPC is used.
set -uo pipefail
mkdir -p ci-out
RPC="${BSQUARED_RPC_URL:-https://rpc.bsquared.network}"
export RPC

if [ -s ci-out/logs_scan.json ]; then
  echo "[ci] logs_scan.json present (cached) - skipping re-scan"
else
python3 - <<'PY' 2>&1 | tee ci-out/logs_scan.txt
import json, os, urllib.request, time
RPC=os.environ["RPC"]
def rpc(m,p):
    for _ in range(4):
        try:
            req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),
                                       headers={"content-type":"application/json"})
            return json.load(urllib.request.urlopen(req,timeout=30))
        except Exception as e:
            time.sleep(1)
    return {"error":"failed"}

head=int(rpc("eth_blockNumber",[])["result"],16)
print("head",head)
targets={
 "staking":"0xd5B5f1CA0fa5636ac54b0a0007BA374A1513346e",
 "vault":"0xe677F4B6104726D76DeBc681d7a862CE269aA8F3",
 "stratmgr":"0xcf38c660e0e99bed4c4ac8817922a0a3a996700b",
}
# scan the whole plausible active window: startBlock=772500 but contract deployed later;
# rewardBlockNumber ~39,482,000 -> scan from 39,000,000 to head in 1000-block windows.
START=39000000
out={k:{"count":0,"by_topic":{},"samples":[]} for k in targets}
w=START
t0=time.time()
while w < head:
    frm=w; to=min(w+999,head)
    for k,addr in targets.items():
        r=rpc("eth_getLogs",[{"fromBlock":hex(frm),"toBlock":hex(to),"address":addr}])
        for lg in r.get("result",[]):
            out[k]["count"]+=1
            t0t=lg["topics"][0] if lg.get("topics") else "0x"
            out[k]["by_topic"][t0t]=out[k]["by_topic"].get(t0t,0)+1
            if len(out[k]["samples"])<25:
                out[k]["samples"].append({"block":int(lg["blockNumber"],16),"tx":lg["transactionHash"],
                                          "topic0":t0t,"topics":lg.get("topics",[])[1:4]})
    w+=1000
print("scan seconds", round(time.time()-t0,1))
for k in targets:
    print("==",k,"count",out[k]["count"])
    for t,c in sorted(out[k]["by_topic"].items(),key=lambda x:-x[1])[:12]:
        print("   topic",t,c)
json.dump({"head":head,"start":START,"result":out},open("ci-out/logs_scan.json","w"),indent=1)
print("wrote ci-out/logs_scan.json")
PY
fi

echo "=== forge build/test handled by workflow ==="
ls -la ci-out
