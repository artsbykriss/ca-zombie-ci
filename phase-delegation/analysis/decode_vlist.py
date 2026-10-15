#!/usr/bin/env python3
"""Decode the Phase Delegation validator list + enumerate all pools on SPoo1.

ValidatorStakeInfo (73 B): active_stake_lamports u64, transient_stake_lamports u64,
last_update_epoch u64, transient_seed_suffix u64, unused u32, validator_seed_suffix u32,
status u8, vote_account_address Pubkey.
ValidatorList header: account_type u8, max_validators u32, vec_len u32.
"""
import base64, json, sys
sys.path.insert(0, '.')
from rpc import rpc, b58enc

raw = base64.b64decode(open('raw_vlist.b64').read())
u64 = lambda o: int.from_bytes(raw[o:o+8], 'little')
u32 = lambda o: int.from_bytes(raw[o:o+4], 'little')
pk = lambda o: b58enc(raw[o:o+32])

acct_type = raw[0]
max_validators = u32(1)
n = u32(5)
print(f"account_type={acct_type} max_validators={max_validators} num={n} space={len(raw)}")
assert len(raw) == 9 + max_validators * 73, "size mismatch"

vals = []
o = 9
for i in range(n):
    v = dict(
        active_stake_lamports=u64(o), transient_stake_lamports=u64(o+8),
        last_update_epoch=u64(o+16), transient_seed_suffix=u64(o+24),
        unused=u32(o+32), validator_seed_suffix=u32(o+36),
        status=raw[o+40], vote_account_address=pk(o+41))
    vals.append(v)
    o += 73
# tail must be zeros
tail_nonzero = sum(1 for b in raw[o:] if b)
print("entries end at", o, "| non-zero bytes in tail:", tail_nonzero)
json.dump(vals, open('vlist_decoded.json', 'w'), indent=1)
for v in vals[:3]:
    print(v)
print("...")
tot_active = sum(v['active_stake_lamports'] for v in vals)
tot_transient = sum(v['transient_stake_lamports'] for v in vals)
print("sum active_stake_lamports:", tot_active, "=", tot_active/1e9, "SOL")
print("sum transient_stake_lamports:", tot_transient, "=", tot_transient/1e9, "SOL")
print("statuses:", {s: sum(1 for v in vals if v['status']==s) for s in set(v['status'] for v in vals)})
print("last_update_epoch values:", sorted(set(v['last_update_epoch'] for v in vals)))
