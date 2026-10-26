import sys, json, hashlib, time
sys.path.insert(0,'.')
from rpc import call, batch
from b58 import b58dec
PID="iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop"
def fullkeys(tx):
    m=tx["transaction"]["message"]; k=[x["pubkey"] for x in m["accountKeys"]]
    la=tx["meta"].get("loadedAddresses") or {}
    k+= list(la.get("writable") or []); k+= list(la.get("readonly") or [])
    return k
def scan(n=1000, start=None):
    opts={"limit":min(n,1000)}
    if start: opts["before"]=start
    sigs=call("getSignaturesForAddress",[PID,opts])
    print("sigs",len(sigs),"slots",sigs[0]["slot"],"->",sigs[-1]["slot"],file=sys.stderr)
    hits=[]
    # batch getTransaction
    for i in range(0,len(sigs),20):
        chunk=sigs[i:i+20]
        reqs=[{"jsonrpc":"2.0","id":j,"method":"getTransaction","params":[s["signature"],{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}]} for j,s in enumerate(chunk)]
        try:
            r=batch(reqs)
        except Exception as e:
            print("batch err",e,file=sys.stderr); time.sleep(2); continue
        if isinstance(r,dict): r=[r]
        byid={x.get("id"):x.get("result") for x in r}
        for j,s in enumerate(chunk):
            tx=byid.get(j)
            if not tx: continue
            keys=fullkeys(tx)
            logs=(tx["meta"].get("logMessages") or [])
            insts=[l for l in logs if "Instruction:" in l and PID[:8] in l or l.startswith("Program log: Instruction:")]
            # detect PID invocation
            involved=False
            for ix in tx["transaction"]["message"]["instructions"]:
                if ix.get("programId")==PID: involved=True
            for g in tx["meta"].get("innerInstructions") or []:
                for ix in g["instructions"]:
                    if ix.get("programId")==PID: involved=True
            if involved:
                hits.append({"sig":s["signature"],"slot":s["slot"],
                             "logs":[l for l in logs if "Instruction:" in l],
                             "keys":keys})
        time.sleep(0.15)
    return hits
if __name__=="__main__":
    n=int(sys.argv[1]) if len(sys.argv)>1 else 1000
    h=scan(n)
    print(json.dumps(h,indent=1)[:20000])
    print("HITS",len(h),file=sys.stderr)
