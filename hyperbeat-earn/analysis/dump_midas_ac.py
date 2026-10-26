#!/usr/bin/env python3
import json, urllib.request, sys, time, subprocess, hashlib
RPC="https://rpc.hyperliquid.xyz/evm"; BLK=int(sys.argv[1]) if len(sys.argv)>1 else 49508160
_id=0
def rpc(m,p):
    global _id; _id+=1
    body=json.dumps({"jsonrpc":"2.0","id":_id,"method":m,"params":p}).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"r/1"})
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=60) as r: d=json.loads(r.read())
            return d.get("result") if "error" not in d else {"__err__":d["error"]}
        except Exception as e:
            if a==3: return {"__exc__":str(e)}
            time.sleep(1.5)
def call(to,data): return rpc("eth_call",[{"to":to,"data":data},hex(BLK)])
def a(h): return "0x"+h[-40:] if isinstance(h,str) and len(h)>=42 else h
def u(h):
    try: return int(h,16)
    except: return h
def s4(s): return subprocess.run(["cast","sig",s],capture_output=True,text=True).stdout.strip()

TOKENS={"lstHYPE":"0x81e064d0eB539de7c3170EDF38C1A42CBd752A76","liquidHYPE":"0x441794D6a8F9A3739F5D4E98a728937b33489D29",
        "hbUSDT":"0x5e105266db42f78FA814322Bce7f388B4C2e61eb","hbUSDC":"0x057ced81348D57Aad579A672d521d7b4396E8a61",
        "dnHYPE":"0x949a7250Bb55Eb79BC6bCC97fCd1C473DB3e6F29","hbXAUt":"0x6EB6724D8D3D4FF9E24d872E8c38403169dC05f8"}
SEL_AC=s4("accessControl()")
print("accessControl()",SEL_AC)
out={}
for n,t in TOKENS.items():
    ac=a(call(t,SEL_AC))
    print(n,"accessControl=",ac)
    out[n]={"token":t,"accessControl":ac}
json.dump(out,open("/home/heisenberg/CA/hyperbeat-earn/analysis/midas_ac.json","w"),indent=1)
