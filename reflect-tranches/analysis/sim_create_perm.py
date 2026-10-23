#!/usr/bin/env python3
"""Probe create_permission_account (full Anchor account list incl. event_authority/program)."""
import json, base64, hashlib, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

RLP = Pubkey.from_string("JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av")
SYSTEM = Pubkey.from_string("11111111111111111111111111111111")
def disc(n): return hashlib.sha256(("global:" + n).encode()).digest()[:8]
def pda(seeds): return Pubkey.find_program_address(seeds, RLP)[0]
SETTINGS = pda([b"settings"])
EVENT_AUTH = pda([b"__event_authority"])

def simulate(ixs, label, payer=None):
    payer = payer or Pubkey.new_unique()
    msg = Message.new_with_blockhash(ixs, payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    val = (r.get("result") or {}).get("value") or {}
    print(f"\n===== {label} =====")
    print("  err:", json.dumps(val.get("err")) if val.get("err") else None, " units:", val.get("unitsConsumed"))
    for l in (val.get("logs") or []):
        if "Instruction:" in l or "AnchorError" in l or "failed" in l or "Program data" in l:
            print("   ", l)
    return val

fresh = Pubkey.new_unique()
new_admin = Pubkey.new_unique()
data = bytes(disc("create_permission_account")) + bytes(new_admin)
# try several account orderings
orders = {
    "A: settings,new_creds,caller,system,event_auth,program": [
        AccountMeta(SETTINGS, False, False), AccountMeta(pda([b"permissions", bytes(new_admin)]), False, True),
        AccountMeta(fresh, True, True), AccountMeta(SYSTEM, False, False),
        AccountMeta(EVENT_AUTH, False, False), AccountMeta(RLP, False, False)],
    "B: settings,new_creds,caller,event_auth,program,system": [
        AccountMeta(SETTINGS, False, False), AccountMeta(pda([b"permissions", bytes(new_admin)]), False, True),
        AccountMeta(fresh, True, True), AccountMeta(EVENT_AUTH, False, False),
        AccountMeta(RLP, False, False), AccountMeta(SYSTEM, False, False)],
}
for k, accs in orders.items():
    simulate([Instruction(RLP, data, accs)], k)

# Also: what does an EXISTING permissions account look like when decoded?
for pk in ["8vMwZJqC2YWYH5ixwBS4RM7EVCxqZi55YPN5XYVxk625",
           "CYsYS9JC3jyufisHDDJybjRTNdfwXxftAjiGa1EacUBY",
           "GNwSK8YpM85bd2YeJaA2BmUxGVqEe4hyCLqc8eR2PCgt"]:
    v = rpc("getAccountInfo", [pk, {"encoding": "base64"}])["result"]["value"]
    d = base64.b64decode(v["data"][0])
    print(f"\n{pk} len={len(d)}")
    print("  disc", d[:8].hex(), "bump", d[8], "authority", Pubkey.from_bytes(d[9:41]))
    print("  tail", d[41:].hex())
