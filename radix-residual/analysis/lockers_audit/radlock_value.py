#!/usr/bin/env python3
"""RadLock: aggregate locked value from Locked Resource NFT data."""
import json
import time

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
XRD_LLAMA = 0.0004519403550191712
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"
NOW = time.time()

data = json.load(open(f"{OUT}/radlock_locked_nft_data.json"))
astro = {t["address"]: t for t in json.load(open(f"{OUT}/astro_tokens.json"))}

rows = []
for nid, it in data.items():
    pj = it["data"]["programmatic_json"]
    f = {x.get("field_name"): x for x in pj.get("fields", [])}
    def val(name):
        x = f.get(name)
        if not x:
            return None
        if x.get("kind") == "Enum":
            if x.get("variant_name") == "Some":
                return x["fields"][0].get("value")
            return None
        return x.get("value")
    token = f.get("token_address", {}).get("value")
    amount = f.get("amount_locked", {}).get("value")
    status = f.get("status", {}).get("variant_name")
    unlock = f.get("unlock_timestamp", {}).get("value")
    created = f.get("created_at_timestamp", {}).get("value")
    rows.append({"id": nid, "token": token, "amount": amount, "status": status,
                 "unlock_ts": unlock, "created_ts": created,
                 "name": val("name"),
                 "expired": unlock is not None and int(unlock) < NOW})
json.dump(rows, open(f"{OUT}/radlock_lock_rows.json", "w"), indent=1)

from collections import defaultdict  # noqa: E402
agg = defaultdict(lambda: {"amount": 0.0, "n_locked": 0, "n_expired": 0,
                           "n_withdrawn": 0, "usd": 0.0})
for r in rows:
    a = agg[r["token"]]
    if r["status"] == "Locked":
        a["amount"] += float(r["amount"] or 0)
        a["n_locked"] += 1
        if r["expired"]:
            a["n_expired"] += 1
    else:
        a["n_withdrawn"] += 1

unpriced = []
for token, a in agg.items():
    if a["n_locked"] == 0 and a["amount"] == 0:
        continue
    if token == XRD:
        a["usd"] = a["amount"] * XRD_LLAMA
    elif token in astro and astro[token].get("tokenPriceXRD") is not None:
        a["usd"] = a["amount"] * astro[token]["tokenPriceXRD"] * XRD_LLAMA
    else:
        unpriced.append(token)
    a["usd"] = round(a["usd"], 2)

tot_locked = sum(a["usd"] for a in agg.values() if a["n_locked"])
tot_all = sum(a["usd"] for a in agg.values())
json.dump({"by_token": {k: v for k, v in agg.items()},
           "total_usd_locked_nominal": round(tot_locked, 2),
           "unpriced_tokens": unpriced,
           "xrd_price_usd": XRD_LLAMA},
          open(f"{OUT}/radlock_valuation.json", "w"), indent=1)
print("total nominal USD (locked):", round(tot_locked, 2))
print("unpriced tokens:", len(unpriced))
for token, a in sorted(agg.items(), key=lambda kv: -kv[1]["usd"])[:15]:
    sym = astro.get(token, {}).get("symbol", "?")
    print(f"  {sym[:14]:14s} amount={a['amount']:.6f} usd={a['usd']:.2f} locked={a['n_locked']} expired={a['n_expired']} withdrawn={a['n_withdrawn']}")
print("withdrawn nfts total:", sum(a["n_withdrawn"] for a in agg.values()))
