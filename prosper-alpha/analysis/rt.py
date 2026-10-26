import json,urllib.request
R="https://rpc.pharos.xyz"
def batch(reqs):
    r=urllib.request.Request(R,data=json.dumps(reqs).encode(),headers={"content-type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=60))
M="0x39630b3c2874276cd664823c44ab23aa69dde80a"
def enc(x): return hex(x)[2:].rjust(64,"0")
def dec(h):
    h=h[2:]; return [int(h[j:j+64],16) for j in range(0,len(h),64)]
xs=[10**12,10**15,10**17,10**18,10**19]
reqs=[]
for x in xs:
    reqs.append({"jsonrpc":"2.0","id":len(reqs),"method":"eth_call","params":[{"to":M,"data":"0x4beb394c"+enc(x)},"latest"]})
res={r["id"]:r.get("result") for r in batch(reqs)}
outs=[dec(res[i])[3] for i in range(len(xs))]
reqs=[]
for p in outs:
    reqs.append({"jsonrpc":"2.0","id":len(reqs),"method":"eth_call","params":[{"to":M,"data":"0xa64190c4"+enc(p)},"latest"]})
res2={r["id"]:r.get("result") for r in batch(reqs)}
for i,x in enumerate(xs):
    pout=outs[i]; back=dec(res2[i])[2]
    print(f"in={x} pOut={pout} netBack={back} delta={back-x} ({100*(back-x)/x:.4f}%)")
