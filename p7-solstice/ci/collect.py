#!/usr/bin/env python3
"""CI collector (read-only) for the Solstice eUSX YieldVault deep-dive.

Runs the decisive gating probes against live mainnet state using
simulateTransaction (sigVerify:false, replaceRecentBlockhash:true).
NO transaction is signed or sent. Uses only keyless public Solana RPCs.

Writes ci-out/solstice_ci.json.
"""
import sys, os, json, base64, time
sys.path.insert(0, "analysis")
import sim
from sim import (rpc, b58dec, b58enc, find_pda, Account, disc, u64le, simulate,
                 parse_events, decode_event, on_curve,
                 PROGRAM, CONTROLLER, VESTING, YIELDPOOL, ASSETVAULT, SHARE_MINT,
                 ASSET_MINT, TOKEN, SYSTEM)
from decode_state import (dec_escrow, dec_pool, dec_token, dec_vesting,
                          dec_unlock_event, dec_lock_event)

OUT = {}

def safe(label, fn):
    try:
        return fn()
    except Exception as e:
        print("FAIL", label, repr(e)[:200])
        OUT.setdefault("errors", []).append({label: repr(e)[:200]})
        return None

def baseline():
    b = {}
    for label, acct, dec in [("controller", CONTROLLER, None),
                             ("yield_pool", YIELDPOOL, dec_pool),
                             ("vesting_schedule", VESTING, dec_vesting),
                             ("asset_vault", ASSETVAULT, dec_token),
                             ("permissioned_account", "5KzVcKDyzMFUh32tMESHjfA7vTALfDHbVxq9HbZd8rz", None),
                             ("share_mint", SHARE_MINT, None)]:
        r = rpc("getAccountInfo", [acct, {"encoding": "base64"}])
        v = r["result"]["value"]
        raw = base64.b64decode(v["data"][0])
        b[label] = dec(raw) if dec else {"len": len(raw)}
    b["slot"] = rpc("getSlot", [])["result"]
    b["blocktime"] = rpc("getBlockTime", [b["slot"]])["result"]
    # upgrade authorities
    for name, prog in [("yieldvault_program", PROGRAM),
                       ("usx_program", "USXyiSTsPEWz55pSK7sZoUL79ntoVGQbaTDT57tH6bx")]:
        r = rpc("getAccountInfo", [prog, {"encoding": "base64"}])
        d = base64.b64decode(r["result"]["value"]["data"][0])
        pd = b58enc(d[4:36])
        r2 = rpc("getAccountInfo", [pd, {"encoding": "base64"}])
        dd = base64.b64decode(r2["result"]["value"]["data"][0])
        auth = b58enc(dd[13:45]) if dd[12] else None
        b[name] = {"programdata": pd, "last_deploy_slot": int.from_bytes(dd[4:12], 'little'),
                   "upgrade_authority": auth, "authority_on_curve": on_curve(dd[13:45]) if auth else None,
                   "elf_len": len(dd) - 45}
    return b

# known live holder with both eUSX and USX (point-in-time 2026-10-25)
USER = "93NyvGRa4SG5p6XDWTpx9JHGU7j8ubw9QUzYLojhv7tJ"
USER_SHARES = "HpYT6iSndAqhm6p5QMedphtx6vYQvRH7kc4zv4aBFGXg"
USER_ASSETS = "56UU2QBBPRcEwxmL7rhNfT3aANbLLFVm6KyErMVVM3pL"

def escrow_pdas(user):
    return find_pda([b"COOLDOWN_ESCROW", b58dec(user)])[0], find_pda([b"COOLDOWN_ESCROW_VAULT", b58dec(user)])[0]

def unlock_ix(user, shares, amt):
    esc, escv = escrow_pdas(user)
    return (PROGRAM,
            [Account(user, signer=True), Account(user, signer=True, writable=True),
             Account(CONTROLLER), Account(VESTING), Account(SHARE_MINT, writable=True),
             Account(shares, writable=True), Account(ASSET_MINT), Account(ASSETVAULT, writable=True),
             Account(YIELDPOOL, writable=True), Account(esc, writable=True),
             Account(escv, writable=True), Account(TOKEN), Account(SYSTEM)],
            disc("unlock") + u64le(amt))

def lock_ix(user, assets, shares, amt):
    return (PROGRAM,
            [Account(user, signer=True, writable=True), Account(user, signer=True, writable=True),
             Account(CONTROLLER), Account(VESTING), Account(SHARE_MINT, writable=True),
             Account(shares, writable=True), Account(ASSET_MINT), Account(ASSETVAULT, writable=True),
             Account(YIELDPOOL, writable=True), Account(assets, writable=True), Account(TOKEN)],
            disc("lock") + u64le(amt))

def withdraw_ix(user, assets):
    esc, escv = escrow_pdas(user)
    return (PROGRAM,
            [Account(user, signer=True), Account(user, signer=True, writable=True),
             Account(CONTROLLER), Account(ASSET_MINT), Account(assets, writable=True),
             Account(esc, writable=True), Account(escv, writable=True), Account(TOKEN)],
            disc("withdraw"))

def events(r):
    out = []
    for raw in parse_events(r.get("logs")):
        n, body = decode_event(raw)
        if n == "UnlockEvent": out.append({"event": n, **dec_unlock_event(body)})
        elif n == "LockEvent": out.append({"event": n, **dec_lock_event(body)})
        else: out.append({"event": n})
    return out

def main():
    print("== baseline")
    OUT["baseline"] = safe("baseline", baseline)
    print(json.dumps(OUT.get("baseline"), indent=1)[:1500])

    esc, escv = escrow_pdas(USER)
    rets = [esc, escv, USER_SHARES, YIELDPOOL, ASSETVAULT, VESTING]
    now = rpc("getBlockTime", [rpc("getSlot", [])["result"]])["result"]

    def sim(tag, ixs, rl=None):
        print("==", tag)
        r = simulate(ixs, rl or rets)
        rec = {"err": r.get("err"), "units": r.get("unitsConsumed"), "events": events(r)}
        if r.get("accounts") and r["accounts"][0]:
            rec["post_escrow"] = dec_escrow(base64.b64decode(r["accounts"][0]["data"][0]))
        if r.get("err") and r.get("logs"):
            rec["anchor_err"] = [l for l in r["logs"] if "AnchorError" in l][:2]
        print("   ", json.dumps(rec)[:600])
        return rec

    OUT["A_unlock_1eUSX"] = safe("A", lambda: sim("A", [unlock_ix(USER, USER_SHARES, 1_000_000)]))
    OUT["B_double_unlock"] = safe("B", lambda: sim("B", [unlock_ix(USER, USER_SHARES, 1_000_000),
                                                          unlock_ix(USER, USER_SHARES, 1_000_000)]))
    OUT["C_lock_1USX"] = safe("C", lambda: sim("C", [lock_ix(USER, USER_ASSETS, USER_SHARES, 1_000_000)]))
    OUT["D_roundtrip_lock_unlock"] = safe("D", lambda: sim("D", [lock_ix(USER, USER_ASSETS, USER_SHARES, 1_000_000),
                                                                  unlock_ix(USER, USER_SHARES, 952_235)]))
    OUT["E_withdraw_active"] = safe("E", lambda: sim("E", [unlock_ix(USER, USER_SHARES, 1_000_000),
                                                           withdraw_ix(USER, USER_ASSETS)]))
    OUT["F_double_withdraw"] = safe("F", lambda: sim("F", [withdraw_ix(USER, USER_ASSETS),
                                                           withdraw_ix(USER, USER_ASSETS)]))
    OUT["G_dust_lock"] = safe("G", lambda: sim("G", [lock_ix(USER, USER_ASSETS, USER_SHARES, 1)]))
    # account substitution: victim escrow
    VICTIM = "9HsFJKqobLFZ6QLT7xXhS3ggDfSGTJPUh2Rfug4VFGWh"
    vesc, vesv = escrow_pdas(VICTIM)
    def sub_unlock():
        ix = unlock_ix(USER, USER_SHARES, 1_000_000)
        # replace escrow metas with victim's
        a = list(ix[1]); a[9] = Account(vesc, writable=True); a[10] = Account(vesv, writable=True)
        return sim("SUB", [(ix[0], a, ix[2])], [vesc, vesv])
    OUT["H_substitute_victim_escrow"] = safe("H", sub_unlock)
    # transfer_in_yield gate
    def tiy():
        ix = (PROGRAM,
              [Account(USER, signer=True), Account(USER, signer=True, writable=True),
               Account("5KzVcKDyzMFUh32tMESHjfA7vTALfDHbVxq9HbZd8rz"), Account(CONTROLLER), Account(VESTING),
               Account(USER_ASSETS, writable=True), Account(ASSET_MINT), Account(ASSETVAULT, writable=True),
               Account(YIELDPOOL, writable=True), Account(TOKEN)],
              disc("transfer_in_yield") + u64le(1_000_000))
        return sim("TIY", [ix], [YIELDPOOL, ASSETVAULT])
    OUT["I_transfer_in_yield_attacker"] = safe("I", tiy)

    OUT["now_blocktime"] = now
    os.makedirs("ci-out", exist_ok=True)
    json.dump(OUT, open("ci-out/solstice_ci.json", "w"), indent=1, default=str)
    print("\nWROTE ci-out/solstice_ci.json")

if __name__ == "__main__":
    main()
