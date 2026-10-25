#!/usr/bin/env python3
"""Driver: read-only simulateTransaction probes of the Solstice eUSX YieldVault.

Tests:
  A. baseline unlock(1.0 eUSX)
  B. double unlock(1.0) x2 in ONE tx  -> escrow accumulation semantics
  C. lock(1.0 USX)                    -> LockEvent math
  D. lock(1.0) then unlock(shares)    -> round-trip / vesting asymmetry
All read-only; no signature, no send.
"""
import sys, json, base64, time
sys.path.insert(0, "analysis")
from sim import *
from decode_state import *

USER = "93NyvGRa4SG5p6XDWTpx9JHGU7j8ubw9QUzYLojhv7tJ"
USER_SHARES = "HpYT6iSndAqhm6p5QMedphtx6vYQvRH7kc4zv4aBFGXg"
USER_ASSETS = "56UU2QBBPRcEwxmL7rhNfT3aANbLLFVm6KyErMVVM3pL"
esc, _ = find_pda([b"COOLDOWN_ESCROW", b58dec(USER)])
escv, _ = find_pda([b"COOLDOWN_ESCROW_VAULT", b58dec(USER)])

def unlock_ix(amt):
    return (PROGRAM,
            [Account(USER, signer=True), Account(USER, signer=True, writable=True),
             Account(CONTROLLER), Account(VESTING),
             Account(SHARE_MINT, writable=True), Account(USER_SHARES, writable=True),
             Account(ASSET_MINT), Account(ASSETVAULT, writable=True),
             Account(YIELDPOOL, writable=True), Account(esc, writable=True),
             Account(escv, writable=True), Account(TOKEN), Account(SYSTEM)],
            disc("unlock") + u64le(amt))

def lock_ix(amt):
    return (PROGRAM,
            [Account(USER, signer=True, writable=True), Account(USER, signer=True, writable=True),
             Account(CONTROLLER), Account(VESTING),
             Account(SHARE_MINT, writable=True), Account(USER_SHARES, writable=True),
             Account(ASSET_MINT), Account(ASSETVAULT, writable=True),
             Account(YIELDPOOL, writable=True), Account(USER_ASSETS, writable=True),
             Account(TOKEN)],
            disc("lock") + u64le(amt))

RETS = [esc, escv, USER_SHARES, SHARE_MINT, YIELDPOOL, ASSETVAULT, VESTING, USER_ASSETS]

def run(name, ixs):
    try:
        r = simulate(ixs, RETS)
    except Exception as e:
        print(name, "RPCFAIL", str(e)[:200]); return None
    print("====", name, "err=", r.get("err"), "units=", r.get("unitsConsumed"))
    for lg in r.get("logs", []):
        if "Program log:" in lg or "consumed" in lg or "failed" in lg.lower() or "Error" in lg:
            print("   ", lg)
    evs = {}
    for raw in parse_events(r.get("logs")):
        n, body = decode_event(raw)
        if n == "UnlockEvent": evs[n] = dec_unlock_event(body)
        elif n == "LockEvent": evs[n] = dec_lock_event(body)
        else: evs[n] = body.hex()
    for n, v in evs.items():
        print("   EVENT", n, json.dumps(v))
    accts = r.get("accounts") or []
    for i, a in enumerate(accts):
        if not a: continue
        raw = base64.b64decode(a["data"][0]); pk = RETS[i]
        if pk == esc: print("   post-ESCROW", json.dumps(dec_escrow(raw)))
        elif pk == escv: print("   post-ESCROW-VAULT", json.dumps(dec_token(raw)))
        elif pk == USER_SHARES: print("   post-USER-SHARES", json.dumps(dec_token(raw)))
        elif pk == SHARE_MINT: print("   post-SHARE-MINT len", len(raw))
        elif pk == YIELDPOOL: print("   post-POOL", json.dumps(dec_pool(raw)))
        elif pk == ASSETVAULT: print("   post-ASSET-VAULT", json.dumps(dec_token(raw)))
        elif pk == VESTING: print("   post-VESTING", json.dumps(dec_vesting(raw)))
        elif pk == USER_ASSETS: print("   post-USER-ASSETS", json.dumps(dec_token(raw)))
    return r

def baseline():
    print("=== baseline")
    for label, acct in [("escrow", esc), ("escrow_vault", escv), ("user_shares", USER_SHARES),
                        ("user_assets", USER_ASSETS), ("share_mint", SHARE_MINT),
                        ("yield_pool", YIELDPOOL), ("asset_vault", ASSETVAULT), ("vesting", VESTING)]:
        r = rpc("getAccountInfo", [acct, {"encoding": "base64"}])
        raw = base64.b64decode(r["result"]["value"]["data"][0])
        if label == "escrow": print("  ", label, json.dumps(dec_escrow(raw)))
        elif label == "yield_pool": print("  ", label, json.dumps(dec_pool(raw)))
        elif label == "vesting": print("  ", label, json.dumps(dec_vesting(raw)))
        elif label == "share_mint": print("  ", label, "len", len(raw))
        else: print("  ", label, json.dumps(dec_token(raw)))
    slot = rpc("getSlot", [])["result"]
    bt = rpc("getBlockTime", [slot])["result"]
    print("  now_blocktime", bt, "slot", slot)

if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    baseline()
    if which in ("all", "A"): run("A_unlock_1.0", [unlock_ix(1_000_000)])
    if which in ("all", "B"): run("B_double_unlock_1.0x2", [unlock_ix(1_000_000), unlock_ix(1_000_000)])
    if which in ("all", "C"): run("C_lock_1.0", [lock_ix(1_000_000)])
