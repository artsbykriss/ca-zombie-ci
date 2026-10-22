#!/usr/bin/env python3
"""Event detail (direction), token metadata, prices, downstream addresses."""
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
            return {"__error__": r.status_code, "__body__": r.text[:300]}
        except Exception:
            time.sleep(2 + i * 2)
    return {"__error__": "exception"}


def ts(t):
    return datetime.datetime.utcfromtimestamp(t).strftime("%Y-%m-%d %H:%M:%SZ")


# --- 1) full event details for the two drain events ---
EVENTS = {
    "drain_usdt_20_46": None,
    "drain_ton_20_48": None,
}
data = json.load(open(os.path.join(OUT, "raw_events_all.json")))
for name, d in data.items():
    for e in d["events"]:
        if e["event_id"].startswith("08b1751a89637f7c14fa"):
            EVENTS["drain_usdt_20_46"] = e["event_id"]
        if e["event_id"].startswith("ba3fc8ad72185639820e"):
            EVENTS["drain_ton_20_48"] = e["event_id"]

evdump = {}
for k, eid in EVENTS.items():
    if not eid:
        continue
    j = get(f"{BASE}/events/{eid}")
    evdump[k] = j
    print(f"\n##### {k}  {eid}")
    if "__error__" in j:
        print("  ERR", j); continue
    print("  ts", ts(j.get("timestamp", 0)), "lt", j.get("lt"))
    for i, a in enumerate(j.get("actions", [])):
        t = a.get("type")
        b = a.get(t, {}) if t else {}
        if t in ("JettonTransfer", "JettonBurn", "JettonMint"):
            jj = b.get("jetton", {}) or {}
            print(f"   [{i}] {t} {b.get('amount')} {jj.get('symbol')} (dec {jj.get('decimals')})"
                  f" from={((b.get('sender') or {}).get('address'))}"
                  f" -> {((b.get('recipient') or b.get('owner') or {}).get('address'))}")
        elif t == "TonTransfer":
            print(f"   [{i}] {t} {b.get('amount')} from={((b.get('sender') or {}).get('address'))}"
                  f" -> {((b.get('recipient') or {}).get('address'))} comment={b.get('comment')}")
        elif t == "SmartContractExec":
            print(f"   [{i}] {t} op={b.get('operation')} executor={((b.get('executor') or {}).get('address'))}"
                  f" contract={((b.get('contract') or {}).get('address'))} value={b.get('ton_attached')}")
        else:
            print(f"   [{i}] {t} {json.dumps(b)[:300]}")

with open(os.path.join(OUT, "drain_event_details.json"), "w") as f:
    json.dump(evdump, f, indent=1)

# --- 2) jetton metadata ---
JETTONS = {
    "AffluentTON": "EQDIKEz2BYLnTRWo5W5a6moZ9PXNtyOVOFF7noi8Ufv3axz_",
    "affUSDTl": "0:6f65ce2fdccc71f575de40ad8aa453a29e0a01f385bb1a68c64501d9e6fd1fed",
    "affTONl": None,
    "affTONm": None,
    "affUSDTm": None,
    "affSENTORAent": None,
}
# find jetton master addresses from events
for name, d in data.items():
    for e in d["events"]:
        for a in e.get("actions", []):
            for t in ("JettonTransfer", "JettonBurn", "JettonMint"):
                b = a.get(t)
                if not b:
                    continue
                jj = b.get("jetton", {}) or {}
                sym = jj.get("symbol")
                if sym in JETTONS and not JETTONS[sym]:
                    JETTONS[sym] = jj.get("address")
print("\n=== JETTON MASTERS ===")
jetinfo = {}
for sym, addr in JETTONS.items():
    if not addr:
        continue
    j = get(f"{BASE}/jettons/{addr}")
    jetinfo[sym] = j
    md = (j.get("metadata") or {})
    print(f"{sym:16s} {addr}  dec={md.get('decimals')} name={md.get('name')} "
          f"supply={j.get('total_supply')} holders={j.get('holders_count')} verified={j.get('verification')}")

with open(os.path.join(OUT, "jetton_info.json"), "w") as f:
    json.dump(jetinfo, f, indent=1)

# --- 3) downstream addresses ---
DOWNS = {
    "0:5987d0a92d9c8d9702": None,
    "0:1b589dd8d4780822f7": None,
    "0:779dcc815138d9500e": None,
    "0:f0e5e2ebc4b9e4166c": None,
    "0:13d2708edb4bc2ea0c": None,
}
# need full addrs
full = {}
for name, d in json.load(open(os.path.join(OUT, "drain_dest_events.json"))):
    pass
dd = json.load(open(os.path.join(OUT, "drain_dest_events.json")))
seen = set()
for e in dd:
    for a in e.get("actions", []):
        for t in ("JettonTransfer", "TonTransfer"):
            b = a.get(t, {})
            for f in ("sender", "recipient"):
                o = b.get(f)
                if isinstance(o, dict) and o.get("address"):
                    seen.add(o["address"])
print("\n=== DOWNSTREAM / ALL DEST-WALLET COUNTERPARTIES ===")
dn = {}
for a in sorted(seen):
    if a == "0:2433bb62557246681d024d9dc273630f8b7be03cb7f0c7c7cb9a85542914c2c2":
        continue
    j = get(f"{BASE}/accounts/{a}")
    dn[a] = j
    print(f"  {a}  is_wallet={j.get('is_wallet')} iface={j.get('interfaces')} "
          f"name={j.get('name')} status={j.get('status')}")

with open(os.path.join(OUT, "downstream_addrs.json"), "w") as f:
    json.dump(dn, f, indent=1)
