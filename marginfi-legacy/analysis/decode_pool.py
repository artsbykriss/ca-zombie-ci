#!/usr/bin/env python3
"""Decode an SPL stake-pool StakePool account (Borsh layout, solana-program/stake-pool v1.0+ / v2.x).
Reads JSON from argv[1] (getAccountInfo base64 output) and prints the decoded pool.
"""
import json, base64, struct, sys
import base58

def b58(b): return base58.b58encode(b).decode()

class R:
    def __init__(self, raw): self.raw = raw; self.o = 0
    def u8(self): v = self.raw[self.o]; self.o += 1; return v
    def u64(self): v = struct.unpack_from('<Q', self.raw, self.o)[0]; self.o += 8; return v
    def i64(self): v = struct.unpack_from('<q', self.raw, self.o)[0]; self.o += 8; return v
    def pubkey(self): v = b58(self.raw[self.o:self.o+32]); self.o += 32; return v
    def opt_pubkey(self):
        t = self.u8()
        if t == 0: return None
        return self.pubkey()
    def fee(self): return {"denominator": self.u64(), "numerator": self.u64()}
    def future_epoch_fee(self):
        t = self.u8()
        if t == 0: return {"tag": 0}
        return {"tag": t, "fee": self.fee()}
    def lockup(self):
        return {"unix_timestamp": self.i64(), "epoch": self.u64(), "custodian": self.pubkey()}

def main():
    d = json.load(open(sys.argv[1]))["result"]["value"]
    raw = base64.b64decode(d["data"][0])
    r = R(raw)
    pool = {
        "account_type": r.u8(),
        "manager": r.pubkey(),
        "staker": r.pubkey(),
        "stake_deposit_authority": r.pubkey(),
        "stake_withdraw_bump_seed": r.u8(),
        "validator_list": r.pubkey(),
        "reserve_stake": r.pubkey(),
        "pool_mint": r.pubkey(),
        "manager_fee_account": r.pubkey(),
        "token_program_id": r.pubkey(),
        "total_lamports": r.u64(),
        "pool_token_supply": r.u64(),
        "last_update_epoch": r.u64(),
        "lockup": r.lockup(),
        "epoch_fee": r.fee(),
        "next_epoch_fee": r.future_epoch_fee(),
        "preferred_deposit_validator": r.opt_pubkey(),
        "preferred_withdraw_validator": r.opt_pubkey(),
        "stake_deposit_fee": r.fee(),
        "stake_withdrawal_fee": r.fee(),
        "next_stake_withdrawal_fee": r.future_epoch_fee(),
        "stake_referral_fee": r.u8(),
        "sol_deposit_authority": r.opt_pubkey(),
        "sol_deposit_fee": r.fee(),
        "sol_referral_fee": r.u8(),
        "sol_withdraw_authority": r.opt_pubkey(),
        "sol_withdrawal_fee": r.fee(),
        "next_sol_withdrawal_fee": r.future_epoch_fee(),
        "last_epoch_pool_token_supply": r.u64(),
        "last_epoch_total_lamports": r.u64(),
    }
    pool["_consumed_bytes"] = r.o
    pool["_account_bytes"] = len(raw)
    pool["_owner"] = d.get("owner")
    pool["_lamports"] = d.get("lamports")
    if pool["pool_token_supply"]:
        pool["pool_token_price_sol"] = pool["total_lamports"] / pool["pool_token_supply"]
    print(json.dumps(pool, indent=2))

if __name__ == "__main__":
    main()
