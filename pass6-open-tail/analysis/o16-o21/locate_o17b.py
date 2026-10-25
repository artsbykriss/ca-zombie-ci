#!/usr/bin/env python3
"""O17 Loyal Earn: confirm the vaults are Squads multisigs (no proprietary program).
Also snapshot custody/TVL for O13-O21 and program lamport balances. Read-only, keyless."""
import json, sys, os, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "o13-o15"))
from sol_rpc import get_account_info, get_balance

SQUADS_V4 = "SQDS4ep65T869zMMBKyuUq6aD6EgTu8psMjkvj52pCf"
SQUADS_V3 = "SMPLecH534NA9acpos4G6x7uf3LWbCAwZQE9e8ZekMu"

def http(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

PROGS = {
    "O16_satrush_main": "satRushGBRY2vgapeTAkoxz26vL2cYqyPi6CnBj7Tco",
    "O16_satrush_staking": "SaTsTaKpGdTfUEPSSwyYgLKkfnZu8uL3D1DbLXshdb7",
    "O18_truedex": "ttaiNybR4ncnBFsBCQKdVus8BNHepErToRp5cuULduL",
    "O19_pascal": "3vCgc3aL1D6acmtiqtUgRSRDhep4PnVgs4jk86dGpg7j",
    "O20_n1bridge": "n1brh2AaBbnMPEjpoCDFs1fzWb5Pa8FC1o8yXp2fAqM",
    "O21_byzanlink_vault": "HyuZ17H9ScJ6GsMnJMYTCUZrw6Jz4AS4RGD9h3Pt4Se",
    "O21_byzanlink_payfi": "B9wHQVTeCkZ8KM8nZTBfHQyfQhJvuihhHa9SdWo4x77U",
    "O13_diversifi": "3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk",
    "O14_overpass": "WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum",
    "O15_zodial": "zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ",
}

def main():
    out = {}
    # 1) O17 vaults -> owner program
    try:
        v = http("https://stats.askloyal.com/api/earn/vaults")
        vaults = v.get("vaults") or v.get("data") or []
        owners = {}
        sample = vaults[:12]
        for a in sample:
            info = get_account_info(a).get("result", {}).get("value")
            if info:
                owners[a] = info.get("owner")
        out["loyal_earn"] = {
            "n_vaults": len(vaults),
            "sampled": owners,
            "squads_v4_count": sum(1 for o in owners.values() if o == SQUADS_V4),
            "squads_v3_count": sum(1 for o in owners.values() if o == SQUADS_V3),
        }
    except Exception as e:
        out["loyal_earn"] = {"error": str(e)}
    # 2) program lamport balances
    bal = {}
    for name, pid in PROGS.items():
        try:
            r = get_balance(pid)
            bal[name] = {"program": pid, "lamports": r.get("result", {}).get("value")}
        except Exception as e:
            bal[name] = {"program": pid, "error": str(e)}
    out["program_lamports"] = bal
    # 3) TVL snapshot
    tvl = {}
    for slug in ["loyal-earn", "sat-rush", "true-dex", "pascal", "n1-exchange",
                 "diversifi", "overpass", "zodial", "byzanlink"]:
        try:
            d = http(f"https://api.llama.fi/protocol/{slug}")
            tvl[slug] = {"name": d.get("name"), "tvl": d.get("currentChainTvls")}
        except Exception as e:
            tvl[slug] = {"error": str(e)}
    out["defillama_tvl"] = tvl
    json.dump(out, open(os.path.join(os.path.dirname(__file__), "locate_o17_result.json"), "w"), indent=1)
    print(json.dumps(out, indent=1)[:5000])

if __name__ == "__main__":
    main()
