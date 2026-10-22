#!/usr/bin/env python3
"""Characterize the 10-12 drop + resolve remaining addresses + friendly attacker addr."""
import json, os, time, requests, datetime

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
            return {"__error__": r.status_code, "__body__": r.text[:200]}
        except Exception:
            time.sleep(2 + i * 2)
    return {"__error__": "exception"}


def ts(t):
    return datetime.datetime.utcfromtimestamp(t).strftime("%Y-%m-%d %H:%M:%SZ")


# friendly address for attacker
j = get(f"{BASE}/accounts/0:2433bb62557246681d024d9dc273630f8b7be03cb7f0c7c7cb9a85542914c2c2")
print("ATTACKER friendly:", j.get("address"))

for name, a in [("addr_34e3ffe0", "0:34e3ffe038f399bd8788d27052db7de158e298585c94070b5179cced530c97a1"),
                ("addr_edc50aa4", "0:edc50aa4808450411e615a5ad0c6224cb4bc23477ac460d5016c472f3c3c02b3"),
                ("addr_68c174ed", "0:68c174edc434d230425bac821c63322f49767d5791d6d8ea368925b4721533a1"),
                ("addr_425d0a76", "0:425d0a76b124c986f9d5e83941aa14ec74d31973fb49717409e578e85a2cbe38"),
                ("addr_ab1071c6", "0:ab1071c6e057fc4c3dcfcee1f9b454b01c10f7cf17976a8b33e3c8c62de6f08a"),
                ("addr_5987d0a9", "0:5987d0a92d9c8d9702"),
                ("addr_1b589dd8", "0:1b589dd8d4780822f7"),
                ("addr_779dcc81", "0:779dcc815138d9500e"),
                ("addr_8529c946", "0:8529c9467a3a7d801e09fe26bce41776aa6300a920874ac85cb9b4880116cdbe")]:
    j = get(f"{BASE}/accounts/{a}")
    print(f"{name:16s} friendly={j.get('address')} wallet={j.get('is_wallet')} iface={j.get('interfaces')} "
          f"name={j.get('name')} status={j.get('status')} bal={j.get('balance')}")

# 10-12 cascade: get first event details
print("\n=== 10-12 10:02:38 Factorial-TON event detail ===")
data = json.load(open(os.path.join(OUT, "raw_events_all.json")))
tgt = None
for name, d in data.items():
    for e in d["events"]:
        if e["timestamp"] == 1791807758 or (1791807600 <= e["timestamp"] <= 1791807900 and name == "Factorial-TON"):
            tgt = e["event_id"]
if tgt:
    j = get(f"{BASE}/events/{tgt}")
    print("  ts", ts(j.get("timestamp", 0)))
    for i, a in enumerate(j.get("actions", [])):
        t = a.get("type"); b = a.get(t, {}) if t else {}
        if t in ("JettonTransfer", "JettonBurn", "JettonMint"):
            jj = b.get("jetton", {}) or {}
            print(f"   [{i}] {t} {b.get('amount')} {jj.get('symbol')} "
                  f"{(b.get('sender') or {}).get('address')} -> {(b.get('recipient') or b.get('owner') or {}).get('address')}")
        elif t == "TonTransfer":
            print(f"   [{i}] Ton {b.get('amount')} {(b.get('sender') or {}).get('address')} -> {(b.get('recipient') or {}).get('address')}")
        elif t == "SmartContractExec":
            print(f"   [{i}] SCE op={b.get('operation')} exec={(b.get('executor') or {}).get('address')} contract={(b.get('contract') or {}).get('address')}")
        else:
            print(f"   [{i}] {t}")

# 0:34e3ffe0 events
print("\n=== 0:34e3ffe0 wallet events (paged) ===")
evs, seen, params = [], set(), {"limit": 100}
for _ in range(10):
    j = get(f"{BASE}/accounts/0:34e3ffe038f399bd8788d27052db7de158e298585c94070b5179cced530c97a1/events", params)
    if "__error__" in j:
        break
    batch = j.get("events", [])
    if not batch: break
    new = 0
    for e in batch:
        if e["event_id"] in seen: continue
        seen.add(e["event_id"]); evs.append(e); new += 1
    if new == 0: break
    params = {"limit": 100, "before_lt": min(e["lt"] for e in batch)}
    time.sleep(0.2)
print(f"  {len(evs)} events; earliest={ts(min(e['timestamp'] for e in evs))}")
for e in sorted(evs, key=lambda x: x["timestamp"])[:40]:
    acts = []
    for a in e.get("actions", []):
        t = a.get("type"); b = a.get(t, {}) if t else {}
        if t in ("JettonTransfer", "JettonBurn", "JettonMint"):
            jj = b.get("jetton", {}) or {}
            try: amt = int(b.get("amount", 0)) / 10 ** jj.get("decimals", 9)
            except Exception: amt = b.get("amount")
            acts.append(f"{t}:{amt}:{jj.get('symbol')}:{(b.get('sender') or {}).get('address','')[:16]}->{(b.get('recipient') or {}).get('address','')[:16]}")
        elif t == "TonTransfer":
            acts.append(f"Ton:{b.get('amount',0)/1e9}")
        else:
            acts.append(t)
    print(f"   {ts(e['timestamp'])} {acts}")
