#!/usr/bin/env python3
import json, urllib.request, time
RPC="https://bsc-rpc.publicnode.com"
A="0x16ceff8d5a4c8648fcc7293f8bd3ac9ada454219"
BANK="0x7817dbf38e9d1c95671625f0052c147864692fe0"
STRANGER="0x7a3f000000000000000000000000000000009f01"
def rpc(method,params):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    for a in range(4):
        try:
            req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"z"})
            with urllib.request.urlopen(req,timeout=25) as r: return json.load(r)
        except Exception as e: time.sleep(0.5+a)
    return {"error":"fail"}
def w(x): return f"{x:064x}"
def calldata(sel, words): return "0x"+sel+ "".join(words)
def try_call(sel, words, frm):
    d=rpc("eth_call",[{"from":frm,"to":A,"data":calldata(sel,words)}, "latest"])
    if "result" in d: return "OK:"+d["result"][:80]
    e=d.get("error",{})
    return "REVERT:"+str(e.get("data") or e.get("message"))[:80]

wordsets={
 "0args":[],
 "1addr(bank)":[w(int(BANK,16))],
 "4w(addr,0,0,0)":[w(int(BANK,16)),w(0),w(0),w(0)],
 "4w(addr,1e18,1e18,stranger)":[w(int(BANK,16)),w(10**18),w(10**18),w(int(STRANGER,16))],
 "3w(addr,u,addr)":[w(int(BANK,16)),w(0),w(int(BANK,16))],
}
for sel in ["f35ca728","d1e57635","9e1941ca","a3f8ea7c","43308267","9a462d4a","f9125e2c","authorize" if False else "b6a5d7de"]:
    print("== selector",sel)
    for name,ws in wordsets.items():
        s=try_call(sel,ws,STRANGER); b=try_call(sel,ws,BANK)
        print(f"   {name:26s} stranger={s:28s} bank={b}")
