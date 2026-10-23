#!/usr/bin/env python3
import json,base64,urllib.request,sys
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.keypair import Keypair
from solders.hash import Hash
from solders.signature import Signature

RPC="https://api.mainnet-beta.solana.com"
def rpc(m,p):
    req=urllib.request.Request(RPC,data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req,timeout=120))

def simulate(ixs, label):
    payer=Pubkey.from_string("Ef1YAVrvuUfjULKGEN2eqUSHwYTSUx2aE3VjoBefxVVb")
    msg=Message.new_with_blockhash(ixs, payer, Hash.default())
    tx=Transaction.populate(msg,[Signature.default()]*msg.header.num_required_signatures)
    raw=base64.b64encode(bytes(tx)).decode()
    r=rpc("simulateTransaction",[raw,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    res=r.get("result",{})
    val=res.get("value",{})
    print(f"\n===== {label} =====")
    print("err:",val.get("err"))
    print("unitsConsumed:",val.get("unitsConsumed"))
    for l in (val.get("logs") or [])[:40]:
        print("  ",l)
    if not res and r.get("error"): print("RPC error:",json.dumps(r["error"])[:400])

EX="J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A"
OR="5g3PW7gtfnM3QYsGPaPGLiCxtous4arSugCct9KPHHWo"
P=lambda s: Pubkey.from_string(s)

# Exchange settle instruction (tag 0x1f), accounts from inner CPI index 0
ex_ix=Instruction(P(EX), bytes.fromhex("1f00007bc6860a130000007bc6860a130000003e50701b00000000a14e160000000000"),
    [AccountMeta(P("3Kmfgp4ue8eRg48as6rzgPtkFvnbZhEnRmn8ESdbiAPC"),False,False),
     AccountMeta(P("HrW16vpyqURMvR4CeRf1QYMucEGKusHuzPVz1V3h7R7B"),False,False),
     AccountMeta(P("iiGr5mtbreSHGuUw5DF1NtVjSqAjLdUvcUUVqQ9jYFc"),False,True),
     AccountMeta(P("ACJeDQXpxGEWdV7Ym7Wt2XgiRU1kBpcoN8m6QHFjokPY"),False,True),
     AccountMeta(P(EX),False,False)])
simulate([ex_ix], "DIRECT exchange settle tag=0x1f (fabricated prices, no oracle caller)")

# Oracle push instruction (tag 0x071f), accounts from tx1 ix0, fresh payer
orc_meta=[(12,0),(7,0),(20,0),(41,0),(3,0),(42,0),(8,0),(19,0),(32,0),(30,0),(15,0),(21,0),(40,0),(37,0),(16,0),(23,0),(31,0)]
keys=json.load(open("tx1.json"))["result"]["transaction"]["message"]["accountKeys"]
metas=[]
for idx,_ in orc_meta:
    metas.append(AccountMeta(P(keys[idx]), idx==0, idx<=13))
orc_ix=Instruction(P(OR), bytes.fromhex("071f"), metas)
simulate([orc_ix], "ORACLE push tag=0x071f (fresh payer, no keeper signature)")
