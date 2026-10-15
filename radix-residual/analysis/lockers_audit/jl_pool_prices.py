#!/usr/bin/env python3
"""Best-effort pricing for large unpriced locked tokens: find a DEX pool holding
the token + XRD and derive price = xrd_reserve / token_reserve."""
import json
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, entity_details  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
TARGETS = {
    "IN": "resource_rdx1tk0l59kfzphrr92ahz86dyyx5s0muwu5ehqukup0dx3judnepajkpl",
    "FOGO": "resource_rdx1t4u0ud77awqdx4lyma4w7c346mw7mz4563w0rhhhpnysjv82huur5w",
    "sREDDICKS": "resource_rdx1t4ay2r4m8gm8rylyz73gu4dfrg08wrz3lnmqqun62ak78r60n9qhpf",
    "MEOWTA": "resource_rdx1tkkw6jzpvjl5an4uwqsg4da3v938vljnqfkrtpkm2s38n2uunfnp3j",
    "FLARE": "resource_rdx1tkeu62dp8vpqjak9r0wkq38u8u5js7kwywpld0jva98ne4mjy3fw8w",
    "BLUES": "resource_rdx1t4cdgz00gyx8uu358gv6gvsuks7upn0f3wd7j4am3l2nrpq9gcmu59",
    "WHY": "resource_rdx1t4hz8agr8qtkfn7q8prtc0vk99hzmz4mkncewahsysud32220pts3c",
    "SPED": "resource_rdx1t40mskhc977paq5trz77jn3zmk0r0lzvg6nwxlaqsgfcaklmrekdgq",
}

out = {}
for sym, res in TARGETS.items():
    holders = []
    cursor = None
    for _ in range(3):  # up to 300 holders
        body = {"resource_address": res, "limit_per_page": 100}
        if cursor:
            body["cursor"] = cursor
        r = post("/extensions/resource-holders/page", body)
        holders.extend(r.get("items", []))
        cursor = r.get("next_cursor")
        if not cursor:
            break
    comps = [h for h in holders if not h["holder_address"].startswith("account_")][:12]
    if not comps:
        out[sym] = {"resource": res, "price_xrd": None, "note": "no component holders in top pages"}
        continue
    addrs = [h["holder_address"] for h in comps]
    det = entity_details(addrs, aggregation_level="Global")
    best = None
    for it in det["items"]:
        funs = {f["resource_address"]: f["amount"] for f in it.get("fungible_resources", {}).get("items", [])}
        if XRD in funs and res in funs:
            xrd_amt = float(funs[XRD])
            tok_amt = float(funs[res])
            if tok_amt > 0 and xrd_amt > 0:
                price = xrd_amt / tok_amt
                nm = it.get("details", {}).get("blueprint_name")
                cand = {"pool": it["address"], "blueprint": nm,
                        "xrd_reserve": xrd_amt, "token_reserve": tok_amt,
                        "price_xrd": price}
                if best is None or xrd_amt > best["xrd_reserve"]:
                    best = cand
    out[sym] = {"resource": res, "pool_price": best}
    print(sym, json.dumps(best)[:220])
json.dump(out, open(f"{OUT}/jl_pool_prices.json", "w"), indent=1)
