#!/usr/bin/env python3
"""Trace attacker jetton holdings + share-token acquisition + AffluentTON supply."""
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


def paginate_events(addr, stop_ts):
    evs, seen = [], set()
    params = {"limit": 100}
    for _ in range(60):
        j = get(f"{BASE}/accounts/{addr}/events", params)
        if "__error__" in j:
            break
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
        if min(e["timestamp"] for e in batch) < stop_ts:
            break
        params = {"limit": 100, "before_lt": min(e["lt"] for e in batch)}
        time.sleep(0.2)
    return evs


ATT = "0:2433bb62557246681d024d9dc273630f8b7be03cb7f0c7c7cb9a85542914c2c2"

print("=== attacker jetton balances ===")
j = get(f"{BASE}/accounts/{ATT}/jettons", {"currencies": "usd"})
for b in j.get("balances", []) if isinstance(j, dict) else []:
    jj = b.get("jetton", {}) or {}
    print(f"  {jj.get('symbol'):20s} {jj.get('address')} bal={b.get('balance')} "
          f"dec={jj.get('decimals')} price={b.get('price')}")

# Attacker's jettons' histories: find jetton wallets
print("\n=== attacker jetton WALLET histories (AffluentTON / affTONl / affUSDTl) ===")
for sym, master in [("AffluentTON", "0:c8284cf60582e74d15a8e56e5aea6a19f4f5cdb7239538517b9e88bc51fbf76b"),
                    ("affTONl", "0:0343a25c2b434cb8d339bb009c4bd6e3727d914ef731608663365848872c14ad"),
                    ("affUSDTl", "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9")]:
    j = get(f"{BASE}/accounts/{ATT}/jettons/{master}/history", {"limit": 50})
    print(f"-- {sym}: {json.dumps(j)[:1200]}")

# Factorial-TON + Factorial-USDT full window event streams
print("\n=== Factorial-TON (affTONl master) events 10-13..10-17 ===")
evs = paginate_events("0:0343a25c2b434cb8d339bb009c4bd6e3727d914ef731608663365848872c14ad", 1791936000)
for e in sorted(evs, key=lambda x: x["timestamp"]):
    if not (1791936000 <= e["timestamp"] < 1792281600):
        continue
    acts = []
    for a in e.get("actions", []):
        t = a.get("type"); b = a.get(t, {}) if t else {}
        if t in ("JettonTransfer", "JettonBurn", "JettonMint"):
            jj = b.get("jetton", {}) or {}
            try: amt = int(b.get("amount", 0)) / 10 ** jj.get("decimals", 9)
            except Exception: amt = b.get("amount")
            acts.append(f"{t}:{amt}:{jj.get('symbol')}:{(b.get('sender') or {}).get('address','')[:18]}->{(b.get('recipient') or {}).get('address','')[:18]}")
        elif t == "TonTransfer":
            acts.append(f"Ton:{b.get('amount',0)/1e9}:{(b.get('sender') or {}).get('address','')[:18]}->{(b.get('recipient') or {}).get('address','')[:18]}")
        else:
            acts.append(t)
    print(f"  {ts(e['timestamp'])} {acts}")

print("\n=== Factorial-USDT (affUSDTl master) events 10-13..10-17 ===")
evs = paginate_events("0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9", 1791936000)
for e in sorted(evs, key=lambda x: x["timestamp"]):
    if not (1791936000 <= e["timestamp"] < 1792281600):
        continue
    acts = []
    for a in e.get("actions", []):
        t = a.get("type"); b = a.get(t, {}) if t else {}
        if t in ("JettonTransfer", "JettonBurn", "JettonMint"):
            jj = b.get("jetton", {}) or {}
            try: amt = int(b.get("amount", 0)) / 10 ** jj.get("decimals", 9)
            except Exception: amt = b.get("amount")
            acts.append(f"{t}:{amt}:{jj.get('symbol')}:{(b.get('sender') or {}).get('address','')[:18]}->{(b.get('recipient') or {}).get('address','')[:18]}")
        elif t == "TonTransfer":
            acts.append(f"Ton:{b.get('amount',0)/1e9}:{(b.get('sender') or {}).get('address','')[:18]}->{(b.get('recipient') or {}).get('address','')[:18]}")
        else:
            acts.append(t)
    print(f"  {ts(e['timestamp'])} {acts}")

# AffluentTON real supply via run method
print("\n=== AffluentTON supply via run-method ===")
for m in ["get_jetton_data", "get_wallet_data"]:
    j = get(f"{BASE}/blockchain/accounts/EQDIKEz2BYLnTRWo5W5a6moZ9PXNtyOVOFF7noi8Ufv3axz_/methods/{m}")
    print(f"  {m}: {json.dumps(j)[:600]}")
