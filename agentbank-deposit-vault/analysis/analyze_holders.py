#!/usr/bin/env python3
import json, collections

V = "0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1".lower()
tx = json.load(open("tokentx_all.json"))
print("transfers:", len(tx))
bal = collections.Counter()
mint = collections.Counter()
burn = collections.Counter()
zero = "0x0000000000000000000000000000000000000000"
for t in tx:
    v = int(t["value"])
    f, to = t["from"].lower(), t["to"].lower()
    if f == zero:
        mint[to] += v
    if to == zero:
        burn[f] += v
    bal[f] -= v
    bal[to] += v
net = {a: b for a, b in bal.items() if b != 0}
print("distinct holders (net nonzero):", len(net))
tot = sum(net.values())
print("sum of net balances (wei):", tot, "=", tot / 1e18, "shares")
print("\nTop 25 holders:")
for a, b in sorted(net.items(), key=lambda x: -x[1])[:25]:
    print(f"  {a} {b/1e18:,.6f}")
print("\nTop depositors (mint):")
for a, b in sorted(mint.items(), key=lambda x: -x[1])[:15]:
    print(f"  {a} minted {b/1e18:,.4f}")
print("\nTop redeemers (burn):")
for a, b in sorted(burn.items(), key=lambda x: -x[1])[:15]:
    print(f"  {a} burned {b/1e18:,.4f}")
# vault WLD flows: deposits = WLD into vault, withdrawals = out
