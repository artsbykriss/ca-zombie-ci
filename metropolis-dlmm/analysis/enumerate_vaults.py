#!/usr/bin/env python3
"""Enumerate Metropolis DLMM VaultFactory oracle vaults on Sonic (read-only).

Batch JSON-RPC. No secrets. Public RPC only.
"""
import json, urllib.request, subprocess
from collections import Counter

RPC = "https://rpc.soniclabs.com"
FACTORY = "0x197d40B36677248E82939f96930bf4E7Fe8aD1c2"

def sig(s):
    return subprocess.check_output(["cast","sig",s]).decode().strip()

SEL_NUM   = sig("getNumberOfVaults(uint8)")
SEL_VAULT = sig("getVaultAt(uint8,uint256)")
SEL_BAL   = sig("getBalances()")
SEL_TOTAL = sig("totalSupply()")
SEL_STRAT = sig("getStrategy()")
SEL_OP    = sig("getOperator()")
SEL_TX    = sig("getTokenX()")
SEL_TY    = sig("getTokenY()")
SEL_PAUSE = sig("isDepositsPaused()")
SEL_FLAG  = sig("isFlaggedForShutdown()")

def rpc_batch(calls):
    payload = [{"jsonrpc":"2.0","id":i,"method":"eth_call",
                "params":[{"to":c["to"],"data":c["data"]},"latest"]} for i,c in enumerate(calls)]
    req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
        headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    with urllib.request.urlopen(req, timeout=90) as r:
        res = json.load(r)
    out = {item["id"]: item.get("result") for item in res}
    return [out[i] for i in range(len(calls))]

def dec_addr(h):
    if not h or len(h) < 42: return None
    return "0x"+h[-40:]

def dec_uint(h):
    if not h or h=="0x": return 0
    return int(h,16)

def word(i): return i.to_bytes(32,"big").hex()

n = dec_uint(rpc_batch([{"to":FACTORY,"data":SEL_NUM+word(2)}])[0])
print("oracle vaults:", n)

vaults=[]
for i in range(n):
    vaults.append(dec_addr(rpc_batch([{"to":FACTORY,"data":SEL_VAULT+word(2)+word(i)}])[0]))
print("sample:", vaults[:3])

res=[]
for v in vaults:
    r = rpc_batch([{"to":v,"data":SEL_STRAT},{"to":v,"data":SEL_BAL},{"to":v,"data":SEL_TOTAL},
                   {"to":v,"data":SEL_TX},{"to":v,"data":SEL_TY},{"to":v,"data":SEL_PAUSE},
                   {"to":v,"data":SEL_FLAG}])
    bal = r[1] or "0x"
    bx = dec_uint(bal[2:66]) if len(bal)>=66 else 0
    by = dec_uint(bal[66:130]) if len(bal)>=130 else 0
    res.append({"vault":v,"strategy":dec_addr(r[0]),"balX":bx,"balY":by,
                "totalSupply":dec_uint(r[2]),"tokenX":dec_addr(r[3]),"tokenY":dec_addr(r[4]),
                "paused":dec_uint(r[5]),"flagged":dec_uint(r[6])})

strats = sorted(set(x["strategy"] for x in res if x["strategy"]))
opmap={}
for i in range(0,len(strats),50):
    chunk=strats[i:i+50]
    rr=rpc_batch([{"to":s,"data":SEL_OP} for s in chunk])
    for s,o in zip(chunk,rr): opmap[s]=dec_addr(o)
for x in res: x["operator"]=opmap.get(x["strategy"])

json.dump(res, open("/home/heisenberg/CA/metropolis-dlmm/analysis/vaults_raw.json","w"), indent=1)
print("dumped", len(res))
print("operator distribution:", Counter(x["operator"] for x in res).most_common(15))
nz=[x for x in res if x["balX"] or x["balY"]]
print("vaults with nonzero getBalances:", len(nz))
for x in nz:
    print(x["vault"],"X",x["balX"],"Y",x["balY"],"op",x["operator"],"paused",x["paused"],"flag",x["flagged"])
