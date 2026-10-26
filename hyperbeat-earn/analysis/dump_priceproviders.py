#!/usr/bin/env python3
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
def dec3(h):
    if not isinstance(h,str) or len(h)<3: return None
    b=h[2:].rjust(192,"0")
    return ("0x"+b[24:64], int(b[64:128],16), int(b[128:192],16))
def code(x): return rpc("eth_getCode",[x,hex(BLK)])
def s4(s): return subprocess.run(["cast","sig",s],capture_output=True,text=True).stdout.strip()
def enc(x): return x[2:].rjust(64,"0")
AC=s4("assetConfigs(address)")
TOKENS={"WHYPE":"0x5555555555555555555555555555555555555555","USDC":"0xb88339cb7199b77e23db6e890353e22632ba630f",
 "USDT0":"0xb8ce59fc3717ada4c02eadf9682a9e934f625ebb","USDe":"0x5d3a1ff2b6bab83b63cd9ad0787074081a52ef34",
 "UETH":"0xbe6727b535545c67d5caa73dea54865b92cf7907","uBTC":"0x9fdbda0a5e284c32744d2f17ee5c74b284993463",
 "XAUt0":"0xf4d9235269a96aadafc9adae454a0618ebe37949","rUSDC":"0x9ab96a4668456896d45c301bc3a15cee76aa7b8d",
 "USR":"0x0ad339d66bf4aed5ce31c64bc37b3244b6394a77","beHYPE":"0xd8FC8F0b03eBA61F64D08B0bef69d80916E5DdA9"}
PRICERS={"lstHYPE":"0x5eD0eC0b0643dAB621Dc814C8D058e161b9b884b","hbUSDT":"0x3636a26ec1d512c5eCff42F7Adaa5cE7964C6579",
 "hbUSDC":"0xe0995A641d454c149E6C808BAA37Cb2B38763316","nLP":"0xC23cdFe493bB5E69bedfCF6E710f508710ac668B",
 "masterUSD":"0x5362454e5648C6Ac7F03969E8a62CFc61F99b9D6","dnHYPE":"0x5100Aee934F0EE05FA78B03114a068Da18aFEd8D",
 "dnPUMP":"0x58F6138DB540D0f5bfB24Fd9b17db54694a92ea6","hbXAUt":"0x988E3E2C26840F2cAe2c5fB55fAeb5e59CE1A597"}
out={}
for pn,p in PRICERS.items():
    base=None
    for tn,t in TOKENS.items():
        r=call(p,AC+enc(t))
        d=dec3(r) if isinstance(r,str) else None
        if d and d[0]!="0x"+"00"*20:
            cs=code(d[0]); csn=(len(cs)-2)//2 if isinstance(cs,str) else None
            pr=call(d[0],s4("getPrice()"))
            dec=call(d[0],s4("decimals()"))
            print(f"{pn:10s} {tn:7s} priceProvider={d[0]} ppCodeSize={csn} getPrice={pr if not isinstance(pr,dict) else pr} ppDecimals={dec if not isinstance(dec,dict) else dec}")
            out.setdefault(pn,{})[tn]={"provider":d[0],"codesize":csn,"getPrice":pr,"ppDecimals":dec}
    if pn not in out: print(f"{pn:10s} (all assetConfigs zero)")
json.dump(out,open("/home/heisenberg/CA/hyperbeat-earn/analysis/price_providers.json","w"),indent=1)
print("done")
