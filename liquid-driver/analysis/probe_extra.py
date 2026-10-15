#!/usr/bin/env python3
"""Extra targeted reads for Liquid Driver — READ ONLY. Uses fetch_state helpers."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/liquid-driver/analysis")
from fetch_state import rpc_batch, call, call_many, addr_result, int_result, enc_addr, enc_uint

F = "fantom"
out = {}

def g(name, to, sig, args=None, chain=F):
    r = call(chain, to, sig, args)
    out[name] = r
    print(name, "=", r, flush=True)

MC = "0x742474dae70fa2ab063ab786b1fbe5704e861a0c"
XL = "0x3ae658656d1c526144db371faef2fff7170654ee"
LQDR = "0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9"
SFTMX = "0xd7028092c830b5c8fce061af2e593413ebbc1fc1"
WFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83"

# MasterChef extras
g("mc.lqdr", MC, "0x0714f3fc")
g("mc.devaddr", MC, "0xd49e77cd")
g("mc.feeAddress", MC, "0x41275358")
g("mc.lqdrPerBlock", MC, "0x11ca2d51")
g("mc.totalAllocPoint", MC, "0x17caf6f1")
g("mc.startBlock", MC, "0x48cd4cb1")
g("mc.owner", MC, "0x8da5cb5b")

# xLQDR extras
g("xl.admin", XL, "0xf851a440")
g("xl.token", XL, "0xfc0c546a")
g("xl.supply", XL, "0x047fc9aa")
g("xl.totalSupply", XL, "0x18160ddd")
g("xl.epoch", XL, "0x900cf0cf")
g("xl.controller", XL, "0xf77c4791")
g("xl.smart_wallet_checker", XL, "0x7175d4f7")

# LQDR
g("lqdr.owner", LQDR, "0x8da5cb5b")
g("lqdr.totalSupply", LQDR, "0x18160ddd")

# sFTMX: is it Stader's?
g("sftmx.totalSupply", SFTMX, "0x18160ddd")
g("sftmx.owner", SFTMX, "0x8da5cb5b")

# native balances of key contracts
for nm, a in (("mc", MC), ("xl", XL), ("sftmx", SFTMX)):
    r = rpc_batch(F, [("eth_getBalance", [a, "latest"])])[0]
    out[f"native.{nm}"] = int(r, 16) if isinstance(r, str) else r
    print(f"native.{nm}", out[f"native.{nm}"], flush=True)

# token balances of interest
probes = [
    ("sftmx.wftm", WFTM, "0x70a08231", enc_addr(SFTMX)),
    ("sftmx.lqdr", LQDR, "0x70a08231", enc_addr(SFTMX)),
    ("xl.wftm", WFTM, "0x70a08231", enc_addr(XL)),
    ("xl.lqdr", LQDR, "0x70a08231", enc_addr(XL)),
    ("mc.lqdrBal", LQDR, "0x70a08231", enc_addr(MC)),
    ("mc.wftmBal", WFTM, "0x70a08231", enc_addr(MC)),
    ("beethoven.wftm", WFTM, "0x70a08231", enc_addr("0x20dd72ed959b6147912c2e529f0a0c651c33c9ce")),
]
res = call_many(F, [(t, s, a) for (_, t, s, a) in probes])
for (nm, t, s, a), r in zip(probes, res):
    out[nm] = int_result(r)
    print(nm, out[nm], flush=True)

with open("/home/heisenberg/CA/liquid-driver/analysis/extra-reads.json", "w") as f:
    json.dump(out, f, indent=1)
print("saved extra-reads.json")
