#!/usr/bin/env python3
"""Fetch verified source/ABI for tokens via Routescan and detect mintability + owner."""
import json, urllib.request, time, sys

UA={"User-Agent":"Mozilla/5.0 research"}
def get(url):
    return json.loads(urllib.request.urlopen(urllib.request.Request(url,headers=UA),timeout=60).read())

def src(chain, addr):
    url=f"https://api.routescan.io/v2/network/mainnet/evm/{chain}/etherscan/api?module=contract&action=getsourcecode&address={addr}"
    try:
        d=get(url)
    except Exception as e:
        return {"error":str(e)}
    if not d.get("result") or not d["result"]:
        return {"error":"noresult","raw":d}
    r=d["result"][0]
    return {"name":r.get("ContractName"),"verified":bool(r.get("SourceCode")),"abi":r.get("ABI"),"compiler":r.get("CompilerVersion"),"proxy":r.get("Proxy"),"impl":r.get("Implementation")}

def rpc(url,method,params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req=urllib.request.Request(url,data=body,headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.loads(urllib.request.urlopen(req,timeout=60).read()).get("result")

def main():
    avax_rpc="https://avalanche-c-chain-rpc.publicnode.com"
    d=json.load(open('/home/heisenberg/CA/moats/analysis/childA/enum-all.json'))
    toks=set(m['stakingToken'] for m in d['chains']['avax']['moats'])
    # robinhood staking tokens
    rh_toks=["0x3f74555B87cFCbfC60B3FDbe020b1FC51a84161a","0xe8fB470E0685437d7739BD2AacBA60b228800335","0x2B1C6953Ca01A5D098d2E22Ab606467b15E5f9f0","0x50832d74a7160E2f7d361F5E678E107D228B9Aa6","0xf01DB9250B636caa52aa9516F2492b2985aE2C2F"]
    out={}
    for t in sorted(toks):
        s=src(43114,t)
        mint=[]
        owner=None
        try:
            abi=json.loads(s.get("abi") or "[]")
            for e in abi:
                if e.get("type")=="function" and "mint" in e.get("name","").lower():
                    mint.append({"name":e["name"],"state":e.get("stateMutability"),"inputs":[i.get("type") for i in e.get("inputs",[])]})
        except Exception:
            abi=[]
        # owner()
        try:
            o=rpc(avax_rpc,"eth_call",[{"to":t,"data":"0x8da5cb5b"},"latest"])
            owner=("0x"+o[-40:]) if o and o!="0x" else None
        except Exception: pass
        out[t]={"src":{k:s.get(k) for k in ("name","verified","compiler","proxy","impl","error")},"mint":mint,"owner":owner}
        print(t, out[t]["src"].get("name"), "verified",out[t]["src"].get("verified"), "mint",mint, "owner",owner, file=sys.stderr)
        time.sleep(0.3)
    json.dump(out,open('/home/heisenberg/CA/moats/analysis/childA/staking-tokens-avax.json','w'),indent=1)

if __name__=="__main__": main()
