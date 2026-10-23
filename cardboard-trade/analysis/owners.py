#!/usr/bin/env python3
import json,urllib.request,base64,sys
RPC="https://api.mainnet-beta.solana.com"
def rpc(m,p):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=120))
keys=json.load(open("/home/heisenberg/CA/cardboard-trade/analysis/tx1.json"))["result"]["transaction"]["message"]["accountKeys"]
# owners via getMultipleAccounts
r=rpc("getMultipleAccounts",[keys,{"encoding":"base64"}])
vals=r["result"]["value"]
KNOWN={"5g3PW7gtfnM3QYsGPaPGLiCxtous4arSugCct9KPHHWo":"ORACLE","J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A":"EXCHANGE",
"11111111111111111111111111111111":"SYSTEM","TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA":"TOKEN",
"TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb":"TOKEN2022","ComputeBudget111111111111111111111111111111":"COMPUTE",
"ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL":"ATA","SysvarRent111111111111111111111111111111111":"RENT",
"SysvarInstructions111111111111111111111111111111":"IXSYSVAR","SysvarClock111111111111111111111111111111111":"CLOCK"}
for k,v in zip(keys,vals):
    if v is None: print(f"{k}  <not found>"); continue
    d=base64.b64decode(v["data"][0]); 
    print(f"{k}  owner={v['owner']} ({KNOWN.get(v['owner'],'?')}) len={len(d)} lamports={v['lamports']} exec={v['executable']}")
