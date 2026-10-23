#!/usr/bin/env python3
"""Test oracle source-account validation by swapping source accounts.
Read-only (simulateTransaction, sigVerify=false)."""
import json,base64,sys,os
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

def run(acct_indices,label):
    metas=[AccountMeta(P(KEYS[i]),False,i in WRITABLE) for i in acct_indices]
    ix=Instruction(P(ORACLE),bytes.fromhex("071f"),metas)
    payer=P(KEYS[0])
    msg=Message.new_with_blockhash([ix],payer,Hash.default())
    tx=Transaction.populate(msg,[Signature.default()]*msg.header.num_required_signatures)
    raw=base64.b64encode(bytes(tx)).decode()
    r=rpc("simulateTransaction",[raw,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v=r.get("result",{}).get("value",{})
    logs=v.get("logs") or []
    print(f"{label:70} err={v.get('err')} cu={v.get('unitsConsumed')}")
    return v

BASE=IX_ACCTS[0]
NAMES={7:"wght",12:"feed",20:"market",41:"config",3:"ex-II",42:"EXCH",8:"ex-ACJe",
 19:"BiSo.19",32:"Tess.32",30:"goon.30",15:"dijk.15",21:"ojh.21",40:"ojh.40",
 37:"DmocjvFX.ojh.37",16:"AQU.16",23:"fast.23",31:"8mZVRgrr.fast.31"}
if __name__=="__main__":
    run(BASE,"BASELINE real ix0")
    tests=[
      (7,29,"swap BiSo 19->29 (same owner)"),
      (7,3,"swap BiSo 19->ex-II (wrong owner)"),
      (7,5,"swap BiSo 19->system 2q5p (wrong owner)"),
      (8,35,"swap Tess 32->35 (same owner)"),
      (8,3,"swap Tess 32->ex-II (wrong owner)"),
      (9,39,"swap goon 30->39 (same owner)"),
      (9,3,"swap goon 30->ex-II (wrong owner)"),
      (10,18,"swap dijk 15->18 (same owner)"),
      (10,3,"swap dijk 15->ex-II (wrong owner)"),
      (11,22,"swap ojh 21->22 (same owner, 624B)"),
      (11,40,"swap ojh 21->40 (same owner, 4144B)"),
      (11,3,"swap ojh 21->ex-II (wrong owner)"),
      (12,21,"swap ojh 40->21 (same owner)"),
      (12,3,"swap ojh 40->ex-II (wrong owner)"),
      (13,21,"swap DmocjvFX 37->21 (same owner ojh)"),
      (13,3,"swap DmocjvFX 37->ex-II (wrong owner)"),
      (14,34,"swap AQU 16->34 (same owner)"),
      (14,3,"swap AQU 16->ex-II (wrong owner)"),
      (15,17,"swap fast 23->17 (same owner)"),
      (15,3,"swap fast 23->ex-II (wrong owner)"),
      (16,23,"swap 8mZVRgrr 31->23 (same owner fast)"),
      (16,3,"swap 8mZVRgrr 31->ex-II (wrong owner)"),
    ]
    for pos,newidx,lab in tests:
        accts=list(BASE); accts[pos]=newidx
        v=run(accts,lab)
        lg=v.get("logs") or []
        # show last interesting log line
        for l in lg[-4:]:
            if "consumed" not in l and "invoke" not in l: print("        ",l)
