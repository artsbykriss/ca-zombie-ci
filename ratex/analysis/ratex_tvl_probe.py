#!/usr/bin/env python3
import solrpc as s, json, base64, urllib.request, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    import base58 as b58
except Exception:
    import b58

PROG="RAtEwzA1rerjeWip6uMuheQtzykxYCrEQRaSFCCrf2D"
_HERE=os.path.dirname(os.path.abspath(__file__))
addrs=json.load(open(os.path.join(_HERE,"ratex_alt.json")))["addresses"]
accts=[]
for i in range(0,len(addrs),80):
    accts += s.rpc("getMultipleAccounts",[addrs[i:i+80],{"encoding":"jsonParsed","commitment":"confirmed"}])["result"]["value"]
mints={}
tot={}
for a,acc in zip(addrs,accts):
    if not acc: continue
    p=acc.get("data",{}).get("parsed",{})
    if p.get("type")=="account":
        info=p["info"]; m=info["mint"]; amt=float(info["tokenAmount"]["uiAmountString"] or 0)
        mints[m]=mints.get(m,0)+1; tot[m]=tot.get(m,0)+amt
print("mints in ALT vaults:")
for m,c in sorted(mints.items(), key=lambda x:-tot[x[0]]):
    print(f"  {m}  accounts={c}  uiAmount={tot[m]:.4f}")
# price
keys=list(tot.keys())
prices={}
for i in range(0,len(keys),50):
    url="https://coins.llama.fi/prices/current/"+",".join(f"solana:{k}" for k in keys[i:i+50])
    try:
        d=json.load(urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":"audit"})))
        prices.update(d.get("coins",{}))
    except Exception as e: print("price err",e)
usd=0
for m,amt in tot.items():
    p=prices.get(f"solana:{m}",{}).get("price")
    if p: usd+=amt*p; print(f"  {m}: {amt:.4f} * ${p} = ${amt*p:,.2f}")
    else: print(f"  {m}: {amt:.4f} * ? (no price)")
print(f"TOTAL RateX ALT-vault TVL = ${usd:,.2f}")
json.dump({"by_mint":tot,"usd":usd},open(os.environ.get("OUT_TVL",os.path.join(_HERE,"ratex_tvl.json")),"w"),indent=1)
