#!/usr/bin/env python3
"""Direct exchange tag-0x1f call (the oracle's settle CPI) reproduced standalone,
plus variants. Read-only (simulateTransaction, sigVerify=false)."""
import json,base64,sys,os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc
from sim_oracle import KEYS, WRITABLE
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature
P=lambda s: Pubkey.from_string(s)
A="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58d(s):
    n=0
    for c in s: n=n*58+A.index(c)
    b=n.to_bytes((n.bit_length()+7)//8,'big')
    return b'\x00'*(len(s)-len(s.lstrip('1')))+b
TX=json.load(open("/home/heisenberg/CA/cardboard-trade/analysis/tx1.json"))["result"]
PAYLOAD=b58d(TX["meta"]["innerInstructions"][0]["instructions"][0]["data"])
EX=Pubkey.from_string("J7vt5nGQd7YggFTV6GPwmWycfxzLjnHoGX6GRUKo9M7A")

def sim(ixs,label):
    payer=P(KEYS[0])
    msg=Message.new_with_blockhash(ixs,payer,Hash.default())
    tx=Transaction.populate(msg,[Signature.default()]*msg.header.num_required_signatures)
    raw=base64.b64encode(bytes(tx)).decode()
    r=rpc("simulateTransaction",[raw,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v=r["result"]["value"]
    print(f"\n===== {label} =====\nerr={v['err']} cu={v['unitsConsumed']}")
    for l in v.get("logs") or []: print("   ",l)
    return v

# exact accounts the oracle passes
ACC=[20,41,3,8,42]
def build(accts):
    metas=[AccountMeta(P(KEYS[i]),False,i in WRITABLE) for i in accts]
    return Instruction(EX,PAYLOAD,metas)

sim([build(ACC)],"DIRECT exchange 0x1f, exact oracle CPI accounts+payload")
# variant: include instructions sysvar
IXSYS="Sysvar1nstructions1111111111111111111111111"
metas=[AccountMeta(P(KEYS[i]),False,i in WRITABLE) for i in ACC]+[AccountMeta(P(IXSYS),False,False)]
sim([Instruction(EX,PAYLOAD,metas)],"DIRECT + SysvarInstructions appended")
