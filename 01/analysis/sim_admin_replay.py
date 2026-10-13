#!/usr/bin/env python3
"""Replay admin/crank instructions with a FRESH signer to test authority gates."""
import json, urllib.request, time, base64
from solders.transaction import VersionedTransaction, Transaction
from solders.message import Message
from solders.pubkey import Pubkey
from solders.hash import Hash

RPC = "https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=5, timeout=120):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(1.2*(i+1))
    raise RuntimeError(str(last))

TXS = {
 "FinalizeWinddown": "3a9JuSEioZ1zRFCCxTGbduKJAGRjRAMhuMPbm6nCzTGA4GUCoRMTZez8e2GmiWjRm9wYA65sBUQT2zxuCCASqBCq",
 "InitWinddownBook": "5UJkZsUv192LK5UCcpiaL7h4FBKnh6MJ8cCDsgrM5soDq24oTLquY6JZPSgDk2GDRWZGCCoWiSKQSYTHZjViYgYe",
 "SetManualRatesAndOverrides": "3xCzkhfuBR2uxwy5DkvARfdhMWXykEBj8XnVuWMxqNBzBtc6PuXGK6Nri9FXQPn72t7XRJwtyxEFtLHSeqCBtyF2",
 "SettleCollateral": "JxspRge1tfXE9WkSjL3VcJBWKFQHcWUirQriY9k6iJwv4rMEgbCFRxx3FqqUdFibTBLkUWMjcoZk7B9NAcqH7vB",
 "CacheOracle_2025": "3cVaCkxjMKvTUHUD8X6B4y1MkVvqZJWPLpFq2sVhRZBHTAWRKvc7mbqyPRPmLbJt7j7a1HbqTkuxgeE7ZfF1JZzX",
}

def sim_tx(tx_bytes,label):
    b64=base64.b64encode(bytes(tx_bytes)).decode()
    r=rpc("simulateTransaction",[b64,{"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"processed"}])
    v=r["result"]["value"]
    logs=v.get("logs") or []
    print(f"\n### {label}\n  err: {json.dumps(v.get('err'))}")
    for l in logs[:40]:
        if "AnchorError" in l or "Instruction:" in l or "failed" in l.lower() or "Result" in l or "consumed" in l:
            print("   log:",l[:190])
    return {"label":label,"err":v.get("err"),"logs":logs}

results=[]
for name,sig in TXS.items():
    try:
        r=rpc("getTransaction",[sig,{"encoding":"base64","maxSupportedTransactionVersion":0}])
        res=r.get("result")
        if not res:
            print(f"{name}: tx not found"); continue
        raw=base64.b64decode(res["transaction"][0])
        tx=VersionedTransaction.from_bytes(raw)
        msg=tx.message
        keys=list(msg.account_keys)
        # original signer index 0
        orig_signer=str(keys[0])
        FRESH=Pubkey.new_unique()
        keys[0]=FRESH
        new_msg=Message.new_with_compiled_instructions(
            msg.header.num_required_signatures,
            msg.header.num_readonly_signed_accounts,
            msg.header.num_readonly_unsigned_accounts,
            keys, Hash.default(), list(msg.instructions))
        new_tx=Transaction.new_unsigned(new_msg)
        # control: replay as-is
        results.append(sim_tx(tx,f"{name} AS-IS (orig signer {orig_signer[:8]}..)"))
        results.append(sim_tx(new_tx,f"{name} FRESH SIGNER"))
    except Exception as e:
        print(f"{name}: ERROR {e}")
    time.sleep(0.3)
json.dump(results,open("analysis/sim_admin_replay.json","w"),indent=1,default=str)
print("\nDONE")
