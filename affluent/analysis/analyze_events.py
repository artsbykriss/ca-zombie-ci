#!/usr/bin/env python3
"""Deep analysis of raw_events_all.json (deduped, before_lt paginated)."""
import json, os, collections, datetime

OUT = os.path.dirname(os.path.abspath(__file__))
W_START, W_END = 1791763200, 1792368000
data = json.load(open(os.path.join(OUT, "raw_events_all.json")))


def ts(t):
    return datetime.datetime.utcfromtimestamp(t).strftime("%Y-%m-%d %H:%M:%SZ")


def fmt(amt, dec):
    try:
        return f"{int(amt)/10**dec:.4f}"
    except Exception:
        return str(amt)


print("== COVERAGE ==")
for name, d in data.items():
    evs = d["events"]
    if not evs:
        print(f"{name:22s} pages={d['pages']:3d} total={d['total_events']:5d} inwin=0")
        continue
    print(f"{name:22s} pages={d['pages']:3d} total={d['total_events']:5d} inwin={len(evs):4d} "
          f"span {ts(min(e['timestamp'] for e in evs))} .. {ts(max(e['timestamp'] for e in evs))}")

print("\n== ACTION HISTOGRAM ==")
for name, d in data.items():
    c = collections.Counter()
    for e in d["events"]:
        for a in e.get("actions", []):
            c[a.get("type")] += 1
    if c:
        print(f"{name:22s} {dict(c)}")

# ---- all mint/burn ----
print("\n== ALL JettonMint / JettonBurn ==")
for name, d in data.items():
    for e in d["events"]:
        for a in e.get("actions", []):
            t = a.get("type")
            if t not in ("JettonMint", "JettonBurn"):
                continue
            b = a.get(t, {})
            j = b.get("jetton", {}) or {}
            amt = b.get("amount")
            print(f"{ts(e['timestamp'])} {name:20s} {t:11s} {fmt(amt,j.get('decimals',9))} "
                  f"{j.get('symbol')} recv={(b.get('recipient') or b.get('owner') or {}).get('address')} "
                  f"tx={e['event_id'][:20]}")

# ---- largest jetton moves per contract ----
print("\n== TOP 8 JETTON MOVES PER CONTRACT (by raw amt) ==")
for name, d in data.items():
    rows = []
    for e in d["events"]:
        for a in e.get("actions", []):
            if a.get("type") != "JettonTransfer":
                continue
            b = a["JettonTransfer"]
            j = b.get("jetton", {}) or {}
            try:
                amt = int(b.get("amount", 0))
            except Exception:
                continue
            rows.append((amt, e["timestamp"], j.get("symbol"), j.get("decimals", 9),
                         (b.get("sender") or {}).get("address"),
                         (b.get("recipient") or {}).get("address"), e["event_id"]))
    rows.sort(reverse=True)
    if not rows:
        continue
    print(f"\n-- {name} ({len(rows)} jetton transfers) --")
    for amt, t, sym, dec, s, r, eid in rows[:8]:
        print(f"   {ts(t)} {fmt(amt,dec):>18s} {str(sym):16s} {str(s)[:16]} -> {str(r)[:16]} {eid[:20]}")

# ---- TonTransfer large ----
print("\n== LARGE TON TRANSFERS (>= 50 TON) ==")
for name, d in data.items():
    for e in d["events"]:
        for a in e.get("actions", []):
            if a.get("type") != "TonTransfer":
                continue
            b = a["TonTransfer"]
            amt = b.get("amount", 0)
            if amt < 50_000_000_000:
                continue
            print(f"{ts(e['timestamp'])} {name:20s} {amt/1e9:.2f} TON "
                  f"{(b.get('sender') or {}).get('address')} -> {(b.get('recipient') or {}).get('address')} "
                  f"tx={e['event_id'][:20]}")
