#!/usr/bin/env python3
"""Enumerate ALL pending redemptions in the Neutron escrow (paginated all_redemptions)."""
import json, base64, urllib.request, urllib.error, sys, time

UA = {"User-Agent": "Mozilla/5.0 (research)"}
BASES = ["https://lcd-neutron.keplr.app", "https://neutron-api.polkachu.com"]
ESCROW = "neutron1rl7key2jr285vwz79hgkusgtw3ylcgateux5p8ajkk4rya067dkserkva8"

def http_get(url, timeout=15):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def smart(q, tries=6):
    qb = base64.b64encode(json.dumps(q).encode()).decode()
    last = None
    for i in range(tries):
        for b in BASES:
            try:
                return http_get(f"{b}/cosmwasm/wasm/v1/contract/{ESCROW}/smart/{qb}")
            except urllib.error.HTTPError as e:
                body = e.read().decode()
                last = {"_http": e.code, "_body": body[:300]}
                if e.code == 500:
                    return last  # contract error - no point retrying
            except Exception as e:
                last = {"_err": str(e)}
        time.sleep(1)
    return last

def main():
    all_red = []
    start_after = None
    for page in range(200):
        q = {"all_redemptions": {"limit": 30}}
        if start_after:
            q["all_redemptions"]["start_after"] = start_after
        r = smart(q)
        if "data" not in r:
            print("ERR page", page, str(r)[:300], file=sys.stderr)
            break
        batch = r["data"]
        if not batch:
            break
        all_red.extend(batch)
        last = batch[-1]
        start_after = [last["user"], last["timestamp"]]
        if len(batch) < 30:
            break
        if page % 10 == 0:
            print(f"page {page}, total {len(all_red)}", file=sys.stderr)
    print(f"TOTAL pending redemptions: {len(all_red)}")
    # aggregate
    from collections import defaultdict
    by_user = defaultdict(list)
    by_source = defaultdict(int)
    by_denom = defaultdict(int)
    for r in all_red:
        by_user[r["user"]].append(r)
        by_source[r["source"]] += 1
        for c in r["funds"]:
            by_denom[c["denom"]] += int(c["amount"])
    print("\nby denom:")
    for d, a in by_denom.items():
        print(f"  {d}: {a}")
    print(f"\nunique users: {len(by_user)}")
    print("by source:")
    for s, c in by_source.items():
        print(f"  {s}: {c}")
    print("\ntop users by count:")
    for u, rs in sorted(by_user.items(), key=lambda kv: -len(kv[1]))[:20]:
        tot = defaultdict(int)
        for r in rs:
            for c in r["funds"]:
                tot[c["denom"]] += int(c["amount"])
        print(f"  {u}: {len(rs)} redemptions, funds={dict(tot)}")
    json.dump(all_red, open("/home/heisenberg/CA/margined-protocol/analysis/escrow-all-redemptions.json", "w"), indent=1)
    # check for same (user,timestamp) collisions
    keys = [(r["user"], r["timestamp"]) for r in all_red]
    dups = len(keys) - len(set(keys))
    print(f"\n(user,timestamp) collisions visible: {dups}")

if __name__ == "__main__":
    main()
