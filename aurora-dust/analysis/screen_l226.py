#!/usr/bin/env python3
"""L2-26 screens: opBNB (LuigiSwap, CUBISwap, BinarySwap, DerpDEX), BTTC (Spooky/JustMoney/Intercroneswap/FilDA/Kyber/Elk/InfiniTORR/MDEX/UniFi/TORRSwap), Viction (LuaSwap factory quick check)."""
import sys, json
sys.path.insert(0, "/home/heisenberg/CA/aurora-dust/analysis")
from rpclib import rpc, batch, sel, enc_addr, enc_uint

GR = sel("getReserves()")
T0 = sel("token0()")
T1 = sel("token1()")
APL = sel("allPairsLength()")
BAL = sel("balanceOf(address)")
DEC = sel("decimals()")

def get_pairs(chain, factory, limit=400):
    n = rpc(chain, "eth_call", [{"to": factory, "data": APL}, "latest"])
    try: n = int(n, 16)
    except Exception: return None, None
    addrs = []
    for i in range(0, min(n, limit), 25):
        res = batch(chain, [("eth_call", [{"to": factory, "data": sel("allPairs(uint256)") + enc_uint(j)}, "latest"]) for j in range(i, min(i+25, n, limit))], chunk=25)
        for r in res:
            if isinstance(r, str) and r.startswith("0x") and len(r) >= 42:
                addrs.append("0x" + r[2:][24:64])
    return n, addrs

def scan(chain, factory, label, limit=400):
    n, addrs = get_pairs(chain, factory, limit)
    print(f"== {label} factory={factory} pairs={n}")
    if not addrs: return
    reserves = {}
    for i in range(0, len(addrs), 30):
        chunk = addrs[i:i+30]
        res = batch(chain, [("eth_call", [{"to": a, "data": GR}, "latest"]) for a in chunk], chunk=15)
        for a, r in zip(chunk, res):
            if isinstance(r, str) and len(r) >= 2+192:
                raw = r[2:]
                reserves[a] = (int(raw[:64],16), int(raw[64:128],16))
    live = {a: v for a, v in reserves.items() if v[0] > 10**9 or v[1] > 10**9}
    print(f"   reserves fetched={len(reserves)} live={len(live)}")
    # native balances of live pairs (skip; focus on token totals)
    return live

if __name__ == "__main__":
    # opBNB factories (from triage data)
    opbnb_targets = {
        "LuigiSwap": None,  # need factory address
        "CUBISwap": None,
        "BinarySwap": None,
        "DerpDEX": None,
    }
    # We don't have factory addresses yet; print placeholders
    print("need factories; loading from triage files")
    import glob
    for f in glob.glob("/home/heisenberg/CA/l2-triage-*/analysis/*.json"):
        pass
