#!/usr/bin/env python3
"""Fetch + decode the Phase Delegation (ex-AeroPool) stake pool state.

Pool:            aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6
Validator list:  aero4efZ7zHhWpqXQj4Uqw59koxj8KXqMCPUuvmhgUQ
Pool mint:       aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF
Owner (program): SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy  (canonical SPL Stake Pool)

Read-only. Writes raw base64 dumps + a decoded JSON to ./.
"""
import base64, json, sys, time
from rpc import rpc, get_account, b58dec, b58enc, pk, u64, slot

POOL = "aero2ePURjuEgLKTzcUmF6RypBncBGd7pMUYCoSsVJ6"
VLIST = "aero4efZ7zHhWpqXQj4Uqw59koxj8KXqMCPUuvmhgUQ"
MINT = "aeroXvCT6tjGVNyTvZy86tFDwE4sYsKCh7FbNDcrcxF"
PROGRAM = "SPoo1Ku8WFXoNDMHPsrGSTSG1Y47rzgn41SLUNakuHy"
MANAGER = "QocTiqKmq654c5hxBitSUD7UKZH7JMzjkcNHeh917wk"
DEPOSIT_AUTH = "4Y6XeEZ2Dg2zXU9NJgdmAG9xpwAsNusLReSTLzJxtZJ8"
MANAGER_FEE = "vFmEFGCZV7vCYPN85Wzp3f4so8LiH7gxPTLYrbHyEBZ"

def opt_pubkey(b, off):
    tag = b[off]
    if tag == 0:
        return None, off + 1
    return pk(b[off+1:off+33]), off + 33

def fee(b, off):
    return {"numerator": u64(b[off:off+8]), "denominator": u64(b[off+8:off+16])}, off + 16

def decode_pool(b):
    d = {}
    off = 0
    d["account_type"] = b[off]; off += 1
    d["manager"] = pk(b[off:off+32]); off += 32
    d["staker"] = pk(b[off:off+32]); off += 32
    d["stake_deposit_authority"] = pk(b[off:off+32]); off += 32
    d["stake_withdraw_bump_seed"] = b[off]; off += 1
    d["validator_list"] = pk(b[off:off+32]); off += 32
    d["reserve_stake"] = pk(b[off:off+32]); off += 32
    d["pool_mint"] = pk(b[off:off+32]); off += 32
    d["manager_fee_account"] = pk(b[off:off+32]); off += 32
    d["token_program_id"] = pk(b[off:off+32]); off += 32
    d["total_lamports"] = u64(b[off:off+8]); off += 8
    d["pool_token_supply"] = u64(b[off:off+8]); off += 8
    d["last_update_epoch"] = u64(b[off:off+8]); off += 8
    d["lockup"] = {"unix_timestamp": int.from_bytes(b[off:off+8],"little",signed=True),
                   "epoch": u64(b[off+8:off+16]), "custodian": pk(b[off+16:off+48])}; off += 48
    d["epoch_fee"], off = fee(b, off)
    d["next_epoch_fee"], off = fee(b, off)
    d["preferred_deposit_validator_vote_address"], off = opt_pubkey(b, off)
    d["preferred_withdraw_validator_vote_address"], off = opt_pubkey(b, off)
    d["stake_deposit_fee"], off = fee(b, off)
    d["stake_withdrawal_fee"], off = fee(b, off)
    d["next_stake_withdrawal_fee"], off = fee(b, off)
    d["stake_referral_fee"] = b[off]; off += 1
    d["sol_deposit_authority"], off = opt_pubkey(b, off)
    d["sol_deposit_fee"], off = fee(b, off)
    d["sol_referral_fee"] = b[off]; off += 1
    d["sol_withdraw_authority"], off = opt_pubkey(b, off)
    d["sol_withdrawal_fee"], off = fee(b, off)
    d["next_sol_withdrawal_fee"], off = fee(b, off)
    d["last_epoch_fee"], off = fee(b, off)
    d["next_epoch_fee_2"], off = fee(b, off)
    d["_decoded_upto"] = off
    d["_total_len"] = len(b)
    d["_tail_hex"] = b[off:].hex()
    return d

def decode_vlist(b):
    d = {}
    off = 0
    d["account_type"] = b[off]; off += 1
    d["max_validators"] = u64(b[off:off+4]); off += 4
    n = u64(b[off:off+4]); off += 4
    d["num_validators"] = n
    vals = []
    for i in range(n):
        v = {}
        v["vote_account_address"] = pk(b[off:off+32]); off += 32
        v["stake_rent_exemption"] = u64(b[off:off+8]); off += 8
        v["transient_stake_lamports"] = u64(b[off:off+8]); off += 8
        v["transient_seed_suffix"] = u64(b[off:off+8]); off += 8
        v["last_update_epoch"] = u64(b[off:off+8]); off += 8
        v["status"] = b[off]; off += 1
        v["validator_seed_suffix"] = u64(b[off:off+4]); off += 4
        vals.append(v)
    d["validators"] = vals
    d["_decoded_upto"] = off
    d["_total_len"] = len(b)
    return d

def main():
    s = slot()
    print("slot:", s, file=sys.stderr)
    out = {"slot": s}
    for name, addr in [("pool", POOL), ("vlist", VLIST), ("mint", MINT)]:
        val, _ = get_account(addr)
        raw = base64.b64decode(val["data"][0])
        open(f"raw_{name}.b64", "w").write(val["data"][0])
        out[name + "_meta"] = {"owner": val["owner"], "lamports": val["lamports"],
                               "space": val["space"], "executable": val["executable"]}
        if name == "pool":
            out["pool"] = decode_pool(raw)
        elif name == "vlist":
            out["vlist"] = decode_vlist(raw)
        else:
            out["mint"] = {
                "mint_authority": (opt_pubkey(raw, 4)[0]),
                "supply": u64(raw[36:44]),
                "decimals": raw[44],
                "is_initialized": raw[45],
                "freeze_authority": (opt_pubkey(raw, 46)[0]),
            }
        time.sleep(0.3)
    json.dump(out, open("pool_state.json", "w"), indent=1)
    print(json.dumps({k: out[k] for k in out if k != "vlist"}, indent=1))
    print("num_validators:", out["vlist"]["num_validators"])

if __name__ == "__main__":
    main()
