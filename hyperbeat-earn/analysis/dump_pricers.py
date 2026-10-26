#!/usr/bin/env python3
import json, urllib.request, sys, time
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
            time.sleep(1.2)
def call(to,data):
    return rpc("eth_call",[{"to":to,"data":data},hex(BLK)])
def a(h): return "0x"+h[-40:] if isinstance(h,str) and len(h)>=42 else h
def u(h):
    try: return int(h,16)
    except: return h
def code(x): return rpc("eth_getCode",[x,hex(BLK)])

SEL={
 "owner":"0x8da5cb5b","depositReceiver":"0xfc8c0851","withdrawalQueue":"0x37d5fe99",
 "pricer":"0xa6138ed9","getRate":"0x679aefce","vaultToken":"0x703bafd5","baseAsset":"0xcdf456e1",
 "pricerParams":"0xbcaa092b","feeRecipient":"0x46904840","exchangeRate":"0x3ba0b9a9",
 "accessControl":"0x0d155f0c","totalAssets":"0x01e1d114","totalSupply":"0x18160ddd",
 "skimRecipient":"0x388af5b5","curator":"0xead542f6","fee":"0xddca3f43","asset":"0x38d52e0f",
 "paused":"0x5c975abb","depositsPaused":"0x60da3e83","withdrawalsPaused":"0xe9f2838e",
 "externalAssets":"0x785c3127","maxDepositAmount":"0x8ed83271","withdrawalFee":"0x8bc7e8c4",
 "lagDuration":"0x24e86d67","operator":"0x570ca735","feesCollector":"0x9cf160f6","maxChangePercent":"0x8a5e0b6e",
}
def g(addr,name):
    s=SEL.get(name)
    if not s: return None
    return call(addr,s)

# strategist EOA
print("strategist code:", code("0x83a80e5b64086197c01cbb123df2aea79a149c1d"))
# oracle proxy impl liquidHYPE
print("liquidHYPE oracle lastAnswer:", call("0x1ceab703956e24b18a0af6b272e0bf3f499aca0f","0xbb23ae25"))
print("liquidHYPE oracle latestRound:", call("0x1ceab703956e24b18a0af6b272e0bf3f499aca0f","0x8a1417ee"))

# Pricers
PRICERS={
 "lstHYPE":"0x5eD0eC0b0643dAB621Dc814C8D058e161b9b884b",
 "hbUSDT":"0x3636a26ec1d512c5eCff42F7Adaa5cE7964C6579",
 "hbUSDC":"0xe0995A641d454c149E6C808BAA37Cb2B38763316",
 "nLP":"0xC23cdFe493bB5E69bedfCF6E710f508710ac668B",
 "masterUSD":"0x5362454e5648C6Ac7F03969E8a62CFc61F99b9D6",
 "dnHYPE":"0x5100Aee934F0EE05FA78B03114a068Da18aFEd8D",
 "dnPUMP":"0x58F6138DB540D0f5bfB24Fd9b17db54694a92ea6",
 "hbXAUt":"0x988E3E2C26840F2cAe2c5fB55fAeb5e59CE1A597",
}
out={"block":BLK,"pricers":{}}
for n,p in PRICERS.items():
    row={"owner":a(g(p,"owner")),"depositReceiver":a(g(p,"depositReceiver")),"vaultToken":a(g(p,"vaultToken")),
         "baseAsset":a(g(p,"baseAsset")),"getRate":u(g(p,"getRate"))}
    out["pricers"][n]=row
    print(f"PRICER {n:10s} owner={row['owner']} depRecv={row['depositReceiver']} vaultTok={row['vaultToken']} base={row['baseAsset']} rate={row['getRate']}",flush=True)

# DepositReceiver discovery: read withdrawalQueue from each pricer's depositReceiver
drs=set(r["depositReceiver"] for r in out["pricers"].values() if r["depositReceiver"])
print("\nunique depositReceivers:", drs)
out["depositReceivers"]={}
for dr in drs:
    row={"owner":a(g(dr,"owner")),"withdrawalQueue":a(g(dr,"withdrawalQueue")),"pricer":a(g(dr,"pricer"))}
    out["depositReceivers"][dr]=row
    print("DepositReceiver",dr,"owner=",row["owner"],"withdrawalQueue=",row["withdrawalQueue"],"pricer=",row["pricer"])
    wq=row["withdrawalQueue"]
    if wq and wq!="0x"+"00"*20:
        c=code(wq); print("   WQ codesize:",(len(c)-2)//2 if isinstance(c,str) else None)

json.dump(out,open("/home/heisenberg/CA/hyperbeat-earn/analysis/pricer_state.json","w"),indent=1)
print("WROTE")
