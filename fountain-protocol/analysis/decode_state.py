#!/usr/bin/env python3
"""Decode the raw state dump into a human-readable summary (stdout)."""
import json, sys

def u(h):
    if not isinstance(h, str) or h == "0x": return None
    return int(h, 16)
def a(h):
    if not isinstance(h, str) or len(h) < 42: return None
    return "0x" + h[-40:]
def s(h):
    if not isinstance(h, str) or h == "0x": return None
    b = bytes.fromhex(h[2:])
    try:
        if len(b) >= 64:
            off = int.from_bytes(b[:32], "big")
            ln = int.from_bytes(b[off:off+32], "big")
            return b[off+32:off+32+ln].decode("utf-8", "replace")
        return b.decode("utf-8", "replace")
    except Exception:
        return None
def wad(x):
    return None if x is None else x / 1e18

d = json.load(open(sys.argv[1]))
print("block:", d["pinned_block"], "latest:", d["latest"])
for label, c in d["comptrollers"].items():
    print(f"\n=== comptroller [{label}] {c['address']}")
    print("  admin:", a(c["admin()"]), " pendingAdmin:", a(c["pendingAdmin()"]))
    print("  oracle:", a(c["oracle()"]), " closeFactor:", wad(u(c["closeFactorMantissa()"])),
          " liqIncentive:", wad(u(c["liquidationIncentiveMantissa()"])))
    print("  pauseGuardian:", a(c["pauseGuardian()"]), " compAddress:", a(c["compAddress()"]))
    print("  markets:", len(c["markets"]))
    for m in c["markets"]:
        f = c["pause_flags"][m]
        t = d["markets"][m]
        print(f"  - {m} {s(t['symbol()'])!r} cash={u(t['getCash()'])} borrows={u(t['totalBorrows()'])}"
              f" supply={u(t['totalSupply()'])} reserves={u(t['totalReserves()'])}"
              f" listed={f.get('isListed')} cf={wad(f.get('collateralFactorMantissa'))}"
              f" paused(m/b/t/s)={f['mint']}/{f['borrow']}/{f['transfer']}/{f['seize']}")
        und = a(t["underlying()"])
        print(f"      underlying={und} exchRate={u(t['exchangeRateStored()'])} rf={wad(u(t['reserveFactorMantissa()']))}"
              f" dec={u(t['decimals()'])} admin={a(t['admin()'])} irm={a(t['interestRateModel()'])}"
              f" oracle_price={u(t.get('oracle_getUnderlyingPrice'))}")
        if isinstance(t["underlying()"], dict):
            print("      underlying() RAW:", json.dumps(t["underlying()"])[:160])
print("\ncode sizes:", {k: (len(v)//2-1 if isinstance(v,str) else v) for k, v in d["raw"]["code"].items()})
