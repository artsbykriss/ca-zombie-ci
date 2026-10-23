#!/usr/bin/env python3
import json,urllib.request,sys
RPC="https://api.mainnet-beta.solana.com"
def rpc(method,params):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=90))
sig=sys.argv[1]
r=rpc("getTransaction",[sig,{"encoding":"jsonParsed","maxSupportedTransactionVersion":1,"commitment":"confirmed"}])
res=r.get("result")
if not res: print("ERR",json.dumps(r)[:500]); sys.exit(1)
msg=res["transaction"]["message"]
accts=msg["accountKeys"]
print("slot",res.get("slot"),"err",res.get("meta",{}).get("err"))
print("num accounts",len(accts))
for i,a in enumerate(accts):
    print(f"  [{i}] {a['pubkey']} signer={a['signer']} writable={a['writable']}")
print("== top-level instructions ==")
for ix in msg["instructions"]:
    pid=ix.get("programId")
    print(f"  pid={pid} accounts={ix.get('accounts')}")
    if ix.get("parsed"): print("     parsed:",json.dumps(ix["parsed"])[:300])
    if ix.get("data"): print("     data:",ix["data"][:200])
print("== inner instructions ==")
for grp in res["meta"].get("innerInstructions",[]) or []:
    print(" index",grp["index"])
    for ix in grp["instructions"]:
        print(f"    pid={ix.get('programId')} accounts={ix.get('accounts')} data={str(ix.get('data'))[:80]} parsed={json.dumps(ix.get('parsed'))[:120] if ix.get('parsed') else ''}")
print("== logs ==")
for l in res["meta"].get("logMessages",[])[:60]:
    print("  ",l)
