#!/usr/bin/env python3
import json,urllib.request,base64,sys
RPC="https://api.mainnet-beta.solana.com"
def rpc(method,params):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=90))
def b58enc(b):
    A="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n=int.from_bytes(b,'big'); s=""
    while n: n,r=divmod(n,58); s=A[r]+s
    return '1'*(len(b)-len(b.lstrip(b'\x00')))+(s or '1')
def dump(prog,out):
    r=rpc("getAccountInfo",[prog,{"encoding":"base64"}]); v=r["result"]["value"]
    d=base64.b64decode(v["data"][0])
    if v["owner"]=="BPFLoaderUpgradeab1e11111111111111111111111" and len(d)==36:
        pd=b58enc(d[4:36])
        r2=rpc("getAccountInfo",[pd,{"encoding":"base64"}]); d2=base64.b64decode(r2["result"]["value"]["data"][0])
        auth=b58enc(d2[13:45]); slot=int.from_bytes(d2[4:12],'little'); elf=d2[45:]
        print(f"{prog} -> pd={pd} auth={auth} slot={slot} elf={len(elf)}")
        open(out,"wb").write(elf)
    else:
        print("not upgradeable?",v["owner"],len(d))
for p,o in [("5g3PW7gtfnM3QYsGPaPGLiCxtous4arSugCct9KPHHWo","cardboard_oracle.so")]:
    dump(p,o)
