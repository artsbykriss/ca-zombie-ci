#!/usr/bin/env python3
"""READ-ONLY auth probe for the deployed RLP program (JrXLmS6...).

Every transaction below is built with a FRESH RANDOM in-memory pubkey as the only
signer and is passed to `simulateTransaction` with sigVerify=false. Nothing is
signed and nothing is broadcast. Purpose: observe whether the deployed program
gates each privileged instruction on the caller's on-chain UserPermissions.

If a role gate is present, an unprivileged fresh signer must be rejected with a
permission error BEFORE any state change.
"""
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
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
ATA = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
PROXY = Pubkey.from_string("pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C")

def disc(n): return hashlib.sha256(("global:" + n).encode()).digest()[:8]

def pda(seeds):
    return Pubkey.find_program_address(seeds, RLP)[0]

SETTINGS = pda([b"settings"])
def permissions(a): return pda([b"permissions", bytes(a)])
def pool(i): return pda([b"liquidity_pool", bytes([i])])
def asset(m): return pda([b"asset", bytes(m)])

def simulate(ixs, label, payer=None):
    payer = payer or Pubkey.new_unique()
    msg = Message.new_with_blockhash(ixs, payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    val = (r.get("result") or {}).get("value") or {}
    print(f"\n===== {label} =====")
    print("  payer:", payer, " err:", json.dumps(val.get("err")) if val.get("err") else None,
          " units:", val.get("unitsConsumed"))
    for l in (val.get("logs") or []):
        if "Instruction:" in l or "AnchorError" in l or "failed" in l or "Error Code" in l:
            print("   ", l)
    return val

if __name__ == "__main__":
    print("SETTINGS PDA =", SETTINGS)
    print("permissions(fresh) =", permissions(Pubkey.new_unique()))

    # ---- 1. update_role_holder with a fresh unprivileged signer
    fresh = Pubkey.new_unique()
    admin_perm = permissions(fresh)
    target = Pubkey.new_unique()
    data = bytes(disc("update_role_holder")) + bytes(target) + bytes([4]) + bytes([0])  # role=CRANK, Add
    ix = Instruction(RLP, data, [
        AccountMeta(fresh, True, True),        # admin (signer)
        AccountMeta(SETTINGS, False, True),    # settings
        AccountMeta(admin_perm, False, True),  # admin_permissions
        AccountMeta(permissions(target), False, True),  # update_admin_permissions
        AccountMeta(Pubkey.new_unique(), False, True),  # strategy?
        AccountMeta(SYSTEM, False, False),
    ])
    simulate([ix], "update_role_holder(role=CRANK) by FRESH signer")

    # ---- 2. update_action_role with a fresh unprivileged signer
    data = bytes(disc("update_action_role")) + bytes([2]) + bytes([1]) + bytes([0])  # action=Slash(2), role=PUBLIC, Add
    ix = Instruction(RLP, data, [
        AccountMeta(fresh, True, True),
        AccountMeta(SETTINGS, False, True),
        AccountMeta(SYSTEM, False, False),
        AccountMeta(admin_perm, False, True),
    ])
    simulate([ix], "update_action_role(action=Slash, role=PUBLIC) by FRESH signer")

    # ---- 3. create_permission_account by a fresh signer
    new_admin = Pubkey.new_unique()
    data = bytes(disc("create_permission_account")) + bytes(new_admin)
    ix = Instruction(RLP, data, [
        AccountMeta(SETTINGS, False, False),
        AccountMeta(permissions(new_admin), False, True),
        AccountMeta(fresh, True, True),
        AccountMeta(SYSTEM, False, False),
    ])
    simulate([ix], "create_permission_account by FRESH signer")

    # ---- 4. slash by a fresh signer
    mint = Pubkey.from_string("2uxaYT1fVrp6Fg2BrxQcyKSW91hefM6dG9krpbeDiirT")
    poolta = Pubkey.from_string("7Km8GaaiThucELwFD1HRdhD7QTWN6hS3vBJEB91nYK4L")
    dest = Pubkey.new_unique()
    data = bytes(disc("slash")) + bytes([2]) + (1).to_bytes(8, "little")
    ix = Instruction(RLP, data, [
        AccountMeta(fresh, True, True),
        AccountMeta(permissions(fresh), False, True),
        AccountMeta(SETTINGS, False, True),
        AccountMeta(pool(2), False, False),
        AccountMeta(mint, False, True),
        AccountMeta(asset(mint), False, True),
        AccountMeta(poolta, False, True),
        AccountMeta(dest, False, True),
        AccountMeta(TOKEN, False, False),
    ])
    simulate([ix], "slash(pool=2, 1 unit) by FRESH signer")

    # ---- 5. freeze_functionality by a fresh signer
    data = bytes(disc("freeze_functionality")) + bytes([2]) + bytes([1])
    ix = Instruction(RLP, data, [
        AccountMeta(fresh, True, True),
        AccountMeta(SETTINGS, False, True),
        AccountMeta(SYSTEM, False, False),
        AccountMeta(admin_perm, False, True),
    ])
    simulate([ix], "freeze_functionality(action=Slash, freeze=true) by FRESH signer")

    # ---- 6. post_oracle_price by a fresh signer (no Chainlink report)
    data = bytes(disc("post_oracle_price")) + b"\x00" * 8
    ix = Instruction(RLP, data, [
        AccountMeta(fresh, True, True),
        AccountMeta(asset(mint), False, False),
        AccountMeta(Pubkey.new_unique(), False, False),
        AccountMeta(Pubkey.new_unique(), False, True),
        AccountMeta(SYSTEM, False, False),
        AccountMeta(Pubkey.from_string("Gt9S41PtjR58CbG9JhJ3J6vxesqrNAswbWYbLNTMZA3c"), False, False),
    ])
    simulate([ix], "post_oracle_price by FRESH signer")

    # ---- 7. withdraw by a fresh signer against an unrelated cooldown (pool 0)
    data = bytes(disc("withdraw")) + bytes([0]) + (0).to_bytes(8, "little")
    ix = Instruction(RLP, data, [
        AccountMeta(fresh, True, True),
        AccountMeta(SETTINGS, False, True),
        AccountMeta(permissions(fresh), False, False),
        AccountMeta(pool(0), False, True),
        AccountMeta(Pubkey.from_string("jrByePxMbHAevzMG4kjUrfMWoZ7bQYwwKJTPcq2WysG"), False, True),
        AccountMeta(Pubkey.new_unique(), False, True),
        AccountMeta(pda([b"cooldown", bytes(fresh), bytes([0]), (0).to_bytes(8, "little")]), False, True),
        AccountMeta(TOKEN, False, False),
        AccountMeta(SYSTEM, False, False),
    ])
    simulate([ix], "withdraw(pool=0, cooldown=0) by FRESH signer (no such cooldown)")
