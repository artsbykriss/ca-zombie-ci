import sys, json, hashlib, time
sys.path.insert(0,'.')
from rpc import call
from b58 import b58dec
PID="iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop"
NAMES = ["autorize","add_to_whitelist_by_auth","whitelist","update_price","sell","withdraw",
         "deposit","mint_gold","burn_gold","init_integrator","update_integrator_fees",
         "close_integrator","withdraw_from_integrator","update_integrator_market_override",
         "init_integrator_v2","update_integrator_v2_fees","close_integrator_v2",
         "withdraw_from_integrator_v2","update_integrator_v2_market_overrides"]
D={hashlib.sha256(("global:"+n).encode()).digest()[:8]:n for n in NAMES}
def fullkeys(tx):
    m=tx["transaction"]["message"]; k=[x["pubkey"] for x in m["accountKeys"]]
    la=tx["meta"].get("loadedAddresses") or {}
    k+= list(la.get("writable") or []); k+= list(la.get("readonly") or [])
    return k
def accts(ix,keys):
    if "accounts" in ix: return ix["accounts"]
    out=[]
    for a in ix.get("accountKeyIndexes") or []:
        out.append(keys[a] if a<len(keys) else "?")
    return out
def run(n=25):
    sigs=call("getSignaturesForAddress",[PID,{"limit":n}])
    res=[]
    for s in sigs:
        if s.get("err"): continue
        try:
            tx=call("getTransaction",[s["signature"],{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}])
        except Exception as e:
            time.sleep(1); continue
        if not tx: continue
        keys=fullkeys(tx)
        ixs=[]
        for ix in tx["transaction"]["message"]["instructions"]:
            ixs.append((ix.get("programId"), ix))
        for g in tx["meta"].get("innerInstructions") or []:
            for ix in g["instructions"]:
                ixs.append((ix.get("programId"), ix))
        for prog,ix in ixs:
            if prog!=PID: continue
            d=ix.get("data")
            raw=b58dec(d)[:8] if d else b""
            nm=D.get(raw, raw.hex() if raw else "empty")
            res.append({"sig":s["signature"],"slot":s["slot"],"ix":nm,
                        "data":d,
                        "accts":accts(ix,keys)})
    print(json.dumps(res,indent=1))
if __name__=="__main__":
    run(int(sys.argv[1]) if len(sys.argv)>1 else 25)
