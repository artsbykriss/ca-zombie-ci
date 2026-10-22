#!/usr/bin/env python3
"""Quantify the 0:34e3ffe0 loop: totals, dates, forwarding, link to 10-16 attacker."""
import json, os, time, requests, datetime, collections

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


def all_events(addr, maxpages=200):
    evs, seen, params = [], set(), {"limit": 100}
    for _ in range(maxpages):
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
        params = {"limit": 100, "before_lt": min(e["lt"] for e in batch)}
        time.sleep(0.15)
    return evs


LOOP = "0:34e3ffe038f399bd8788d27052db7de158e298585c94070b5179cced530c97a1"
ATT = "0:2433bb62557246681d024d9dc273630f8b7be03cb7f0c7c7cb9a85542914c2c2"

evs = all_events(LOOP)
print(f"0:34e3ffe0 total events: {len(evs)}  span {ts(min(e['timestamp'] for e in evs))} .. {ts(max(e['timestamp'] for e in evs))}")

per_day = collections.Counter()
ton_in = collections.Counter()
ton_out = collections.Counter()
aff_in = collections.Counter()
burn = collections.Counter()
counterparties = collections.Counter()
for e in evs:
    d = ts(e["timestamp"])[:10]
    for a in e.get("actions", []):
        t = a.get("type"); b = a.get(t, {}) if t else {}
        if t == "JettonBurn":
            jj = b.get("jetton", {}) or {}
            try: amt = int(b.get("amount", 0)) / 10 ** jj.get("decimals", 9)
            except Exception: amt = 0
            burn[d] += amt
        elif t == "JettonTransfer":
            jj = b.get("jetton", {}) or {}
            try: amt = int(b.get("amount", 0)) / 10 ** jj.get("decimals", 9)
            except Exception: amt = 0
            r = (b.get("recipient") or {}).get("address")
            if r == LOOP:
                aff_in[d] += amt
        elif t == "TonTransfer":
            amt = b.get("amount", 0) / 1e9
            r = (b.get("recipient") or {}).get("address")
            s = (b.get("sender") or {}).get("address")
            if r == LOOP:
                ton_in[d] += amt
                counterparties["IN:" + str(s)[:20]] += 1
            if s == LOOP:
                ton_out[d] += amt
                counterparties["OUT:" + str(r)[:20]] += 1

print("\ndate       #burns  affTONl_burned   TON_in     TON_out")
for d in sorted(set(list(burn) + list(ton_in))):
    print(f"{d}  {burn[d]:>8.0f} affTONl   in={ton_in[d]:>14.2f} TON  out={ton_out[d]:>12.2f} TON")
print("\nTOTAL affTONl burned:", sum(burn.values()))
print("TOTAL TON in:", sum(ton_in.values()), " TON out:", sum(ton_out.values()))
print("\ntop counterparties:", counterparties.most_common(15))

# check 10-14/10-15
print("\n=== 0:34e3ffe0 events on 2026-10-14 / 10-15 ===")
for e in sorted(evs, key=lambda x: x["timestamp"]):
    if 1792022400 <= e["timestamp"] < 1792195200:
        print("  ", ts(e["timestamp"]), [a.get("type") for a in e.get("actions", [])])

# is LOOP linked to ATT?
print("\n=== link check LOOP<->ATT ===")
print("  ATT in LOOP counterparties?", any(ATT in k for k in counterparties))

# affTONl supply + vault balances now
print("\n=== current supplies ===")
for label, addr in [("affTONl/FactorialTON", "EQADQ6JcK0NMuNM5uwCcS9bjcn2RTvcxYIZjNlhIhywUrfBN"),
                    ("FactorialUSDT", "EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW"),
                    ("AffluentTON", "EQDIKEz2BYLnTRWo5W5a6moZ9PXNtyOVOFF7noi8Ufv3axz_")]:
    j = get(f"{BASE}/jettons/{addr}")
    md = j.get("metadata", {}) or {}
    print(f"  {label:22s} supply={j.get('total_supply')} dec={md.get('decimals')} holders={j.get('holders_count')}")

with open(os.path.join(OUT, "loop_34e3ffe0_events.json"), "w") as f:
    json.dump(evs, f, indent=1)
