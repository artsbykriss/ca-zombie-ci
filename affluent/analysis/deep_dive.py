#!/usr/bin/env python3
"""Deeper dive: full addresses, the 2 batched drain txs, and the drain-destination wallet."""
import json, os, time, requests, collections, datetime

OUT = os.path.dirname(os.path.abspath(__file__))
BASE = "https://tonapi.io/v2"
S = requests.Session()
S.headers.update({"Accept": "application/json", "User-Agent": "affluent-readonly/1.0"})


def get(url, params=None, tries=5):
    for i in range(tries):
        try:
            r = S.get(url, params=params, timeout=45)
            if r.status_code == 200:
                return r.json()
            if r.status_code == 429:
                time.sleep(3 + i * 3); continue
            return {"__error__": r.status_code, "__body__": r.text[:300]}
        except Exception as e:
            time.sleep(2 + i * 2); last = str(e)
    return {"__error__": "exception", "__body__": last}


def ts(t):
    return datetime.datetime.utcfromtimestamp(t).strftime("%Y-%m-%d %H:%M:%SZ")


data = json.load(open(os.path.join(OUT, "raw_events_all.json")))

# 1) collect every full raw address seen in sender/recipient fields + map to names
addr_names = {}
for name, d in data.items():
    for e in d["events"]:
        for a in e.get("actions", []):
            for k in ("JettonTransfer", "JettonBurn", "JettonMint", "TonTransfer"):
                b = a.get(k)
                if not b:
                    continue
                for fld in ("sender", "recipient", "owner"):
                    o = b.get(fld)
                    if isinstance(o, dict) and o.get("address"):
                        addr_names.setdefault(o["address"], set()).add(name)

print("=== unique counterparty addresses in window ===")
for a, ns in sorted(addr_names.items()):
    print(f"  {a}  <- {sorted(ns)}")

# 2) locate the 2 batched drain events by event_id prefix, get their base txs
TARGETS = ["08b1751a89637f7c14fa", "ba3fc8ad72185639820e"]
ev_by_pref = {}
for name, d in data.items():
    for e in d["events"]:
        for pre in TARGETS:
            if e["event_id"].startswith(pre):
                ev_by_pref[pre] = e

print("\n=== TARGET EVENTS -> base txs ===")
all_base = set()
for pre, e in ev_by_pref.items():
    print(f"\n--- event {pre} ({ts(e['timestamp'])}) ---")
    print("   actions:", [a.get("type") for a in e.get("actions", [])])
    for btx in e.get("base_transactions", []):
        print("   base_tx", btx)
        all_base.add(btx)

# 3) pull each base tx
txdump = {}
for btx in sorted(all_base):
    j = get(f"{BASE}/blockchain/transactions/{btx}")
    txdump[btx] = j
    if "__error__" in j:
        print("TX", btx, "ERR", j); continue
    print(f"\n### TX {btx}")
    print(f"    lt={j.get('lt')} success={j.get('success')} ts={ts(j.get('utime',0))} "
          f"total_fees={j.get('total_fees')}")
    im = j.get("in_msg", {}) or {}
    print(f"    IN  {((im.get('source') or {}).get('address'))} -> "
          f"{((im.get('destination') or {}).get('address'))} val={im.get('value')} "
          f"op={im.get('op_code')} {im.get('decoded_op_name')}")
    for m in j.get("out_msgs", []) or []:
        print(f"    OUT {((m.get('source') or {}).get('address'))} -> "
              f"{((m.get('destination') or {}).get('address'))} val={m.get('value')} "
              f"op={m.get('op_code')} {m.get('decoded_op_name')}")
    time.sleep(0.3)

with open(os.path.join(OUT, "drain_tx_details.json"), "w") as f:
    json.dump(txdump, f, indent=1)

# 4) the drain destination wallet: full event history
DEST = "0:2433bb62557246681d024d9dc273630f8b7be03cb7f0c7c7cb9a85542914c2c2"
print("\n=== DRAIN DEST WALLET HISTORY ===")
evs = []
params = {"limit": 100}
seen = set()
for _ in range(40):
    j = get(f"{BASE}/accounts/{DEST}/events", params)
    if "__error__" in j:
        print("ERR", j); break
    batch = j.get("events", [])
    if not batch:
        break
    new = 0
    for e in batch:
        if e["event_id"] in seen:
            continue
        seen.add(e["event_id"]); evs.append(e); new += 1
    if new == 0:
        break
    oldest_lt = min(e["lt"] for e in batch)
    params = {"limit": 100, "before_lt": oldest_lt}
    time.sleep(0.2)

print(f"total events for dest: {len(evs)}")
for e in sorted(evs, key=lambda x: x["timestamp"]):
    acts = []
    for a in e.get("actions", []):
        t = a.get("type")
        if t in ("JettonTransfer", "JettonBurn", "JettonMint"):
            b = a[t]; jj = b.get("jetton", {}) or {}
            try:
                amt = int(b.get("amount", 0)) / 10 ** jj.get("decimals", 9)
            except Exception:
                amt = b.get("amount")
            s = (b.get("sender") or {}).get("address")
            r = (b.get("recipient") or b.get("owner") or {}).get("address")
            acts.append(f"{t} {amt} {jj.get('symbol')} {str(s)[:20]}->{str(r)[:20]}")
        elif t == "TonTransfer":
            b = a[t]
            acts.append(f"TonTransfer {b.get('amount',0)/1e9}TON")
        else:
            acts.append(t)
    print(f"  {ts(e['timestamp'])} {acts}")

with open(os.path.join(OUT, "drain_dest_events.json"), "w") as f:
    json.dump(evs, f, indent=1)
