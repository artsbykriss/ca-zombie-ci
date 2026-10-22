#!/usr/bin/env python3
"""Check AffluentTON identity/supply + scan 10-14..10-16 for the exploit window."""
import json, os, time, requests, datetime, collections

OUT = os.path.dirname(os.path.abspath(__file__))
BASE = "https://tonapi.io/v2"
TC = "https://toncenter.com/api/v2"
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
        except Exception:
            time.sleep(2 + i * 2)
    return {"__error__": "exception"}


def ts(t):
    return datetime.datetime.utcfromtimestamp(t).strftime("%Y-%m-%d %H:%M:%SZ")


# 1) which jetton master is "AffluentTON" in the drain transfer?
det = json.load(open(os.path.join(OUT, "drain_event_details.json")))
print("=== jetton masters used in drain events ===")
for k, j in det.items():
    if "__error__" in j:
        continue
    for a in j.get("actions", []):
        for t in ("JettonTransfer", "JettonBurn", "JettonMint"):
            b = a.get(t)
            if not b:
                continue
            jj = b.get("jetton", {}) or {}
            print(f"  {k:20s} {t:14s} sym={jj.get('symbol')} addr={jj.get('address')} dec={jj.get('decimals')} amt={b.get('amount')}")

# 2) real supply via toncenter get_jetton_data
print("\n=== toncenter get_jetton_data ===")
MASTERS = {
    "AffluentTON_EQDIKEz2": "EQDIKEz2BYLnTRWo5W5a6moZ9PXNtyOVOFF7noi8Ufv3axz_",
    "affTONl/FactorialTON": "EQADQ6JcK0NMuNM5uwCcS9bjcn2RTvcxYIZjNlhIhywUrfBN",
    "FactorialUSDT": "EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW",
}
for label, addr in MASTERS.items():
    j = get(f"{TC}/runGetMethod", {"address": addr, "method": "get_jetton_data", "stack": "[]"})
    print(f"-- {label} {addr}")
    print("   ", json.dumps(j)[:500])

# 3) AffluentTON master own event stream (mints?) - use /v2/accounts/{addr}/events
print("\n=== AffluentTON master account events ===")
j = get(f"{BASE}/accounts/EQDIKEz2BYLnTRWo5W5a6moZ9PXNtyOVOFF7noi8Ufv3axz_/events", {"limit": 100})
if "__error__" not in j:
    for e in j.get("events", [])[:40]:
        acts = []
        for a in e.get("actions", []):
            t = a.get("type")
            b = a.get(t, {}) if t else {}
            if t in ("JettonTransfer", "JettonMint", "JettonBurn"):
                jj = b.get("jetton", {}) or {}
                acts.append(f"{t}:{b.get('amount')}:{jj.get('symbol')}:{(b.get('sender') or {}).get('address','')[:16]}->{(b.get('recipient') or {}).get('address','')[:16]}")
            else:
                acts.append(t)
        print(f"   {ts(e['timestamp'])} {acts}")

# 4) scan 10-14..10-16 23:59 for every contract
print("\n=== EVENTS 2026-10-14 00:00 .. 2026-10-16 23:59 ===")
A = 1792022400  # 10-14
B = 1792281600  # 10-18  (whole 14,15,16,17)
data = json.load(open(os.path.join(OUT, "raw_events_all.json")))
rows = []
for name, d in data.items():
    for e in d["events"]:
        if not (A <= e["timestamp"] < B):
            continue
        for a in e.get("actions", []):
            t = a.get("type")
            b = a.get(t, {}) if t else {}
            val = None
            extra = ""
            if t in ("JettonTransfer", "JettonBurn", "JettonMint"):
                jj = b.get("jetton", {}) or {}
                try:
                    val = int(b.get("amount", 0)) / 10 ** jj.get("decimals", 9)
                except Exception:
                    val = b.get("amount")
                extra = f"{val} {jj.get('symbol')} {(b.get('sender') or {}).get('address','')[:16]}->{(b.get('recipient') or b.get('owner') or {}).get('address','')[:16]}"
            elif t == "TonTransfer":
                val = b.get("amount", 0) / 1e9
                extra = f"{val} TON {(b.get('sender') or {}).get('address','')[:16]}->{(b.get('recipient') or {}).get('address','')[:16]}"
            rows.append((e["timestamp"], name, t, extra, e["event_id"][:16]))
rows.sort()
for r in rows:
    if r[2] in ("JettonTransfer", "JettonBurn", "JettonMint", "TonTransfer"):
        print(f"  {ts(r[0])} {r[1]:20s} {r[2]:14s} {r[3]}")
