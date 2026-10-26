#!/usr/bin/env python3
"""Check every candidate Depositor: vaultToken, isPaused, depositCap, and isDepositToken whitelist."""
import json, urllib.request, sys, time, subprocess
RPC="https://rpc.hyperliquid.xyz/evm"; BLK=int(sys.argv[1]) if len(sys.argv)>1 else 49508160
_id=0
def rpc(m,p):
    global _id; _id+=1
    body=json.dumps({"jsonrpc":"2.0","id":_id,"method":m,"params":p}).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"r/1"})
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=40) as r: d=json.loads(r.read())
            return d.get("result") if "error" not in d else {"__err__":d["error"]}
        except Exception as e:
            if a==3: return {"__exc__":str(e)}
            time.sleep(1.0)
def call(to,data): return rpc("eth_call",[{"to":to,"data":data},hex(BLK)])
def a(h): return "0x"+h[-40:] if isinstance(h,str) and len(h)>=42 else h
def u(h):
    try: return int(h,16)
    except: return h
def s4(s): return subprocess.run(["cast","sig",s],capture_output=True,text=True).stdout.strip()
def enc(x): return x[2:].rjust(64,"0")
def code(x): return rpc("eth_getCode",[x,hex(BLK)])

CANDS=[
 ("LST_HYPE","0x205ac1e0380b0b9cce691bd4c6f3c14258ae9201"),("LST_HYPE","0x2b158d44eebb03a025f75b79f1d8b3004ac97737"),("LST_HYPE","0xf5d4f036856837adfb91cf863f470d215cf8a99c"),
 ("LIQUID_HYPE","0x5bfb09dd155c0ec3f375b266a7353c0ba64f9d60"),("LIQUID_HYPE","0x6f4fc4bbff4ea40e4b05033ed3ea80fb0a5cc6b6"),("LIQUID_HYPE","0xf538675d292d8b372712f44eaf306cc66cf6d8dc"),
 ("HB_USDT","0x6261f30144b259c74243d5f5d9230941186ac936"),("HB_USDT","0xa715f0bdbac0c81f8da0f8f7356efc3ae02561c0"),("HB_USDT","0xbe8a4f1a312b94a712f8e5367b02ae6e378e6f19"),
 ("HB_USDC","0xd202cf41a607627cd1a31f650d13599b588ebd1c"),("HB_USDC","0x929df52b0c3315d03922e12e54b46157395be4d0"),("HB_USDC","0x3e3619d5fab6560c96ebd6061e91f3a3a9d85a45"),
 ("DN_HYPE","0xbf8cd92d291b9b08cf1365815da516d8e053a20d"),("DN_HYPE","0xa4a6b89354e278666fb908ccdb16276ae151ff00"),("DN_HYPE","0x127c5945c93906cc36cf32eb7f9504af66e464b9"),
 ("DN_PUMP","0xaf8ffedf0e57ee9f6518340b9eb913ffa7dbc66b"),("DN_PUMP","0x76a48c429a48346cb5b80544bffc8132a30defa8"),("DN_PUMP","0x5121a54a97e7d3980596ccd306a16c82702e9bb0"),
 ("HB_XAUT","0xccbc13af723bee139a5cc48f0c7169a56e10d2d3"),("HB_XAUT","0x48fb106ef0c0c1a19eddc9c5d27a945e66da1c4e"),("HB_XAUT","0x46a12ddca8c92742251b2a2c33610bf8ae090cd9"),
]
UND={"WHYPE":"0x5555555555555555555555555555555555555555","USDC":"0xb88339cb7199b77e23db6e890353e22632ba630f",
 "USDT0":"0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb","USDe":"0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34",
 "UETH":"0xbe6727b535545c67d5caa73dea54865b92cf7907","uBTC":"0x9fdbda0a5e284c32744d2f17ee5c74b284993463",
 "XAUt0":"0xf4d9235269a96aadafc9adae454a0618ebe37949","rUSDC":"0x9ab96a4668456896d45c301bc3a15cee76aa7b8d",
 "USR":"0x0ad339d66bf4aed5ce31c64bc37b3244b6394a77","beHYPE":"0xd8FC8F0b03eBA61F64D08B0bef69d80916E5DdA9"}
S={"vaultToken":s4("vaultToken()"),"isPaused":s4("isPaused()"),"depositCap":s4("depositCap()"),
   "pricer":s4("pricer()"),"isDepositToken":s4("isDepositToken(address)"),"depositReceiver":s4("depositReceiver()"),
   "baseAsset":s4("baseAsset()")}
out=[]
for fam,addr in CANDS:
    cs=code(addr); csn=(len(cs)-2)//2 if isinstance(cs,str) else None
    row={"fam":fam,"depositor":addr,"codesize":csn}
    if csn and csn>100:
        vt=a(call(addr,S["vaultToken"])); row["vaultToken"]=vt
        pr=a(call(addr,S["pricer"])); row["pricer"]=pr
        row["isPaused"]=u(call(addr,S["isPaused"]))
        row["depositCap"]=u(call(addr,S["depositCap"]))
        row["depositReceiver"]=a(call(addr,S["depositReceiver"]))
        base=a(call(pr,S["baseAsset"])) if pr!="0x"+"00"*20 else None
        row["baseAsset"]=base
        toks={}
        for tn,t in UND.items():
            r=call(addr,S["isDepositToken"]+enc(t))
            if isinstance(r,str) and r.endswith("1"): toks[tn]=t
        row["depositTokens"]=list(toks.keys())
    out.append(row)
    print(json.dumps(row))
json.dump(out,open("/home/heisenberg/CA/hyperbeat-earn/analysis/depositors_all.json","w"),indent=1)
