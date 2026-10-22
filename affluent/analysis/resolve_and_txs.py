#!/usr/bin/env python3
"""Resolve relevant addresses + pull full details for the two batched drain txs."""
import json, os, time, requests

OUT = os.path.dirname(os.path.abspath(__file__))
BASE = "https://tonapi.io/v2"
S = requests.Session()
S.headers.update({"Accept": "application/json", "User-Agent": "affluent-readonly/1.0"})


def get(url, params=None, tries=4):
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


RAWS = {
    "drain_dest_2433": "0:2433bb62557246681d024d9dc273630f8b7be03cb7f0c7c7cb9a85542914c2c2",
    "addr_0343a25c": "0:0343a25c2b434c",  # truncated, will resolve full from events
    "BasicPool": "0:ab1071c6e057fc4c3dcfcee1f9b454b01c10f7cf17976a8b33e3c8c62de6f08a",
    "AdvancedPool": "0:425d0a76b124c9",
    "LendingVaultPool": "0:503038d654b797",
    "edc50aa4": "0:edc50aa4808450",
    "68c174ed": "0:68c174edc434d2",
    "f9b6ac76": "0:f9b6ac76b461b0",
    "3d893760": "0:3d893760b0fc6f",
    "a80898ae": "0:a80898ae58f176",
}

TOTAL = 0


def resolve(addr, name):
    j = get(f"{BASE}/accounts/{addr}")
    if "__error__" in j:
        print(f"{name:20s} {addr}  ERR {j}")
        return
    print(f"{name:20s} {j.get('address')}  is_wallet={j.get('is_wallet')} "
          f"interfaces={j.get('interfaces')} name={j.get('name')} "
          f"status={j.get('status')} bal={j.get('balance')}")
    return j


print("=== RESOLVE ===")
res = {}
for name, a in RAWS.items():
    try:
        res[name] = resolve(a, name)
    except Exception as e:
        print(name, "EXC", e)

# --- the two big batched txs ---
TXS = {
    "tx_08b1751a89637f7c14fa": None,
    "tx_ba3fc8ad72185639820e": None,
}
# find full hashes from raw_events_all.json
data = json.load(open(os.path.join(OUT, "raw_events_all.json")))
found = {}
for name, d in data.items():
    for e in d["events"]:
        for btx in e.get("base_transactions", []) or []:
            for pre in ("08b1751a89637f7c14fa", "ba3fc8ad72185639820e"):
                if btx.startswith(pre):
                    found[pre] = (btx, name, e["timestamp"], e["event_id"])
for k, v in found.items():
    print("FOUND base_tx", k, v)

print("\n=== TX DETAILS ===")
txdump = {}
for pre, (btx, name, t, eid) in found.items():
    j = get(f"{BASE}/blockchain/transactions/{btx}")
    txdump[pre] = j
    if "__error__" in j:
        print(pre, "ERR", j); continue
    print(f"\n--- {pre} ({name}) ts={t} ---")
    print("  hash", j.get("hash"))
    print("  lt", j.get("lt"), "success", j.get("success"))
    im = j.get("in_msg", {})
    print("  in_msg from", (im.get("source") or {}).get("address"),
          "-> ", (im.get("destination") or {}).get("address"))
    print("  in_msg value", im.get("value"), "op", im.get("op_code"),
          "decoded", json.dumps(im.get("decoded_op_name")))
    for m in j.get("out_msgs", []) or []:
        print("  out_msg", (m.get("source") or {}).get("address"), "->",
              (m.get("destination") or {}).get("address"),
              "val", m.get("value"), "op", m.get("op_code"), m.get("decoded_op_name"))

with open(os.path.join(OUT, "tx_details.json"), "w") as f:
    json.dump(txdump, f, indent=1)
with open(os.path.join(OUT, "addr_resolve.json"), "w") as f:
    json.dump(res, f, indent=1)
