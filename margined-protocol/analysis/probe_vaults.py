#!/usr/bin/env python3
"""Fast concurrent live-state probe for Margined/Locust vault contracts."""
import json, base64, urllib.request, urllib.error, sys
from concurrent.futures import ThreadPoolExecutor

UA = {"User-Agent": "Mozilla/5.0 (research)"}

ENDPOINTS = {
    "osmosis": ["https://osmosis-rest.publicnode.com", "https://osmosis-api.polkachu.com", "https://rest-osmosis.ecostake.com"],
    "neutron": ["https://neutron-api.polkachu.com", "https://lcd-neutron.keplr.app"],
}

VAULTS = {
    "osmosis": {
        "stOSMO": "osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5",
        "stTIA": "osmo1q3w9kedgtc8sdh7xlcr77ydv3qu7fs2e3q6xznysp2lrdfyz9xyqv26yqv",
        "ampOSMO": "osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq",
        "bOSMO": "osmo159f7axyc32cyfgzx0gs9r98jwpgutj5qz4ns97xvu7nw3xzpavzsg2uxr3",
        "qOSMO": "osmo18vk0rsu4qwzx74g9alu2f7x5zs99sluwkuh5wp70yed2ne4pmutqf9lvdu",
        "usdcaxlGrid": "osmo1qngwlgzt0r3fdg6zgln5wa6mr5c7t6fek3qqgxesujjak5ds747sy6qu2f",
        "OSMORedemption": "osmo15fqmdl8lfl9h0qflljd63ufw9j2m7xmsk3hu5vsn8xpta4hk5chqt7mddc",
        "TIARedemption": "osmo1reyz7pwu7y9e7lmzqg6j4h7jcv32du7n7jhnk2lz93a9lxr56ess2qtgzl",
        "ATOMRedemption": "osmo1hvl5kj4xzdj4udxjv2dzk2zfqhzkd9afqygwq3t84tn53e0250zqrltj48",
        "DYDXRedemption": "osmo1grs74ux62lukjdlfs9ll4myyulcyjcd4uzwpw3cgnzdygtsspp2se2ense",
    },
    "neutron": {
        "ATOMFund": "neutron1puedrclm6rn33x3zv66xg6m23qcdagayqua6jj2wqzvfznlqef8qe53wr2",
        "NTRNStructured": "neutron13h4jzme5880knnc23xvwu9gytynnxu5cc0fek6fndmjyctzznj9sd5yhhy",
        "ATOMdATOM": "neutron1f99ujxefjr4jqmskc7hvg09am6pdq2j2c5049xwl0de4cavc4rfsl866y0",
        "wBTCUSDC": "neutron17fyzkafg4scrd6xu0sp9llrl6hazegza7yer4erlea0kvk30yxsqk2xqfd",
        "NTRNUSDC": "neutron1t0fl9k43g86sv60ghx9vtwed9rpgtf49rxzm05ff477j23h52c6s0urdc7",
        "TIAUSDC": "neutron1wv8pl7tsatzx6n9yaqfksvu5y0x7j50g6mhy636udwfn3vyqp0hsu7g8yk",
        "ATOMUSDC": "neutron1krqwpk0kmphl93kykavp2fnr88g5rnrpk40c34a55yrl00tmfz0s99ewc6",
        "TIAFund": "neutron14q3umuuvyv6mndd5acuc3n8u5mlvrrq3kkzrputu3rkhz8nd2uzqmfl4v6",
    },
}

def http_get(url, timeout=10):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def try_endpoints(chain, path, timeout=10):
    errs = []
    for base in ENDPOINTS[chain]:
        try:
            return http_get(base + path, timeout), base
        except Exception as e:
            errs.append(f"{base}: {e}")
    return {"_err": errs}, None

def smart(chain, addr, query):
    q = base64.b64encode(json.dumps(query).encode()).decode()
    return try_endpoints(chain, f"/cosmwasm/wasm/v1/contract/{addr}/smart/{q}")

def contract_info(chain, addr):
    return try_endpoints(chain, f"/cosmwasm/wasm/v1/contract/{addr}")

def balances(chain, addr):
    return try_endpoints(chain, f"/cosmos/bank/v1beta1/balances/{addr}?pagination.limit=200")

QUERIES = {
    "info": {"info": {}},
    "total_assets": {"total_assets": {}},
    "total_supply": {"total_vault_token_supply": {}},
    "config": {"vault_extension": {"vaultenator": {"config": {}}}},
    "state": {"vault_extension": {"vaultenator": {"state": {}}}},
    "version": {"vault_extension": {"vaultenator": {"version": {}}}},
    "pending_redemptions": {"vault_extension": {"vaultenator": {"pending_redemptions": {"limit": 30}}}},
    "withdrawable": {"vault_extension": {"vaultenator": {"withdrawable_amount": {}}}},
}

def probe_one(chain, name, addr):
    e = {}
    ci, _ = contract_info(chain, addr)
    e["contract_info"] = ci.get("contract_info", ci)
    for qname, q in QUERIES.items():
        r, base = smart(chain, addr, q)
        if "data" in r:
            e[qname] = r["data"]
        else:
            e[qname + "_err"] = str(r)[:160]
    r, _ = balances(chain, addr)
    e["bank"] = r.get("balances", r)
    return name, e

def main():
    out = {"_meta": {}}
    for chain in ("osmosis", "neutron"):
        r, base = try_endpoints(chain, "/cosmos/base/tendermint/v1beta1/blocks/latest")
        out["_meta"][chain + "_height"] = r.get("block", {}).get("header", {}).get("height") if "block" in r else r
        out["_meta"][chain + "_time"] = r.get("block", {}).get("header", {}).get("time") if "block" in r else None
    jobs = []
    for chain, vaults in VAULTS.items():
        for name, addr in vaults.items():
            jobs.append((chain, name, addr))
    with ThreadPoolExecutor(max_workers=10) as ex:
        futs = {ex.submit(probe_one, c, n, a): (c, n) for c, n, a in jobs}
        for f in futs:
            c, n = futs[f]
            try:
                name, e = f.result()
                out.setdefault(c, {})[name] = e
                print(f"[{c}] {name} ok", file=sys.stderr)
            except Exception as ex2:
                out.setdefault(c, {})[n] = {"_exception": str(ex2)}
                print(f"[{c}] {n} EXC {ex2}", file=sys.stderr)
    with open("/home/heisenberg/CA/margined-protocol/analysis/live-state-probe1.json", "w") as fp:
        json.dump(out, fp, indent=1)
    print(json.dumps(out["_meta"], indent=1))

if __name__ == "__main__":
    main()
