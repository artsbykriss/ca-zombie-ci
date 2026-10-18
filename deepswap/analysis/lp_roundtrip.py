#!/usr/bin/env python3
"""Exact deposit->withdraw round-trip simulation for the DeepSwap pool with burned LP.

The pool_state.lp_supply is 5,312.897 (raw 5,312,897,514,527) but the LP mint supply is 0.
A new depositor mints LP against the phantom supply; the program rounds deposits UP and
withdrawals DOWN. This proves the round trip cannot return more than was deposited.
"""
import json

R0 = 358_467_893_506      # WSOL vault, lamports
R1 = 78_884_379_116_951   # DEEP vault, 6 decimals
S = 5_312_897_514_527     # pool_state.lp_supply (raw, 9 decimals)

def ceil_div(a, b):
    return (a + b - 1) // b

rows = []
for L in [1, 10**3, 10**6, 10**9, S // 2, S, 2 * S, 10 * S]:
    d0 = ceil_div(L * R0, S)
    d1 = ceil_div(L * R1, S)
    n0, n1, nS = R0 + d0, R1 + d1, S + L
    w0, w1 = L * n0 // nS, L * n1 // nS
    rows.append({"lp": L, "deposit0": d0, "deposit1": d1,
                 "withdraw0": w0, "withdraw1": w1,
                 "delta0": w0 - d0, "delta1": w1 - d1})
    print(rows[-1])

any_positive = any(r["delta0"] > 0 or r["delta1"] > 0 for r in rows)
print("any positive delta:", any_positive)
json.dump({"R0": R0, "R1": R1, "S": S, "rows": rows, "any_positive": any_positive},
          open("/home/heisenberg/CA/deepswap/analysis/lp_roundtrip.json", "w"), indent=1)
assert not any_positive, "round trip extracted value"
