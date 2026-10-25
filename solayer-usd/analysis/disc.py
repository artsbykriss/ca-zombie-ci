#!/usr/bin/env python3
"""Compute Anchor discriminators for the recovered usdc-pool-program names."""
import hashlib, json

ixs = ["initialize","update_susd_metadata","update_susd_rate","deposit","initiate_batch_deposit",
       "withdraw","initiate_batch_withdraw","resolve_batch_withdraw","update_openeden_info",
       "set_fee","set_manager","set_operator","set_rate_authority","collect_fee",
       "emergency_transfer_rwa_token","handle_frozen_accounts","claim_with_migrated_deposit_proof",
       "sunset_redeem_all","sunset_finalize","sunset_initiate_batch_withdraw",
       "create_susd_offset_pda","migrate_deposit_proof","resolve_batch_deposit"]
accts = ["Pool","DepositProof","WithdrawProof","OpenedenInfo","SusdSupplyOffset",
         "MigratedDepositProof","SunsetInfo"]
evs = ["DepositEvent","WithdrawEvent"]

def disc(prefix, name):
    return hashlib.sha256((prefix+name).encode()).digest()[:8].hex()

out = {"instructions": {}, "accounts": {}, "events": {}}
for n in ixs:
    out["instructions"][disc("global:", n)] = n
for n in accts:
    out["accounts"][disc("account:", n)] = n
for n in evs:
    out["events"][disc("event:", n)] = n

print("== instructions ==")
for k, v in sorted(out["instructions"].items()): print(k, v)
print("== accounts ==")
for k, v in sorted(out["accounts"].items()): print(k, v)
print("== pool disc f19a6d0411b16dbc ->", out["accounts"].get("f19a6d0411b16dbc"))
json.dump(out, open("discriminators.json", "w"), indent=1)
