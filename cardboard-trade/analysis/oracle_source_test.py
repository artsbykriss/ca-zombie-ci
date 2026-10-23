#!/usr/bin/env python3
# Independent test: does the ORACLE push validate its price-source accounts?
# Replaces one external-DEX source account with a bogus account and re-simulates the 071f push.
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
OR="5g3PW7gtfnM3QYsGPaPGLiCxtous4arSugCct9KPHHWo"
keys=json.load(open("tx1.json"))["result"]["transaction"]["message"]["accountKeys"]
PAYER=P("Ef1YAVrvuUfjULKGEN2eqUSHwYTSUx2aE3VjoBefxVVb")
IDX=[12,7,20,41,3,42,8,19,32,30,15,21,40,37,16,23,31]  # oracle push ix0 account indices
def build(accounts, label):
    metas=[AccountMeta(P(a), False, i<=13) for a,i in accounts]
    ix=Instruction(P(OR), bytes.fromhex("071f"), metas)
    msg=Message.new_with_blockhash([ix], PAYER, Hash.default())
    tx=Transaction.populate(msg,[Signature.default()]*msg.header.num_required_signatures)
    raw=base64.b64encode(bytes(tx)).decode()
    r=rpc("simulateTransaction",[raw,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v=r.get("result",{}).get("value",{})
    print(f"\n== {label} ==\nerr={v.get('err')} cu={v.get('unitsConsumed')}")
    for l in (v.get("logs") or [])[:25]: print("  ",l)
    return v
# control: real accounts
build([(keys[i],i) for i in IDX], "CONTROL: oracle push, real accounts")
# swap Tessera source 9NkuAWB (idx32) -> a system account (bogus source)
alt=[(keys[i],i) for i in IDX]
alt[8]=("11111111111111111111111111111111",32)
build(alt, "SWAP Tessera source 9NkuAWB -> SystemProgram (bogus source)")
# swap GoonFi source 8TxrtAx (idx30) -> keeper (bogus source, non-DEX)
alt2=[(keys[i],i) for i in IDX]
alt2[9]=("Ef1YAVrvuUfjULKGEN2eqUSHwYTSUx2aE3VjoBefxVVb",30)
build(alt2, "SWAP GoonFi source 8TxrtAx -> keeper EOA (bogus source)")
