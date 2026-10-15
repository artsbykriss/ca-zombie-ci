#!/usr/bin/env python3
"""Probe raw responses (success or error) for a set of queries against Margined contracts."""
import json, base64, urllib.request, urllib.error, sys

UA = {"User-Agent": "Mozilla/5.0 (research)"}

TARGETS = {
    "osmosis": {
        "usdcaxlGrid": ("https://osmosis-api.polkachu.com", "osmo1qngwlgzt0r3fdg6zgln5wa6mr5c7t6fek3qqgxesujjak5ds747sy6qu2f"),
        "DYDXRedemption": ("https://osmosis-api.polkachu.com", "osmo1grs74ux62lukjdlfs9ll4myyulcyjcd4uzwpw3cgnzdygtsspp2se2ense"),
        "stOSMO": ("https://osmosis-api.polkachu.com", "osmo16s3sxs5886p42kteunp6370pken2n5ukzszz0trkr39epqtawn2qk4r9l5"),
    },
    "neutron": {
        "ATOMFund": ("https://lcd-neutron.keplr.app", "neutron1puedrclm6rn33x3zv66xg6m23qcdagayqua6jj2wqzvfznlqef8qe53wr2"),
        "wBTCUSDC": ("https://lcd-neutron.keplr.app", "neutron17fyzkafg4scrd6xu0sp9llrl6hazegza7yer4erlea0kvk30yxsqk2xqfd"),
    },
}

QUERIES = {
    "info": {"info": {}},
    "total_assets": {"total_assets": {}},
    "total_supply": {"total_vault_token_supply": {}},
    "convert_to_shares_1": {"convert_to_shares": {"amount": "1000000"}},
    "convert_to_assets_1": {"convert_to_assets": {"amount": "1000000"}},
    "config": {"vault_extension": {"vaultenator": {"config": {}}}},
    "config_alt": {"config": {}},
    "state": {"vault_extension": {"vaultenator": {"state": {}}}},
    "state_alt": {"state": {}},
    "version": {"vault_extension": {"vaultenator": {"version": {}}}},
    "version_alt": {"version": {}},
    "owner": {"vault_extension": {"vaultenator": {"owner": {}}}},
    "vault_std_info": {"vault_standard_info": {}},
    "pending_redemptions": {"vault_extension": {"vaultenator": {"pending_redemptions": {"limit": 10}}}},
    "withdrawable_amount": {"vault_extension": {"vaultenator": {"withdrawable_amount": {}}}},
    "estimate_vault_assets": {"vault_extension": {"vaultenator": {"estimate_vault_assets": {"amount": "1000000"}}}},
    "all_redemptions": {"all_redemptions": {"limit": 5}},
    "redemptions": {"redemptions": {"user": "osmo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq", "limit": 5}},
}

def http_get(url, timeout=12):
    req = urllib.request.Request(url, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return {"_http": e.code, "_body": e.read().decode()[:400]}
    except Exception as e:
        return {"_error": str(e)}

def main():
    out = {}
    def save():
        with open("/home/heisenberg/CA/margined-protocol/analysis/raw-probe1.json", "w") as f:
            json.dump(out, f, indent=1)
    for chain, targets in TARGETS.items():
        for name, (base, addr) in targets.items():
            e = {}
            for qname, q in QUERIES.items():
                qb = base64.b64encode(json.dumps(q).encode()).decode()
                r = http_get(f"{base}/cosmwasm/wasm/v1/contract/{addr}/smart/{qb}")
                e[qname] = r
            out[f"{chain}/{name}"] = e
            save()
            print(f"done {chain}/{name}", file=sys.stderr)
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
