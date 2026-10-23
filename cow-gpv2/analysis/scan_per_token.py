#!/usr/bin/env python3
"""Per-token full-range scan of Approval(owner=settlement) for the tokens the settlement holds.
Closes the gap left by the (slow) global scan. Read-only."""
import json, os, sys, urllib.request, time

KEY = os.environ["ETHERSCANV2_API_KEY"]
APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
T1 = "0x0000000000000000000000009008d19f58aabd9ed0d60971565aa8510560ab41"
HEAD = 26253971

TOKENS = {
 "WBTC":"0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
 "imBTC":"0x3212b29e33587a00fb1c83346f5dbfa69a458923",
 "SLP":"0xcc8fa225d80b9c7d42f96e9570156c65d6caaa25",
 "EURS":"0xdb25f211ab05b1c97d595516f45794528a807ad8",
 "XAUt":"0x68749665ff8d2d112fa859aa293f07a622782f38",
 "USDC":"0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
 "USDT":"0xdac17f958d2ee523a2206206994597c13d831ec7",
 "DAI":"0x6b175474e89094c44da98b954eedeac495271d0f",
 "WETH":"0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
 "USDe":"0x4c9edd5852cd905f086c759e8383e09bff1e68b3",
 "USDS":"0xdc035d45d973e3ec169d2276ddab16f1e407384f",
 "sDAI":"0x83f20f44975d03b1b09e64809b757c47f942beea",
 "COW":"0xdef1ca1fb7fbcdc777520aa7f396b4e015f497ab",
 "GNO":"0x6810e776880c02933d47db1b9fc05908e5386b96",
}

def get(frm,to,tok):
    url=("https://api.etherscan.io/v2/api?chainid=1&module=logs&action=getLogs"
         f"&fromBlock={frm}&toBlock={to}&address={tok}&topic0={APPROVAL}&topic1={T1}"
         f"&topic0_1_opr=and&apikey={KEY}")
    for a in range(6):
        try:
            with urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":"research/1.0"}),timeout=60) as r:
                j=json.load(r)
            if j.get("status")=="0" and "No" in str(j.get("message","")): return []
            if not isinstance(j.get("result"),list): raise RuntimeError(j)
            return j["result"]
        except Exception:
            if a==5: raise
            time.sleep(1.5*(a+1))

out={}
for name,tok in TOKENS.items():
    rows=[]
    def scan(frm,to):
        res=get(frm,to,tok)
        if len(res)<1000 or frm>=to: rows.extend(res); return
        mid=(frm+to)//2; scan(frm,mid); scan(mid+1,to)
    b=0
    while b<=HEAD:
        e=min(b+2_000_000-1,HEAD); scan(b,e); b=e+1
    sp={}
    for x in rows:
        s="0x"+x["topics"][2][-40:]
        sp.setdefault(s,0); sp[s]+=1
    out[name]={"token":tok,"n":len(rows),"spenders":sp}
    print(f"{name}: {len(rows)} approval logs, spenders={list(sp)}",flush=True)
json.dump(out,open("/home/heisenberg/CA/cow-gpv2/analysis/per_token_spenders.json","w"),indent=1)
print("done")
