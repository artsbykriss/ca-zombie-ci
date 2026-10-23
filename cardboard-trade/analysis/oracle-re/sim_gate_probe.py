#!/usr/bin/env python3
"""Probe the exchange tag-0x1f caller gate. Read-only (simulateTransaction)."""
import json,base64,sys,os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc
from sim_oracle import KEYS, WRITABLE, IX_ACCTS, build_oracle_ix, ORACLE
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
IXSYS="Sysvar1nstructions1111111111111111111111111"

def sim(ixs,label,extra=None):
    payer=P(KEYS[0])
    msg=Message.new_with_blockhash(ixs,payer,Hash.default())
    tx=Transaction.populate(msg,[Signature.default()]*msg.header.num_required_signatures)
    raw=base64.b64encode(bytes(tx)).decode()
    r=rpc("simulateTransaction",[raw,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v=r["result"]["value"]
    logs=[l for l in (v.get("logs") or []) if "log:" in l or "invoke" in l]
    print(f"{label:64} err={v['err']} cu={v['unitsConsumed']} logs={logs[:4]}")
    return v

ACC=[20,41,3,8,42]
def exix(accts,payload=PAYLOAD):
    return Instruction(EX,payload,[AccountMeta(P(KEYS[i]),False,i in WRITABLE) for i in accts])

sim([exix(ACC)],"0) exchange 0x1f alone")
sim([exix(ACC+[25])],"1) +oracle program acct appended")
sim([exix(ACC+[37])],"2) +DmocjvFX(ojh) appended")
sim([exix(ACC+[7])],"3) +oracle weights acct appended")
sim([exix([25]+ACC)],"4) oracle program prepended to accts")
# prepend a real oracle 071f push as ix0
sim([build_oracle_ix(0), exix(ACC)],"5) oracle 071f push THEN direct exchange 0x1f")
sim([exix(ACC), build_oracle_ix(0)],"6) direct exchange 0x1f THEN oracle 071f push")
# sysvar prepended in account list
sim([Instruction(EX,PAYLOAD,[AccountMeta(P(IXSYS),False,False)]+[AccountMeta(P(KEYS[i]),False,i in WRITABLE) for i in ACC])],"7) sysvar first in account list")
