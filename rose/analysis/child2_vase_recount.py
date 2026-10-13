#!/usr/bin/env python3
"""child2_vase_recount.py - recount VASE shares from full log set (transfer+deposit+withdraw),
verify against balanceOf, save corrected child2_vase_full.json."""
import json, time
from collections import Counter, defaultdict
import requests
S=requests.Session()
RPC="https://mainnet.aurora.dev"
VASE="0xee793001ce9fa988712b15a59ccf5dc7d54b22ff"
LT="0x6eabe333476233fd382224f233210cb808a7bc4c4de64f9d76628bf63c677b1a"
LD="0xb2346165e782564f17f5b7e555c21f4fd96fbc93458572bf0113ea35a958fc55"
LW="0xad9ab9ee6953d4d177f4a03b3a3ac3178ffcb9816319f348060194aa76b14486"
DEC={"RUSD":18,"WBTC":8,"UST":18,"USDC":6,"USDT":6,"WNEAR":24,"WETH":18}

def pad(a): return a[2:].lower().rjust(64,"0")
def rpc_batch(calls,chunk=40):
    out=[]
    for i in range(0,len(calls),chunk):
        part=calls[i:i+chunk]
        payload=[{"jsonrpc":"2.0","id":k,"method":m,"params":p} for k,(m,p) in enumerate(part)]
        for attempt in range(6):
            try:
                r=S.post(RPC,json=payload,timeout=180)
                if r.status_code==429: time.sleep(2+attempt*2); continue
                by={x["id"]:x for x in r.json()}
                for k in range(len(part)):
                    x=by.get(k,{}); out.append(x.get("result",{"error":x.get("error")}))
                break
            except Exception:
                if attempt==5: raise
                time.sleep(1+attempt)
    return out

def main():
    raw=json.load(open("/tmp/opencode/vase_all_logs.json"))
    prev=json.load(open("/home/heisenberg/CA/rose/analysis/child2_vase_full.json"))
    blk=int(prev["block"])
    bytok=defaultdict(list)
    for lg in raw:
        t=lg["topics"]
        if t[0] in (LT,LD,LW):
            bytok["0x"+t[1][-40:]].append(lg)
    out={"block":blk,"vase":VASE,"tokens":{}}
    for sym,tok in prev["tokens"].items():
        elastic=int(tok["elastic"]); base=int(tok["base"])
        logs=bytok["0x"+tok["token"][2:].lower()]
        results={}
        for label,order in [("A",lambda t:(t[2][-40:],t[3][-40:])),("B",lambda t:(t[3][-40:],t[2][-40:]))]:
            shares=defaultdict(int)
            for lg in logs:
                t=lg["topics"]; sig=t[0]
                if sig==LT:
                    f,to=order(t); f="0x"+f.lower(); to="0x"+to.lower(); amt=int(lg["data"],16)
                    shares[f]-=amt; shares[to]+=amt
                elif sig==LD:
                    to="0x"+t[3][-40:].lower(); share=int(lg["data"][66:130],16)
                    shares[to]+=share
                elif sig==LW:
                    f="0x"+t[2][-40:].lower(); share=int(lg["data"][66:130],16)
                    shares[f]-=share
            results[label]=(shares,sum(shares.values()))
        best_label="A" if abs(results["A"][1]-base)<=abs(results["B"][1]-base) else "B"
        shares,best_tot=results[best_label]
        best={k:v for k,v in shares.items() if v>0}
        print(sym,"order",best_label,"sum",best_tot,"base",base,"match",best_tot==base)
        # reconcile EOA appearance
        eoa="0x3820feddeaba00564166e68a73babdae5740394f"
        print("   EOA shares recount:",best.get(eoa))
        top=sorted(best.items(),key=lambda kv:-kv[1])[:15]
        calls=[("eth_call",[{"to":VASE,"data":"0xf7888aec"+pad(tok["token"])+a[2:].rjust(64,"0")},"latest"]) for a,_ in top]
        res=rpc_batch(calls)
        ver=[]
        for (a,net),r in zip(top,res):
            oc=int(r,16) if isinstance(r,str) else None
            amt=net*elastic//base if base else net
            ver.append({"addr":a,"shares_recount":str(net),"balanceOf":str(oc) if oc is not None else None,
                        "match":oc==net if oc is not None else None,"amount_prop":str(amt)})
        nmatch=sum(1 for v in ver if v["match"])
        out["tokens"][sym]={"token":tok["token"],"decimals":DEC[sym],"elastic":str(elastic),"base":str(base),
            "sumSharesRecount":str(best_tot),"sumMatchBase":best_tot==base,"transferOrder":best_label,
            "logCounts":{"transfer":len([l for l in logs if l["topics"][0]==LT]),
                         "deposit":len([l for l in logs if l["topics"][0]==LD]),
                         "withdraw":len([l for l in logs if l["topics"][0]==LW])},
            "vaseTokenBalance":tok["vaseTokenBalance"],"excess":tok["excess"],
            "verifyMatched":f"{nmatch}/15","top":ver,
            "allShares":{k:str(v) for k,v in sorted(best.items(),key=lambda kv:-kv[1])}}
        # ensure EOA present
        eoa="0x3820feddeaba00564166e68a73babdae5740394f"
        if eoa not in best: print("  WARN EOA not in holders", sym)
    json.dump(out,open("/home/heisenberg/CA/rose/analysis/child2_vase_full.json","w"),indent=1)
    print("saved")

if __name__=="__main__":
    main()
