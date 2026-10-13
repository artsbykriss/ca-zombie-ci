#!/usr/bin/env python3
"""Split each aToken's supply into: held by HF<1 borrowers (locked), held by HF>=1 borrowers,
and other holders (withdrawable). Also compute the cash coverage per reserve."""
import importlib.util, json

spec = importlib.util.spec_from_file_location("sb", "analysis/scan_borrowers.py")
sb = importlib.util.module_from_spec(spec); spec.loader.exec_module(sb)
sb.choose_rpc()

dec = {"DAI": 18, "ETH": 18, "WFTM": 18, "BTC": 8, "fUSDT": 6, "USDC": 6, "CRV": 18, "MIM": 18, "LINK": 18}
atoks, cash, supply = {}, {}, {}
for (sym, asset, vdebt) in sb.RESERVES:
    rd = sb.rpc("eth_call", [{"to": sb.POOL, "data": "0x35ea6a75" + asset[2:].rjust(64, "0")}, "latest"])
    b = bytes.fromhex(rd[2:])
    atok = "0x" + b[224+12:256].hex()
    atoks[sym] = atok
    bal = sb.rpc("eth_call", [{"to": asset, "data": "0x70a08231" + atok[2:].rjust(64, "0")}, "latest"])
    cash[sym] = int(bal, 16) / 10**dec[sym]
    ts = sb.rpc("eth_call", [{"to": atok, "data": "0x18160ddd"}, "latest"])
    supply[sym] = int(ts, 16) / 10**dec[sym]

d = json.load(open("ci-out/borrowers.json"))
bs = [b for b in d["borrowers"] if "healthFactor" in b]
HF1 = 10**18
locked_by = {"hf<1": [b for b in bs if int(b["healthFactor"]) < HF1],
             "hf>=1": [b for b in bs if int(b["healthFactor"]) >= HF1]}

out = {}
for grp, people in locked_by.items():
    multi = sb.multicall_balances_multi(list(atoks.values()), [b["address"] for b in people])
    inv = {v: k for k, v in atoks.items()}
    tot = {s: 0.0 for s in atoks}
    for a, per in multi.items():
        for t, v in per.items():
            tot[inv[t]] += v / 10**dec[inv[t]]
    out[grp] = tot

print(f"{'reserve':6s} {'cash':>16s} {'supply':>16s} {'cash%':>7s} {'HF<1 holders':>16s} {'HF>=1 holders':>16s} {'other':>16s}")
for s in atoks:
    l = out["hf<1"].get(s, 0.0)
    h = out["hf>=1"].get(s, 0.0)
    o = supply[s] - l - h
    cov = cash[s] / supply[s] * 100 if supply[s] else 0
    print(f"{s:6s} {cash[s]:16.4f} {supply[s]:16.4f} {cov:6.2f}% {l:16.4f} {h:16.4f} {o:16.4f}")
print()
print("HF<1 holder counts:", len(locked_by["hf<1"]), " HF>=1:", len(locked_by["hf>=1"]))
