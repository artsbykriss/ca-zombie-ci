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
        except Exception: time.sleep(0.5+a)
    return {"error":"fail"}
def w(x): return f"{x:064x}"
def tc(sel,words,frm,value="0x0"):
    d=rpc("eth_call",[{"from":frm,"to":A,"data":"0x"+sel+"".join(words),"value":value},"latest"])
    if "result" in d: return "OK:"+d["result"][:100]
    e=d.get("error",{}); return "REVERT:"+str(e.get("data") or e.get("message"))[:100]

sels=["f35ca728","d1e57635","9e1941ca","a3f8ea7c","43308267","9a462d4a","f9125e2c"]
shapes={
 "4w(bank,0,0,stranger)":[w(int(BANK,16)),w(0),w(0),w(int(STRANGER,16))],
 "4w(stranger,0,0,stranger)":[w(int(STRANGER,16)),w(0),w(0),w(int(STRANGER,16))],
 "4w(bank,1,1,stranger)":[w(int(BANK,16)),w(1),w(1),w(int(STRANGER,16))],
 "4w(stranger,1,1,stranger)":[w(int(STRANGER,16)),w(1),w(1),w(int(STRANGER,16))],
 "4w(0,0,0,0)":[w(0),w(0),w(0),w(0)],
 "5w(bank,1,1,stranger,0)":[w(int(BANK,16)),w(1),w(1),w(int(STRANGER,16)),w(0)],
}
for sel in sels:
    print("==",sel)
    for nm,ws in shapes.items():
        print(f"  {nm:30s} val0 stranger={tc(sel,ws,STRANGER):22s} | val1e18 stranger={tc(sel,ws,STRANGER,'0xde0b6b3a7640000'):22s} | val1e18 bank={tc(sel,ws,BANK,'0xde0b6b3a7640000')}")
