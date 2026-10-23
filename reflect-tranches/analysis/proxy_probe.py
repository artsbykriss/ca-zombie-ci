#!/usr/bin/env python3
"""Probe the deployed Reflect proxy program (pRoxYU64...) instruction dispatch.
The program is Pinocchio with a 1-byte discriminator; each handler logs its name.
READ-ONLY: simulateTransaction with sigVerify=false, nothing sent."""
import json, base64, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

PROXY = Pubkey.from_string("pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C")
SYSTEM = Pubkey.from_string("11111111111111111111111111111111")
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")

def simulate(ixs, label, payer=None):
    payer = payer or Pubkey.new_unique()
    msg = Message.new_with_blockhash(ixs, payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    val = (r.get("result") or {}).get("value") or {}
    logs = [l.replace("Program log: ", "") for l in (val.get("logs") or [])
            if l.startswith("Program log: ")]
    return val.get("err"), val.get("unitsConsumed"), logs

print("=== 1-byte discriminator probe (with the program id + a fresh signer as accounts) ===")
for d in list(range(0, 16)) + [100, 101, 200, 255]:
    ix = Instruction(PROXY, bytes([d]), [
        AccountMeta(Pubkey.new_unique(), True, True),
        AccountMeta(SYSTEM, False, False),
    ])
    err, units, logs = simulate([ix], f"disc {d}")
    print(f"  disc {d:3}: err={json.dumps(err) if err else None:40} units={units} logs={logs[:2]}")
