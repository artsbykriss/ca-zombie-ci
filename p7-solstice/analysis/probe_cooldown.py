#!/usr/bin/env python3
"""Cooldown-branch matrix: does the fast cooldown key off the unlock amount,
the resulting escrow total, or escrow initialization? (read-only sim)"""
import sys, json, base64, time
sys.path.insert(0, "analysis")
from sim import *
from decode_state import dec_escrow, dec_token, dec_unlock_event, dec_lock_event

def unlock_ix(user, shares_acct, amt):
    esc, _ = find_pda([b"COOLDOWN_ESCROW", b58dec(user)])
    escv, _ = find_pda([b"COOLDOWN_ESCROW_VAULT", b58dec(user)])
    ix = (PROGRAM,
          [Account(user, signer=True), Account(user, signer=True, writable=True),
           Account(CONTROLLER), Account(VESTING),
           Account(SHARE_MINT, writable=True), Account(shares_acct, writable=True),
           Account(ASSET_MINT), Account(ASSETVAULT, writable=True),
           Account(YIELDPOOL, writable=True), Account(esc, writable=True),
           Account(escv, writable=True), Account(TOKEN), Account(SYSTEM)],
          disc("unlock") + u64le(amt))
    return ix, esc, escv

def probe(tag, user, shares_acct, amt):
    esc, _ = find_pda([b"COOLDOWN_ESCROW", b58dec(user)])
    escv, _ = find_pda([b"COOLDOWN_ESCROW_VAULT", b58dec(user)])
    pre = None
    r0 = rpc("getAccountInfo", [esc, {"encoding": "base64"}])
    if r0["result"]["value"]:
        pre = dec_escrow(base64.b64decode(r0["result"]["value"]["data"][0]))
    now = rpc("getBlockTime", [rpc("getSlot", [])["result"]])["result"]
    ix, _, _ = unlock_ix(user, shares_acct, amt)
    r = simulate([ix], [esc, escv, shares_acct])
    print("====", tag, "unlock", amt / 1e6, "eUSX  user", user[:8], "err", r.get("err"), "now", now)
    if pre: print("   pre-escrow amount", pre["asset_amount"] / 1e6, "end", pre["cooldown_end"])
    for raw in parse_events(r.get("logs")):
        n, body = decode_event(raw)
        if n == "UnlockEvent":
            e = dec_unlock_event(body)
            delta = e["cooldown_end"] - now
            print("   UnlockEvent asset", e["asset_amount"] / 1e6, "escrow_after", e["cooldown_escrow_asset_amount"] / 1e6,
                  "init_needed", e["is_init_needed"], "cooldown_end", e["cooldown_end"],
                  "=> period", delta, "s (fast=86400, std=604800)")
    for i, a in enumerate(r.get("accounts") or []):
        if a and i == 0:
            d = dec_escrow(base64.b64decode(a["data"][0]))
            print("   post-escrow amount", d["asset_amount"] / 1e6, "end", d["cooldown_end"])
    return r

if __name__ == "__main__":
    sh = json.load(open("analysis/small_holders.json"))
    by_owner = {x[0]: x for x in sh}
    # fresh, small escrow cases
    u1 = "HDoTHbkcqp"  # placeholder
    for o, t, amt, esc, escamt in sh:
        if esc is None:
            u1 = o; t1 = t; break
    probe("F1_fresh_small", u1, t1, 10_000_000)
    probe("F2_fresh_bigger", u1, t1, min(100_000_000, 0))
