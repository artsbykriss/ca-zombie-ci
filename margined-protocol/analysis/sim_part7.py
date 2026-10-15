#!/usr/bin/env python3
"""Part 7: pool spot price check + stTIA vault round trip + qOSMO panic."""
import json, base64, urllib.request, urllib.error, sys
sys.path.insert(0, "/home/heisenberg/CA/margined-protocol/analysis")
import sim_gates as SG

OSMO_BASE = "https://osmosis-api.polkachu.com"

def http_get(url, timeout=20):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (research)"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def pool_spot(pool_id, denom_in, denom_out):
    # poolmanager spot price: /osmosis/poolmanager/v1beta1/{pool_id}/spot_price?base_asset_denom=..&quote_asset_denom=..
    url = f"{OSMO_BASE}/osmosis/poolmanager/v1beta1/{pool_id}/spot_price?base_asset_denom={urllib.parse.quote(denom_in)}&quote_asset_denom={urllib.parse.quote(denom_out)}"
    try:
        return http_get(url)
    except Exception as e:
        return {"err": str(e)}

def pool(pool_id):
    try:
        return http_get(f"{OSMO_BASE}/osmosis/poolmanager/v1beta1/{pool_id}")
    except Exception as e:
        return {"err": str(e)}

import urllib.parse
STOSMO = "ibc/D176154B0C63D1F9C6DCFB4F70349EBF2E2B5A87A05902F57A6AE92B863E9AEC"
STTIA = "ibc/D79E7D83AB399BFFF93433E54FAA480C191248FC556924A2A8351AE2638B3877"
out = {}
print("== pool 1252 spot stOSMO->OSMO:")
r = pool_spot(1252, STOSMO, "uosmo")
out["pool1252_spot"] = r
print(json.dumps(r, indent=1)[:400])
print("== pool 1252 info:")
r2 = pool(1252)
out["pool1252"] = r2
print(json.dumps(r2, indent=1)[:600])
print("== pool 1428 (stTIA) spot:")
r3 = pool_spot(1428, STTIA, "uosmo")
out["pool1428_spot"] = r3
print(json.dumps(r3, indent=1)[:300])

# stTIA LSD vault round trip (deployer2 has 0.5 stTIA)
STTIA_VAULT = "osmo1q3w9kedgtc8sdh7xlcr77ydv3qu7fs2e3q6xznysp2lrdfyz9xyqv26yqv"
STTIA_SHARE = "factory/osmo1q3w9kedgtc8sdh7xlcr77ydv3qu7fs2e3q6xznysp2lrdfyz9xyqv26yqv/lsd-vault-1428"
addr, pk = SG.SIGNERS["osmosis"]["deployer2"]
seq = SG.sequence("osmosis", addr)
dep = SG.simulate("osmosis", [{"contract": STTIA_VAULT, "msg": {"deposit": {"amount": "500000", "recipient": None}},
                               "funds": [{"denom": STTIA, "amount": "500000"}]}], addr, pk, seq)
out["dep_sttia"] = dep
def events_of(r): return r["resp"].get("result", {}).get("events", []) if r.get("ok") else []
def find_minted(ev, denom, recipient):
    amts = []
    for e in ev:
        a = {x["key"]: x["value"] for x in e.get("attributes", [])}
        if e.get("type") in ("transfer", "coin_received") and a.get("receiver") == recipient:
            for coin in a.get("amount", "").split(","):
                coin = coin.strip()
                if coin.endswith(denom):
                    amts.append(int(coin[:-len(denom)]))
    return max(amts) if amts else None
minted = find_minted(events_of(dep), STTIA_SHARE, addr)
print("stTIA dep ok:", dep.get("ok"), "minted:", minted, "err:", str(dep.get("body") or "")[:200])
out["sttia_minted"] = minted
if minted:
    rt = SG.simulate("osmosis", [
        {"contract": STTIA_VAULT, "msg": {"deposit": {"amount": "500000", "recipient": None}}, "funds": [{"denom": STTIA, "amount": "500000"}]},
        {"contract": STTIA_VAULT, "msg": {"redeem": {"amount": str(minted), "recipient": None}}, "funds": [{"denom": STTIA_SHARE, "amount": str(minted)}]},
    ], addr, pk, seq)
    out["rt_sttia"] = rt
    print("stTIA rt ok:", rt.get("ok"), str(rt.get("body") or "")[:250])
    if rt.get("ok"):
        pay = {}
        for e in events_of(rt):
            a = {x["key"]: x["value"] for x in e.get("attributes", [])}
            if e.get("type") == "transfer" and a.get("recipient") == addr and a.get("msg_index") == "1":
                for coin in a.get("amount", "").split(","):
                    coin = coin.strip()
                    pay[coin] = pay.get(coin, 0)
        print("stTIA payout:", json.dumps(pay)[:300])

# qOSMO panic full message
qOSMO = "osmo18vk0rsu4qwzx74g9alu2f7x5zs99sluwkuh5wp70yed2ne4pmutqf9lvdu"
d2addr, d2pk = SG.SIGNERS["osmosis"]["deployer2"]
dep2 = SG.simulate("osmosis", [{"contract": qOSMO, "msg": {"deposit": {"amount": "1000000", "recipient": None}},
                                "funds": [{"denom": "ibc/42D24879D4569CE6477B7E88206ADBFE47C222C6CAD51A54083E4A72594269FC", "amount": "1000000"}]}], d2addr, d2pk, seq)
out["dep_qosmo"] = dep2
print("qOSMO dep:", str(dep2.get("body") or dep2.get("err"))[:500])
json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/sim-part7.json", "w"), indent=1)
