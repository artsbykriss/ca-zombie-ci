#!/usr/bin/env python3
"""Fetch recent committed transactions touching the Weft market; save manifests."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, ledger_state

MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
POOL = "component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn"

ls = ledger_state()
print("head:", ls["state_version"])
stream = post("/stream/transactions", {
    "limit_per_page": 100,
    "from_ledger_state": {"state_version": max(1, ls["state_version"] - 200000)},
    "filter": {"affected_global_entities": [MARKET, POOL]},
    "order": "desc",
})
items = stream.get("items", [])
print("items:", len(items))
slim = [{"sv": it["state_version"], "intent": it["intent_hash"], "fee": it["fee_paid"], "ts": it["round_timestamp"]} for it in items]
json.dump(slim, open("weft_recent_txs_index.json", "w"), indent=1)

# fetch details for the first 12 (most recent)
out = []
for it in items[:14]:
    try:
        d = post("/transaction/committed-details", {"intent_hash": it["intent_hash"], "opt_ins": {"raw_manifest": True}})
        out.append(d)
    except Exception as e:
        print("detail fail", it["intent_hash"], str(e)[:120])
json.dump(out, open("weft_recent_tx_details.json", "w"), indent=1)
for d in out:
    tr = d.get("transaction", {})
    man = tr.get("manifest") or (tr.get("raw_manifest") or {}).get("raw")
    if man is None:
        man = json.dumps(tr)[:200]
    print("=" * 100)
    print("intent:", tr.get("intent_hash"), "| fee:", tr.get("fee_paid"), "| status:", d.get("transaction", {}).get("status"))
    print(man[:3000] if isinstance(man, str) else json.dumps(man)[:3000])
