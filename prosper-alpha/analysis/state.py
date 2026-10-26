import json,urllib.request,sys
R="https://rpc.pharos.xyz"
def batch(reqs):
    data=json.dumps(reqs).encode()
    r=urllib.request.Request(R,data=data,headers={"content-type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=60))
def call(to,sel):
    return {"to":to,"data":sel}
SEL={"externalPair":"0x1c5eac33","pToken":"0x58a06f07","curveK":"0x19b80ee7","phase":"0xb1c9fe6e","startedAt":"0xf21f537d","endsAt":"0x0a09284a","migrationEscrow":"0x54e9d781","curatorFeeRecipient":"0x2bbd63d9","wrappedNative":"0xeb6d3a11","accessController":"0xbc43cbaf","globalConfig":"0xa7c1abe0"}
WPROS="0x52c48d4213107b20bc583832b0d951fb9ca8f0b0"
markets=["0xf08ff5a4b073019643e399647ad0f36a0ee7f132","0x21e1c2dd76cf9c3223dc38fe53bb63b4f1234d8a","0x1fc917f395c29676eab585a977d90eed2e612f57","0xfb7ca7dda333fb2f8c67a12b30b5b2587d86ca09","0xc204be06141bbbcced26fd0719b8feae131b3e17","0xcfdf761f111ea6679a1e3a23d2e718d317e936cb","0x1f11a4e9386893ad793f318e440f563d6c0b7ce2","0x87a087c37974ae725da1a8303d91343af488aa9e"]
reqs=[]; keys=[]
for m in markets:
    for name,s in SEL.items():
        reqs.append({"jsonrpc":"2.0","id":len(reqs),"method":"eth_call","params":[call(m,s),"latest"]}); keys.append((m,name))
    reqs.append({"jsonrpc":"2.0","id":len(reqs),"method":"eth_call","params":[call(WPROS,"0x70a08231"+"0"*24+m[2:]),"latest"]}); keys.append((m,"wpros_balance"))
    reqs.append({"jsonrpc":"2.0","id":len(reqs),"method":"eth_getBalance","params":[m,"latest"]}); keys.append((m,"native_balance"))
out={}
# batch in chunks of 10
for i in range(0,len(reqs),10):
    chunk=reqs[i:i+10]
    res=batch(chunk)
    res={r["id"]:r.get("result") for r in res}
    for j in range(i,i+len(chunk)):
        m,name=keys[j]; r=res.get(j)
        if r is None: v=None
        elif r=="0x": v=None
        elif name in ("wpros_balance","native_balance","curveK","phase","startedAt","endsAt"): v=int(r,16)
        else: v="0x"+r[-40:]
        out.setdefault(m,{"market":m})[name]=v
print(json.dumps(out,indent=1))
