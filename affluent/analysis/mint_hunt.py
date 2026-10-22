#!/usr/bin/env python3
"""Examine the 20:36:39 event (likely the mint) and raw master transactions."""
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
VU = "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9"   # Factorial-USDT vault
VT = "0:0343a25c2b434cb8d339bb009c4bd6e3727d914ef731608663365848872c14ad"   # Factorial-TON vault

# find event ids at 20:36:39
evs = json.load(open(os.path.join(OUT, "drain_dest_events.json")))
targets = []
for e in evs:
    if e["timestamp"] in (1792182999, 1792183000) or (1792182900 <= e["timestamp"] <= 1792183200):
        targets.append(e["event_id"])
print("candidate event ids near 20:36:", targets)

for eid in targets:
    j = get(f"{BASE}/events/{eid}")
    print(f"\n##### event {eid}  ts={ts(j.get('timestamp',0)) if '__error__' not in j else '?'}")
    if "__error__" in j:
        print("  ERR", j); continue
    for i, a in enumerate(j.get("actions", [])):
        t = a.get("type"); b = a.get(t, {}) if t else {}
        if t in ("JettonTransfer", "JettonBurn", "JettonMint"):
            jj = b.get("jetton", {}) or {}
            print(f"   [{i}] {t} amt={b.get('amount')} {jj.get('symbol')} "
                  f"from={(b.get('sender') or {}).get('address')} -> {(b.get('recipient') or b.get('owner') or {}).get('address')}")
        elif t == "TonTransfer":
            print(f"   [{i}] TonTransfer {b.get('amount')} from={(b.get('sender') or {}).get('address')} -> {(b.get('recipient') or {}).get('address')}")
        elif t == "SmartContractExec":
            print(f"   [{i}] SCE op={b.get('operation')} exec={(b.get('executor') or {}).get('address')} "
                  f"contract={(b.get('contract') or {}).get('address')} val={b.get('ton_attached')}")
        elif t == "ContractDeploy":
            print(f"   [{i}] Deploy {b.get('address')} {b.get('interfaces')}")
        else:
            print(f"   [{i}] {t} {json.dumps(b)[:250]}")
    print("   base_transactions:", j.get("base_transactions"))
    print("   in_progress:", j.get("in_progress"), "is_scam:", j.get("is_scam"))

# raw transactions on the vaults around that time
print("\n\n=== Factorial-USDT vault raw transactions ===")
for label, addr in [("USDT-vault", VU), ("TON-vault", VT)]:
    j = get(f"{BASE}/blockchain/accounts/{addr}/transactions", {"limit": 30})
    print(f"-- {label} {addr}")
    for t in j.get("transactions", [])[:30]:
        im = t.get("in_msg", {}) or {}
        print(f"   lt={t.get('lt')} {ts(t.get('now',0))} success={t.get('success')} "
              f"in op={im.get('op_code')} src={(im.get('source') or {}).get('address')} "
              f"dst={(im.get('destination') or {}).get('address')} val={im.get('value')} "
              f"hash={t.get('hash','')[:16]}")
