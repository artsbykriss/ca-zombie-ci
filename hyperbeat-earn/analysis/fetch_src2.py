#!/usr/bin/env python3
import json, os, urllib.request, time
KEY = os.environ["ETHERSCANV2_API_KEY"]
OUT = "/home/heisenberg/CA/hyperbeat-earn/analysis/src"
ADDRS = {
 "nLP": "0x4Cc221cf1444333510a634CE0D8209D2D11B9bbA",
 "masterUSD": "0x9065E3153B1393Bb5f76520cdc1e08E49eb04B03",
 "oracle_nLP": "0xC23cdFe493bB5E69bedfCF6E710f508710ac668B",
 "oracle_masterUSD": "0x5362454e5648C6Ac7F03969E8a62CFc61F99b9D6",
 "ultraHYPE_proxy": "0x96C6cBB6251Ee1c257b2162ca0f39AA5Fa44B1FB",
 "oracle_dnHYPE": "0x5100Aee934F0EE05FA78B03114a068Da18aFEd8D",
 "oracle_hbXAUt": "0x988E3E2C26840F2cAe2c5fB55fAeb5e59CE1A597",
 "accessControl_midas": "0x0000000000000000000000000000000000000000",
}
def fetch(addr, action="getsourcecode"):
    url=f"https://api.etherscan.io/v2/api?chainid=999&module=contract&action={action}&address={addr}&apikey={KEY}"
    for a in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":"r/1"}),timeout=40) as r:
                return json.loads(r.read())
        except Exception as e:
            if a==3: return {"__exc__":str(e)}
            time.sleep(2)
for name,addr in ADDRS.items():
    if addr=="0x"+"00"*20: continue
    d=fetch(addr); res=d.get("result")
    if isinstance(res,list) and res:
        x=res[0]; sc=x.get("SourceCode") or ""
        open(f"{OUT}/{name}.srccode.txt","w").write(sc)
        if x.get("ABI"): open(f"{OUT}/{name}.abi.json","w").write(x["ABI"])
        print(f"{name:24s} {addr} {x.get('ContractName')} proxy={x.get('Proxy')} impl={x.get('Implementation')} len={len(sc)}")
    else:
        print(f"{name:24s} {addr} RESULT={str(res)[:120]}")
