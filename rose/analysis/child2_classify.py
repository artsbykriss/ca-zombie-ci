#!/usr/bin/env python3
"""child2_classify.py - classify all significant holders: EOA vs contract, nonce, explorer name, owner."""
import json, time
import requests
S=requests.Session()
S.headers.update({"User-Agent":"rose-holder-map/1.0"})
RPC="https://mainnet.aurora.dev"; EXP="https://explorer.aurora.dev"

def rpc(method,params,tries=5,timeout=60):
    for i in range(tries):
        try:
            r=S.post(RPC,json={"jsonrpc":"2.0","id":1,"method":method,"params":params},timeout=timeout)
            j=r.json()
            if "error" in j: return {"ERR":j["error"]}
            return j.get("result")
        except Exception:
            time.sleep(1+i)
    return {"ERR":"timeout"}

def batch(calls,chunk=40):
    out=[]
    for i in range(0,len(calls),chunk):
        part=calls[i:i+chunk]
        payload=[{"jsonrpc":"2.0","id":k,"method":m,"params":p} for k,(m,p) in enumerate(part)]
        for a in range(5):
            try:
                r=S.post(RPC,json=payload,timeout=120)
                by={x["id"]:x for x in r.json()}
                for k in range(len(part)):
                    x=by.get(k,{}); out.append(x.get("result",{"ERR":x.get("error")}))
                break
            except Exception:
                if a==4: raise
                time.sleep(1+a)
    return out

KNOWN={
 "0xc90db0d8713414d78523436dc347419164544a3f":"3pool",
 "0x8fe44f5cce02d5be44e3446bbc2e8132958d22b8":"metaUST pool",
 "0xa34315f1ef49392387dd143f4578083a9bd33e94":"metaFRAX pool",
 "0x65a761136815b45a9d78d9781d22d47247b49d23":"metaMAI pool",
 "0x79b0a67a4045a7a8dc04b17456f4fe15339cba34":"RUSD pool",
 "0xee793001ce9fa988712b15a59ccf5dc7d54b22ff":"VASE (BentoBox)",
 "0xe23d2289fbca7de725dc21a13fc096787a85e16f":"stROSE vault",
 "0x64c922e3824ab40cbbedd6c8092d148c283d3d3d":"Garden clone 0x64C9",
 "0xfbaf3ebf228eb712b1267285787e51add70086bb":"Garden clone 0xfbAF",
 "0x0f44fcd177098cb2b063b50f6c62e4f1e1f9d596":"Garden clone 0x0F44",
 "0x084355fdd5fcfd55d60c5b8626756a6906576f13":"Garden clone 0x0843",
 "0xe8f7f08d50e12145cb722cff861e6a9b43eadba1":"Garden clone 0xe8F7",
 "0xf042f2dabba35f83eb126116f7ff8dadfc631e97":"Fee receiver PaymentSplitter",
 "0xff79d5bff48e1c01b722560d6ffdfce9fc883587":"3pool LP token",
 "0x857050ef3a0241a2c1f65ca1f0c100a04e4aed93":"Kashi master contract",
 "0x6adf17424f6e68733c71209471da50e155b5c5b2":"pools owner EOA",
 "0x0e2a05ca5d1e218034f2b7deb6e9419159839f8b":"VASE owner",
 "0x19cc40283b057d6608c22f1d20f17e16c245642e":"RUSD token",
}

def classify(addrs):
    res={}
    calls=[]
    for a in addrs:
        calls.append(("eth_getCode",[a,"latest"]))
        calls.append(("eth_getTransactionCount",[a,"latest"]))
    out=batch(calls)
    for i,a in enumerate(addrs):
        code=out[2*i]; nonce=int(out[2*i+1],16) if isinstance(out[2*i+1],str) else None
        res[a]={"codeLen":len(code)-2 if isinstance(code,str) and code.startswith("0x") else None,"nonce":nonce,"isContract":(len(code)-2>0) if isinstance(code,str) and code.startswith("0x") else None}
    # owner checks for contracts
    ocalls=[]; oaddrs=[]
    for a,v in res.items():
        if v["isContract"]:
            ocalls.append(("eth_call",[{"to":a,"data":"0x8da5cb5b"},"latest"])); oaddrs.append(a)
    ores=batch(ocalls) if ocalls else []
    for a,r in zip(oaddrs,ores):
        if isinstance(r,str) and r.startswith("0x") and len(r)>=66 and int(r,16)!=0:
            res[a]["owner"]="0x"+r[-40:]
    # explorer names
    for a,v in res.items():
        try:
            r=S.get(f"{EXP}/api/v2/addresses/{a}",timeout=30)
            j=r.json()
            v["name"]=j.get("name"); v["is_contract_explorer"]=j.get("is_contract")
            v["public_tags"]=j.get("public_tags"); v["proxy_type"]=j.get("proxy_type")
            v["implementations"]=j.get("implementations")
        except Exception as ex:
            v["explorer_err"]=repr(ex)
        time.sleep(0.15)
    return res

def main():
    raw=json.load(open("/home/heisenberg/CA/rose/analysis/child2_holders_raw.json"))
    vase=json.load(open("/home/heisenberg/CA/rose/analysis/child2_vase_full.json"))
    fees=json.load(open("/home/heisenberg/CA/rose/analysis/child2_fees.json"))
    addrs=set()
    for sym,t in raw["lp"].items():
        for v in t["top"][:15]: addrs.add(v["addr"])
    for v in raw["stRose"]["top"][:15]: addrs.add(v["addr"])
    for v in raw["rose"]["top"][:40]: addrs.add(v["addr"])
    for sym,t in vase["tokens"].items():
        for v in t["top"]: addrs.add(v["addr"])
    for p in fees["splitter"]["payees_raw"]:
        if p.get("payee"): addrs.add(p["payee"])
    addrs={a.lower() for a in addrs}
    print("classifying",len(addrs),"addresses")
    res=classify(sorted(addrs))
    for a,v in res.items():
        v["known"]=KNOWN.get(a)
    json.dump(res,open("/home/heisenberg/CA/rose/analysis/child2_classified.json","w"),indent=1)
    nEOA=sum(1 for v in res.values() if v["isContract"] is False)
    nC=sum(1 for v in res.values() if v["isContract"] is True)
    print("EOAs",nEOA,"contracts",nC)
    for a,v in res.items():
        if v["isContract"]:
            print(" C",a,v.get("name"),"nonce",v["nonce"],"codeLen",v["codeLen"],"owner",v.get("owner"),"known",v.get("known"))
    print("---- EOAs with nonce 0 (dead-looking) ----")
    for a,v in res.items():
        if v["isContract"] is False and v["nonce"]==0:
            print(" E",a,v.get("name"))

if __name__=="__main__":
    main()
