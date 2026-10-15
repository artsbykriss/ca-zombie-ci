#!/usr/bin/env python3
"""Fresh bank + total_assets + controller TWAP scan for all Margined contracts."""
import json, base64, urllib.request, urllib.error, sys, time
from concurrent.futures import ThreadPoolExecutor

UA = {"User-Agent": "Mozilla/5.0 (research)"}
ENDPOINTS = {
    "osmosis": ["https://osmosis-api.polkachu.com", "https://osmosis-rest.publicnode.com"],
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
EXTRA = {
    "neutron": {
        "escrow": "neutron1rl7key2jr285vwz79hgkusgtw3ylcgateux5p8ajkk4rya067dkserkva8",
        "treasury": "neutron1d9uwvv4w4n8yfnng8enl643vml4xwke63m63gl",
        "admin": "neutron1ha2hjlce7sqp59g8xhxz2jds97x8fdw9k9wngp",
    },
    "osmosis": {
        "treasury": "osmo1dw2yh3w85yda8qcfc07kl0pjnywz2wc04wjh5c",
    },
}
CONTROLLERS = {
    "neutron": {
        "atomfund": "neutron1ajk4hcvtf48qwt773v8cpwraq2qtj9kum6x6twua8jzv7863y8csqs64ca",
        "atomdatom": "neutron1cgd08p87rl70psgqneua6nv4s3hzhvtgeykg7hfzqk0x48u589wsa9ss2l",
        "ntrnusdc": "neutron13tyej6xvgj4uc4c2xxgktjkgllzgngaksqkvyv42lx6y82teum6q3307xw",
        "tiausdc": "neutron1sj9ax77exvyc86dv30399dw54yehnfajaltj8ugf70vswus9xuks4ldwtu",
        "atomusdc": "neutron1rtvdz9u2zdwtadc8zglawau3f6jrh8jefxjwayl9jc42e24t5rlsflpchs",
        "tiafund": "neutron1kz5qqv5jmz7q6y96ftq0ew9023m3tmhpex788z4slhm0xuax7vpqz72jev",
        "wbtcusdc": "neutron1me4fuchq3pgle46dvdxsgvpz02z605gkr0sgs6uwew25cpgg3ydsfg8zms",
    },
    "osmosis": {
        "lsd_controller": "osmo1x83dj67d25gjfwhfrp6qa893yjc2nr3dfcyt02",
        "redemption_controller": "osmo1pzpe5v33udccmv64w57tv6pk8cjy06rtxfmsjq",
    },
}

def http_get(url, timeout=12):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def try_ep(chain, path, tries=3):
    last = None
    for i in range(tries):
        for base in ENDPOINTS[chain]:
            try:
                return http_get(base + path)
            except urllib.error.HTTPError as e:
                last = {"_http": e.code, "_body": e.read().decode()[:200]}
                if e.code in (404,):
                    return last
            except Exception as e:
                last = {"_err": str(e)}
    return last

def smart(chain, addr, q):
    qb = base64.b64encode(json.dumps(q).encode()).decode()
    return try_ep(chain, f"/cosmwasm/wasm/v1/contract/{addr}/smart/{qb}")

def bank(chain, addr):
    return try_ep(chain, f"/cosmos/bank/v1beta1/balances/{addr}?pagination.limit=200")

def one(chain, name, addr):
    e = {}
    b = bank(chain, addr)
    e["bank"] = b.get("balances", b)
    ta = smart(chain, addr, {"total_assets": {}})
    e["total_assets"] = ta.get("data", ta)
    ts = smart(chain, addr, {"total_vault_token_supply": {}})
    e["total_supply"] = ts.get("data", ts)
    cfg = smart(chain, addr, {"vault_extension": {"vaultenator": {"config": {}}}})
    if "data" in cfg:
        e["config"] = cfg["data"]
    else:
        cfg2 = smart(chain, addr, {"config": {}})
        if "data" in cfg2:
            e["config"] = cfg2["data"]
    st = smart(chain, addr, {"vault_extension": {"vaultenator": {"state": {}}}})
    if "data" in st:
        e["state"] = st["data"]
    return name, e

def main():
    out = {"vaults": {}, "extras": {}, "controllers": {}}
    for chain in ("osmosis", "neutron"):
        r = try_ep(chain, "/cosmos/base/tendermint/v1beta1/blocks/latest")
        out.setdefault("meta", {})[chain + "_height"] = r.get("block", {}).get("header", {}).get("height")
    def save():
        json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/fresh-scan.json", "w"), indent=1)
    jobs = []
    for chain, vs in VAULTS.items():
        for n, a in vs.items():
            jobs.append(("vaults", chain, n, a))
    for chain, vs in EXTRA.items():
        for n, a in vs.items():
            jobs.append(("extras", chain, n, a))
    with ThreadPoolExecutor(max_workers=8) as ex:
        futs = {}
        for kind, chain, n, a in jobs:
            futs[ex.submit(one, chain, n, a)] = (kind, chain, n)
        for f in futs:
            kind, chain, n = futs[f]
            try:
                name, e = f.result()
                out[kind].setdefault(chain, {})[name] = e
                save()
                print(f"[{kind}/{chain}] {n} ok", file=sys.stderr)
            except Exception as e2:
                print(f"[{kind}/{chain}] {n} EXC {e2}", file=sys.stderr)
    # controllers: twap + spot
    for chain, cs in CONTROLLERS.items():
        for n, a in cs.items():
            e = {}
            for qn, q in [("twap420", {"twap_price": {"duration": 420}}),
                          ("twap3600", {"twap_price": {"duration": 3600}}),
                          ("spot", {"spot_price": {}})]:
                r = smart(chain, a, q)
                e[qn] = r.get("data", r)
            out["controllers"].setdefault(chain, {})[n] = e
            save()
            print(f"[controller/{chain}] {n} ok", file=sys.stderr)
    print("saved")

if __name__ == "__main__":
    main()
