#!/usr/bin/env python3
"""probe selectors: eth_call with from, print OK/revert reason, gas used via debug trace optional"""
import json,os,sys,urllib.request
URL=os.environ[sys.argv[1]]
TO=sys.argv[2]; FROM=sys.argv[3] if len(sys.argv)>3 else "0x1111111111111111111111111111111111111111"
sels=sys.argv[4:]
def post(payload):
    req=urllib.request.Request(URL,data=json.dumps(payload).encode(),headers={"content-type":"application/json","user-agent":"research/1.0"})
    return json.load(urllib.request.urlopen(req,timeout=40))
for s in sels:
    data=s if s.startswith("0x") else "0x"+s
    r=post({"jsonrpc":"2.0","id":1,"method":"debug_traceCall","params":[{"to":TO,"data":data,"from":FROM,"gas":"0x1c9c380"},"latest",{"tracer":"callTracer"}]})
    res=r.get("result") or {}
    out=res.get("output","")
    err=res.get("error")
    reason=None
    if out and out[:10]=="0x08c379a0":
        try:
            b=out[2:]; ln=int(b[8+64:8+128],16); reason=bytes.fromhex(b[8+128:8+128+ln*2]).decode()
        except Exception: pass
    print(f"{data[:10]:12s} err={str(err)[:60]:60s} gas={res.get('gasUsed')} out={out[:80]} reason={reason} calls={len(res.get('calls',[])) if isinstance(res.get('calls'),list) else 0}")
