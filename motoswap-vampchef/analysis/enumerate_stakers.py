#!/usr/bin/env python3
"""Enumerate MotoStaking stakers from Blockscout logs; sum positions + unclaimed tickets."""
import json, urllib.request, urllib.parse, time

BASE="https://eth.blockscout.com/api/v2/addresses/0xCE88F2C6B49EfBb92555eE5475311f0e250C2528/logs"
RPC="https://ethereum-rpc.publicnode.com"
accounts=set(); pages=0; url=BASE
while url and pages<40:
    req=urllib.request.Request(url,headers={"User-Agent":"research/1.0"})
    with urllib.request.urlopen(req,timeout=60) as r: j=json.load(r)
    for it in j.get("items",[]):
        dec=it.get("decoded") or {}
        mc=dec.get("method_call","")
        if any(x in mc for x in ["Staked(","Appended(","Imported(","UnstakeRequested("]):
            for p in dec.get("parameters",[]):
                if p.get("name") in ("account","user") and p.get("indexed"):
                    accounts.add(p["value"])
    np=j.get("next_page_params")
    pages+=1
    if not np: break
    url=BASE+"?"+urllib.parse.urlencode(np)
    print("page",pages,"accounts",len(accounts),flush=True)

print("unique accounts",len(accounts))
SEL_POS="0x55f57510"; SEL_UNST="0x685abbe6"
def batch(calls):
    payload=[{"jsonrpc":"2.0","id":i,"method":"eth_call","params":[{"to":t,"data":d},"latest"]} for i,(t,d) in enumerate(calls)]
    out=[]
    for s in range(0,len(payload),20):
        for a in range(4):
            try:
                req=urllib.request.Request(RPC,data=json.dumps(payload[s:s+20]).encode(),headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
                with urllib.request.urlopen(req,timeout=90) as r: j=json.load(r)
                by={x['id']:x for x in j}
                out += [by.get(i,{}).get('result','0x') for i in range(s,min(s+20,len(payload)))]
                break
            except Exception as e:
                print('retry',a,e,flush=True); time.sleep(2)
        else:
            out += ['0x']*len(payload[s:s+20])
    return out
addrs=sorted(accounts)
calls=[]
for a in addrs:
    calls.append(("0xCE88F2C6B49EfBb92555eE5475311f0e250C2528",SEL_POS+"%064x"%int(a,16)))
    calls.append(("0xCE88F2C6B49EfBb92555eE5475311f0e250C2528",SEL_UNST+"%064x"%int(a,16)))
res=batch(calls)
raw=0; unclaimed=0; rows=[]
for i,a in enumerate(addrs):
    p=res[2*i]; u=res[2*i+1]
    amt=int(p[2:66],16) if p and p!='0x' and len(p)>=66 else 0
    ticket=int(u,16) if u and u!='0x' else 0
    raw+=amt; unclaimed+=ticket
    rows.append({"account":a,"position_amount":amt,"claimable_unstaked":ticket})
print("sum position amount",raw, raw/1e18)
print("sum claimable unstaked",unclaimed, unclaimed/1e18)
print("sum both",(raw+unclaimed)/1e18)
json.dump({"accounts":len(addrs),"sum_position":raw,"sum_claimable_unstaked":unclaimed,"rows":rows},open('/home/heisenberg/CA/motoswap-vampchef/analysis/stakers_positions.json','w'),indent=1)
