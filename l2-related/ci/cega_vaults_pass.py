import json,subprocess,time
def cast(args,timeout=40):
    try:
        r=subprocess.run(["cast"]+args,capture_output=True,text=True,timeout=timeout)
        return r.stdout.strip()
    except Exception: return ""
def call(rpcs,to,sig,args=None,tries=5):
    for i in range(tries):
        rpc=rpcs[i%len(rpcs)]
        out=cast(["call",to,sig]+(args or [])+["--rpc-url",rpc])
        if out: return out
        time.sleep(1.0)
    return ""
GV="getVault(address)((uint128,uint64,uint16,uint16,uint32,address,uint40,uint8,uint8,bool,bool))"
out={}
for chain,rpcs,entry,vf in ((1,["https://ethereum-rpc.publicnode.com","https://eth.drpc.org","https://1rpc.io/eth"],"0x7a67D5Eb2D6684d3e899575aAAA5AB31b79890c2","analysis/cega-v2/vaults-1.json"),
                           (42161,["https://arb1.arbitrum.io/rpc","https://arbitrum-one-rpc.publicnode.com"],"0xFD62eEbAA64D2F33BbDb42e713Fba7E94EF2dA50","analysis/cega-v2/vaults-42161.json")):
    vaults=list(json.load(open(vf)).keys())
    recs={}
    for i,v in enumerate(vaults):
        ts=call(rpcs,v,"totalSupply()(uint256)")
        gv=call(rpcs,entry,GV,[v])
        rec={"ts_raw":ts,"gv_raw":gv}
        if gv.startswith("("):
            parts=[p.strip() for p in gv.strip("()").split(",")]
            try:
                rec["totalAssets"]=int(parts[0]); rec["vaultStatus"]=int(parts[7]); rec["productId"]=int(parts[4])
            except Exception: pass
        try: rec["totalSupply"]=int(ts.split()[0])
        except Exception: rec["totalSupply"]=None
        recs[v]=rec
        if i%15==0: print(chain,i,len(vaults),flush=True)
        time.sleep(0.15)
    out[str(chain)]=recs
    nz=[r for r in recs.values() if r.get("totalSupply")]
    print(chain,"nonzero supply:",len(nz),"of",len(vaults),flush=True)
json.dump(out,open("ci-out/cega-vaults.json","w"),indent=1)
for c,recs in out.items():
    nz=[r for r in recs.values() if r.get("totalSupply")]
    print(c,"vaults:",len(recs),"nonzero supply:",len(nz),"sum totalAssets:",sum(r.get("totalAssets",0) for r in recs.values()))
print("done")
