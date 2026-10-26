import json,urllib.request
R="https://rpc.pharos.xyz"
WPROS="0x52c48d4213107b20bc583832b0d951fb9ca8f0b0"
TIMELOCK="0x152ecca16f86faa5d1fc2ed0a1b2baf5aacd794b"
PRICE=0.633288
def batch(reqs):
    r=urllib.request.Request(R,data=json.dumps(reqs).encode(),headers={"content-type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=60))
d=json.load(open("vaults_api.json"))["data"]["list"]
# market WPROS from API realWrappedNativeReserve
tot0=tot3=0; n0=n3=0
for v in d:
    r=v["runtime"]; p=r["phase"]; res=int(r["realWrappedNativeReserve"])
    if p==0: tot0+=res; n0+=1
    elif p==3: tot3+=res; n3+=1
print("phase0 markets",n0,"WPROS",tot0/1e18)
print("phase3 markets",n3,"WPROS",tot3/1e18)
print("total in-curve WPROS",(tot0+tot3)/1e18, "USD", (tot0+tot3)/1e18*PRICE)
# graduated pools
grads=[v for v in d if v["runtime"]["phase"]==2]
reqs=[];keys=[]
for v in grads:
    pair=v["runtime"]["externalPair"]; pt=v["pToken"]
    for name,sel,args in [("t0","0x0dfe1681",""),("t1","0xd21220a7",""),
                          ("res","0x0902f1ac",""),
                          ("lpbal","0x70a08231","0"*24+TIMELOCK[2:]),
                          ("lpsup","0x18160ddd","")]:
        to = pair if name!="lpbal" and name!="lpsup" else pair
        reqs.append({"jsonrpc":"2.0","id":len(reqs),"method":"eth_call","params":[{"to":to,"data":sel+args},"latest"]})
        keys.append((pair,pt,v["pVaultSymbol"],name))
res={}
for i in range(0,len(reqs),10):
    for x in batch(reqs[i:i+10]):
        res[x["id"]]=x.get("result")
pools={}
for j,(pair,pt,sym,name) in enumerate(keys):
    r=res.get(j)
    pools.setdefault(pair,{"sym":sym,"pToken":pt})[name]=r
total=0
for pair,info in pools.items():
    t0="0x"+info["t0"][-40:]; t1="0x"+info["t1"][-40:]
    rr=info["res"][2:]; r0=int(rr[0:64],16); r1=int(rr[64:128],16)
    lp=int(info["lpbal"],16); sup=int(info["lpsup"],16)
    wp = r0 if t0.lower()==WPROS else (r1 if t1.lower()==WPROS else None)
    if wp is None: print("WARN no WPROS side",pair); continue
    share = wp*lp//sup if sup else 0
    total+=share
    print(f'{info["sym"]:7s} pair={pair} resWPROS={wp/1e18:14.3f} lp/sup={lp/sup if sup else 0:.4f} lockedWPROS={share/1e18:14.3f}')
print("TOTAL graduated WPROS in timelock:",total/1e18,"USD",total/1e18*PRICE)
print("GRAND TOTAL TVL (curve+graduated) WPROS",(tot0+tot3+total)/1e18,"USD",(tot0+tot3+total)/1e18*PRICE)
