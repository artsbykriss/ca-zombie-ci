#!/usr/bin/env python3
"""Scan all Wefty CDPs via get_cdp previews (resilient, resumable)."""
import json, sys, os
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import preview

MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
STATE_FILE = "weft_cdp_health_raw.json"


def get_cdp_batch(ids):
    idlist = ", ".join(f'NonFungibleLocalId("{i}")' for i in ids)
    m = f"""CALL_METHOD
    Address("{MARKET}")
    "get_cdp"
    Array<NonFungibleLocalId>({idlist})
;
"""
    resp = preview(m, nonce=7)
    rc = resp.get("receipt", {})
    return rc.get("status"), rc.get("error_message"), rc.get("output", []) or []


def fetch_batch(ids, results, depth=0):
    if not ids:
        return
    try:
        st, err, outs = get_cdp_batch(ids)
    except Exception as e:
        st, err, outs = "Exception", str(e)[:200], []
    if st == "Succeeded" and outs:
        pj = outs[0].get("programmatic_json") or {}
        for e in pj.get("entries", []):
            results[e["key"]["value"]] = e["value"]["fields"]
        return
    es = str(err)
    if "NonFungibleNotFound" in es and len(ids) == 1:
        return  # burned; skip
    if len(ids) == 1:
        print("  skip", ids[0], es[:120])
        return
    mid = len(ids) // 2
    fetch_batch(ids[:mid], results, depth + 1)
    fetch_batch(ids[mid:], results, depth + 1)


def main():
    data = json.load(open("weft_cdp_nft_data.json"))
    ids = [d["non_fungible_id"] for d in data if not d.get("is_burned")]
    print("live ids:", len(ids))
    results = {}
    if os.path.exists(STATE_FILE):
        results = json.load(open(STATE_FILE))
        print("resume with", len(results))
    todo = [i for i in ids if i not in results]
    print("todo:", len(todo))
    B = 10
    for i in range(0, len(todo), B):
        batch = todo[i:i + B]
        fetch_batch(batch, results)
        if i % 100 == 0:
            json.dump(results, open(STATE_FILE, "w"))
            print(f"progress {i}/{len(todo)} total={len(results)}")
    json.dump(results, open(STATE_FILE, "w"))
    print("parsed:", len(results))

    def dec(f):
        try:
            return float(f.get("value") or 0)
        except Exception:
            return 0.0
    rows = []
    for cid, fields in results.items():
        if len(fields) < 14:
            continue
        rows.append({
            "id": cid,
            "loan_value": dec(fields[0]),
            "adj_loan_value": dec(fields[1]),
            "collateral_value": dec(fields[2]),
            "health_collateral": dec(fields[3]),
            "liq_collateral": dec(fields[4]),
            "health_ltv": dec(fields[7]),
            "liquidation_ltv": dec(fields[8]),
            "n_loans": len(fields[11].get("entries", [])),
            "n_colls": len(fields[12].get("entries", [])),
            "n_nft_colls": len(fields[13].get("entries", [])),
        })
    rows.sort(key=lambda r: -r["liquidation_ltv"])
    json.dump(rows, open("weft_cdp_health_summary.json", "w"), indent=1)
    liquidatable = [r for r in rows if r["liquidation_ltv"] > 1 and r["loan_value"] > 0]
    print("CDPs with liquidation_ltv > 1:", len(liquidatable))
    print("CDPs with any loan:", sum(1 for r in rows if r["n_loans"] > 0))
    print("top 25:")
    for r in rows[:25]:
        print(f"  {r['id']}: liq_ltv={r['liquidation_ltv']:.6f} health_ltv={r['health_ltv']:.6f} "
              f"loan={r['loan_value']:.6f} adj={r['adj_loan_value']:.6f} coll={r['collateral_value']:.6f} "
              f"loans={r['n_loans']} colls={r['n_colls']} nft={r['n_nft_colls']}")


if __name__ == "__main__":
    main()
