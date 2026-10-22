#!/usr/bin/env python3
"""Final: forwarding target identity + exact tx hashes for each drain session."""
import json, os, time, requests, datetime

OUT = os.path.dirname(os.path.abspath(__file__))
BASE = "https://tonapi.io/v2"
S = requests.Session()
S.headers.update({"Accept": "application/json", "User-Agent": "affluent-readonly/1.0"})


def get(url, params=None, tries=4):
    for i in range(tries):
        try:
            r = S.get(url, params=params, timeout=45)
            if r.status_code == 200:
                return r.json()
            time.sleep(2)
        except Exception:
            time.sleep(2)
    return {"__error__": "fail"}


def ts(t):
    return datetime.datetime.utcfromtimestamp(t).strftime("%Y-%m-%d %H:%M:%SZ")


loop = json.load(open(os.path.join(OUT, "loop_34e3ffe0_events.json")))

# forwarding target full address
print("=== 0:34e3ffe0 outbound TON (full addresses) ===")
outs = {}
for e in loop:
    for a in e.get("actions", []):
        if a.get("type") == "TonTransfer":
            b = a["TonTransfer"]
            s = (b.get("sender") or {}).get("address")
            r = (b.get("recipient") or {}).get("address")
            if s == "0:34e3ffe038f399bd8788d27052db7de158e298585c94070b5179cced530c97a1":
                outs.setdefault(r, []).append((e["timestamp"], b.get("amount", 0) / 1e9, e["event_id"]))
for r, v in outs.items():
    print(f"  -> {r}  n={len(v)}  total={sum(x[1] for x in v):.2f} TON")
    for t, amt, eid in sorted(v):
        print(f"       {ts(t)} {amt:.2f} TON  event={eid}")
    j = get(f"{BASE}/accounts/{r}")
    print(f"       account: wallet={j.get('is_wallet')} iface={j.get('interfaces')} name={j.get('name')} status={j.get('status')}")

# example tx hashes per session: first event of each day's burst
print("\n=== example event_ids / base tx per drain session ===")
by_day = {}
for e in loop:
    d = ts(e["timestamp"])[:10]
    by_day.setdefault(d, []).append(e)
for d, evs in sorted(by_day.items()):
    evs.sort(key=lambda x: x["timestamp"])
    for e in evs[:2]:
        j = get(f"{BASE}/events/{e['event_id']}")
        bts = j.get("base_transactions") if isinstance(j, dict) else None
        print(f"  {d} {ts(e['timestamp'])} event={e['event_id']}")
        print(f"      base_transactions={bts}")

# the two 10-16 txs (known)
print("\n=== 10-16 drain txs (from earlier) ===")
for h in ["08b1751a89637f7c14fa4232fca3ceb93f0ce54548c2d473f4fdb04b0a7e7df1",
          "ba3fc8ad72185639820e639316d3a8b2521cb07be96eb8522d29f6c168aa846a"]:
    j = get(f"{BASE}/events/{h}")
    print(f"  {h[:24]}... ts={ts(j.get('timestamp',0)) if isinstance(j,dict) else '?'} "
          f"lt={j.get('lt') if isinstance(j,dict) else '?'}")
