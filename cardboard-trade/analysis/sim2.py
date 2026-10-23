#!/usr/bin/env python3
import json,base64,urllib.request
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature
RPC="https://api.mainnet-beta.solana.com"
def rpc(m,p):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=120))
P=lambda s: Pubkey.from_string(s)
sig="4ZVhgQXvnc5tGWqJGrEKTsJKfa1Tb5nxf9nuUr8Ke2tmgyHL5srxMTkdN5MCKRnLCZ65DpjSnynZh7ZZbdro2yoR"

# raw tx base64
raw=rpc("getTransaction",[sig,{"encoding":"base64","maxSupportedTransactionVersion":1,"commitment":"confirmed"}])["result"]["transaction"][0]
keys=[k for k in json.load(open("tx1.json"))["result"]["transaction"]["message"]["accountKeys"]]
addrs=[{"address":k,"encoding":"base64"} for k in keys]
def sim(rawtx,label,addrs=None):
    cfg={"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}
    if addrs: cfg["accounts"]={"encoding":"base64","addresses":addrs}
    r=rpc("simulateTransaction",[rawtx,cfg])
    v=r.get("result",{}).get("value",{})
    print(f"\n===== {label} =====\nerr:{v.get('err')} cu:{v.get('unitsConsumed')}")
    for l in (v.get("logs") or [])[:50]: print("  ",l)
    return v
print("### CONTROL: replay original tx raw ###")
v=sim(raw,"original tx replay (sigVerify=false)",addrs)
# show changed accounts
for a in v.get("accounts") or []:
    print("  post acct",a.get("pubkey"),"lamports",a.get("lamports"),"datalen",len(base64.b64decode(a["data"][0])) if a.get("data") else None)

# direct exchange settle with accounts output
ex_ix=Instruction(P("J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A"), bytes.fromhex("1f00007bc6860a130000007bc6860a130000003e50701b00000000a14e160000000000"),
    [AccountMeta(P("3Kmfgp4ue8eRg48as6rzgPtkFvnbZhEnRmn8ESdbiAPC"),False,False),
     AccountMeta(P("HrW16vpyqURMvR4CeRf1QYMucEGKusHuzPVz1V3h7R7B"),False,False),
     AccountMeta(P("iiGr5mtbreSHGuUw5DF1NtVjSqAjLdUvcUUVqQ9jYFc"),False,True),
     AccountMeta(P("ACJeDQXpxGEWdV7Ym7Wt2XgiRU1kBpcoN8m6QHFjokPY"),False,True),
     AccountMeta(P("J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A"),False,False)])
payer=P("Ef1YAVrvuUfjULKGEN2eqUSHwYTSUx2aE3VjoBefxVVb")
msg=Message.new_with_blockhash([ex_ix],payer,Hash.default())
tx=Transaction.populate(msg,[Signature.default()]*msg.header.num_required_signatures)
raw2=base64.b64encode(bytes(tx)).decode()
sim(raw2,"DIRECT exchange settle (accounts output)",["HrW16vpyqURMvR4CeRf1QYMucEGKusHuzPVz1V3h7R7B","iiGr5mtbreSHGuUw5DF1NtVjSqAjLdUvcUUVqQ9jYFc","ACJeDQXpxGEWdV7Ym7Wt2XgiRU1kBpcoN8m6QHFjokPY","3Kmfgp4ue8eRg48as6rzgPtkFvnbZhEnRmn8ESdbiAPC"])
