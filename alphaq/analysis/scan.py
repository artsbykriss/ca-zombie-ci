import json,sys,time,collections
from rpc import call,batch
from b58 import b58dec
PID="ALPHAQmeA7bjrVuccPsYPiCvsi428SNwte66Srvs4pHA"
def fullkeys(tx):
    m=tx["transaction"]["message"]; k=list(m["accountKeys"])
    la=tx["meta"].get("loadedAddresses") or {}
    k+=list(la.get("writable") or []); k+=list(la.get("readonly") or [])
    return k
def aq_ixs(tx):
    keys=fullkeys(tx); out=[]
    for i,ix in enumerate(tx["transaction"]["message"]["instructions"]):
        if keys[ix["programIdIndex"]]==PID: out.append(("top",i,ix,keys))
    for g in tx["meta"].get("innerInstructions") or []:
        for ix in g["instructions"]:
            if ix["programIdIndex"]<len(keys) and keys[ix["programIdIndex"]]==PID:
                out.append((f"inner{g['index']}",None,ix,keys))
    return out
def scan(n=1000, out="scan_result.json"):
    sigs=call("getSignaturesForAddress",[PID,{"limit":min(1000,n)}])
    hist=collections.Counter(); samples={}
    txs_ok=0
    for i,s in enumerate(sigs):
        try:
            tx=call("getTransaction",[s["signature"],{"encoding":"json","maxSupportedTransactionVersion":1}],retries=4)
        except Exception as e:
            continue
        if not tx: continue
        txs_ok+=1
        for kind,idx,ix,keys in aq_ixs(tx):
            raw=b58dec(ix["data"]); key=(raw[0] if raw else -1,len(raw))
            hist[key]+=1
            if key not in samples:
                samples[key]={"sig":s["signature"],"slot":tx["slot"],"kind":kind,
                    "data":raw.hex(),"accounts":[keys[a] for a in ix["accounts"]],
                    "err":tx["meta"]["err"]}
        if i%100==99: print("...",i+1,"txs, hist",dict(hist),flush=True)
    res={"program":PID,"n_sigs":len(sigs),"n_txs":txs_ok,"hist":{f"{k[0]}:{k[1]}":v for k,v in hist.items()},"samples":samples}
    json.dump(res,open(out,"w"),indent=1)
    return res
if __name__=="__main__":
    n=int(sys.argv[1]) if len(sys.argv)>1 else 300
    out=sys.argv[2] if len(sys.argv)>2 else "scan_result.json"
    r=scan(n,out)
    print("hist",r["hist"])
    print("tag17 samples:", [k for k in r["samples"] if k.startswith("17:")])
