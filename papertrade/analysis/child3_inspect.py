#!/usr/bin/env python3
"""Inspect book depth coverage in bp terms."""
import json

for coin in ("BTC", "ETH"):
    d = json.load(open(f"/home/heisenberg/CA/papertrade/analysis/child3-books-{coin}.json"))
    book = d["response"]
    bids = [(float(l["px"]), float(l["sz"])) for l in book["levels"][0]]
    asks = [(float(l["px"]), float(l["sz"])) for l in book["levels"][1]]
    mid = (bids[0][0] + asks[0][0]) / 2
    print(f"=== {coin} mid={mid} fetched={d['fetched_at_utc']}")
    print(" asks: top..last px", asks[0][0], asks[-1][0], f"({(asks[-1][0]/mid-1)*1e4:.1f} bp)")
    print(" bids: top..last px", bids[0][0], bids[-1][0], f"({(1-bids[-1][0]/mid)*1e4:.1f} bp)")
    total_ask_usd = sum(p * s for p, s in asks)
    total_bid_usd = sum(p * s for p, s in bids)
    print(f" total ask notional in 20 levels: ${total_ask_usd:,.0f}")
    print(f" total bid notional in 20 levels: ${total_bid_usd:,.0f}")
    print(" ask levels (px, sz, notional, bp from mid):")
    cum = 0
    for p, s in asks[:20]:
        cum += p * s
        print(f"   {p:>10.2f} {s:>10.4f} ${p*s:>12,.0f}  cum ${cum:>14,.0f}  {(p/mid-1)*1e4:6.2f} bp")
    print(" bid levels:")
    cum = 0
    for p, s in bids[:20]:
        cum += p * s
        print(f"   {p:>10.2f} {s:>10.4f} ${p*s:>12,.0f}  cum ${cum:>14,.0f}  {(1-p/mid)*1e4:6.2f} bp")
    print()
