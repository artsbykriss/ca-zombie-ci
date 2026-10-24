#!/usr/bin/env python3
"""Read-only simulateTransaction matrix #2. NO signing, NO sending."""
import base64, json, sys, hashlib, struct
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call, get_account
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from solders.message import Message
from solders.transaction import Transaction
from solders.hash import Hash
from solders.signature import Signature

PROGRAM = Pubkey.from_string("par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV")
PAIR = Pubkey.from_string("EwqMpnBHKEd537E37kcsNU9Qi82uukjVAXsC8K5Kswt7")
PAIR_EXSOL = Pubkey.from_string("HwsGQqoXwQjGg5CDojLTipmeYFSmovoHtk7ZFtgrxSop")
AC = Pubkey.from_string("fVo899DhvJosC7DuN2T9p5GYfsTGJqTv6TDeE97YGBe")
PAIR_AUTH = Pubkey.from_string("WYSyHasQGFCtfHb1W5pFf64YCzvMSahJgBoZei5RrwJ")
WINDOW_AUTH = Pubkey.from_string("F2x6FM19gx68ubHWxNBsJKQksM5N38QhmgYhEG7yLnHv")
DEPOSIT_AUTH = Pubkey.from_string("CpdVRBHtnDd3RbYzvESXdrAD5bhWdQNvbfLUfjJpQnTE")
UNSEAL_AUTH = Pubkey.from_string("DY9GqHNXBRxyS2cM4x8DasUwpRXzU2GDo2LFAefAjDkK")
GUARDIAN = Pubkey.from_string("AZWrrrLqpoP8Eq1vw3bNaGJuau9E4P5kqqrB1jfhxJZ5")
ORDINARY = Pubkey.from_string("5RfcgB1KUeoUjxph7bLqLTdJ1DwbwazXQHGMeoDHoaen")
USDC = Pubkey.from_string("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
LST = Pubkey.from_string("8B9vL4c9w5HiyFXdPT8Z8hgFvSeZ14Y5DxjCZyRSTf4z")
FEE = Pubkey.from_string("Bw4N68gHwCJGewLdaBfQToHtKhVcMBRvNhkRxa5ZPV17")
PAIR_USDC_ACCT = Pubkey.from_string("67f3oEHTLfkBcShmgtivVT5gzqVYrJ9HMP6oCRhS3n7Y")
TOKEN = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
ATA_P = Pubkey.from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
SYS = Pubkey.from_string("11111111111111111111111111111111")
PRICE_FEED = Pubkey.from_string("7UVimffxr9ow1uXYxsr4LHAcV58mLzhmwaeKvJ1pjLiE")
# an active window for pikUSDC (from windows.json)
WIN_PIKUSDC = Pubkey.from_string("BxYp8eSwBFdQg6snYCc8akbCSaiBSFQMruC1DwpDCbEN")

def disc(n): return hashlib.sha256(f"global:{n}".encode()).digest()[:8]
def u64(x): return x.to_bytes(8,"little")

def sim(payer, ixs, label):
    try:
        bh = Hash.from_string(call("getLatestBlockhash",[{"commitment":"confirmed"}])["result"]["value"]["blockhash"])
        msg = Message.new_with_blockhash(ixs, payer, bh)
        tx = Transaction.populate(msg, [Signature.default()]*msg.header.num_required_signatures)
        r = call("simulateTransaction",[base64.b64encode(bytes(tx)).decode(),
                 {"sigVerify":False,"replaceRecentBlockhash":True,"encoding":"base64","commitment":"confirmed"}])
        val = r.get("result",{})
        if "value" in val: val = val["value"]
        err = val.get("err"); logs = val.get("logs") or []
        print(f"\n##### {label}\n   err = {json.dumps(err)}")
        for l in logs:
            if "Program log:" in l or "failed" in l or "success" in l:
                print("   ", l)
    except Exception as e:
        print(f"\n##### {label}\n   EXCEPTION {e}")

# ---- seal_program (guardian) ----
def seal_ix(signer, ac=AC):
    return Instruction(PROGRAM, disc("seal_program"), [AccountMeta(signer,True,False), AccountMeta(ac,False,True)])
sim(GUARDIAN, [seal_ix(GUARDIAN)], "seal_program CONTROL: real guardian signer")
sim(ORDINARY, [seal_ix(ORDINARY)], "seal_program ATTACKER: ordinary signer")

# ---- vault_withdraw ----
def vault_withdraw_ix(authority):
    return Instruction(PROGRAM, disc("vault_withdraw")+u64(1), [
        AccountMeta(PAIR,False,False), AccountMeta(authority,True,True), AccountMeta(AC,False,False),
        AccountMeta(PAIR_USDC_ACCT,True,False), AccountMeta(ORDINARY,True,True), AccountMeta(USDC,False,False),
        AccountMeta(ATA_P,False,False), AccountMeta(TOKEN,False,False), AccountMeta(SYS,False,False)])
sim(PAIR_AUTH, [vault_withdraw_ix(PAIR_AUTH)], "vault_withdraw CONTROL: real vault_authority")
sim(ORDINARY, [vault_withdraw_ix(ORDINARY)], "vault_withdraw ATTACKER: ordinary signer")

# ---- fund_withdrawal_window ----
def fund_ix(signer):
    return Instruction(PROGRAM, disc("fund_withdrawal_window"), [
        AccountMeta(AC,False,False), AccountMeta(PAIR,False,False), AccountMeta(WIN_PIKUSDC,True,False),
        AccountMeta(signer,True,True), AccountMeta(ORDINARY,True,False), AccountMeta(ORDINARY,True,False),
        AccountMeta(USDC,False,False), AccountMeta(TOKEN,False,False)])
sim(DEPOSIT_AUTH, [fund_ix(DEPOSIT_AUTH)], "fund_withdrawal_window CONTROL: real deposit_authority")
sim(ORDINARY, [fund_ix(ORDINARY)], "fund_withdrawal_window ATTACKER: ordinary signer")

# ---- create_withdrawal_window ----
def cww_ix(authority):
    # params: start,end,ewt,exp,max
    import time
    now = 1792879903
    data = disc("create_withdrawal_window") + struct.pack("<qqqqQ", now+600, now+90000, now+100000, now+1000000, 10**12)
    return Instruction(PROGRAM, data, [
        AccountMeta(PAIR,False,False), AccountMeta(authority,True,True), AccountMeta(AC,False,False),
        AccountMeta(ORDINARY,True,True), AccountMeta(USDC,False,False), AccountMeta(LST,False,False)])
sim(WINDOW_AUTH, [cww_ix(WINDOW_AUTH)], "create_withdrawal_window CONTROL: real window_authority")
sim(ORDINARY, [cww_ix(ORDINARY)], "create_withdrawal_window ATTACKER: ordinary signer")

# ---- withdraw_fees : SystemAccount destination_owner -> try 3010 ----
def wf_ix(vault_auth, dest_owner):
    return Instruction(PROGRAM, disc("withdraw_fees")+u64(1), [
        AccountMeta(AC,False,False), AccountMeta(PAIR,False,False), AccountMeta(LST,False,False),
        AccountMeta(FEE,True,False), AccountMeta(ORDINARY,True,True), AccountMeta(dest_owner,False,False),
        AccountMeta(vault_auth,True,True), AccountMeta(TOKEN,False,False), AccountMeta(ATA_P,False,False), AccountMeta(SYS,False,False)])
sim(PAIR_AUTH, [wf_ix(PAIR_AUTH, ORDINARY)], "withdraw_fees CONTROL dest_owner=ordinary(system-owned)")
sim(PAIR_AUTH, [wf_ix(PAIR_AUTH, AC)], "withdraw_fees dest_owner=access_control PDA (program-owned) -> expect 3010")
sim(ORDINARY, [wf_ix(ORDINARY, ORDINARY)], "withdraw_fees ATTACKER: ordinary signer")

# ---- update_pair_limits: substitute pair with AC (program-owned wrong disc) ----
def upl_ix(authority, pair=PAIR, ac=AC):
    data = disc("update_pair_limits") + b"\x01"+u64(10**13) + b"\x00\x00\x00\x00"
    return Instruction(PROGRAM, data, [AccountMeta(pair,False,True), AccountMeta(authority,True,False), AccountMeta(ac,False,False)])
sim(PAIR_AUTH, [upl_ix(PAIR_AUTH, pair=AC)], "update_pair_limits pair=access_control PDA (program-owned, wrong disc)")
sim(PAIR_AUTH, [upl_ix(PAIR_AUTH, pair=ORDINARY)], "update_pair_limits pair=ordinary system acct")
