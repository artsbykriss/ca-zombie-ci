import sys, json, hashlib, time
sys.path.insert(0,'.')
from rpc import call, batch
from b58 import b58dec,b58enc
PID="iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop"
EP="https://api.mainnet-beta.solana.com"
def fullkeys(tx):
    m=tx["transaction"]["message"]; k=[x["pubkey"] for x in m["accountKeys"]]
    la=tx["meta"].get("loadedAddresses") or {}
    k+= list(la.get("writable") or []); k+= list(la.get("readonly") or [])
    return k
def scan(n=1000, before=None):
    opts={"limit":min(n,1000)}
    if before: opts["before"]=before
    sigs=call("getSignaturesForAddress",[PID,opts],ep=EP,retries=4)
    sys.stderr.write(f"sigs {len(sigs)} slots {sigs[0]['slot']} -> {sigs[-1]['slot']}\n")
    hits=[]
    for i in range(0,len(sigs),10):
        chunk=sigs[i:i+10]
        reqs=[{"jsonrpc":"2.0","id":j,"method":"getTransaction","params":[s["signature"],{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}]} for j,s in enumerate(chunk)]
        for attempt in range(5):
            try:
                r=batch(reqs,ep=EP,retries=1)
                break
            except Exception as e:
                sys.stderr.write(f"batch err {e}\n"); time.sleep(2)
        else:
            continue
        if isinstance(r,dict): r=[r]
        byid={x.get("id"):x.get("result") for x in r}
        for j,s in enumerate(chunk):
            tx=byid.get(j)
            if not tx: continue
            keys=fullkeys(tx)
            logs=(tx["meta"].get("logMessages") or [])
            top=[]; inner=[]
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
        if i%100==0: sys.stderr.write(f"  ..{i} hits={len(hits)}\n")
        time.sleep(0.1)
    return hits
if __name__=="__main__":
    n=int(sys.argv[1]) if len(sys.argv)>1 else 1000
    h=scan(n)
    json.dump(h,open("core_hits.json","w"),indent=1)
    print("HITS",len(h))
