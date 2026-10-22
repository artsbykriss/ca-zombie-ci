#!/usr/bin/env python3
"""Directional dump of attacker activity + USD valuation + BasicPool sanity."""
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


ATT = "0:2433bb62557246681d024d9dc273630f8b7be03cb7f0c7c7cb9a85542914c2c2"
FRIENDLY = "EQ"  # computed below

dd = json.load(open(os.path.join(OUT, "drain_dest_events.json")))

print("=== ATTACKER WALLET: directional flows ===")
net_usdt_out = 0.0
net_ton_out = 0.0
for e in sorted(dd, key=lambda x: x["timestamp"]):
    lines = []
    for a in e.get("actions", []):
        t = a.get("type")
        b = a.get(t, {}) if t else {}
        if t in ("JettonTransfer", "JettonBurn", "JettonMint"):
            jj = b.get("jetton", {}) or {}
            dec = jj.get("decimals", 9)
            try:
                amt = int(b.get("amount", 0)) / 10 ** dec
            except Exception:
                amt = b.get("amount")
            s = (b.get("sender") or {}).get("address")
            r = (b.get("recipient") or b.get("owner") or {}).get("address")
            sym = jj.get("symbol")
            arrow = "OUT" if s == ATT else ("IN " if r == ATT else "?? ")
            lines.append(f"{arrow} {t} {amt:.4f} {sym}")
        elif t == "TonTransfer":
            amt = b.get("amount", 0) / 1e9
            s = (b.get("sender") or {}).get("address")
            r = (b.get("recipient") or {}).get("address")
            arrow = "OUT" if s == ATT else ("IN " if r == ATT else "?? ")
            lines.append(f"{arrow} TonTransfer {amt:.4f} TON")
    if lines:
        print(f"{ts(e['timestamp'])}  " + " | ".join(lines))

# --- TON price history via llama coins ---
print("\n=== TON USD PRICE (llama coins) ===")
for label, t in [("2026-10-12", 1791849600), ("2026-10-13", 1791936000),
                 ("2026-10-14", 1792022400), ("2026-10-15", 1792108800),
                 ("2026-10-16T2046", 1792183560), ("2026-10-17", 1792281600)]:
    j = get(f"https://coins.llama.fi/prices/historical/{t}/coingecko:the-open-network")
    pr = None
    if isinstance(j, dict):
        pr = (j.get("coins", {}).get("coingecko:the-open-network", {}) or {}).get("price")
    print(f"  {label:16s} TON = ${pr}")

# --- BasicPool sanity: is it really active in window? ---
print("\n=== BasicPool sanity (first 25 in-window events) ===")
data = json.load(open(os.path.join(OUT, "raw_events_all.json")))
bp = data["BasicPool"]["events"]
for e in sorted(bp, key=lambda x: x["timestamp"])[:25]:
    types = [a.get("type") for a in e.get("actions", [])]
    print(f"  {ts(e['timestamp'])} {types}")

# --- hunt for JettonMint anywhere ---
print("\n=== ANY JettonMint across all contracts (window) ===")
n = 0
for name, d in data.items():
    for e in d["events"]:
        for a in e.get("actions", []):
            if a.get("type") == "JettonMint":
                n += 1
                print("  MINT", name, ts(e["timestamp"]), json.dumps(a)[:300])
print("  total JettonMint:", n)

# --- mint hunt via tonapi jetton events endpoint for affTONl & affUSDTl & AffluentTON ---
print("\n=== JETTON MASTER EVENT STREAM (mint/burn) ===")
for label, addr in [("affTONl/FactorialTON", "0:0343a25c2b434cb8d339bb009c4bd6e3727d914ef731608663365848872c14ad"),
                    ("FactorialUSDT", "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9")]:
    j = get(f"{BASE}/accounts/{addr}/events", {"limit": 100})
    if "__error__" in j:
        print(label, "ERR", j); continue
    print(f"-- {label}: {len(j.get('events', []))} events (newest 100)")
    for e in j.get("events", [])[:30]:
        acts = []
        for a in e.get("actions", []):
            t = a.get("type")
            if t in ("JettonMint", "JettonBurn", "JettonTransfer"):
                b = a[t]
                jj = b.get("jetton", {}) or {}
                try:
                    amt = int(b.get("amount", 0)) / 10 ** jj.get("decimals", 9)
                except Exception:
                    amt = b.get("amount")
                acts.append(f"{t}:{amt}:{jj.get('symbol')}")
            else:
                acts.append(t)
        print(f"   {ts(e['timestamp'])} {acts}")
