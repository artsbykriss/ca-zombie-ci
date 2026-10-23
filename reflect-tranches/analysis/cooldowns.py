#!/usr/bin/env python3
"""Decode the live RLP Cooldown accounts and test whether an unrelated fresh signer
can call `withdraw` on them (READ-ONLY simulateTransaction, sigVerify=false)."""
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
COOLDOWN_DISC = bytes.fromhex("32a65ec0ea4098d0")
def disc(n): return hashlib.sha256(("global:" + n).encode()).digest()[:8]
def pda(seeds): return Pubkey.find_program_address(seeds, RLP)[0]
SETTINGS = pda([b"settings"])

r = rpc("getProgramAccounts", [str(RLP), {"encoding": "base64",
        "filters": [{"memcmp": {"offset": 0, "bytes": b58e(COOLDOWN_DISC)}}]}])
cooldowns = []
for a in r["result"]:
    d = base64.b64decode(a["account"]["data"][0])
    cooldowns.append((a["pubkey"], d))

print("cooldown count:", len(cooldowns))
# try to decode: disc(8) then fields; print offsets of the repeating pubkey
for pk, d in cooldowns[:3]:
    print("\n", pk, "len", len(d))
    print("  ", d.hex())
    # locate the repeated 32-byte pubkey
    known = bytes.fromhex("793f98166734fd7c317b1def48808693a9349317c4dff38eb249d3246f113ffd")
    print("   pubkey at", d.find(known))
# dump all with offsets of the common pubkey
print("\nall cooldowns:")
for pk, d in cooldowns:
    known = bytes.fromhex("793f98166734fd7c317b1def48808693a9349317c4dff38eb249d3246f113ffd")
    off = d.find(known)
    print(f"  {pk} len={len(d)} pubkey@ {off}  u64@8={int.from_bytes(d[8:16],'little')}")
json.dump([{"pubkey": p, "hex": d.hex()} for p, d in cooldowns],
          open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cooldowns.json"), "w"), indent=2)
