#!/usr/bin/env python3
import hashlib, json, base64, sys, struct
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call
from solders.pubkey import Pubkey

PROGRAM = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV"

def disc(prefix, name):
    return hashlib.sha256(f"{prefix}:{name}".encode()).digest()[:8]

INSTRUCTIONS = ["create_access_control","create_pair","stake","create_withdrawal_window",
 "request_withdraw","execute_withdraw","restake_expired_withdraw","fund_withdrawal_window",
 "vault_withdraw","update_pair_yield","initiate_authority_transfer","accept_authority_transfer",
 "cancel_authority_transfer","close_withdrawal_window","cancel_withdrawal_request","swap_lst",
 "seal_program","unseal_program","manage_guardian","update_pair_limits","update_sol_usdc_feed",
 "update_whitelist","withdraw_fees","create_token_metadata","migrate","update_pair_type",
 "update_nav","migrate_pair_v2","migrate_access_control_v2","migrate_pt_staking",
 "create_access_control_window","create_token_metadata"]

imap = {}
print("=== instruction discriminators ===")
for n in INSTRUCTIONS:
    d = disc("global", n)
    imap[d.hex()] = n
    print(f"  {n:35s} {d.hex()}")

json.dump(imap, open("/home/heisenberg/CA/exceed-finance/analysis/childB/ix-disc.json","w"), indent=2)

ACCOUNTS = ["Pair","AccessControl","WithdrawalWindow","WithdrawalRequest"]
amap = {}
print("=== account discriminators ===")
for n in ACCOUNTS:
    d = disc("account", n)
    amap[n] = d.hex()
    print(f"  {n:22s} {d.hex()}")
json.dump(amap, open("/home/heisenberg/CA/exceed-finance/analysis/childB/acct-disc.json","w"), indent=2)

# enumerate all program accounts
print("\n=== getProgramAccounts ===")
r = call("getProgramAccounts", [PROGRAM, {"encoding": "base64", "commitment": "confirmed"}])
vals = r.get("result", [])
print("total accounts owned by program:", len(vals))
buckets = {}
for v in vals:
    d = base64.b64decode(v["account"]["data"][0])
    dis = d[:8].hex()
    name = next((k for k, vv in amap.items() if vv == dis), f"unknown:{dis}")
    buckets.setdefault(name, []).append((v["pubkey"], len(d), v["account"]["lamports"]))
for name, lst in buckets.items():
    print(f"\n-- {name}: {len(lst)}")
    for pk, ln, lam in lst:
        print(f"    {pk}  len={ln} lamports={lam}")
json.dump({k: [list(x) for x in v] for k, v in buckets.items()},
          open("/home/heisenberg/CA/exceed-finance/analysis/childB/program-accounts.json","w"), indent=2)
