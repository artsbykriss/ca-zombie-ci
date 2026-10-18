#!/usr/bin/env python3
"""Snapshot MarketG1 live state (read-only). Public endpoints only."""
import json, time, hashlib, urllib.request
import tronlib as T

P = "TU2MJ5Veik1LRAgjeSzEdvmDYx7mefJZvd"
S = "TU3kjFuhtEo42tsCBtfYUAZxoqQ4yuSLQ5"
RM = "TXA2WjFc5f86deJcZZCdbdpkpUTKTA3VDM"

def b58(n):
    h = format(int(n), "x").zfill(40)
    raw = bytes.fromhex("41" + h)
    chk = hashlib.sha256(hashlib.sha256(raw).digest()).digest()[:4]
    return T.b58encode(raw + chk)

def u(contract, sig, args=""):
    r = T.call_uint(contract, sig, args)
    return r.get("value")

def m(contract, sig, args="", n=2):
    r = T.call_multi(contract, sig, args, n)
    return r.get("values")

out = {"generated_at": int(time.time()), "contract": P, "strx": S, "rate_model": RM}
out["block"] = T.now_block()
out["proxy_balance_sun"] = T.rpc("/wallet/getaccount", {"address": P, "visible": True}).get("balance", 0)
out["proxy_balance_trx"] = out["proxy_balance_sun"] / 1e6

for sig in ["admin()", "pendingAdmin()", "implementation()", "pendingImplementation()",
            "strx()", "initialized()", "minFee()", "feeRatio()", "liquidateThreshold()",
            "usageChargeRatio()", "rateRampTime()", "maxRentalScaleLimit()",
            "badDebt()", "badDebtCovered()", "badDebtGap()", "totalRent()", "rentClaimed()",
            "totalDelegated()", "totalUnfreezable()", "rentalRateModels(uint256)"]:
    args = T.enc_uint(1) if "uint256" in sig else ""
    v = u(P, sig, args)
    if sig in ("admin()", "pendingAdmin()", "implementation()", "pendingImplementation()", "strx()"):
        out[sig] = {"raw": v, "base58": b58(v) if v else None}
    elif sig == "rentalRateModels(uint256)":
        out[sig] = {"raw": v, "base58": b58(v) if v else None}
    else:
        out[sig] = v

for t in [0, 1]:
    out[f"rentPaused[{t}]"] = bool(u(P, "rentPaused(uint256)", T.enc_uint(t)))
    out[f"totalDelegatedOfType[{t}]"] = u(P, "totalDelegatedOfType(uint256)", T.enc_uint(t))
    out[f"totalUnfreezableOfType[{t}]"] = u(P, "totalUnfreezableOfType(uint256)", T.enc_uint(t))
    out[f"delegatableOfType[{t}]"] = u(P, "delegatableOfType(uint256)", T.enc_uint(t))
    out[f"maxRentableOfType[{t}]"] = u(P, "maxRentableOfType(uint256)", T.enc_uint(t))
    out[f"globalRentState[{t}]"] = m(P, "globalRentState(uint256)", T.enc_uint(t), 2)
    out[f"initialRentRate[{t}]"] = m(P, "initialRentRate(uint256)", T.enc_uint(t), 2)
    out[f"futureRentRate[{t}]"] = m(P, "futureRentRate(uint256)", T.enc_uint(t), 2)
    out[f"_rentalRate(0,{t})"] = u(P, "_rentalRate(uint256,uint256)", T.enc_uint(0) + T.enc_uint(t))
    out[f"_liquidateRate({t})"] = u(P, "_liquidateRate(uint256)", T.enc_uint(t))
    out[f"_stableRate({t})"] = u(P, "_stableRate(uint256)", T.enc_uint(t))

out["rate_model_params"] = {k: u(RM, f"{k}()") for k in ["baseRate", "multiplier", "jumpMultiplier", "kink"]}
out["strx_state"] = {
    "market": b58(u(S, "market()")),
    "totalRentIncome": u(S, "totalRentIncome()"),
    "totalUnderlying": u(S, "totalUnderlying()"),
    "exchangeRate": u(S, "exchangeRate()"),
}
try:
    p = json.loads(urllib.request.urlopen("https://coins.llama.fi/prices/current/coingecko:tron", timeout=30).read())
    out["trx_price_usd"] = p["coins"]["coingecko:tron"]["price"]
except Exception as e:
    out["trx_price_usd"] = None
    out["price_error"] = str(e)
if out.get("trx_price_usd"):
    out["proxy_balance_usd"] = out["proxy_balance_trx"] * out["trx_price_usd"]

json.dump(out, open("live_state.json", "w"), indent=1)
print(json.dumps(out, indent=1)[:3000])
