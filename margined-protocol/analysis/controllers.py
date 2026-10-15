#!/usr/bin/env python3
"""Check controller/treasury/escrow addresses referenced by Margined vaults."""
import json, base64, urllib.request, urllib.error, sys
from concurrent.futures import ThreadPoolExecutor

UA = {"User-Agent": "Mozilla/5.0 (research)"}
ENDPOINTS = {
    "osmosis": ["https://osmosis-api.polkachu.com", "https://osmosis-rest.publicnode.com"],
    "neutron": ["https://lcd-neutron.keplr.app", "https://neutron-api.polkachu.com"],
}

ADDRS = {
    "osmosis": {
        "lsd_controller": "osmo1x83dj67d25gjfwhfrp6qa893yjc2nr3dfcyt02",
        "redemption_controller": "osmo1pzpe5v33udccmv64w57tv6pk8cjy06rtxfmsjq",
        "treasury": "osmo1dw2yh3w85yda8qcfc07kl0pjnywz2wc04wjh5c",
        "deployer": "osmo1g8qypve6l95xmhgc0fddaecerffymsl7kn9muw",
        "deployer2": "osmo13y2js99t6huwdgm5z26k6ugv8l09gvckjyztgz",
        "rewards_osmo_red": "osmo1p9tdspvs6l2gn3yxtssc5wx5eufc9qnwj4r2c6uq6mwuqmyl33rqwa4wkx",
        "rewards_tia_red": "osmo15xffqydxm0dcj5e0mhkepy3vvsupn9w563jla5tumdd6wtene97sfdeltw",
        "rewards_atom_red": "osmo13aufectwr3wpgwflkxqgfhlfsv326fl6x29kkgwg27ge0u7krk8s85nyea",
    },
    "neutron": {
        "admin": "neutron1ha2hjlce7sqp59g8xhxz2jds97x8fdw9k9wngp",
        "treasury": "neutron1d9uwvv4w4n8yfnng8enl643vml4xwke63m63gl",
        "redemption_escrow": "neutron1rl7key2jr285vwz79hgkusgtw3ylcgateux5p8ajkk4rya067dkserkva8",
        "atomfund_controller": "neutron1ajk4hcvtf48qwt773v8cpwraq2qtj9kum6x6twua8jzv7863y8csqs64ca",
        "atomdatom_controller": "neutron1cgd08p87rl70psgqneua6nv4s3hzhvtgeykg7hfzqk0x48u589wsa9ss2l",
        "ntrnusdc_controller": "neutron13tyej6xvgj4uc4c2xxgktjkgllzgngaksqkvyv42lx6y82teum6q3307xw",
        "tiausdc_controller": "neutron1sj9ax77exvyc86dv30399dw54yehnfajaltj8ugf70vswus9xuks4ldwtu",
        "atomusdc_controller": "neutron1rtvdz9u2zdwtadc8zglawau3f6jrh8jefxjwayl9jc42e24t5rlsflpchs",
        "tiafund_controller": "neutron1kz5qqv5jmz7q6y96ftq0ew9023m3tmhpex788z4slhm0xuax7vpqz72jev",
        "wbtcusdc_controller": "neutron1me4fuchq3pgle46dvdxsgvpz02z605gkr0sgs6uwew25cpgg3ydsfg8zms",
    },
}

def http_get(url, timeout=15):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def try_ep(chain, path):
    for base in ENDPOINTS[chain]:
        try:
            return http_get(base + path)
        except Exception:
            continue
    return {"_unreachable": True}

def one(chain, name, addr):
    out = {"address": addr}
    ci = try_ep(chain, f"/cosmwasm/wasm/v1/contract/{addr}")
    if "contract_info" in ci:
        c = ci["contract_info"]
        out["contract"] = {"code_id": c.get("code_id"), "label": c.get("label"), "admin": c.get("admin"), "creator": c.get("creator")}
    b = try_ep(chain, f"/cosmos/bank/v1beta1/balances/{addr}?pagination.limit=200")
    out["bank"] = b.get("balances", b)
    # version / config via smart query
    q = base64.b64encode(json.dumps({"vault_extension": {"vaultenator": {"config": {}}}}).encode()).decode()
    cfg = try_ep(chain, f"/cosmwasm/wasm/v1/contract/{addr}/smart/{q}")
    if "data" in cfg:
        out["vaultenator_config"] = cfg["data"]
    q2 = base64.b64encode(json.dumps({"config": {}}).encode()).decode()
    cfg2 = try_ep(chain, f"/cosmwasm/wasm/v1/contract/{addr}/smart/{q2}")
    if "data" in cfg2:
        out["config"] = cfg2["data"]
    return name, out

def main():
    out = {}
    jobs = [(c, n, a) for c, d in ADDRS.items() for n, a in d.items()]
    with ThreadPoolExecutor(max_workers=6) as ex:
        futs = {ex.submit(one, c, n, a): (c, n) for c, n, a in jobs}
        for f in futs:
            c, n = futs[f]
            try:
                name, e = f.result()
                out.setdefault(c, {})[name] = e
                print(f"[{c}] {n}: bank={json.dumps(e.get('bank'))[:200]} contract={json.dumps(e.get('contract'))[:200]}", file=sys.stderr)
            except Exception as e2:
                out.setdefault(c, {})[n] = {"_exception": str(e2)}
    json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/controllers.json", "w"), indent=1)
    print("saved")

if __name__ == "__main__":
    main()
