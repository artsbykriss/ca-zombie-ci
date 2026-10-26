#!/usr/bin/env python3
"""Resolve EIP-1967 impl/admin for Hyperbeat proxies + read getRate/lastAnswer."""
import json, urllib.request, sys, time
RPC = "https://rpc.hyperliquid.xyz/evm"
BLK = int(sys.argv[1]) if len(sys.argv) > 1 else 49508160
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
ADMIN_SLOT = "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"
_id=0
def rpc(m,p):
    global _id; _id+=1
    body=json.dumps({"jsonrpc":"2.0","id":_id,"method":m,"params":p}).encode()
    req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
    for a in range(4):
        try:
            with urllib.request.urlopen(req,timeout=40) as r: d=json.loads(r.read())
            if "error" in d: return {"__err__":d["error"]}
            return d.get("result")
        except Exception as e:
            if a==3: return {"__exc__":str(e)}
            time.sleep(1.2)
def slot(addr,s): return rpc("eth_getStorageAt",[addr,s,hex(BLK)])
def addr_of(h): return "0x"+h[-40:] if isinstance(h,str) and len(h)>=42 else None
def call(addr,data):
    return rpc("eth_call",[{"to":addr,"data":data},hex(BLK)])
def code(a): return rpc("eth_getCode",[a,hex(BLK)])

PROXIES = [
 ("0x441794D6a8F9A3739F5D4E98a728937b33489D29","liquidHYPE"),
 ("0xD66d69c288d9a6FD735d7bE8b2e389970fC4fD42","wVLP"),
 ("0x81e064d0eB539de7c3170EDF38C1A42CBd752A76","lstHYPE"),
 ("0x5e105266db42f78FA814322Bce7f388B4C2e61eb","hbUSDT"),
 ("0x057ced81348D57Aad579A672d521d7b4396E8a61","hbUSDC"),
 ("0x4Cc221cf1444333510a634CE0D8209D2D11B9bbA","nLP"),
 ("0x9065E3153B1393Bb5f76520cdc1e08E49eb04B03","masterUSD"),
 ("0x949a7250Bb55Eb79BC6bCC97fCd1C473DB3e6F29","dnHYPE"),
 ("0x8858A307a85982c2B3CB2AcE1720237f2f09c39B","dnPUMP"),
 ("0x6EB6724D8D3D4FF9E24d872E8c38403169dC05f8","hbXAUt"),
 ("0x96C6cBB6251Ee1c257b2162ca0f39AA5Fa44B1FB","UltraHYPE"),
 ("0xc061d38903b99aC12713B550C2CB44B221674F94","UltrauBTC"),
 ("0x1ceab703956e24b18a0af6b272e0bf3f499aca0f","oracle"),
]
out={"block":BLK,"proxies":[]}
for a,l in PROXIES:
    impl=addr_of(slot(a,IMPL_SLOT)); admin=addr_of(slot(a,ADMIN_SLOT))
    row={"addr":a,"label":l,"impl":impl,"admin":admin}
    if impl and impl!="0x"+"00"*20:
        c=code(impl); row["impl_codesize"]=(len(c)-2)//2 if isinstance(c,str) else None
    out["proxies"].append(row)
    print(f"{l:12s} {a} impl={impl} admin={admin} implcs={row.get('impl_codesize')}",flush=True)

# rate oracles
RATES = {
 "lstHYPE":"0x5eD0eC0b0643dAB621Dc814C8D058e161b9b884b",
 "hbUSDT":"0x3636a26ec1d512c5eCff42F7Adaa5cE7964C6579",
 "hbUSDC":"0xe0995A641d454c149E6C808BAA37Cb2B38763316",
 "nLP":"0xC23cdFe493bB5E69bedfCF6E710f508710ac668B",
 "masterUSD":"0x5362454e5648C6Ac7F03969E8a62CFc61F99b9D6",
 "dnHYPE":"0x5100Aee934F0EE05FA78B03114a068Da18aFEd8D",
 "dnPUMP":"0x58F6138DB540D0f5bfB24Fd9b17db54694a92ea6",
 "hbXAUt":"0x988E3E2C26840F2cAe2c5fB55fAeb5e59CE1A597",
}
out["rates"]={}
for l,a in RATES.items():
    r=call(a,"0x679aefce")  # getRate()
    cs=code(a); cs=(len(cs)-2)//2 if isinstance(cs,str) else None
    out["rates"][l]={"oracle":a,"getRate":int(r,16) if isinstance(r,str) and r!="0x" else r,"codesize":cs}
    print(f"RATE {l:12s} {a} getRate={out['rates'][l]['getRate']} cs={cs}",flush=True)

# oracle lastAnswer variants
for sig,name in [("0xba2e56b2","lastAnswer?")]:
    r=call("0x1ceab703956e24b18a0af6b272e0bf3f499aca0f",sig)
    print(f"oracle {name} {sig} -> {r}",flush=True)
json.dump(out,open("/home/heisenberg/CA/hyperbeat-earn/analysis/proxies.json","w"),indent=1)
print("WROTE proxies.json")
