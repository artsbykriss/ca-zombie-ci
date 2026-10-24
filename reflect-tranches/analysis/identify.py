#!/usr/bin/env python3
"""Identify RLP account types by PDA derivation; decode UserPermissions role sets."""
import sys, os, json, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc, b58e
from solders.pubkey import Pubkey

RLP = Pubkey.from_string("JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av")
def pda(seeds): return Pubkey.find_program_address(seeds, RLP)[0]

r = rpc("getProgramAccounts", [str(RLP), {"encoding": "base64"}])
accts = {}
for a in r["result"]:
    accts[a["pubkey"]] = base64.b64decode(a["account"]["data"][0])

print("SETTINGS =", pda([b"settings"]), "size", len(accts.get(str(pda([b"settings"])), b"")))
for i in range(0, 12):
    p = str(pda([b"liquidity_pool", bytes([i])]))
    if p in accts:
        print(f"pool[{i}] = {p} size {len(accts[p])}")
# permissions for the oracle crank + known authorities
CAND = {
    "pRiCE (oracle crank)": "pRiCEzwgkSi7KTsQHdyfuRbPEuCFoK9sA5QVn2hvABV",
    "28sR8pmJ (upgrade auth)": "28sR8pmJxhtZNci3hPervkxu9f93nvHpFikbtzXoxmWA",
    "KuBAWM6p (admin)": "KuBAWM6pZ43ip8b7eB3kjJwUqdPwYpSuoCFkn4bcLgw",
    "apyaB89k (proxy auth)": "apyaB89kiVoc1xfYiYAMmRDB2M1qSYYdHy7psv5pPwE",
}
ROLES = ["UNSET", "PUBLIC", "TESTEE", "FREEZE", "CRANK", "MANAGER", "SUPREMO"]
for label, k in CAND.items():
    p = str(pda([b"permissions", bytes(Pubkey.from_string(k))]))
    if p in accts:
        d = accts[p]
        print(f"permissions[{label}] = {p} size {len(d)} hex {d.hex()[:120]}")
    else:
        print(f"permissions[{label}] = {p} NOT FOUND")

# classify all accounts by derived seeds
by_size = {}
for pk, d in accts.items():
    by_size.setdefault(len(d), []).append(pk)
print("\nsizes:", {k: len(v) for k, v in sorted(by_size.items())})
# print the 168-byte ones and decode roles
print("\n168-byte accounts (candidate UserPermissions):")
for pk in by_size.get(168, []):
    d = accts[pk]
    print(" ", pk, d.hex())
print("\n75-byte accounts:")
for pk in by_size.get(75, []):
    print(" ", pk, accts[pk].hex())
print("\n55-byte accounts:")
for pk in by_size.get(55, []):
    print(" ", pk, accts[pk].hex())
