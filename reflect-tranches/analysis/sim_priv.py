#!/usr/bin/env python3
"""Use the REAL privileged signers with sigVerify=false (read-only simulation) to walk each
privileged instruction past the role gate and expose its full account list."""
import json, base64, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

P = Pubkey.from_string
RLP = P("JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av")
SYSTEM = P("11111111111111111111111111111111")
TOKEN = P("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
SUPREMO = P("28sR8pmJxhtZNci3hPervkxu9f93nvHpFikbtzXoxmWA")
MANAGER = P("KuBAWM6pZ43ip8b7eB3kjJwUqdPwYpSuoCFkn4bcLgw")
def disc(n):
    import hashlib
    return hashlib.sha256(("global:" + n).encode()).digest()[:8]
def pda(seeds):
    return Pubkey.find_program_address(seeds, RLP)[0]
SETTINGS = pda([b"settings"])
EVENT = pda([b"__event_authority"])
PERM_SUP = pda([b"permissions", bytes(SUPREMO)])
PERM_MGR = pda([b"permissions", bytes(MANAGER)])

def sim(ixs, label, signer):
    msg = Message.new_with_blockhash(ixs, signer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    v = (r.get("result") or {}).get("value") or {}
    print(f"\n== {label}\n   err={json.dumps(v.get('err')) if v.get('err') else None} units={v.get('unitsConsumed')}")
    for l in (v.get("logs") or [])[:8]:
        if "AnchorError" in l or "Instruction:" in l or "failed" in l:
            print("    ", l.replace("Program log: ", ""))
    return v

# update_role_holder: try account-list variants with the real SUPREMO signing
target = Pubkey.new_unique()
tperm = pda([b"permissions", bytes(target)])
base_data = bytes(disc("update_role_holder")) + bytes(target) + bytes([4]) + bytes([0])
variants = {
 "A admin,settings,admin_perm,update_perm,strategy,system": [SUPREMO, SETTINGS, PERM_SUP, tperm, tperm, SYSTEM],
 "B admin,settings,admin_perm,update_perm,event,program,system": [SUPREMO, SETTINGS, PERM_SUP, tperm, EVENT, RLP, SYSTEM],
 "C admin,settings,admin_perm,update_perm,event,program": [SUPREMO, SETTINGS, PERM_SUP, tperm, EVENT, RLP],
 "D admin,settings,update_perm,admin_perm,event,program": [SUPREMO, SETTINGS, tperm, PERM_SUP, EVENT, RLP],
}
for k, accs in variants.items():
    sim([Instruction(RLP, base_data, [AccountMeta(x, i == 0, True) for i, x in enumerate(accs)])],
        f"update_role_holder {k}", SUPREMO)

# update_action_role
data = bytes(disc("update_action_role")) + bytes([2, 1, 0])
for k, accs in {
 "A admin,settings,system,admin_perm": [SUPREMO, SETTINGS, SYSTEM, PERM_SUP],
 "B admin,settings,admin_perm,system,event,program": [SUPREMO, SETTINGS, PERM_SUP, SYSTEM, EVENT, RLP],
 "C admin,settings,admin_perm,event,program,system": [SUPREMO, SETTINGS, PERM_SUP, EVENT, RLP, SYSTEM],
}.items():
    sim([Instruction(RLP, data, [AccountMeta(x, i == 0, True) for i, x in enumerate(accs)])],
        f"update_action_role {k}", SUPREMO)

# freeze_functionality
data = bytes(disc("freeze_functionality")) + bytes([2, 1])
for k, accs in {
 "A admin,settings,system,admin_perm": [SUPREMO, SETTINGS, SYSTEM, PERM_SUP],
 "B admin,settings,admin_perm,system,event,program": [SUPREMO, SETTINGS, PERM_SUP, SYSTEM, EVENT, RLP],
 "C admin,settings,admin_perm,event,program": [SUPREMO, SETTINGS, PERM_SUP, EVENT, RLP],
}.items():
    sim([Instruction(RLP, data, [AccountMeta(x, i == 0, True) for i, x in enumerate(accs)])],
        f"freeze_functionality {k}", SUPREMO)
