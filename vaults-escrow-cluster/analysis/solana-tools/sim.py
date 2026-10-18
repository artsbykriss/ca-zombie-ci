#!/usr/bin/env python3
"""Read-only simulateTransaction helper (never sends). Uses solders for serialization."""
import base64, json
from solders.instruction import Instruction, AccountMeta
from solders.pubkey import Pubkey
from solders.hash import Hash
from solders.message import Message
from solders.transaction import Transaction
import rpc, pda

PROGRAM = "offerbkFMvVfpQhL8ZQ5iromnjct5rz3r52B9ewu3ie"
PID = pda.b58decode(PROGRAM)
EVENT_AUTH = pda.find_program_address([b"__event_authority"], PID)[0]

def simulate(ixs, payer, commitment="confirmed"):
    """ixs: list of {programId, accounts:[(pubkey,isSigner,isWritable)], data:bytes}"""
    bh = Hash.from_string(rpc.rpc("getLatestBlockhash", [{"commitment": commitment}])["value"]["blockhash"])
    sol_ixs = []
    payer_pk = Pubkey.from_string(payer)
    for ix in ixs:
        metas = [AccountMeta(Pubkey.from_string(a[0]), a[1], a[2]) for a in ix["accounts"]]
        sol_ixs.append(Instruction(Pubkey.from_string(ix["programId"]), ix["data"], metas))
    msg = Message.new_with_blockhash(sol_ixs, payer_pk, bh)
    tx = Transaction.new_unsigned(msg)
    b64 = base64.b64encode(bytes(tx)).decode()
    return rpc.rpc("simulateTransaction", [b64, {
        "encoding": "base64", "sigVerify": False, "replaceRecentBlockhash": True,
        "commitment": commitment, "innerInstructions": True,
    }])

def ix(program, accounts, data):
    return {"programId": program, "accounts": accounts, "data": data}
