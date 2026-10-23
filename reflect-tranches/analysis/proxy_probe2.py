#!/usr/bin/env python3
"""Probe proxy discriminators 6..20, 100, 101 with a real existing payer + 12 accounts."""
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
REAL = Pubkey.from_string("pRiCEzwgkSi7KTsQHdyfuRbPEuCFoK9sA5QVn2hvABV")

def simulate(ix, label, payer=REAL, n=12):
    accs = [AccountMeta(payer, True, True)] + [AccountMeta(PROXY if i % 2 else SYSTEM, False, i % 3 == 0) for i in range(n - 1)]
    ix = Instruction(PROXY, ix, accs)
    msg = Message.new_with_blockhash([ix], payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    val = (r.get("result") or {}).get("value") or {}
    logs = [l.replace("Program log: ", "") for l in (val.get("logs") or []) if l.startswith("Program log: ")]
    print(f"  disc {label:3}: err={json.dumps(val.get('err')) if val.get('err') else None:45} logs={logs[:3]}")

for d in list(range(6, 25)) + [100, 101]:
    simulate(bytes([d]), d)
