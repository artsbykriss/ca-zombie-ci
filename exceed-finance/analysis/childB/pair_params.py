#!/usr/bin/env python3
import json, struct
pairs = json.load(open("/home/heisenberg/CA/exceed-finance/analysis/childB/all-pairs.json"))
print(f"{'symbol':8s} {'base':6s} {'rate':>10s} {'interval_rate':>16s} {'spi':>6s} {'deposit_cap':>20s} {'min_deposit':>14s} {'stake_bps':>9s} {'swap_bps':>8s} {'wd_bps':>6s} {'last_ts':>12s}")
for addr, p in pairs.items():
    ex = bytes.fromhex(p["extra"])
    dc = struct.unpack_from("<Q", ex, 0)[0]
    md = struct.unpack_from("<Q", ex, 8)[0]
    sf = struct.unpack_from("<H", ex, 16)[0]
    sw = struct.unpack_from("<H", ex, 18)[0]
    wd = struct.unpack_from("<H", ex, 20)[0]
    print(f"{p['symbol']:8s} {p['base_symbol']:6s} {p['last_rate']/1e12:>10.6f} {p['interval_rate']:>16d} {p['seconds_per_interval']:>6d} {dc:>20d} {md:>14d} {sf:>9d} {sw:>8d} {wd:>6d} {p['last_timestamp']:>12d}")
