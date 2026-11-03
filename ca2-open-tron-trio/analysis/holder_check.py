#!/usr/bin/env python3
"""Per-user accounting checks: find current holders with non-zero claimable balances.

Uses public event history to pick candidate users, then read-only view calls.
Writes analysis/holder_check.json.
"""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tronlib as T

OUT = os.path.dirname(os.path.abspath(__file__))
FRESH = T.fresh_address()
C = {"CherryPool": "TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR",
     "PokerGame": "TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn",
     "FireFull": "TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW"}


def call(addr, sig, params=""):
    r = T.trigger(FRESH, addr, sig, params)
    return {"sig": sig, "parameter": params, "result": r.get("result"),
            "constant_result": r.get("constant_result"),
            "energy_used": r.get("energy_used")}


def words(r):
    cr = r.get("constant_result") or []
    out = []
    for blob in cr:
        blob = blob[2:] if blob.startswith("0x") else blob
        for i in range(0, len(blob) - 63, 64):
            out.append(int(blob[i:i + 64], 16))
    return out


def hexaddr(hexstr):
    try:
        return T.hex_to_addr(hexstr)
    except Exception:
        return None


def main():
    ev = json.load(open(f"{OUT}/events.json"))
    out = {"block": T.now_block(), "probe_address": FRESH, "contracts": {}}

    # ---- CherryPool: aggregate TRX deposits / withdrawals per user ----
    dep = {}
    for r in ev["CherryPool"]["OnDeposit"]:
        u = hexaddr(r["result"]["1"])
        if u:
            dep[u] = dep.get(u, 0) + int(r["result"]["2"])
    top = sorted(dep.items(), key=lambda x: -x[1])[:20]
    chk = []
    for u, amt in top:
        r1 = call(C["CherryPool"], "getUserTokenAmount(address)", T.enc_addr(u))
        r2 = call(C["CherryPool"], "tokenUserAmountOf(address,address)",
                  T.enc_addr(T.hex_to_addr("0" * 40)) + T.enc_addr(u))
        w1, w2 = words(r1), words(r2)
        chk.append({"user": u, "deposited_sun": amt, "getUserTokenAmount": w1,
                    "tokenUserAmountOf_zero": w2,
                    "raw1": r1.get("constant_result"), "raw2": r2.get("constant_result"),
                    "energy1": r1.get("energy_used"), "energy2": r2.get("energy_used")})
        print(f"Cherry {u} dep={amt/1e6:.0f} bal={w1} m={w2}")
        time.sleep(0.7)
    out["contracts"]["CherryPool"] = {"top_depositors": chk}

    # ---- FireFull: players() struct for recent joiners + withdrawers ----
    cands = []
    for r in ev["FireFull"]["JoinEvent"][:20] + ev["FireFull"]["WithdrawEvent"][:20]:
        u = hexaddr(r["result"]["0"])
        if u and u not in cands:
            cands.append(u)
    ff = []
    for u in cands[:30]:
        r = call(C["FireFull"], "players(address)", T.enc_addr(u))
        w = words(r)
        ff.append({"user": u, "players": w, "field8": w[8] if len(w) > 8 else None,
                   "raw": r.get("constant_result"), "energy": r.get("energy_used")})
        print(f"FireFull {u} fields={w}")
        time.sleep(0.7)
    out["contracts"]["FireFull"] = {"players": ff}

    json.dump(out, open(f"{OUT}/holder_check.json", "w"), indent=1)


if __name__ == "__main__":
    main()
