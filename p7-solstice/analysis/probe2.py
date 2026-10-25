#!/usr/bin/env python3
"""Second matrix: active-cooldown withdraw, double withdraw, chunked unlock, dust unlock,
lock->unlock round trip. Read-only sim."""
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

def now_bt(): return rpc("getBlockTime", [rpc("getSlot", [])["result"]])["result"]

def show(tag, ixs, rets):
    now = now_bt(); r = simulate(ixs, rets)
    print("====", tag, "err", r.get("err"), "now", now)
    for raw in parse_events(r.get("logs")):
        n, body = decode_event(raw)
        if n == "UnlockEvent":
            e = dec_unlock_event(body)
            print("   Unlock asset", e["asset_amount"]/1e6, "escrow_after", e["cooldown_escrow_asset_amount"]/1e6,
                  "init", e["is_init_needed"], "period", e["cooldown_end"]-now)
        elif n == "LockEvent":
            print("   Lock", json.dumps(dec_lock_event(body)))
        elif n == "WithdrawEvent":
            o=0; print("   Withdraw user", b58enc(body[32:64]), "amt", int.from_bytes(body[64:72],'little')/1e6)
    for i, a in enumerate(r.get("accounts") or []):
        if a and rets[i].startswith(("EcNuh", "Du8KC")) or (a and i==0 and "COOLDOWN" in ""):
            pass
    if rets and rets[0].startswith("EcNuh"):
        for i,a in enumerate(r.get("accounts") or []):
            if a and i==0:
                print("   post-escrow", json.dumps(dec_escrow(base64.b64decode(a["data"][0]))))
    return r

if __name__ == "__main__":
    U1="93NyvGRa4SG5p6XDWTpx9JHGU7j8ubw9QUzYLojhv7tJ"; A1="56UU2QBBPRcEwxmL7rhNfT3aANbLLFVm6KyErMVVM3pL"
    S1="HpYT6iSndAqhm6p5QMedphtx6vYQvRH7kc4zv4aBFGXg"
    # active cooldown withdraw: first unlock then immediately withdraw (2 ixs one tx) -> withdraw should fail 6013
    ua,esc,escv = unlock_ix(U1, S1, 1_000_000)
    wa,_,_ = withdraw_ix(U1, A1)
    show("WITHDRAW_ACTIVE_after_unlock", [ua, wa], [esc, escv, A1])
    # double withdraw (escrow expired) in one tx -> 2nd should fail
    show("DOUBLE_WITHDRAW_expired", [wa, wa], [esc, escv, A1])
    # chunked unlock to try to downgrade: BkvK (130k eUSX, no escrow), 500 then 600 (total ~1155>1000)
    U3="BkvKpstxgeEJYzvFnWWuAbTDcrFMJBtyk3XxUfGG9D7n"; T3="HjTieHb4KW2c2dZTzwsHsFQVrG6QMm92raM4fXyBjSPg"
    u1,esc,escv = unlock_ix(U3, T3, 500_000_000)  # ~525 USX
    u2,_,_ = unlock_ix(U3, T3, 600_000_000)       # total ~1155 USX >1000
    show("CHUNK_fast_then_over", [u1, u2], [esc, escv, T3])
    # dust unlock (1 share)
    u1x,esc,escv = unlock_ix(U1, S1, 1)
    show("UNLOCK_1share", [u1x], [esc, escv, S1])
    # lock->unlock round trip in one tx: lock 1_000_000 USX then unlock the shares it minted
    lk = lock_ix(U1, A1, S1, 1_000_000)
    show("LOCK_1.0", [lk], [YIELDPOOL, S1, A1])
