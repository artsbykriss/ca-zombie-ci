#!/usr/bin/env python3
"""Child1: enumerate VASE master-contract events via Aurora Blockscout (explorer.aurora.dev).
Public keyless API. Transforms responses (compact fields)."""
import json, urllib.request, urllib.parse, time
from Crypto.Hash import keccak

API = "https://explorer.aurora.dev/api/v2"
VASE = "0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF"

def topic(sig):
    h = keccak.new(digest_bits=256); h.update(sig.encode())
    return "0x" + h.hexdigest()

TOPICS = {
    "WhiteListMasterContract": topic("LogWhiteListMasterContract(address,bool)"),
    "SetMasterContractApproval": topic("LogSetMasterContractApproval(address,address,bool)"),
    "Deploy": topic("LogDeploy(address,bytes,address)"),
    "RegisterProtocol": topic("LogRegisterProtocol(address)"),
}

def get(url, retries=4):
    for _ in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            return json.loads(urllib.request.urlopen(req, timeout=60).read())
        except urllib.error.HTTPError as e:
            if e.code >= 500:
                time.sleep(2); continue
            return {"http_error": e.code, "body": e.read()[:200].decode("utf8", "replace")}
        except Exception:
            time.sleep(2)
    return {"error": "unreachable"}

def fetch_topic(name, tp):
    url = f"{API}/addresses/{VASE}/logs?topic={tp}"
    items = []
    pages = 0
    while url and pages < 60:
        r = get(url)
        if "items" in r:
            for it in r["items"]:
                items.append({
                    "topics": it.get("topics"),
                    "data": it.get("data"),
                    "block": it.get("block_number"),
                    "tx": it.get("transaction_hash"),
                })
        else:
            print(f"  [{name}] page {pages} unexpected: {str(r)[:200]}")
            break
        pages += 1
        npp = r.get("next_page_params")
        if not npp:
            break
        url = f"{API}/addresses/{VASE}/logs?topic={tp}&" + urllib.parse.urlencode(npp)
        time.sleep(0.3)
    return items

def main():
    out = {"vase": VASE, "topics": TOPICS, "source": "explorer.aurora.dev/api/v2", "events": {}}
    for name, tp in TOPICS.items():
        items = fetch_topic(name, tp)
        out["events"][name] = items
        print(f"{name}: {len(items)} events (topic {tp})")

    wl = []
    for it in out["events"]["WhiteListMasterContract"]:
        mc = "0x" + it["topics"][1][-40:]
        wl.append({"master": mc, "approved": int(it["data"], 16) != 0, "block": it["block"]})
    out["whitelist_events"] = wl
    print("\nwhitelist events:")
    for w in wl:
        print("  ", w)

    deploys = []
    for it in out["events"]["Deploy"]:
        deploys.append({
            "master": "0x" + it["topics"][1][-40:],
            "clone": "0x" + it["topics"][2][-40:],
            "block": it["block"],
        })
    out["deploys"] = deploys
    masters = {}
    for d in deploys:
        masters.setdefault(d["master"], []).append(d["clone"])
    print(f"\ndeploy events: {len(deploys)} total")
    for m, cs in masters.items():
        print(f"  master {m}: {len(cs)} clones")
        for c in cs[:12]:
            print(f"     {c}")

    approvals = []
    for it in out["events"]["SetMasterContractApproval"]:
        approvals.append({
            "master": "0x" + it["topics"][1][-40:],
            "user": "0x" + it["topics"][2][-40:],
            "approved": int(it["data"], 16) != 0,
            "block": it["block"],
        })
    out["approvals"] = approvals
    by_master = {}
    for a in approvals:
        k = (a["master"], a["user"])
        by_master.setdefault(a["master"], {})
        by_master[a["master"]][a["user"]] = a["approved"]
    print(f"\napproval events: {len(approvals)}")
    for m, us in by_master.items():
        trues = sum(1 for v in us.values() if v)
        print(f"  master {m}: {len(us)} users, {trues} currently approved")

    regs = ["0x" + it["topics"][1][-40:] for it in out["events"]["RegisterProtocol"]]
    out["registerProtocol"] = regs
    print("\nregisterProtocol:", regs)

    # contract verification status
    r = get(f"{API}/smart-contracts/{VASE}")
    out["vase_contract_info"] = {
        "is_verified": r.get("is_verified"),
        "language": r.get("language"),
        "compiler_version": r.get("compiler_version"),
        "name": r.get("name"),
        "match_type": r.get("is_verified") if "is_verified" in r else None,
        "raw_keys": list(r.keys())[:20] if isinstance(r, dict) else None,
    }
    print("\nVASE contract info:", json.dumps(out["vase_contract_info"], indent=1))

    json.dump(out, open("child1_events.json", "w"), indent=1)
    print("\nsaved child1_events.json")

if __name__ == "__main__":
    main()
