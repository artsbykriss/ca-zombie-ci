#!/usr/bin/env python3
"""Final evidence gathering: address resolution, prices, supply, mint hunt."""
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


ADDrs = {
    "attacker": "0:2433bb62557246681d024d9dc273630f8b7be03cb7f0c7c7cb9a85542914c2c2",
    "orchestrator": "0:0343a25c2b434cb8d339bb009c4bd6e3727d914ef731608663365848872c14ad",
    "batch1": "0:39ae7f14483d9fe7e68d71ec9180db017fc08e2bd35cf8ddd3561b0e031efea7",
    "batch2": "0:182392860577067df54309c2b27694db3138512810ba3e61c5428a332298098b",
    "deployed_9cdc9c26": "0:9cdc9c26653cb74f7db74c49455a96cf462d8bc3a17185f00dc60d53cb982dde",
    "deployed_8df00bc8": "0:8df00bc88a4fc555ac87aa6c724007973443e4b2688184d1e33e4111a5f42279",
    "factorial_usdt_vault": "0:06b609ebd46d170e294651170e077a54865f8ba3ffc9f936893f42b87b2f1cb9",
    "exchange_5987d0a9": "0:5987d0a92d9c8d9702",
    "addr_1b589dd8": "0:1b589dd8d4780822f7",
    "addr_779dcc81": "0:779dcc815138d9500e",
    "addr_f0e5e2eb": "0:f0e5e2ebc4b9e4166c",
    "addr_13d2708e": "0:13d2708edb4bc2ea0c",
    "addr_34e3ffe0": "0:34e3ffe038f399bd8788d27052db7de158e298585c94070b5179cced530c97a1",
    "BasicPool": "0:ab1071c6e057fc4c3dcfcee1f9b454b01c10f7cf17976a8b33e3c8c62de6f08a",
    "StormAdvancedPool": "0:8e03780ddc393e9a5ebaceec7fbee89aee64c805310d2b1b68983e930e09c565",
    "AdvancedPool": "0:425d0a76b124c986f9d5e83941aa14ec74d31973fb49717409e578e85a2cbe38",
    "EthenaPool": "0:3d893760b0fc6f934f227425d0a1e7c6a8918b4c3405cb85b7e00b448fb67fdb",
    "StormUsdtPool": "0:1825d53d24545c280c0c66fdcca83d105630443063bfe26830389b5304e1d1db",
    "LendingVaultPool": "0:503038d654b797d2f0143434d12fe680ebae4422d2f34af38dcb02831d72510a",
    "StormTonPool": "0:379b81f7bd350e797196fa8e80132671bfa8bbf6d47e8b57f85e25b9f3c1c9a2",
    "addr_8d801987": "0:8d801987541456a4c79913b13dd9133e19e727bfcf0b25a5c0966aa7e1601f24",
    "FactorialTON_friendly": "EQADQ6JcK0NMuNM5uwCcS9bjcn2RTvcxYIZjNlhIhywUrfBN",
    "FactorialUSDT_friendly": "EQAGtgnr1G0XDilGURcOB3pUhl-Lo__J-TaJP0K4ey8cuSaW",
}

print("=== ACCOUNT RESOLUTION ===")
res = {}
for name, a in ADDrs.items():
    j = get(f"{BASE}/accounts/{a}")
    res[name] = j
    if "__error__" in j:
        print(f"{name:22s} {a} ERR {j}")
        continue
    print(f"{name:22s} {j.get('address'):<52s} wallet={j.get('is_wallet')} "
          f"iface={j.get('interfaces')} name={j.get('name')} status={j.get('status')} "
          f"bal={j.get('balance')}")
with open(os.path.join(OUT, "addr_resolution.json"), "w") as f:
    json.dump(res, f, indent=1)

print("\n=== TON / AffluentTON PRICE ===")
# tonapi rates
for sym in ["TON", "USDT"]:
    j = get(f"{BASE}/rates", {"tokens": sym, "currencies": "usd"})
    print(sym, json.dumps(j)[:300])
# historical: use toncenter or tonapi /rates/chart
j = get(f"{BASE}/rates/chart", {"token": "ton", "currency": "usd",
                                "start_date": 1791590400, "end_date": 1792368000})
print("ton chart:", json.dumps(j)[:600])

# AffluentTON jetton full
print("\n=== AFFLUENTTON JETTON ===")
for label, addr in [("AffluentTON_EQDIKEz2", "EQDIKEz2BYLnTRWo5W5a6moZ9PXNtyOVOFF7noi8Ufv3axz_"),
                    ("affTONl_0343", "0:0343a25c2b434cb8d339bb009c4bd6e3727d914ef731608663365848872c14ad")]:
    j = get(f"{BASE}/jettons/{addr}")
    print(label, json.dumps(j)[:700])

# supply changes: use toncenter runGetMethod on jetton master? use tonapi /jettons/{addr}/holders
print("\n=== AFFLUENTTON HOLDERS (top) ===")
j = get(f"{BASE}/jettons/EQDIKEz2BYLnTRWo5W5a6moZ9PXNtyOVOFF7noi8Ufv3axz_/holders", {"limit": 20})
if "__error__" not in j:
    for h in j.get("addresses", [])[:20]:
        o = h.get("owner", {})
        print(f"  {o.get('address')} wallet={o.get('is_wallet')} bal={h.get('balance')} "
              f"name={o.get('name')}")
else:
    print("ERR", j)
