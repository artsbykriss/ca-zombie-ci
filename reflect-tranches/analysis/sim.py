#!/usr/bin/env python3
"""READ-ONLY instruction-dispatch probe.

Builds transactions with a FRESH RANDOM signer and simulated (never sent) via
`simulateTransaction` with sigVerify=false. Used to (a) confirm Anchor
discriminators empirically from the program's own 'Instruction: <Name>' logs and
(b) observe the auth outcome of each instruction for an unprivileged caller.

No transaction is ever signed or broadcast; no private key is used.
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
PROXY = Pubkey.from_string("pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C")
SYSTEM = Pubkey.from_string("11111111111111111111111111111111")

def disc(name):
    return hashlib.sha256(("global:" + name).encode()).digest()[:8]

def simulate(ixs, payer, label, extra_meta=None, sigverify=False):
    metas = [AccountMeta(payer, True, True)]
    msg = Message.new_with_blockhash(ixs, payer, Hash.default())
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    raw = base64.b64encode(bytes(tx)).decode()
    cfg = {"encoding": "base64", "sigVerify": sigverify, "replaceRecentBlockhash": True,
           "commitment": "processed"}
    r = rpc("simulateTransaction", [raw, cfg])
    val = (r.get("result") or {}).get("value") or {}
    logs = val.get("logs") or []
    print(f"\n===== {label} =====")
    print("  err:", json.dumps(val.get("err"))[:200] if val.get("err") else None,
          "units:", val.get("unitsConsumed"))
    for l in logs:
        if "Instruction:" in l or "Instruction " in l or "failed" in l.lower() or "Error" in l or "error" in l:
            print("   ", l)
    return val, logs

def probe_dispatch(names, program, label):
    """Send disc-only instructions and read the program's own dispatch log."""
    print(f"\n########## DISPATCH PROBE {label} ##########")
    for n in names:
        ix = Instruction(program, disc(n), [])
        # one account so the tx is well-formed
        payer = Pubkey.new_unique()
        val, logs = simulate([ix], payer, f"{n} (disc {disc(n).hex()})")
        got = [l for l in logs if "Instruction:" in l or "Instruction " in l]
        print("   ->", got)

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "probe"
    if mode == "probe":
        names = ["initialize_rlp", "initialize_lp", "initialize_pool_reserve", "add_asset",
                 "update_deposit_cap", "slash", "deposit", "restake", "request_withdrawal",
                 "withdraw", "migrate_cooldown", "swap", "create_permission_account",
                 "update_action_role", "update_role_holder", "migrate_asset", "update_oracle",
                 "post_oracle_price", "force_remove_asset", "freeze_functionality",
                 "deposit_rewards"]
        probe_dispatch(names, RLP, "RLP")
