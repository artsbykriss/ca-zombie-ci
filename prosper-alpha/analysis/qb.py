import json,urllib.request
R="https://rpc.pharos.xyz"
def batch(reqs):
    r=urllib.request.Request(R,data=json.dumps(reqs).encode(),headers={"content-type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=60))
M="0x39630b3c2874276cd664823c44ab23aa69dde80a"  # pPika ActiveInner
QB="0x4beb394c"; QS="0xa64190c4"
def enc(x): return hex(x)[2:].rjust(64,"0")
reqs=[]
xs=[10**6,10**12,10**15,10**17,10**18,10**19,10**20,10**21,10**22]
for x in xs:
    reqs.append({"jsonrpc":"2.0","id":len(reqs),"method":"eth_call","params":[{"to":M,"data":QB+enc(x)},"latest"]})
    reqs.append({"jsonrpc":"2.0","id":len(reqs),"method":"eth_call","params":[{"to":M,"data":QS+enc(x)},"latest"]})
res=batch(reqs)
res={r["id"]:r.get("result") for r in res}
for i,x in enumerate(xs):
    b=res[2*i]; s=res[2*i+1]
    def dec(h):
        if not h or h=="0x": return None
        h=h[2:]; return [int(h[j:j+64],16) for j in range(0,len(h),64)]
    print("x=%d quoteBuy=%s quoteSell=%s"%(x,dec(b),dec(s)))
