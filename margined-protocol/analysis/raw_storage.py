#!/usr/bin/env python3
"""Read raw cw-storage-plus items for all Margined contracts (read-only)."""
import json, base64, urllib.request, urllib.error, sys
from concurrent.futures import ThreadPoolExecutor

UA = {"User-Agent": "Mozilla/5.0 (research)"}
ENDPOINTS = {
    "osmosis": ["https://osmosis-api.polkachu.com", "https://osmosis-rest.publicnode.com", "https://rest-osmosis.ecostake.com"],
    "neutron": ["https://lcd-neutron.keplr.app", "https://neutron-api.polkachu.com"],
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
KEYS = ["config", "state", "owner", "ownership_proposals", "contract_info", "pending_redemptions",
        "redemption", "pending_deposits", "pending_redemptions_queue", "deposits", "redemptions",
        "vault_info", "strategy", "fees", "queue", "pending", "total_deposits", "positions"]

def http_get(url, timeout=12):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def raw(chain, addr, key):
    k = base64.b64encode(key.encode()).decode()
    for base in ENDPOINTS[chain]:
        try:
            r = http_get(f"{base}/cosmwasm/wasm/v1/contract/{addr}/raw/{k}")
            d = r.get("data")
            if d:
                try:
                    return {"key": key, "value": json.loads(base64.b64decode(d))}
                except Exception:
                    return {"key": key, "raw_b64": d[:400]}
            return None
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None  # key not found
            continue
        except Exception:
            continue
    return {"key": key, "_unreachable": True}

def probe(chain, name, addr):
    e = {}
    for k in KEYS:
        r = raw(chain, addr, k)
        if r is None:
            continue
        e[k] = r.get("value", r)
    return name, e

def main():
    out = {}
    def save():
        json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/raw-storage.json", "w"), indent=1)
    jobs = [(c, n, a) for c, vs in VAULTS.items() for n, a in vs.items()]
    with ThreadPoolExecutor(max_workers=8) as ex:
        futs = {ex.submit(probe, c, n, a): (c, n) for c, n, a in jobs}
        for f in futs:
            c, n = futs[f]
            try:
                name, e = f.result()
                out.setdefault(c, {})[name] = e
                save()
                print(f"[{c}] {n} keys={list(e.keys())}", file=sys.stderr)
            except Exception as ex2:
                out.setdefault(c, {})[n] = {"_exception": str(ex2)}
                save()
    with open("/home/heisenberg/CA/margined-protocol/analysis/raw-storage.json", "w") as fp:
        json.dump(out, fp, indent=1)
    print("saved")

if __name__ == "__main__":
    main()
