#!/usr/bin/env python3
"""Borrower/position analysis for Hover markets (read-only, batched)."""
import json, sys, time, urllib.request
sys.path.insert(0, ".")
from rpc import sel, enc_addr, batch, rpc

COMP = "0x3A4Ec955a18eF6eB33025599505E7d404a4d59eC"
MARKETS = {
    "hKAVA": "0xb51eFaF2f7aFb8a2F5Be0b730281E414FB487636",
    "hATOM": "0x1Bf92bE674483D54A8E3A589e456c39eAC4339bd",
    "hUSDT": "0xcE86EBc669BBf07A64A0a55BB105Cc2B5B5d1961",
}
CF = {"hKAVA": 0.60, "hATOM": 0.35, "hUSDT": 0.85}
DEC_UND = {"hKAVA": 18, "hATOM": 6, "hUSDT": 6}
PRICE = {"hKAVA": 0.06850863923316375, "hATOM": 1.6864361950103595, "hUSDT": 0.9991027317556025}

def borrowers(market):
    d = json.load(open(f"logs_{market}_Borrow.json"))
    out = set()
    for e in d:
        t = e["topics"]; data = e["data"]
        out.add("0x" + (t[1][-40:] if len(t) >= 2 else data[26:66]))
    return out

def main():
    addrs = sorted(set().union(*[borrowers(m) for m in MARKETS]))
    print(f"unique borrowers: {len(addrs)}")
    block = rpc("eth_blockNumber", [])
    # exchange rates
    rates = {}
    for m, a in MARKETS.items():
        r = batch([(a, sel("exchangeRateStored()"))], block=block)[0]
        rates[m] = int(r, 16)
    print("exchangeRateStored:", {k: v for k, v in rates.items()})
    # account snapshots
    calls = []
    meta = []
    for addr in addrs:
        for m, a in MARKETS.items():
            calls.append((a, sel("getAccountSnapshot(address)") + enc_addr(addr)))
            meta.append((addr, m))
    res = []
    for i in range(0, len(calls), 60):
        res.extend(batch(calls[i:i+60], block=block))
        if i % 600 == 0:
            print(f"  {i}/{len(calls)}", flush=True)
    snap = {}
    for (addr, m), r in zip(meta, res):
        if isinstance(r, dict):
            snap[(addr, m)] = None
        else:
            h = r[2:]
            err = int(h[0:64], 16); tok = int(h[64:128], 16); bor = int(h[128:192], 16); r2 = int(h[192:256], 16)
            snap[(addr, m)] = (err, tok, bor, r2)
    out = []
    for addr in addrs:
        row = {"address": addr, "positions": {}, "collateral_usd": 0, "debt_usd": 0, "liquidity_usd": 0}
        for m in MARKETS:
            s = snap.get((addr, m))
            if not s: 
                row["positions"][m] = "ERR"
                continue
            err, tok, bor, rate = s
            coll = tok * rate / 1e18 / (10 ** DEC_UND[m])
            debt = bor / (10 ** DEC_UND[m])
            row["positions"][m] = {"cTokens": tok, "collateral_units": coll, "debt_units": debt, "rate": rate, "snap_err": err}
            row["collateral_usd"] += coll * PRICE[m]
            row["debt_usd"] += debt * PRICE[m]
            row["liquidity_usd"] += coll * PRICE[m] * CF[m]
        row["shortfall_usd"] = max(0.0, row["debt_usd"] - row["liquidity_usd"])
        row["net_usd"] = row["collateral_usd"] - row["debt_usd"]
        row["collateral_usd"] = round(row["collateral_usd"], 2)
        row["debt_usd"] = round(row["debt_usd"], 2)
        row["liquidity_usd"] = round(row["liquidity_usd"], 2)
        row["shortfall_usd"] = round(row["shortfall_usd"], 2)
        row["net_usd"] = round(row["net_usd"], 2)
        out.append(row)
    json.dump({"block": int(block, 16), "rates": rates, "prices": PRICE, "cf": CF, "borrowers": out}, open("borrowers.json", "w"), indent=1)
    liq = [r for r in out if r["shortfall_usd"] > 0.01]
    print(f"\nborrowers with shortfall: {len(liq)}")
    for r in sorted(liq, key=lambda x: -x["shortfall_usd"])[:25]:
        print(f"  {r['address']} coll=${r['collateral_usd']:,.2f} debt=${r['debt_usd']:,.2f} liq=${r['liquidity_usd']:,.2f} short=${r['shortfall_usd']:,.2f} net=${r['net_usd']:,.2f}")
    active = [r for r in out if r["debt_usd"] > 0.01]
    print(f"\nborrowers with debt > $0.01: {len(active)}")
    for r in sorted(active, key=lambda x: -x["debt_usd"])[:25]:
        print(f"  {r['address']} coll=${r['collateral_usd']:,.2f} debt=${r['debt_usd']:,.2f} short=${r['shortfall_usd']:,.2f} net=${r['net_usd']:,.2f}")

if __name__ == "__main__":
    main()
