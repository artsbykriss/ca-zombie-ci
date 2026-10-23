#!/usr/bin/env python3
"""Round 2: exact account lists for the RLP admin instructions, using the real SUPREMO signer
(sigVerify=false, read-only simulation)."""
import json, base64, os, sys, hashlib
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
SUPREMO = P("28sR8pmJxhtZNci3hPervkxu9f93nvHpFikbtzXoxmWA")
MANAGER = P("KuBAWM6pZ43ip8b7eB3kjJwUqdPwYpSuoCFkn4bcLgw")
def disc(n): return hashlib.sha256(("global:" + n).encode()).digest()[:8]
def pda(s): return Pubkey.find_program_address(s, RLP)[0]
SETTINGS = pda([b"settings"]); EVENT = pda([b"__event_authority"])
PERM_SUP = pda([b"permissions", bytes(SUPREMO)]); PERM_MGR = pda([b"permissions", bytes(MANAGER)])

def sim(ixs, label, signer):
    msg = Message.new_with_blockhash(ixs, signer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    r = rpc("simulateTransaction", [raw, {"encoding": "base64", "sigVerify": False,
                                          "replaceRecentBlockhash": True, "commitment": "processed"}])
    v = (r.get("result") or {}).get("value") or {}
    print(f"\n== {label}\n   err={json.dumps(v.get('err')) if v.get('err') else None} units={v.get('unitsConsumed')}")
    for l in (v.get("logs") or [])[:8]:
        if "AnchorError" in l or "Instruction:" in l or "failed" in l or "Program data" in l:
            print("    ", l.replace("Program log: ", ""))
    return v

# update_action_role with [admin, settings, system, admin_permissions, event, program]
data = bytes(disc("update_action_role")) + bytes([2, 1, 0])   # Slash -> PUBLIC, Add
sim([Instruction(RLP, data, [AccountMeta(x, i == 0, True) for i, x in enumerate(
    [SUPREMO, SETTINGS, SYSTEM, PERM_SUP, EVENT, RLP])])], "update_action_role(real SUPREMO)", SUPREMO)
sim([Instruction(RLP, data, [AccountMeta(x, i == 0, True) for i, x in enumerate(
    [MANAGER, SETTINGS, SYSTEM, PERM_MGR, EVENT, RLP])])], "update_action_role(real MANAGER)", MANAGER)

# freeze_functionality
data = bytes(disc("freeze_functionality")) + bytes([2, 1])
sim([Instruction(RLP, data, [AccountMeta(x, i == 0, True) for i, x in enumerate(
    [SUPREMO, SETTINGS, SYSTEM, PERM_SUP, EVENT, RLP])])], "freeze_functionality(real SUPREMO)", SUPREMO)

# update_role_holder against an EXISTING permissions account (MANAGER), signed by the SUPREMO
data = bytes(disc("update_role_holder")) + bytes(MANAGER) + bytes([4]) + bytes([0])  # give MANAGER CRANK
sim([Instruction(RLP, data, [AccountMeta(x, i == 0, True) for i, x in enumerate(
    [SUPREMO, SETTINGS, PERM_SUP, PERM_MGR, PERM_MGR, EVENT, RLP, SYSTEM])])],
    "update_role_holder(existing target) real SUPREMO", SUPREMO)

# slash signed by the SUPREMO against pool 0 (asset0)
POOL0 = pda([b"liquidity_pool", bytes([0])])
MINT0 = P("AvZZF1YaZDziPY2RCK4oJrRVrbN3mTD9NL24hPeaZeUj")
ASSET0 = pda([b"asset", bytes(MINT0)])
POOL0_ATA = P("Dh1sPTGc9YycHKnw5t4S1Ss24TtcoWTiD61azGSmtoS5")
DEST = P("UVw4BJXJqnVpi9Qw98KXcHNYS6ZG836ZcX8rqibTnFq")
data = bytes(disc("slash")) + bytes([0]) + (1).to_bytes(8, "little")
sim([Instruction(RLP, data, [AccountMeta(x, i == 0, True) for i, x in enumerate(
    [SUPREMO, PERM_SUP, SETTINGS, POOL0, MINT0, ASSET0, POOL0_ATA, DEST, P("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")])])],
    "slash(1 unit, pool0) real SUPREMO", SUPREMO)
