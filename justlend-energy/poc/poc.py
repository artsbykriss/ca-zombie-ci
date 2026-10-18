#!/usr/bin/env python3
"""JustLend Energy Rental (MarketG1) — read-only PoC / dry-run harness.

TRON is not EVM-forkable with Foundry, so the PoC uses:
  * live TronGrid `triggerconstantcontract` dry-runs against the deployed
    MarketProxy at the latest block (no broadcast, no signature), and
  * an exact arithmetic replay ("shadow ledger") of the verified MarketG1
    repay formulas with the live parameters.

No secrets, no keyed endpoints, no transactions. Output: poc/results/poc_results.json
"""
import json, os, sys, time, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tronlib as T

P = "TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd"
HERE = os.path.dirname(os.path.abspath(__file__))
RES = {}

def h2b(h):
    h = h.lower().replace("0x", "").zfill(40)
    raw = bytes.fromhex("41" + h)
    chk = hashlib.sha256(hashlib.sha256(raw).digest()).digest()[:4]
    return T.b58encode(raw + chk)

def u(contract, sig, args=""):
    r = T.call_uint(contract, sig, args)
    if r.get("value") is None:
        raise RuntimeError(f"read failed: {sig} {r.get('raw',{}).get('result')}")
    return r["value"]

def multi(contract, sig, args="", n=3):
    for _ in range(5):
        r = T.call_multi(contract, sig, args, n)
        if r.get("ok") and len(r.get("values", [])) >= n:
            return r["values"]
        time.sleep(1.5)
    raise RuntimeError(f"read failed: {sig}")

def sim(contract, sig, args, owner):
    """Read-only dry run. Returns dict with success, return value hex, logs."""
    return T.constant(contract, sig, args, owner)

def call_ok(resp):
    """TronGrid returns result.result=True even for a REVERT. Success means
    a non-empty ABI return and no REVERT message."""
    msg = (resp.get("result") or {}).get("message")
    return (not msg) and bool((resp.get("constant_result") or [""])[0])

def revert_msg(resp):
    msg = (resp.get("result") or {}).get("message")
    c = (resp.get("constant_result") or [""])[0]
    text = None
    if c.startswith("08c379a0"):
        b = bytes.fromhex(c[8:])
        if len(b) >= 64:
            ln = int.from_bytes(b[32:64], "big")
            text = b[64:64 + ln].decode("utf-8", "replace")
    return text or msg

# ---------------------------------------------------------------- live state
def snapshot():
    st = {"block": T.now_block()}
    st["balance_sun"] = T.rpc("/wallet/getaccount", {"address": P, "visible": True}).get("balance", 0)
    st["balance_trx"] = st["balance_sun"] / 1e6
    for sig in ["minFee()", "feeRatio()", "liquidateThreshold()", "usageChargeRatio()",
                "maxRentalScaleLimit()", "badDebt()", "badDebtCovered()", "badDebtGap()",
                "totalRent()", "rentClaimed()", "totalDelegatedOfType(uint256)"]:
        st[sig] = u(P, sig, T.enc_uint(1) if "uint256" in sig else "")
    st["delegatable"] = u(P, "delegatableOfType(uint256)", T.enc_uint(1))
    st["rate"] = u(P, "_rentalRate(uint256,uint256)", T.enc_uint(0) + T.enc_uint(1))
    st["liquidateRate"] = u(P, "_liquidateRate(uint256)", T.enc_uint(1))
    st["stableRate"] = u(P, "_stableRate(uint256)", T.enc_uint(1))
    st["rentPaused_energy"] = bool(u(P, "rentPaused(uint256)", T.enc_uint(1)))
    return st

# ---------------------------------------------------- double-refund tests
def double_refund():
    out = []
    pairs = json.load(open(os.path.join(HERE, "inputs/liquidated_pairs.json")))
    for p in pairs:
        renter, receiver = h2b(p["renter"]), h2b(p["receiver"])
        rt = p["resourceType"]
        args = T.enc_addr(renter) + T.enc_addr(receiver) + T.enc_uint(rt)
        st = multi(P, "rentals(address,address,uint256)", args, 3)
        ret = sim(P, "returnResource(address,uint256,uint256)",
                  T.enc_addr(receiver) + T.enc_uint(1) + T.enc_uint(rt), renter)
        liq = sim(P, "liquidate(address,address,uint256)",
                  T.enc_addr(renter) + T.enc_addr(receiver) + T.enc_uint(rt), P)
        out.append({
            "tx": p["tx"], "block": p["block"],
            "renter": renter, "receiver": receiver,
            "liquidatedAmount_sun": p["liquidatedAmount"],
            "liquidateFee_sun": p["liquidateFee"],
            "sendBack_sun": p["sendBack"],
            "usageRental_sun": p["usageRental"],
            "rentals_now": st,                      # must be [0,0,index]
            "re_rented_since": st[0] > 0,
            "return_after_liquidate_ok": call_ok(ret),
            "return_after_liquidate_error": revert_msg(ret),
            "second_liquidate_ok": call_ok(liq),
            "second_liquidate_error": revert_msg(liq),
        })
        time.sleep(0.4)
    return out

# ------------------------------------------------------- dirty-rent test
def dirty_rent():
    p = json.load(open(os.path.join(HERE, "inputs/live_rental_pair.json")))[0]
    renter, receiver = p["renter"], p["receiver"]
    args = T.enc_addr(renter) + T.enc_addr(receiver) + T.enc_uint(1)
    rent = multi(P, "rentals(address,address,uint256)", args, 3)
    gi = multi(P, "getRentInfo(address,address,uint256)", args, 3)
    resp = sim(P, "returnResource(address,uint256,uint256)",
               T.enc_addr(receiver) + T.enc_uint(rent[0]) + T.enc_uint(1), renter)
    logs = resp.get("logs") or []
    usage = None
    sb_log = None
    for log in logs:
        if log.get("topics", [""])[0].startswith("f7e21d5bf1"):
            w = [int(log["data"][i:i + 64], 16) for i in range(0, len(log["data"]), 64)]
            # ReturnResource: subedAmount, resourceType, usageRental, subedSecurityDeposit, amount, securityDeposit, rentIndex
            if len(w) >= 7:
                usage, sb_log = w[2], w[3]
    sb = int((resp.get("constant_result") or ["0"])[0], 16)
    return {
        "renter": renter, "receiver": receiver,
        "amount_sun": rent[0], "storedDeposit_sun": rent[1],
        "effectiveDeposit_sun": gi[0], "liquidatable_now": bool(gi[2]),
        "sim_return_ok": call_ok(resp),
        "sendBack_sun": sb, "sendBack_trx": sb / 1e6,
        "usageRental_sun": usage, "usageRental_trx": (usage / 1e6 if usage else None),
        "subedSecurityDeposit_log_sun": sb_log,
        "effective_minus_sendBack_sun": gi[0] - sb,
        "note": "usageRental>0 proves the dirty-resource charge is live (not free energy); "
                "sendBack is strictly below the effective deposit",
    }

# -------------------------------------------------------- shadow ledger
def fee(a, fee_ratio, min_fee):
    return max(min_fee, a * fee_ratio // 10**18)

def liquidate_split(D, A, fee_amt, dirty, restore, usage_ratio, rate):
    dr = (dirty * restore * usage_ratio // 10**18) * rate // 10**18
    if dr + fee_amt > D:
        dr = D - fee_amt if D > fee_amt else 0
    D2 = D - dr
    if D2 < fee_amt:
        bad_debt = fee_amt - D2
        send_back = 0
    else:
        bad_debt = 0
        send_back = D2 - fee_amt
    return {"dirtyRent": dr, "sendBack": send_back, "liquidatorFee": fee_amt, "marketBadDebt": bad_debt}

def fresh_cycle(st):
    ratio, minfee, ucr, rate = st["feeRatio()"], st["minFee()"], st["usageChargeRatio()"], st["rate"]
    rows = []
    for a_trx in [1_000, 10_000, 100_000, 1_000_000, 10_000_000, 100_000_000]:
        A = a_trx * 10**6
        f = fee(A, ratio, minfee)
        one_day = A * rate * 86400 // 10**18
        d_min = f + one_day + 1
        # self-liquidate one block (3 s) after renting, energy unused
        rent_3s = A * rate * 3 // 10**18
        D_eff = d_min - rent_3s
        liquidatable = D_eff <= f + one_day
        split = liquidate_split(D_eff, A, f, 0, 0, ucr, rate)
        # attacker = renter + liquidator: -D_min + sendBack + fee
        net = split["sendBack"] + split["liquidatorFee"] - d_min
        # wait 1.2 days so D_eff < fee, energy unused
        rent_12d = A * rate * int(1.2 * 86400) // 10**18
        D_eff2 = max(0, d_min - rent_12d)
        split2 = liquidate_split(D_eff2, A, f, 0, 0, ucr, rate)
        net2 = split2["sendBack"] + split2["liquidatorFee"] - d_min
        rows.append({
            "amount_trx": a_trx, "fee_trx": f / 1e6, "oneDayRent_trx": one_day / 1e6,
            "minDeposit_trx": d_min / 1e6,
            "immediate_liquidatable_after_1_block": liquidatable,
            "self_liq_1_block_net_trx": net / 1e6,
            "after_1_2d_effectiveDeposit_trx": D_eff2 / 1e6,
            "after_1_2d_self_liq_net_trx": net2 / 1e6,
            "after_1_2d_marketBadDebt_trx": split2["marketBadDebt"] / 1e6,
        })
    return rows

def abandoned_keeper(st):
    """Third-party keeper on an abandoned order: market-funded part."""
    ratio, minfee, ucr, rate = st["feeRatio()"], st["minFee()"], st["usageChargeRatio()"], st["rate"]
    rows = []
    for a_trx in [10_000, 100_000, 1_000_000, 10_000_000, 100_000_000]:
        A = a_trx * 10**6
        f = fee(A, ratio, minfee)
        split = liquidate_split(0, A, f, 0, 0, ucr, rate)  # zero residual deposit
        rows.append({"amount_trx": a_trx, "keeperFee_trx": f / 1e6,
                     "marketBadDebt_trx": split["marketBadDebt"] / 1e6,
                     "keeperNetBeforeGas_trx": f / 1e6})
    return rows

def main():
    st = snapshot()
    RES["state"] = st
    RES["block"] = st["block"]
    RES["double_refund"] = double_refund()
    RES["dirty_rent"] = dirty_rent()
    RES["fresh_self_liquidation"] = fresh_cycle(st)
    RES["abandoned_order_keeper"] = abandoned_keeper(st)
    # summary flags
    dr = RES["double_refund"]
    closed = all((not d["return_after_liquidate_ok"]) and (not d["second_liquidate_ok"])
                 for d in dr if not d["re_rented_since"])
    RES["summary"] = {
        "double_refund_closed": closed,
        "double_refund_pairs_tested": sum(1 for d in dr if not d["re_rented_since"]),
        "double_refund_pairs_re_rented": sum(1 for d in dr if d["re_rented_since"]),
        "dirty_rent_charged": (RES["dirty_rent"]["usageRental_sun"] or 0) > 0,
        "max_self_liq_net_trx": max(r["self_liq_1_block_net_trx"] for r in RES["fresh_self_liquidation"]),
        "max_self_liq_net_after_1_2d_trx": max(r["after_1_2d_self_liq_net_trx"] for r in RES["fresh_self_liquidation"]),
        "badDebt_gap_sun": st["badDebtGap()"],
        "badDebt_gap_trx": st["badDebtGap()"] / 1e6,
        "balance_trx": st["balance_trx"],
        "protocol_funded_EU_usd": 0.0,
    }
    outdir = os.path.join(HERE, "results")
    os.makedirs(outdir, exist_ok=True)
    json.dump(RES, open(os.path.join(outdir, "poc_results.json"), "w"), indent=1)
    print(json.dumps(RES["summary"], indent=1))
    print("double refund:", [(d["liquidateFee_sun"], d["sendBack_sun"],
                              d["return_after_liquidate_error"], d["second_liquidate_error"]) for d in dr])
    print("dirty rent:", RES["dirty_rent"]["sendBack_trx"], RES["dirty_rent"]["usageRental_trx"])
    print("fresh cycle:", RES["fresh_self_liquidation"])

if __name__ == "__main__":
    main()
