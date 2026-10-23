#!/usr/bin/env python3
"""Simulate the oracle 071f push and diff the oracle-owned accounts (feed/weights)
against their live on-chain state. Read-only (simulateTransaction, sigVerify=false)."""
import json,base64,sys,os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc
from sim_oracle import build_oracle_ix, KEYS, IX_ACCTS, WRITABLE
from solders.pubkey import Pubkey
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

def sim(ixs,payer,out):
    msg=Message.new_with_blockhash(ixs,payer,Hash.default())
    tx=Transaction.populate(msg,[Signature.default()]*msg.header.num_required_signatures)
    raw=base64.b64encode(bytes(tx)).decode()
    cfg={"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed",
         "accounts":{"encoding":"base64","addresses":out}}
    return rpc("simulateTransaction",[raw,cfg])

def onchain(addrs):
    r=rpc("getMultipleAccounts",[addrs,{"encoding":"base64"}])
    return [base64.b64decode(v["data"][0]) if v and v.get("data") else None for v in r["result"]["value"]]

if __name__=="__main__":
    idx=int(sys.argv[1]) if len(sys.argv)>1 else 0
    # oracle-owned accounts in this instruction
    feed=KEYS[IX_ACCTS[idx][0]]; wght=KEYS[IX_ACCTS[idx][1]]
    ex_accts=[KEYS[3],KEYS[8]] if idx==0 else ([KEYS[11],KEYS[13]] if idx==1 else [KEYS[1],KEYS[6]])
    out=[feed,wght]+ex_accts
    before=onchain(out)
    r=sim([build_oracle_ix(idx)],Pubkey.from_string(KEYS[0]),out)
    v=r["result"]["value"]
    print(f"ix{idx} err={v['err']} cu={v['unitsConsumed']}")
    for i,a in enumerate(v.get("accounts") or []):
        post=base64.b64decode(a["data"][0]) if a.get("data") else b""
        pre=before[i] or b""
        diffs=[j for j in range(max(len(pre),len(post))) if (pre[j:j+1]!=post[j:j+1])]
        print(f"  {out[i]} prelen={len(pre)} postlen={len(post)} ndiff={len(diffs)}")
        if diffs and len(diffs)<80:
            for j in diffs[:40]:
                print(f"      off {j}: {pre[j:j+1].hex() or '--'} -> {post[j:j+1].hex() or '--'}")
        elif diffs:
            print(f"      first diffs at {diffs[:20]}")
        # if small, print full
        if len(post)<=200: print("      pre :",pre.hex()); print("      post:",post.hex())
