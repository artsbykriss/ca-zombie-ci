#!/usr/bin/env python3
"""Final consolidated live-state snapshot of all Eklipse pools (pinned block)."""
import json, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from rpc2 import rpc, eth_call

PRECISION = 10**18
BLOCK = int(rpc("eth_blockNumber", []), 16)
BH = hex(BLOCK)
print("block", BLOCK, flush=True)

def enc(sig4, *args):
    d = sig4
    for a in args: d += hex(int(a))[2:].rjust(64, "0")
    return d
def call(to, sig4, *args):
    for _ in range(6):
        r = eth_call(to, enc(sig4, *args), BH)
        if isinstance(r, str): return r
    return None
def u(r): return int(r, 16) if isinstance(r, str) and r not in ("0x", "") else None
def words(h):
    if not isinstance(h, str) or h == "0x": return []
    b = h[2:]; return [b[i:i+64] for i in range(0, len(b), 64)]
def ad(w): return "0x" + w[-40:]

PRICES = {
    "KDAI": 0.09635042744861741,
    "oUSDT": 0.10509040883124349,
    "oUSDC": 0.29619875144537683,
    "pUSD": 1.0002535922982352,
    "EKL": 0.0, "KSD": 0.0, "KASH": 0.0, "oBUSD": 0.0, "USDK": 0.0,
}
TOK = {
    "KDAI": ("0x5c74070fdea071359b86082bd9f9b3deaafbe32b", 18),
    "oUSDT": ("0xcee8faf64bb97a73bb51e115aa89c17ffa8dd167", 6),
    "oUSDC": ("0x754288077d0ff82af7a5317c7cb8c444d421d103", 6),
    "pUSD": ("0x168439b5eebe8c83db9eef44a0d76c6f54767ae4", 18),
    "KSD": ("0x4fa62f1f404188ce860c8f0041d6ac3765a72e67", 18),
    "KASH": ("0xce40569d65106c32550626822b91565643c07823", 18),
    "oBUSD": ("0x210bc03f49052169d5588a52c317f71cf2078b85", 18),
    "USDK": ("0xd2137fdf10bd9e4e850c17539eb24cfe28777753", 18),
}
POOLS = {
    "base":  "0x4F5d9F3b17988aA047e6F1Bc511fEc0BF25691f4",
    "meta":  "0xe59234EeDC854b3b37D48EFd8a529069C3990F83",
    "p3":    "0x323fdda29fa2B8028eF9Fb48c1D45e5A39214D9A",
    "p4":    "0x5B4ed8321ea13047195104037798f29257EAc28c",
    "p5":    "0x29c6Eb808020Ef4889A9f25d35b69edBAfB0C78e",
    "p6":    "0x7f352a4332fAD433D381d700118f8C9b0A1E1abb",
    "p7":    "0xB1b782f2D30505e9984e37e00C6494437d94c223",
    "p8":    "0xddA06aaB425a1A390c131F790A56AB3380e3B7EC",
    "p9":    "0x75Dc33f8247245E8E08852E68E7f275E2a41fD40",
}
BASE_LP = "0xd83b9dfa49d6c6d2a69554576e712e45a8a13e49"
META_LP = "0x63c7d72963ed6e0c255835b606bef55ebeb1b5f8"

out = {"block": BLOCK, "pools": {}}
total_usd = 0.0
for name, addr_ in POOLS.items():
    rec = {"address": addr_}
    wt = words(call(addr_, "0xaa6ca808"))
    n = u(wt[1]) if wt else 0
    toks = [ad(wt[2+i]) for i in range(n)]
    wb = words(call(addr_, "0xa1dc9031"))
    bals = [u(wb[2+i]) for i in range(n)]
    vp = u(call(addr_, "0xe25aa5fa")); A = u(call(addr_, "0xd46300fd"))
    rec["owner"] = ad(words(call(addr_, "0x8da5cb5b"))[0])
    rec["paused"] = u(call(addr_, "0x5c975abb"))
    rec["A"] = A; rec["vp"] = vp
    rec["lpToken"] = ad(words(call(addr_, "0x8214f5a4"))[0])
    rec["tokens"] = []
    usd = 0.0
    for t, b in zip(toks, bals):
        sym = None; dec = 18
        for k, (a2, d2) in TOK.items():
            if a2.lower() == t.lower(): sym, dec = k, d2; break
        if sym is None and t.lower() == BASE_LP.lower(): sym, dec = "baseLP", 18
        amt = b / 10**dec
        if sym == "baseLP":
            # real value of the base LP = share of base pool's market value
            p = None
        else:
            p = PRICES.get(sym, 0.0)
        v = amt * p if p else 0.0
        rec["tokens"].append({"symbol": sym, "address": t, "balance": str(b), "amount": amt, "usd": round(v, 2)})
        usd += v
    rec["usd_priced"] = round(usd, 2)
    total_usd += usd
    out["pools"][name] = rec
    print(f"{name:5s} {addr_} owner={rec['owner'][:10]} paused={rec['paused']} A={A} vp={vp/1e18:.9f} lp={rec['lpToken']}", flush=True)
    for t in rec["tokens"]:
        print(f"      {str(t['symbol']):8s} {t['amount']:>20.6f}  usd={t['usd']}", flush=True)

# base LP real value
base = out["pools"]["base"]
base_usd = base["usd_priced"]
base_lp_supply = u(call(BASE_LP, "0x18160ddd"))
base_lp_usd = base_usd / (base_lp_supply / 1e18)
print(f"\nbase pool priced USD = {base_usd:.2f}; base LP supply = {base_lp_supply/1e18:.3f}; real USD/LP = {base_lp_usd:.5f}")
out["base_lp_real_usd"] = base_lp_usd
# add real value of baseLP held by other pools
extra = 0.0
for name, rec in out["pools"].items():
    for t in rec["tokens"]:
        if t["symbol"] == "baseLP":
            extra += t["amount"] * base_lp_usd
            t["usd"] = round(t["amount"] * base_lp_usd, 2)
print(f"baseLP held by other pools real USD = {extra:.2f}")
out["total_priced_usd"] = round(total_usd + extra, 2)
print(f"TOTAL priced USD (incl baseLP at real value) = {total_usd + extra:.2f}")
with open(os.path.join(os.path.dirname(__file__), "final_state.json"), "w") as f:
    json.dump(out, f, indent=1)
print("saved final_state.json")
