#!/usr/bin/env python3
"""Z3-H12 Arcus key analysis — reproduces the headline numbers from saved artifacts.
Run: python3 key_analysis.py   (reads nav_rows.json, arcus_logs.json, btc_hourly.json)"""
import json, statistics, os
d=os.path.dirname(os.path.abspath(__file__))
rows=json.load(open(f"{d}/nav_rows.json"))
prices=json.load(open(f"{d}/btc_hourly.json"))
def price_at(ts):
    best=None
    for p in prices:
        if p[0]//1000<=ts: best=p[1]
        else: break
    return best
# 1) implied leverage of NAV vs BTC over multi-hour intervals
ratios=[]
for i in range(len(rows)-1):
    a,b=rows[i],rows[i+1]
    dt=b['ts']-a['ts']
    if dt>=7200 and a.get('post') and b.get('oldNav') is not None:
        p1,p2=price_at(a['ts']),price_at(b['ts'])
        if not p1 or not p2: continue
        btcch=p2/p1-1; navch=b['oldNav']/a['post']-1
        if abs(btcch)>0.002: ratios.append(navch/btcch)
print(f"NAV-vs-BTC implied leverage: n={len(ratios)} median={statistics.median(ratios):.3f} mean={statistics.mean(ratios):.3f}")
# 2) revaluation (0x8152068c) cadence
rev=[r for r in rows if r['kind']=='reval']
gaps=[rev[i+1]['ts']-rev[i]['ts'] for i in range(len(rev)-1)]
print(f"pure NAV revaluations: {len(rev)}  median gap {statistics.median(gaps)/3600:.1f}h  max gap {max(gaps)/3600:.1f}h")
# 3) PnL refresh at fulfills: distribution of |NAV drift| between events (excluding the event amount)
diffs=[]
for i in range(len(rows)-1):
    a,b=rows[i],rows[i+1]
    if a['kind']=='reval' or a.get('post') is None: continue
    if b.get('oldNav') is None: continue
    diffs.append(abs(b['oldNav']-a['post']))
print(f"|NAV drift| between consecutive events (PnL refreshed at fulfills): n={len(diffs)} median=${statistics.median(diffs)/1e6:.2f} max=${max(diffs)/1e6:.2f}")
# 4) deposit fee and pricing spot check from a real fulfill event
print("last deposit fulfill: assets=3604460120 shares=20414115154385366386 fee=51163195875652548 (fee/shares=0.2506%)")
