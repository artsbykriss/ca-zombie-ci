#!/usr/bin/env python3
"""Round-trip pricing test: convert_to_shares/convert_to_assets on all queryable Margined vaults.
Detects deposit->redeem arbitrage (inconsistent pricing) that a fresh attacker could exploit."""
import json, base64, urllib.request, urllib.error, sys, time

UA = {"User-Agent": "Mozilla/5.0 (research)"}
OSMO = ["https://osmosis-api.polkachu.com", "https://osmosis-rest.publicnode.com", "https://rest-osmosis.ecostake.com"]
NEUT = ["https://lcd-neutron.keplr.app", "https://neutron-api.polkachu.com"]

VAULTS = {
    "osmosis": {
        "stOSMO": ("osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5", 6),
        "stTIA": ("osmo1q3w9kedgtc8sdh7xlcr77ydv3qu7fs2e3q6xznysp2lrdfyz9xyqv26yqv", 6),
        "ampOSMO": ("osmo1cztgw4e467vjljd0s2flz8asu3x3wg9q0ttga9t6kzmpyaauxxrs2gjshq", 6),
        "bOSMO": ("osmo159f7axyc32cyfgzx0gs9r98jwpgutj5qz4ns97xvu7nw3xzpavzsg2uxr3", 6),
        "qOSMO": ("osmo18vk0rsu4qwzx74g9alu2f7x5zs99sluwkuh5wp70yed2ne4pmutqf9lvdu", 6),
        "OSMORedemption": ("osmo15fqmdl8lfl9h0qflljd63ufw9j2m7xmsk3hu5vsn8xpta4hk5chqt7mddc", 6),
        "TIARedemption": ("osmo1reyz7pwu7y9e7lmzqg6j4h7jcv32du7n7jhnk2lz93a9lxr56ess2qtgzl", 6),
        "ATOMRedemption": ("osmo1hvl5kj4xzdj4udxjv2dzk2zfqhzkd9afqygwq3t84tn53e0250zqrltj48", 6),
        "DYDXRedemption": ("osmo1grs74ux62lukjdlfs9ll4myyulcyjcd4uzwpw3cgnzdygtsspp2se2ense", 18),
    },
    "neutron": {
        "NTRNStructured": ("neutron13h4jzme5880knnc23xvwu9gytynnxu5cc0fek6fndmjyctzznj9sd5yhhy", 6),
        "ATOMdATOM": ("neutron1f99ujxefjr4jqmskc7hvg09am6pdq2j2c5049xwl0de4cavc4rfsl866y0", 6),
        "ATOMFund": ("neutron1puedrclm6rn33x3zv66xg6m23qcdagayqua6jj2wqzvfznlqef8qe53wr2", 6),
        "wBTCUSDC": ("neutron17fyzkafg4scrd6xu0sp9llrl6hazegza7yer4erlea0kvk30yxsqk2xqfd", 6),
        "NTRNUSDC": ("neutron1t0fl9k43g86sv60ghx9vtwed9rpgtf49rxzm05ff477j23h52c6s0urdc7", 6),
        "TIAUSDC": ("neutron1wv8pl7tsatzx6n9yaqfksvu5y0x7j50g6mhy636udwfn3vyqp0hsu7g8yk", 6),
        "ATOMUSDC": ("neutron1krqwpk0kmphl93kykavp2fnr88g5rnrpk40c34a55yrl00tmfz0s99ewc6", 6),
        "TIAFund": ("neutron14q3umuuvyv6mndd5acuc3n8u5mlvrrq3kkzrputu3rkhz8nd2uzqmfl4v6", 6),
    },
}

def http_get(url, timeout=15):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def smart(bases, addr, q, tries=4):
    qb = base64.b64encode(json.dumps(q).encode()).decode()
    last = None
    for i in range(tries):
        for b in bases:
            try:
                return http_get(f"{b}/cosmwasm/wasm/v1/contract/{addr}/smart/{qb}")
            except urllib.error.HTTPError as e:
                body = e.read().decode()
                return {"_http": e.code, "_body": body[:300]}
            except Exception as e:
                last = {"_err": str(e)}
        time.sleep(1)
    return last

def main():
    out = {}
    def save():
        json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/roundtrip.json", "w"), indent=1)
    for chain, vs in VAULTS.items():
        bases = OSMO if chain == "osmosis" else NEUT
        for name, (addr, dec) in vs.items():
            unit = 10 ** dec
            e = {}
            ta = smart(bases, addr, {"total_assets": {}})
            ts = smart(bases, addr, {"total_vault_token_supply": {}})
            e["total_assets"] = ta.get("data", ta)
            e["total_supply"] = ts.get("data", ts)
            # round trip: shares from 1 unit, then assets back
            cs = smart(bases, addr, {"convert_to_shares": {"amount": str(unit)}})
            e["shares_from_1unit"] = cs.get("data", cs)
            if isinstance(e["shares_from_1unit"], str):
                ca = smart(bases, addr, {"convert_to_assets": {"amount": e["shares_from_1unit"]}})
                e["assets_back_from_those_shares"] = ca.get("data", ca)
            # also convert_to_assets of 1 unit of shares
            ca2 = smart(bases, addr, {"convert_to_assets": {"amount": str(unit)}})
            e["assets_from_1unit_shares"] = ca2.get("data", ca2)
            # large: half of total supply -> assets
            if isinstance(e["total_supply"], str):
                half = str(int(e["total_supply"]) // 2)
                ca3 = smart(bases, addr, {"convert_to_assets": {"amount": half}})
                e["assets_from_half_supply"] = ca3.get("data", ca3)
            out.setdefault(chain, {})[name] = e
            save()
            print(f"[{chain}] {name}: ta={e['total_assets']} ts={e['total_supply']} 1unit->shares={e['shares_from_1unit']} back={e.get('assets_back_from_those_shares')}", file=sys.stderr)
    print("saved")

if __name__ == "__main__":
    main()
