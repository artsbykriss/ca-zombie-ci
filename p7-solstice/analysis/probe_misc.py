#!/usr/bin/env python3
"""Withdraw / dust / large-fresh-unlock probes (read-only sim)."""
import sys, json, base64
sys.path.insert(0, "analysis")
from sim import *
from decode_state import *

def unlock_ix(user, shares_acct, amt):
    esc, _ = find_pda([b"COOLDOWN_ESCROW", b58dec(user)])
    escv, _ = find_pda([b"COOLDOWN_ESCROW_VAULT", b58dec(user)])
    return (PROGRAM,
            [Account(user, signer=True), Account(user, signer=True, writable=True),
             Account(CONTROLLER), Account(VESTING),
             Account(SHARE_MINT, writable=True), Account(shares_acct, writable=True),
             Account(ASSET_MINT), Account(ASSETVAULT, writable=True),
             Account(YIELDPOOL, writable=True), Account(esc, writable=True),
             Account(escv, writable=True), Account(TOKEN), Account(SYSTEM)],
            disc("unlock") + u64le(amt)), esc, escv

def lock_ix(user, assets_acct, shares_acct, amt):
    return (PROGRAM,
            [Account(user, signer=True, writable=True), Account(user, signer=True, writable=True),
             Account(CONTROLLER), Account(VESTING),
             Account(SHARE_MINT, writable=True), Account(shares_acct, writable=True),
             Account(ASSET_MINT), Account(ASSETVAULT, writable=True),
             Account(YIELDPOOL, writable=True), Account(assets_acct, writable=True),
             Account(TOKEN)],
            disc("lock") + u64le(amt))

def withdraw_ix(user, assets_acct):
    esc, _ = find_pda([b"COOLDOWN_ESCROW", b58dec(user)])
    escv, _ = find_pda([b"COOLDOWN_ESCROW_VAULT", b58dec(user)])
    return (PROGRAM,
            [Account(user, signer=True), Account(user, signer=True, writable=True),
             Account(CONTROLLER), Account(ASSET_MINT), Account(assets_acct, writable=True),
             Account(esc, writable=True), Account(escv, writable=True), Account(TOKEN)],
            disc("withdraw")), esc, escv

def now_bt():
    return rpc("getBlockTime", [rpc("getSlot", [])["result"]])["result"]

def run(tag, ixs, rets):
    now = now_bt()
    r = simulate(ixs, rets)
    print("====", tag, "err", r.get("err"), "now", now, "units", r.get("unitsConsumed"))
    for raw in parse_events(r.get("logs")):
        n, body = decode_event(raw)
        if n == "UnlockEvent":
            e = dec_unlock_event(body)
            print("   Unlock asset", e["asset_amount"]/1e6, "escrow_after", e["cooldown_escrow_asset_amount"]/1e6,
                  "init", e["is_init_needed"], "period", e["cooldown_end"]-now)
        elif n == "LockEvent":
            print("   Lock", json.dumps(dec_lock_event(body)))
        elif n == "WithdrawEvent":
            print("   Withdraw", body.hex())
    for i, a in enumerate(r.get("accounts") or []):
        if not a: continue
        raw = base64.b64decode(a["data"][0])
        print("   post[%d]" % i, rets[i][:8], raw.hex()[:150])
    return r

if __name__ == "__main__":
    # fresh large unlock: Bc5bth4Mn2 (58k eUSX, no escrow), unlock 2000 eUSX (~2100 USX > 1000)
    U2 = "Bc5bth4Mn2n8DX1etZwvnq3uDEGg479s2D24TCEsnXHf"; T2 = "BzSdBewagDuotSXmsakFyNU4FGZBdAFGnFJNahTEkBt2"
    ix, esc, escv = unlock_ix(U2, T2, 2_000_000_000)
    run("LARGE_FRESH_unlock_2000eUSX", [ix], [esc, escv, T2])
    # withdraw with expired cooldown: 93Nyv (escrow end 1792728416 < now)
    U1 = "93NyvGRa4SG5p6XDWTpx9JHGU7j8ubw9QUzYLojhv7tJ"; A1 = "56UU2QBBPRcEwxmL7rhNfT3aANbLLFVm6KyErMVVM3pL"
    ix, esc, escv = withdraw_ix(U1, A1)
    run("WITHDRAW_expired", [ix], [esc, escv, A1])
    # dust lock 1 unit
    ix = lock_ix(U1, A1, "HpYT6iSndAqhm6p5QMedphtx6vYQvRH7kc4zv4aBFGXg", 1)
    run("DUST_lock_1unit", [ix], [YIELDPOOL, A1])
