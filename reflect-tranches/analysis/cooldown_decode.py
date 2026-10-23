#!/usr/bin/env python3
"""Decode Cooldown fields and test `withdraw` auth for an unrelated fresh signer."""
import sys, os, json, base64, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc, b58e
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

RLP = Pubkey.from_string("JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av")
SYSTEM = Pubkey.from_string("11111111111111111111111111111111")
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
ATA_PROG = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
def disc(n): return hashlib.sha256(("global:" + n).encode()).digest()[:8]
def pda(seeds): return Pubkey.find_program_address(seeds, RLP)[0]
SETTINGS = pda([b"settings"])

cools = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cooldowns.json")))
# decode fields of each
print("=== decoded Cooldown fields (heuristic) ===")
for c in cools[:6]:
    d = bytes.fromhex(c["hex"])
    print(f"\n{c['pubkey']}")
    print("  disc", d[:8].hex(), "byte8", d[8], "u64[9:17]", int.from_bytes(d[9:17], "little"))
    print("  [17:49] pubkey", Pubkey.from_bytes(d[17:49]))
    print("  byte49", d[49], "u64[50:58]", int.from_bytes(d[50:58], "little"))
    print("  rest", d[58:].hex())

# find escrow LP token accounts owned by each cooldown PDA
print("\n=== escrow token accounts per cooldown ===")
for c in cools:
    r = rpc("getTokenAccountsByOwner", [c["pubkey"], {"programId": str(TOKEN)}, {"encoding": "jsonParsed"}])
    tas = r.get("result", {}).get("value", [])
    for a in tas:
        info = a["account"]["data"]["parsed"]["info"]
        print(f"  {c['pubkey']} -> {a['pubkey']} mint={info['mint']} amount={info['tokenAmount']['uiAmountString']}")
    if not tas:
        print(f"  {c['pubkey']} -> (no token accounts)")

def simulate(ixs, label, payer=None):
    payer = payer or Pubkey.new_unique()
    msg = Message.new_with_blockhash(ixs, payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    val = (r.get("result") or {}).get("value") or {}
    print(f"\n===== {label} =====")
    print("  err:", json.dumps(val.get("err")) if val.get("err") else None, " units:", val.get("consumed") or val.get("unitsConsumed"))
    for l in (val.get("logs") or []):
        if "Instruction:" in l or "AnchorError" in l or "failed" in l or "Error Code" in l:
            print("   ", l)
    return val
