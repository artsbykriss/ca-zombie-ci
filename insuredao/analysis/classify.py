#!/usr/bin/env python3
"""Compute the E-U / H-O / P / S split for InsureDAO Ethereum v1 from saved state."""
import json

ms = json.load(open('analysis/market-tokens.json'))
st = json.load(open('analysis/full-state.json'))['markets']

POOLS = [m for m in ms if m['symbol'] is None and m['crowdPool'] is None and m['addr'].lower() not in
         ('0xdaea5b1b6b12ac4c4f51ab12649e96ab3ab98c3a','0xd5f1ab3c61ef3a6a6f1aa6141256aa008d2fb5a1','0x7e08dab409ad1bcebc5be5674cb2c0f3540a4d3d')]
IDX = [m for m in ms if m['addr'].lower() in ('0xdaea5b1b6b12ac4c4f51ab12649e96ab3ab98c3a','0xd5f1ab3c61ef3a6a6f1aa6141256aa008d2fb5a1','0x7e08dab409ad1bcebc5be5674cb2c0f3540a4d3d')]
CDS = [m for m in ms if m['addr'].lower() == '0x86c82e8cd8a865f01a8cebed870af5d58e69a439']

tot_attrib = 0
print("== PoolTemplate markets ==")
lp_claims = 0; idx_premiums = 0; locked = 0
for r in POOLS:
    a = st[r['addr']]['vaultAttrib'] or 0
    ol = r['origLiq'] or 0; ad = r['attDebt'] or 0
    lk = r['lockedAmt'] or 0
    lp_claims += ol; idx_premiums += ad; locked += lk; tot_attrib += a
    assert a == ol + ad, (r['addr'], a, ol, ad)
    print(f"  {r['addr']} attrib={a}  LP={ol}  indexPrem={ad}  locked={lk}")
print(f"  SUM attrib={tot_attrib}  LP={lp_claims}  indexPrem={idx_premiums}  locked={locked}")

print("== IndexTemplate markets ==")
idx_lp = 0
for r in IDX:
    a = st[r['addr']]['vaultAttrib'] or 0
    idx_lp += a; tot_attrib += a
    print(f"  {r['addr']} attrib={a} totalLiq={r['totLiq']}")
print(f"  SUM index attrib={idx_lp}")

print("== CDS ==")
for r in CDS:
    a = st[r['addr']]['vaultAttrib'] or 0
    tot_attrib += a
    print(f"  {r['addr']} attrib={a} crowdPool={r['crowdPool']} surplus={r['surplusPool']}")

fees = st['0xF4d046D8FaC6dc37b5eAFAdd34407b19De3Ba350']['vaultAttrib']
print(f"\nPoolProxy fees (P) = {fees}")
print(f"Σ markets attributions = {tot_attrib}")
print(f"totalAttributions (chain) = 122292300439")
print(f"dust unaccounted = {122292300439 - tot_attrib - fees}")
ho = lp_claims + idx_premiums + idx_lp + CDS[0]['crowdPool']
print(f"\nH-O total (LP claims + index premiums + index LP + CDS LP) = {ho} raw = ${ho/1e6:.2f}")
print(f"E-U = 0 ; P = {fees} raw = ${fees/1e6:.4f}")
