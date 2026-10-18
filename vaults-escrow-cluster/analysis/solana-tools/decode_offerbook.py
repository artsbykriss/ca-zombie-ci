#!/usr/bin/env python3
"""Decode Offerbook zero-copy accounts from raw getProgramAccounts output."""
import base64, json, struct
from base58 import b58encode

def p(b): return b58encode(b).decode()

def u64(d,o): return struct.unpack_from("<Q", d, o)[0]
def u32(d,o): return struct.unpack_from("<I", d, o)[0]
def u16(d,o): return struct.unpack_from("<H", d, o)[0]

def asset(d, o):
    tag = d[o]
    if tag == 1:
        return {"kind":"token","mint":p(d[o+1:o+33]),"token_program":p(d[o+33:o+65])}
    return {"kind":tag}

def decode_offer(d):
    return {
        "creator": p(d[8:40]),
        "side": d[40], "status": d[41],
        "principal": asset(d,48),
        "collateral": asset(d,320),
        "filter_kind": d[592],
        "principal_amount": u64(d,864),
        "remaining_principal": u64(d,872),
        "collateral_amount": u64(d,880),
        "remaining_collateral": u64(d,888),
        "apy": u32(d,904), "duration": u32(d,908),
        "created_at": u64(d,912), "expired_at": u64(d,920), "updated_at": u64(d,928),
        "min_fill_amount": u64(d,936), "fill_counter": u64(d,944),
        "allow_partial_fill": d[952], "bump": d[953], "allow_extend": d[954],
        "countered_offer": p(d[960:992]),
    }

def decode_loan(d):
    return {
        "lender": p(d[8:40]), "borrower": p(d[40:72]), "creator": p(d[72:104]),
        "offer": p(d[104:136]),
        "status": d[136], "loan_type": d[137], "fill_index": u64(d,144),
        "principal": asset(d,152), "collateral": asset(d,424),
        "apy": u32(d,696), "duration": u32(d,700),
        "principal_amount": u64(d,704), "collateral_amount": u64(d,712),
        "interest": u64(d,720), "created_at": u64(d,728),
        "expired_at": u64(d,736), "updated_at": u64(d,744),
        "bump": d[752], "collateral_account_bump": d[753],
        "extendable": d[754], "extension_count": d[755],
    }

def decode_user(d):
    return {"owner": p(d[8:40]), "referrer": p(d[40:72]),
            "referral_count": u64(d,72), "offer_count": u64(d,80),
            "total_lender_loans": u64(d,88), "total_borrower_loans": u64(d,96),
            "total_lender_liquidations": u64(d,104), "total_borrower_liquidations": u64(d,112),
            "updated_at": u64(d,120), "created_at": u64(d,128), "bump": d[136]}

def decode_config(d):
    return {"admin": p(d[8:40]), "fee_authority": p(d[40:72]),
            "config_bump": d[72], "fee_authority_bump": d[73],
            "interest_fee_bps": u16(d,80), "repay_fee_bps": u16(d,82),
            "liquidation_fee_bps": u16(d,84), "referral_rewards_fee_bps": u16(d,86),
            "referee_rewards_fee_bps": u16(d,88),
            "min_principal_amount": u64(d,96), "min_collateral_amount": u64(d,104),
            "min_duration": u32(d,112), "min_expiry": u32(d,116), "max_apy": u32(d,120),
            "max_duration": u32(d,124), "max_expiry": u32(d,128),
            "is_paused": d[132], "disable_repayment": d[133]}

def load(path):
    j = json.load(open(path))
    out = {}
    for x in j["accounts"]:
        out[x["pubkey"]] = base64.b64decode(x["account"]["data"][0])
    return j["slot"], out
