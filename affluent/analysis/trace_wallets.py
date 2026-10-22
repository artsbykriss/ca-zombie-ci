#!/usr/bin/env python3
"""Trace the attacker's share-token jetton wallets to find the unbacked mint origin."""
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


def wallet_events(addr):
    evs, seen = [], set()
    params = {"limit": 100}
    for _ in range(40):
        j = get(f"{BASE}/accounts/{addr}/events", params)
        if "__error__" in j:
            return evs, j
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
        params = {"limit": 100, "before_lt": min(e["lt"] for e in batch)}
        time.sleep(0.2)
    return evs, None


WALLETS = {
    "attacker_affUSDTl_wallet": "0:c5d314158486e15bd6ebeae11943290ad3de773ec6a42b760b75ed251f109b9a",
    "attacker_affTONl_wallet": "0:38c7acdae4bd05dfdf84bd74f7134a61dffa3cc1b4b7c7422dc875abe680c12b",
    "attacker_AffluentTON_wallet_8df00bc8": "0:8df00bc88a4fc555ac87aa6c724007973443e4b2688184d1e33e4111a5f42279",
    "attacker_governed_wallet_9cdc9c26": "0:9cdc9c26653cb74f7db74c49455a96cf462d8bc3a17185f00dc60d53cb982dde",
}

dump = {}
for name, addr in WALLETS.items():
    evs, err = wallet_events(addr)
    dump[name] = {"address": addr, "err": err, "events": evs}
    print(f"\n##### {name} {addr}  ({len(evs)} events)")
    for e in sorted(evs, key=lambda x: x["timestamp"]):
        acts = []
        for a in e.get("actions", []):
            t = a.get("type"); b = a.get(t, {}) if t else {}
            if t in ("JettonTransfer", "JettonBurn", "JettonMint"):
                jj = b.get("jetton", {}) or {}
                try: amt = int(b.get("amount", 0)) / 10 ** jj.get("decimals", 9)
                except Exception: amt = b.get("amount")
                acts.append(f"{t}:{amt}:{jj.get('symbol')}:"
                            f"{(b.get('sender') or {}).get('address','')[:20]}->"
                            f"{(b.get('recipient') or {}).get('address','')[:20]}")
            elif t == "TonTransfer":
                acts.append(f"Ton:{b.get('amount',0)/1e9}:"
                            f"{(b.get('sender') or {}).get('address','')[:20]}->"
                            f"{(b.get('recipient') or {}).get('address','')[:20]}")
            else:
                acts.append(t)
        print(f"  {ts(e['timestamp'])} {acts}")

with open(os.path.join(OUT, "attacker_jetton_wallets.json"), "w") as f:
    json.dump(dump, f, indent=1)

# Also: attacker wallet full history back to creation
print("\n\n##### attacker MAIN wallet full history")
ATT = "0:2433bb62557246681d024d9dc273630f8b7be03cb7f0c7c7cb9a85542914c2c2"
evs, err = wallet_events(ATT)
print(f"  ({len(evs)} events) earliest={ts(min(e['timestamp'] for e in evs))}")
j = get(f"{BASE}/accounts/{ATT}")
print("  account:", json.dumps({k: j.get(k) for k in ("address", "is_wallet", "interfaces", "status", "balance", "get_methods")})[:400])
