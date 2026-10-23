#!/usr/bin/env python3
"""For each source swap, capture the resulting oracle FEED account (1338B) and
WEIGHTS account (191B) data and compare against baseline. Read-only."""
import json,base64,sys,os,hashlib
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc
from sim_oracle import KEYS, IX_ACCTS, WRITABLE, ORACLE
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature
P=lambda s: Pubkey.from_string(s)

def sim(acct_indices):
    metas=[AccountMeta(P(KEYS[i]),False,i in WRITABLE) for i in acct_indices]
    ix=Instruction(P(ORACLE),bytes.fromhex("071f"),metas)
    msg=Message.new_with_blockhash([ix],P(KEYS[0]),Hash.default())
    tx=Transaction.populate(msg,[Signature.default()]*msg.header.num_required_signatures)
    raw=base64.b64encode(bytes(tx)).decode()
    out=[KEYS[12],KEYS[7]]
    cfg={"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed",
         "accounts":{"encoding":"base64","addresses":out}}
    r=rpc("simulateTransaction",[raw,cfg])
    v=r["result"]["value"]
    accs=v.get("accounts") or []
    feed=base64.b64decode(accs[0]["data"][0]); wght=base64.b64decode(accs[1]["data"][0])
    return v.get("err"),v.get("unitsConsumed"),feed,wght

def price_region(b):
    # weights: 5 u32 price slots at offsets 21,25,29,33,37
    import struct
    w=[struct.unpack_from("<I",b,o)[0] for o in (21,25,29,33,37)]
    return w

BASE=IX_ACCTS[0]
be,bc,bf,bw=sim(BASE)
print(f"BASELINE err={be} cu={bc}")
print("  weights prices:",price_region(bw))
print("  feed sha:",hashlib.sha256(bf).hexdigest()[:16])
for pos,newidx,lab in [(7,3,"BiSo->ex-II"),(7,5,"BiSo->system"),(8,3,"Tess->ex-II"),(9,3,"goon->ex-II"),
                       (10,3,"dijk->ex-II"),(11,3,"ojh21->ex-II"),(12,3,"ojh40->ex-II"),(13,3,"DmocjvFX->ex-II"),
                       (14,3,"AQU->ex-II"),(15,3,"fast->ex-II"),(16,3,"8mZVRgrr->ex-II"),
                       (7,29,"BiSo->29"),(10,18,"dijk->18"),(13,21,"DmocjvFX->ojh21")]:
    a=list(BASE); a[pos]=newidx
    e,c,f,w=sim(a)
    print(f"{lab:20} err={e} cu={c} wsha={hashlib.sha256(w).hexdigest()[:8]} prices={price_region(w)} feedsame={f==bf} wsame={w==bw}")
