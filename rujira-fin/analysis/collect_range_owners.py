#!/usr/bin/env python3
"""Read-only: enumerate every FIN CCL range with its owner across all FIN pairs.
Writes analysis/range_owners.json. No secrets, no transactions."""
import json, base64, urllib.request, time
from concurrent.futures import ThreadPoolExecutor

BASE = "https://gateway.liquify.com/chain/thorchain_api"

def get(path, tries=3):
    last = None
    for _ in range(tries):
        try:
            return json.load(urllib.request.urlopen(BASE + path, timeout=35))
        except Exception as e:
            last = e; time.sleep(1.5)
    raise last

def smart(addr, msg, tries=3):
    b = base64.b64encode(json.dumps(msg).encode()).decode()
    return get(f"/cosmwasm/wasm/v1/contract/{addr}/smart/{b}", tries)

def contract_info(addr):
    try:
        return get(f"/cosmwasm/wasm/v1/contract/{addr}")["contract_info"]
    except Exception:
        return None

def ranges_for(a):
    out = []; cursor = None
    for _ in range(30):
        msg = {"ranges": {"limit": 100}}
        if cursor: msg["ranges"]["cursor"] = cursor
        try:
            d = smart(a, msg)["data"]
        except Exception:
            break
        out += d.get("ranges", []); cursor = d.get("cursor")
        if not cursor: break
    return out

def main():
    fin = open("analysis/fin_addrs.txt").read().split()
    rows = []
    with ThreadPoolExecutor(max_workers=6) as ex:
        results = list(ex.map(lambda a: (a, ranges_for(a)), fin))
    owner_count = {}
    for a, rs in results:
        for r in rs:
            rows.append({"pair": a, "idx": r["idx"], "owner": r["owner"],
                         "base": r["base"], "quote": r["quote"]})
            owner_count[r["owner"]] = owner_count.get(r["owner"], 0) + 1
    # identify contract owners (ranges owned by a contract, not an EOA)
    owners = sorted(owner_count, key=lambda o: -owner_count[o])
    contract_owners = []
    with ThreadPoolExecutor(max_workers=8) as ex:
        infos = list(ex.map(contract_info, owners[:400]))
    for o, ci in zip(owners[:400], infos):
        if ci:
            contract_owners.append({"owner": o, "ranges": owner_count[o],
                                    "code_id": ci.get("code_id"), "admin": ci.get("admin"),
                                    "label": ci.get("label")})
    json.dump({"total_ranges": len(rows), "distinct_owners": len(owner_count),
               "top_owners": [{"owner": o, "ranges": owner_count[o]} for o in owners[:30]],
               "contract_owners": contract_owners, "rows": rows},
              open("analysis/range_owners.json", "w"), indent=1)
    print("ranges", len(rows), "owners", len(owner_count))
    print("contract owners:", json.dumps(contract_owners, indent=1))

if __name__ == "__main__":
    main()
