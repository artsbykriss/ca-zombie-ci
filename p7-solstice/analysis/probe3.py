#!/usr/bin/env python3
"""Extra account-substitution probes on unlock/withdraw/lock (read-only sim)."""
import sys, json, base64
sys.path.insert(0, "analysis")
from sim import *
from decode_state import *

USER = "93NyvGRa4SG5p6XDWTpx9JHGU7j8ubw9QUzYLojhv7tJ"
USER_SHARES = "HpYT6iSndAqhm6p5QMedphtx6vYQvRH7kc4zv4aBFGXg"
USER_ASSETS = "56UU2QBBPRcEwxmL7rhNfT3aANbLLFVm6KyErMVVM3pL"
VICTIM = "9HsFJKqobLFZ6QLT7xXhS3ggDfSGTJPUh2Rfug4VFGWh"
VICTIM_SHARES = "7Qb2M7U566tctPQYKXjvCbJxSkEue4bVrkxfe7GBjrKt"  # owned by another user
esc, _ = find_pda([b"COOLDOWN_ESCROW", b58dec(USER)])
escv, _ = find_pda([b"COOLDOWN_ESCROW_VAULT", b58dec(USER)])

def run(tag, ix, rets):
    r = simulate([ix], rets)
    ae = [l for l in (r.get("logs") or []) if "AnchorError" in l]
    print("====", tag, "err", r.get("err"))
    for l in ae[:1]:
        print("   ", l)

# unlock with a user_shares account owned by someone else
run("UNLOCK_foreign_user_shares",
    (PROGRAM, [Account(USER, signer=True), Account(USER, signer=True, writable=True), Account(CONTROLLER), Account(VESTING),
               Account(SHARE_MINT, writable=True), Account(VICTIM_SHARES, writable=True), Account(ASSET_MINT),
               Account(ASSETVAULT, writable=True), Account(YIELDPOOL, writable=True), Account(esc, writable=True),
               Account(escv, writable=True), Account(TOKEN), Account(SYSTEM)], disc("unlock") + u64le(1_000_000)),
    [VICTIM_SHARES])

# unlock with a bogus share_mint (the USX mint)
run("UNLOCK_bogus_share_mint",
    (PROGRAM, [Account(USER, signer=True), Account(USER, signer=True, writable=True), Account(CONTROLLER), Account(VESTING),
               Account(ASSET_MINT, writable=True), Account(USER_SHARES, writable=True), Account(ASSET_MINT),
               Account(ASSETVAULT, writable=True), Account(YIELDPOOL, writable=True), Account(esc, writable=True),
               Account(escv, writable=True), Account(TOKEN), Account(SYSTEM)], disc("unlock") + u64le(1_000_000)),
    [USER_SHARES])

# withdraw with victim's USX account as user_assets
run("WITHDRAW_foreign_user_assets",
    (PROGRAM, [Account(USER, signer=True), Account(USER, signer=True, writable=True), Account(CONTROLLER),
               Account(ASSET_MINT), Account(VICTIM_SHARES, writable=True), Account(esc, writable=True),
               Account(escv, writable=True), Account(TOKEN)], disc("withdraw")),
    [esc, escv])

# lock with a bogus asset_vault (not the pool vault)
run("LOCK_bogus_asset_vault",
    (PROGRAM, [Account(USER, signer=True, writable=True), Account(USER, signer=True, writable=True), Account(CONTROLLER),
               Account(VESTING), Account(SHARE_MINT, writable=True), Account(USER_SHARES, writable=True), Account(ASSET_MINT),
               Account(USER_ASSETS, writable=True), Account(YIELDPOOL, writable=True), Account(USER_ASSETS, writable=True),
               Account(TOKEN)], disc("lock") + u64le(1_000_000)),
    [YIELDPOOL])
