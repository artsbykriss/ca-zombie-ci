#!/usr/bin/env python3
"""Valuation of Pools Finance (IOTA L1) pools using on-chain reserves + pool-implied prices.
Anchor: IOTA = $0.0453 (DefiLlama coingecko:iota, 2026-10-15). All other non-stable
tokens are priced from AMM pool ratios (chain-implied), VUSD/USDT0 at $0.94/$1.00."""
import json

IOTA_USD = 0.0453
VUSD_USD = 0.9428   # from IOTA/VUSD pool ratio (cross-checked with stIOTA/VUSD pool)
USDT0_USD = 1.0

snap = json.load(open('analysis/pool-snapshot.json'))

# pool-implied prices (token -> USD), derived from ratios; documented in README
# stIOTA from IOTA/stIOTA pool; vIOTA from stIOTA/vIOTA; TLN from stIOTA/TLN & vIOTA/TLN; etc.
res = {}
def rv(pool, key): return int(snap[pool][key])

# pool cd2b2764: IOTA/stIOTA
A =  rv('0xcd2b276437db9612fc7a8d85fe5b3b09a6b5638c0b3ab2003f5f7b284e353d8c','res_a')/1e9
B =  rv('0xcd2b276437db9612fc7a8d85fe5b3b09a6b5638c0b3ab2003f5f7b284e353d8c','res_b')/1e9
STIOTA_USD = IOTA_USD * A / B
# vIOTA from 716c2540 (stIOTA/vIOTA)
A2 =  rv('0x716c2540d0b79f55c3b093edb975a95c51a70d081d2339f29a4622758b413d27','res_a')/1e9
B2 =  rv('0x716c2540d0b79f55c3b093edb975a95c51a70d081d2339f29a4622758b413d27','res_b')/1e9
VIOTA_USD = STIOTA_USD * A2 / B2
# TLN from 16866908 (stIOTA/TLN) and 90c25188 (vIOTA/TLN)
A3 =  rv('0x168669080aafe0434d4b0b86ffa9e4786cdbb42de7074e3fcd6c40d4f987320f','res_a')/1e9
B3 =  rv('0x168669080aafe0434d4b0b86ffa9e4786cdbb42de7074e3fcd6c40d4f987320f','res_b')/1e9
TLN_USD = STIOTA_USD * A3 / B3
A4 =  rv('0x90c251884d6a99fd9536f1955a38323d90f75e58eef0593eedb386935373d298','res_a')/1e9
B4 =  rv('0x90c251884d6a99fd9536f1955a38323d90f75e58eef0593eedb386935373d298','res_b')/1e9
TLN_USD2 = VIOTA_USD * A4 / B4
# CYB from ab0fa403 (stIOTA/CYB)
A5 =  rv('0xab0fa403e2f366c56c31a8ddc6bfd7f236aafcf33cd8cd95b00d280e4d582f17','res_a')/1e9
B5 =  rv('0xab0fa403e2f366c56c31a8ddc6bfd7f236aafcf33cd8cd95b00d280e4d582f17','res_b')/1e6
CYB_USD = STIOTA_USD * A5 / B5
# BARBA from 62cf58f6 (IOTA/BARBA)
A6 =  rv('0x62cf58f654159333951f47aac462f4360e477ddf02af71f79b0bdf25278e9e47','res_a')/1e9
B6 =  rv('0x62cf58f654159333951f47aac462f4360e477ddf02af71f79b0bdf25278e9e47','res_b')/1e6
BARBA_USD = IOTA_USD * A6 / B6
# IRT from c3cb4e51 (IRT/vIOTA)
A7 =  rv('0xc3cb4e5156ca635526b22f05e5cc357d7cc7d7d5d0f3338fa15294a772e381b8','res_a')/1e9
B7 =  rv('0xc3cb4e5156ca635526b22f05e5cc357d7cc7d7d5d0f3338fa15294a772e381b8','res_b')/1e9
IRT_USD = VIOTA_USD * B7 / A7
# iBTC from 5bfad3ec (stIOTA/iBTC)
A8 =  rv('0x5bfad3ec1f92e45fce283849d8f84617edb232e63af665c5b76653b5e63d0ee1','res_a')/1e9
B8 =  rv('0x5bfad3ec1f92e45fce283849d8f84617edb232e63af665c5b76653b5e63d0ee1','res_b')/1e10
IBTC_USD = STIOTA_USD * A8 / B8

PRICES = {
    'IOTA': IOTA_USD, 'stIOTA': STIOTA_USD, 'vIOTA': VIOTA_USD,
    'VUSD': VUSD_USD, 'USDT0': USDT0_USD, 'TLN': TLN_USD,
    'CYB': CYB_USD, 'BRA': BARBA_USD, 'IRT': IRT_USD, 'iBTC': IBTC_USD,
}
DEC = {'IOTA':9,'stIOTA':9,'vIOTA':9,'VUSD':6,'USDT0':6,'TLN':9,'CYB':6,'BRA':6,'IRT':9,'iBTC':10}

out = {'prices': PRICES, 'tln_crosscheck': TLN_USD2, 'pools': [], 'total_usd': 0.0}
for pid, p in snap.items():
    a = int(p['res_a'])/10**DEC[p['sym_a']] * PRICES[p['sym_a']]
    b = int(p['res_b'])/10**DEC[p['sym_b']] * PRICES[p['sym_b']]
    aa = int(p['admin_a'])/10**DEC[p['sym_a']] * PRICES[p['sym_a']]
    bb = int(p['admin_b'])/10**DEC[p['sym_b']] * PRICES[p['sym_b']]
    out['pools'].append({'pool': pid, 'pair': f"{p['sym_a']}/{p['sym_b']}", 'reserve_usd': round(a+b,2),
                         'admin_fees_usd': round(aa+bb,2), 'lp_supply': p['lp_supply']})
    out['total_usd'] += a+b
    out['total_usd'] = round(out['total_usd'],2)
out['pools'].sort(key=lambda x: -x['reserve_usd'])
out['admin_fees_total_usd'] = round(sum(p['admin_fees_usd'] for p in out['pools']),2)
json.dump(out, open('analysis/valuation.json','w'), indent=1)
print(json.dumps(out, indent=1))
