#!/usr/bin/env python3
"""
Live-state snapshot (CI): treasury UTxOs, TCheckCoin distribution, current
GroupInfo parameters and USD pricing. Read-only public Koios + CoinGecko.
"""
import json
import os
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)

KOIOS = "https://api.koios.rest/api/v1"
TREASURY = "addr1xyw0kswupwx38ljnvq8pwpvae0x69krywdr7cffg3d84ydp9nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncsw5rzpd"
GROUPINFO = "addr1w9vxq85q0zqwkdm86n3kefxtw5c4pw2mzm9a0v3vqj42kmqylk9gw"
OLD_CHECK = "addr1x9y94ggrg0mrhnp2g0ckyhwggyynfz8ydpd6vp7vrpa6f9f9nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncsrlh4ng"
NEW_CHECK = "addr1xxxqy7ggyc8tc22ppnj0llnc3kj3pexhl4nlfvua83makh39nvv84g58ykxqh90xx6j8ywgjst0dkt430w9lxgdmzncsurygyp"
TCHECK_POLICY = "526d246045bf4a66ae86fd7a9985a91ef3752113f9daa9060bb54be6"
NIGHT_POLICY = "0691b2fecca1ac4f53cb6dfb00b7013e561d1f34403b957cbb5af1fa"


def get(url):
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    for a in range(4):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                return json.loads(r.read())
        except Exception:
            if a == 3:
                raise
            time.sleep(3 * (a + 1))


def post(path, payload):
    req = urllib.request.Request(
        KOIOS + path, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "Accept": "application/json"},
        method="POST")
    for a in range(4):
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                return json.loads(r.read())
        except Exception:
            if a == 3:
                raise
            time.sleep(3 * (a + 1))


def main():
    tip = post("/tip", {})[0]
    utxos = post("/address_utxos", {"_addresses": [TREASURY], "_extended": True})
    lovelace = sum(int(u["value"]) for u in utxos)
    assets = {}
    for u in utxos:
        for a in (u.get("asset_list") or []):
            key = f"{a['policy_id']}.{a['asset_name']}"
            assets[key] = assets.get(key, 0) + int(a["quantity"])

    gi = post("/address_utxos", {"_addresses": [GROUPINFO], "_extended": True})
    gi_params = None
    if gi:
        gi_params = gi[0].get("inline_datum", {}).get("value")

    old = post("/address_utxos", {"_addresses": [OLD_CHECK], "_extended": True})
    new = post("/address_utxos", {"_addresses": [NEW_CHECK], "_extended": True})

    holders = post("/asset_addresses", {"_asset_policy": TCHECK_POLICY,
                                        "_asset_name": "54436865636b436f696e"})
    tinfo = post("/asset_info", {"_asset_list": [[TCHECK_POLICY, "54436865636b436f696e"]]})

    prices = {}
    try:
        prices = get("https://api.coingecko.com/api/v3/simple/price?ids=cardano,midnight-3&vs_currencies=usd")
    except Exception as e:  # noqa: BLE001
        prices = {"error": str(e)}

    ada = lovelace / 1e6
    night_units = assets.get(f"{NIGHT_POLICY}.4e49474854", 0)
    night = night_units / 1e6
    ada_px = prices.get("cardano", {}).get("usd")
    night_px = prices.get("midnight-3", {}).get("usd")

    res = {
        "fetched_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "tip": {"block_height": tip["block_height"], "epoch": tip["epoch_no"], "hash": tip["hash"]},
        "treasury": {
            "address": TREASURY,
            "utxo_count": len(utxos),
            "lovelace": lovelace,
            "ada": round(ada, 6),
            "assets": assets,
            "night": round(night, 6),
        },
        "group_info": {"address": GROUPINFO, "utxos": len(gi), "params": gi_params},
        "tcheck": {
            "policy": TCHECK_POLICY,
            "total_supply": tinfo[0]["total_supply"] if tinfo else None,
            "holders": [{"addr": h["payment_address"], "qty": h["quantity"]} for h in holders],
            "old_check_utxos": len(old),
            "new_check_utxos": len(new),
        },
        "prices": prices,
        "usd": {
            "ada": round(ada * ada_px, 2) if ada_px else None,
            "night": round(night * night_px, 2) if night_px else None,
            "ada_plus_night": round(ada * ada_px + night * night_px, 2) if (ada_px and night_px) else None,
        },
    }
    with open(os.path.join(OUT, "live_state.json"), "w") as f:
        json.dump(res, f, indent=2)
    print(json.dumps({k: res[k] for k in ("tip", "usd")}, indent=2))
    print("treasury ada", res["treasury"]["ada"], "night", res["treasury"]["night"],
          "utxos", res["treasury"]["utxo_count"])
    print("tcheck holders", len(res["tcheck"]["holders"]), "old", len(old), "new", len(new))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
