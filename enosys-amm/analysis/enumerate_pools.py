#!/usr/bin/env python3
"""Enumerate Enosys V3 factory pools and snapshot live state. Read-only."""
import json, time, urllib.request, sys
import rpc

FACT = {14: "0x17aa157ac8c54034381b840cb8f6bf7fc355f0de",
        19: "0x416f1ccbc55033ae0133da96f9096fe8c2c17e7d"}
SEL = {"poolsCount":"0x8c788de0","pools":"0xac4afa38","token0":"0x0dfe1681","token1":"0xd21220a7",
       "fee":"0xddca3f43","tickSpacing":"0xd0c93a7c","slot0":"0x3850c7bd","liquidity":"0x1a686502",
       "protocolFees":"0x1ad8b03b","balanceOf":"0x70a08231","decimals":"0x313ce567","symbol":"0x95d89b41",
       "factory":"0xc45a0155","feeGrowthGlobal0X128":"0xf3058399","feeGrowthGlobal1X128":"0x46141319"}

def dec_addr(r): return "0x"+r[-40:] if r and len(r)>=42 else r

def batch_call(chain, calls):
    """calls: list of (to,data). Returns list of hex results or None on revert."""
    payload=[]
    for i,(to,data) in enumerate(calls):
        payload.append({"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":to,"data":data},"latest"]})
    # try endpoints in order
    for url in rpc.RPCS[chain]:
        try:
            req=urllib.request.Request(url,data=json.dumps(payload).encode(),
                headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0 research"})
            with urllib.request.urlopen(req,timeout=60) as f:
                out=json.loads(f.read().decode())
            res=[None]*len(calls)
            for item in out:
                if "result" in item: res[item["id"]]=item["result"]
            return res
        except Exception as e:
            last=e
    raise RuntimeError(str(last))

def main():
    allout={"read_at_utc":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()),"chains":{}}
    for chain in (14,19):
        blk=rpc.block(chain)
        n=int(rpc.call(chain,FACT[chain],SEL["poolsCount"]),16)
        # first get pool addresses
        pools=[]
        for start in range(0,n,20):
            calls=[(FACT[chain],SEL["pools"]+f"{i:064x}") for i in range(start,min(start+20,n))]
            res=batch_call(chain,calls)
            pools += [dec_addr(r) for r in res if r]
        print(chain,"block",blk,"pools",len(pools),flush=True)
        info={}
        # per pool: token0, token1, fee, tickSpacing, slot0, liquidity, protocolFees, balances
        for start in range(0,len(pools),8):
            chunk=pools[start:start+8]
            calls=[]
            for p in chunk:
                calls += [(p,SEL["token0"]),(p,SEL["token1"]),(p,SEL["fee"]),(p,SEL["tickSpacing"]),
                          (p,SEL["slot0"]),(p,SEL["liquidity"]),(p,SEL["protocolFees"])]
            res=batch_call(chain,calls)
            for j,p in enumerate(chunk):
                r=res[j*7:(j+1)*7]
                if not r[0] or not r[1]: continue
                info[p]={"token0":dec_addr(r[0]),"token1":dec_addr(r[1]),
                         "fee":int(r[2],16),"tickSpacing":int(r[3],16),
                         "slot0_raw":r[4],"liquidity":int(r[5],16),
                         "protocolFees0":int(r[6],16) if r[6] and r[6]!="0x" else None,
                         "protocolFees1":int(r[6][66:],16) if r[6] and len(r[6])>130 else None}
            print("  ",chain,start,"/",len(pools),flush=True)
        # balances for all tokens
        tokens=set()
        for p,d in info.items(): tokens.add(d["token0"]); tokens.add(d["token1"])
        meta={}
        toks=sorted(tokens)
        for start in range(0,len(toks),10):
            chunk=toks[start:start+10]
            calls=[]
            for t in chunk:
                calls += [(t,SEL["decimals"]),(t,SEL["symbol"])]
            res=batch_call(chain,calls)
            for j,t in enumerate(chunk):
                d=res[j*2]; s=res[j*2+1]
                try:
                    dec=int(d,16)
                except: dec=None
                sym=None
                if s and len(s)>130:
                    try:
                        ln=int(s[66:130],16); sym=bytes.fromhex(s[130:130+ln*2]).decode(errors="replace")
                    except: pass
                meta[t]={"decimals":dec,"symbol":sym}
        for start in range(0,len(pools),10):
            chunk=pools[start:start+10]
            calls=[]
            for p in chunk:
                if p not in info: continue
                calls += [(info[p]["token0"],SEL["balanceOf"]+"0"*24+p[2:]),(info[p]["token1"],SEL["balanceOf"]+"0"*24+p[2:])]
            res=batch_call(chain,calls)
            k=0
            for p in chunk:
                if p not in info: continue
                info[p]["bal0"]=int(res[k],16) if res[k] and res[k]!="0x" else None
                info[p]["bal1"]=int(res[k+1],16) if res[k+1] and res[k+1]!="0x" else None
                k+=2
        allout["chains"][str(chain)]={"block":blk,"factory":FACT[chain],"pools_count":n,
                                       "tokens":meta,"pools":info}
        print(" done",chain,flush=True)
    open("pools_live.json","w").write(json.dumps(allout,indent=1))
    print("saved pools_live.json")

if __name__=="__main__":
    main()
