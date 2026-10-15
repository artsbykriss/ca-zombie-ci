#!/usr/bin/env python3
"""Patient full-history paginator via mainnet-beta (the only endpoint with deep history).
Read-only. Saves incrementally to /home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"""
import json, sys, time, urllib.request, os

OUT = "/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"
ADDRS = {
    "pool": "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG",
    "reserve": "phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2",
    "stake8QtQ": "8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh",
    "mint": "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG",
    "fee": "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U",
    "vlist": "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821",
    "manager_pda": "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1",
}
URL = "https://api.mainnet-beta.solana.com"
MAX_PAGES = {"pool": 40, "reserve": 40, "stake8QtQ": 20, "mint": 40, "fee": 20, "vlist": 20, "manager_pda": 10}

def post(method, params, timeout=50):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def get_sigs(addr):
    sigs = []
    before = None
    for page in range(MAX_PAGES.get(len(sigs), 40)):
        params = [addr, {"limit": 1000}]
        if before:
            params[1]["before"] = before
        for attempt in range(10):
            try:
                d = post("getSignaturesForAddress", params)
                if "result" in d:
                    break
                err = json.dumps(d.get("error"))[:80]
                print(f"  {addr[:8]} page{page} attempt{attempt} err {err}", flush=True)
            except Exception as e:
                print(f"  {addr[:8]} page{page} attempt{attempt} exc {str(e)[:70]}", flush=True)
            time.sleep(min(45, 10 + attempt * 6))
        else:
            return sigs, False
        page_sigs = d["result"]
        sigs.extend(page_sigs)
        if len(page_sigs) < 1000:
            return sigs, True
        before = page_sigs[-1]["signature"]
        if (page + 1) % 5 == 0:
            print(f"  {addr[:8]} ... {len(sigs)} sigs, oldest slot {sigs[-1]['slot']}", flush=True)
        time.sleep(5)
    return sigs, False

def main():
    db = {}
    if os.path.exists(OUT):
        try:
            db = json.load(open(OUT))
        except Exception:
            db = {}
    # seed pool with existing mb_pool_sigs.json
    if "pool" not in db and os.path.exists("/home/heisenberg/CA/phase-stake/analysis/mb_pool_sigs.json"):
        d = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_pool_sigs.json"))
        if "result" in d:
            db["pool"] = {"address": ADDRS["pool"], "sigs": d["result"], "complete": False}
    budget = float(sys.argv[1]) if len(sys.argv) > 1 else 2400
    t0 = time.time()
    for name, addr in ADDRS.items():
        cur = db.get(name, {"address": addr, "sigs": [], "complete": False})
        if cur.get("complete"):
            print(name, "already complete", len(cur["sigs"]), flush=True)
            continue
        if time.time() - t0 > budget:
            print("budget exhausted", flush=True)
            break
        print("fetching", name, "existing", len(cur["sigs"]), flush=True)
        # if we have some sigs already, continue from the last
        existing = cur["sigs"]
        more, complete = get_sigs_continue(addr, existing)
        cur["sigs"] = more
        cur["complete"] = complete
        cur["count"] = len(more)
        db[name] = cur
        json.dump(db, open(OUT, "w"), indent=1)
        if more:
            print(f"{name}: total {len(more)} complete={complete} newest slot {more[0]['slot']} ({more[0]['blockTime']}) oldest slot {more[-1]['slot']} ({more[-1]['blockTime']})", flush=True)
        else:
            print(name, "no sigs", flush=True)
    print("DONE", flush=True)

def get_sigs_continue(addr, existing):
    if not existing:
        return get_sigs(addr)
    sigs = existing
    before = sigs[-1]["signature"] if not existing[-1] else None
    # we don't know if the existing list ended at a page boundary; continue strictly after the last signature
    before = sigs[-1]["signature"]
    while len(sigs) < MAX_PAGES.get(len(sigs), 40) * 1000:
        params = [addr, {"limit": 1000, "before": before}]
        ok = False
        for attempt in range(10):
            try:
                d = post("getSignaturesForAddress", params)
                if "result" in d:
                    ok = True
                    break
            except Exception:
                pass
            time.sleep(min(45, 10 + attempt * 6))
        if not ok:
            return sigs, False
        page_sigs = d["result"]
        sigs.extend(page_sigs)
        if len(page_sigs) < 1000:
            return sigs, True
        before = page_sigs[-1]["signature"]
        time.sleep(5)
    return sigs, False

if __name__ == "__main__":
    main()
