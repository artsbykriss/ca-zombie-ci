#!/usr/bin/env python3
import json,urllib.request,base64
RPC="https://api.mainnet-beta.solana.com"
def rpc(m,p):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=120))
CFG="HrW16vpyqURMvR4CeRf1QYMucEGKusHuzPVz1V3h7R7B"
# token accounts owned by config
for tok in ["TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA","TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"]:
    r=rpc("getTokenAccountsByOwner",[CFG,{"programId":tok},{"encoding":"jsonParsed"}])
    vals=r.get("result",{}).get("value",[])
    print(f"== token program {tok[:8]}: {len(vals)} accounts")
    for a in vals:
        info=a["account"]["data"]["parsed"]["info"]
        print("  ",a["pubkey"],"mint",info["mint"],"amount",info["tokenAmount"]["uiAmountString"],"dec",info["tokenAmount"]["decimals"])
# config raw
r=rpc("getAccountInfo",[CFG,{"encoding":"base64"}])
d=base64.b64decode(r["result"]["value"]["data"][0])
print("== config len",len(d))
print(d.hex())
