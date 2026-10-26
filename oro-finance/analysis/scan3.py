import sys, json, time
sys.path.insert(0,'.')
import rpc2
from b58 import b58dec
PID="iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop"
def fullkeys(tx):
    m=tx["transaction"]["message"]; k=[x["pubkey"] for x in m["accountKeys"]]
    la=tx["meta"].get("loadedAddresses") or {}
    k+= list(la.get("writable") or []); k+= list(la.get("readonly") or [])
    return k
def scan(n=1000):
    sigs=rpc2.call("getSignaturesForAddress",[PID,{"limit":min(n,1000)}])
    sys.stderr.write(f"sigs {len(sigs)} slots {sigs[0]['slot']} -> {sigs[-1]['slot']}\n")
    hits=[]
    for i in range(0,len(sigs),25):
        chunk=sigs[i:i+25]
        reqs=[{"jsonrpc":"2.0","id":j,"method":"getTransaction","params":[s["signature"],{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}]} for j,s in enumerate(chunk)]
        try:
            r=rpc2.batch(reqs)
        except Exception as e:
            sys.stderr.write(f"batch err {e}\n"); continue
        if isinstance(r,dict): r=[r]
        byid={x.get("id"):x.get("result") for x in r}
        for j,s in enumerate(chunk):
            tx=byid.get(j)
            if not tx: continue
            keys=fullkeys(tx)
            logs=(tx["meta"].get("logMessages") or [])
            top=[];inner=[]
            for ix in tx["transaction"]["message"]["instructions"]:
                if ix.get("programId")==PID: top.append(ix)
            for g in tx["meta"].get("innerInstructions") or []:
                for ix in g["instructions"]:
                    if ix.get("programId")==PID: inner.append(ix)
            if top or inner:
                hits.append({"sig":s["signature"],"slot":s["slot"],
                    "logs":[l for l in logs if "Instruction:" in l],
                    "top":[{"data":ix.get("data"),"accts":ix.get("accounts") or ix.get("accountKeyIndexes")} for ix in top],
                    "inner":[{"data":ix.get("data"),"accts":ix.get("accounts") or ix.get("accountKeyIndexes")} for ix in inner],
                    "keys":keys})
        if i%250==0: sys.stderr.write(f"  ..{i} hits={len(hits)}\n")
    return hits
if __name__=="__main__":
    h=scan(int(sys.argv[1]) if len(sys.argv)>1 else 1000)
    json.dump(h,open("core_hits.json","w"),indent=1)
    print("HITS",len(h))
