#!/usr/bin/env python3
"""Read-only simulateTransaction matrix. NO signing, NO sending."""
import base64, json, sys, hashlib
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

PROGRAM = Pubkey.from_string("par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV")
PAIR_PIKUSDC = Pubkey.from_string("EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7")
PAIR_EXSOL = Pubkey.from_string("HwsGQqoXwQjGg5CDojLTipmeYFSmovoHtk7ZFtgrxSop")
AC = Pubkey.from_string("fVo899DhvJosC7DuN2T9p5GYfsTGJqTv6TDeE97YGBe")
PAIR_AUTH = Pubkey.from_string("WYSyHasQGFCtfHb1W5pFf64YCzvMSahJgBoZei5RrwJ")  # also vault_authority
WINDOW_AUTH = Pubkey.from_string("F2x6FM19gx68ubHWxNBsJKQksM5N38QhmgYhEG7yLnHv")
DEPOSIT_AUTH = Pubkey.from_string("CpdVRBHtnDd3RbYzvESXdrAD5bhWdQNvbfLUfjJpQnTE")
# an existing, ordinary wallet (a staker seen in tx history) - system-owned, exists
ORDINARY = Pubkey.from_string("5RfcgB1KUeoUjxph7bLqLTdJ1DwbwazXQHGMeoDHoaen")
ORDINARY2 = Pubkey.from_string("CV1o9gjMKAhj9mkU7EbBxC8sbXfSZ3dDA4mzFLkTyZTY")

def disc(name): return hashlib.sha256(f"global:{name}".encode()).digest()[:8]
def u64(x): return x.to_bytes(8, "little")
def opt_u64(v): return b"\x01" + u64(v) if v is not None else b"\x00"
def opt_u16(v): return b"\x01" + v.to_bytes(2, "little") if v is not None else b"\x00"

def simulate(payer, ixs, label):
    try:
        bh = Hash.from_string(call("getLatestBlockhash", [{"commitment": "confirmed"}])["result"]["value"]["blockhash"])
        msg = Message.new_with_blockhash(ixs, payer, bh)
        tx = Transaction.populate(msg, [Signature.default()] * msg.header.num_required_signatures)
        txb64 = base64.b64encode(bytes(tx)).decode()
        r = call("simulateTransaction", [txb64, {"sigVerify": False, "replaceRecentBlockhash": True,
                                                 "encoding": "base64", "commitment": "confirmed"}])
        val = r.get("result", {})
        if "value" in val: val = val["value"]
        err = val.get("err"); logs = val.get("logs") or []
        print(f"\n##### {label}")
        print(f"   err = {json.dumps(err)}")
        for l in logs[-12:]:
            if "Program log:" in l or "invoke" in l or "failed" in l or "success" in l or "Error" in l:
                print("   ", l)
    except Exception as e:
        print(f"\n##### {label}\n   EXCEPTION {e}")

def upl_ix(authority, pair=PAIR_PIKUSDC, ac=AC):
    data = disc("update_pair_limits") + opt_u64(10_000_000_000_000) + opt_u64(None) + opt_u16(None) + opt_u16(None) + opt_u16(None)
    return Instruction(PROGRAM, data, [AccountMeta(pair, False, True), AccountMeta(authority, True, False), AccountMeta(ac, False, False)])

def upy_ix(authority, pair=PAIR_PIKUSDC, ac=AC):
    data = disc("update_pair_yield") + u64(1_000_000_000_000)
    return Instruction(PROGRAM, data, [AccountMeta(pair, False, True), AccountMeta(authority, True, False), AccountMeta(ac, False, False)])

print("=== update_pair_limits substitution matrix ===")
simulate(PAIR_AUTH, [upl_ix(PAIR_AUTH)], "T1 control: real pair_authority signer, real AC")
simulate(ORDINARY, [upl_ix(ORDINARY)], "T2 authority=ordinary wallet signer, real AC")
simulate(ORDINARY, [upl_ix(ORDINARY, ac=ORDINARY)], "T3 authority=ordinary, AC=ordinary(not program-owned)")
simulate(ORDINARY, [upl_ix(ORDINARY, ac=PAIR_AUTH)], "T4 authority=ordinary, AC=pair_authority acct(system-owned)")
simulate(PAIR_AUTH, [upl_ix(PAIR_AUTH, ac=PAIR_AUTH)], "T5 real authority, AC=pair_authority acct(system-owned)")
simulate(PAIR_AUTH, [upl_ix(PAIR_AUTH, pair=PAIR_EXSOL)], "T6 real authority, pair=exSOL pair (seeds ok)")

print("\n=== update_pair_yield substitution matrix ===")
simulate(ORDINARY, [upy_ix(ORDINARY)], "T7 authority=ordinary signer, real AC")
simulate(ORDINARY, [upy_ix(ORDINARY, ac=ORDINARY)], "T8 authority=ordinary, AC=ordinary")
