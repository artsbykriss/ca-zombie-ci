#!/usr/bin/env python3
"""Re-query failed bank balances + controller TWAPs + denom traces."""
import json, base64, urllib.request, urllib.error, sys, time

UA = {"User-Agent": "Mozilla/5.0 (research)"}
OSMO = ["https://osmosis-api.polkachu.com", "https://osmosis-rest.publicnode.com", "https://rest-osmosis.ecostake.com"]
NEUT = ["https://lcd-neutron.keplr.app", "https://neutron-api.polkachu.com"]

RETRY_ADDRS = {
    "osmosis": {
        "usdcaxlGrid": "osmo1qngwlgzt0r3fdg6zgln5wa6mr5c7t6fek3qqgxesujjak5ds747sy6qu2f",
        "DYDXRedemption": "osmo1grs74ux62lukjdlfs9ll4myyulcyjcd4uzwpw3cgnzdygtsspp2se2ense",
    },
    "neutron": {
        "ATOMFund": "neutron1puedrclm6rn33x3zv66xg6m23qcdagayqua6jj2wqzvfznlqef8qe53wr2",
        "wBTCUSDC": "neutron17fyzkafg4scrd6xu0sp9llrl6hazegza7yer4erlea0kvk30yxsqk2xqfd",
        "NTRNUSDC": "neutron1t0fl9k43g86sv60ghx9vtwed9rpgtf49rxzm05ff477j23h52c6s0urdc7",
        "TIAUSDC": "neutron1wv8pl7tsatzx6n9yaqfksvu5y0x7j50g6mhy636udwfn3vyqp0hsu7g8yk",
        "ATOMUSDC": "neutron1krqwpk0kmphl93kykavp2fnr88g5rnrpk40c34a55yrl00tmfz0s99ewc6",
        "TIAFund": "neutron14q3umuuvyv6mndd5acuc3n8u5mlvrrq3kkzrputu3rkhz8nd2uzqmfl4v6",
    },
}
CONTROLLERS = {
    "osmosis": {
        "lsd_controller": "osmo1x83dj67d25gjfwhfrp6qa893yjc2nr3dfcyt02",
        "redemption_controller": "osmo1pzpe5v33udccmv64w57tv6pk8cjy06rtxfmsjq",
    },
    "neutron": {
        "atomfund": "neutron1ajk4hcvtf48qwt773v8cpwraq2qtj9kum6x6twua8jzv7863y8csqs64ca",
        "atomdatom": "neutron1cgd08p87rl70psgqneua6nv4s3hzhvtgeykg7hfzqk0x48u589wsa9ss2l",
        "ntrnusdc": "neutron13tyej6xvgj4uc4c2xxgktjkgllzgngaksqkvyv42lx6y82teum6q3307xw",
        "tiausdc": "neutron1sj9ax77exvyc86dv30399dw54yehnfajaltj8ugf70vswus9xuks4ldwtu",
        "atomusdc": "neutron1rtvdz9u2zdwtadc8zglawau3f6jrh8jefxjwayl9jc42e24t5rlsflpchs",
        "tiafund": "neutron1kz5qqv5jmz7q6y96ftq0ew9023m3tmhpex788z4slhm0xuax7vpqz72jev",
        "wbtcusdc": "neutron1me4fuchq3pgle46dvdxsgvpz02z605gkr0sgs6uwew25cpgg3ydsfg8zms",
    },
}
DENOM_TRACES = {
    "osmosis": [
        "D79E7D83AB399BFFF93433E54FAA480C191248FC556924A2A8351AE2638B3877",
        "D176154B0C63D1F9C6DCFB4F70349EBF2E2B5A87A05902F57A6AE92B863E9AEC",
        "42D24879D4569CE6477B7E88206ADBFE47C222C6CAD51A54083E4A72594269FC",
        "A8CA5EE328FA10C9519DF6057DA1F69682D28F7D0F5CCC7ECB72E3DCA2D157A4",
        "C360EF34A86D334F625E4CBB7DA3223AEA97174B61F35BB3758081A8160F7D9B",
        "9BCB27203424535B6230D594553F1659C77EC173E36D9CF4759E7186EE747E84",
        "698350B8A61D575025F3ED13E9AC9C0F45C89DEFE92F76D5838F1D3C1A7FF7C9",
        "498A0751C798A0D9A389AA3691123DADA57DAA4FE165D5C75894505B876BA6E4",
        "27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2",
    ],
    "neutron": [
        "C4CFF46FD6DE35CA4CF4CE031E643C8FDC9BA4B99AE598E9B0ED98FE3A2319F9",
        "773B4D0A3CD667B2275D5A4A7A2F0909C0BA0F4059C0B9181E680DDF4965DCC7",
        "B559A80D62249C8AA07A380E2A2BEA6E5CA9A6F079C912C3A9E9B494105E4F81",
        "78F7404035221CD1010518C7BC3DD99B90E59C2BA37ABFC3CE56B0CFB7E8901B",
        "DF8722298D192AAB85D86D0462E8166234A6A9A572DD4A2EA7996029DF4DB363",
    ],
}

def http_get(url, timeout=15):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def try_ep(bases, path, tries=5):
    last = None
    for i in range(tries):
        for b in bases:
            try:
                return http_get(b + path)
            except urllib.error.HTTPError as e:
                last = {"_http": e.code, "_body": e.read().decode()[:300]}
                if e.code == 404:
                    return last
            except Exception as e:
                last = {"_err": str(e)}
        time.sleep(1)
    return last

def main():
    out = {"banks": {}, "controllers": {}, "denoms": {}}
    def save():
        json.dump(out, open("/home/heisenberg/CA/margined-protocol/analysis/recheck.json", "w"), indent=1)
    for chain, addrs in RETRY_ADDRS.items():
        bases = OSMO if chain == "osmosis" else NEUT
        for n, a in addrs.items():
            r = try_ep(bases, f"/cosmos/bank/v1beta1/balances/{a}?pagination.limit=200", tries=6)
            out["banks"].setdefault(chain, {})[n] = r.get("balances", r)
            save()
            print(f"[bank/{chain}] {n}: {json.dumps(r.get('balances', r))[:250]}", file=sys.stderr)
    for chain, cs in CONTROLLERS.items():
        bases = OSMO if chain == "osmosis" else NEUT
        for n, a in cs.items():
            e = {}
            for qn, q in [("twap420", {"twap_price": {"duration": 420}}), ("twap3600", {"twap_price": {"duration": 3600}}), ("spot", {"spot_price": {}})]:
                qb = base64.b64encode(json.dumps(q).encode()).decode()
                r = try_ep(bases, f"/cosmwasm/wasm/v1/contract/{a}/smart/{qb}", tries=4)
                e[qn] = r.get("data", r)
            out["controllers"].setdefault(chain, {})[n] = e
            save()
            print(f"[ctrl/{chain}] {n}: {json.dumps(e)[:300]}", file=sys.stderr)
    for chain, hashes in DENOM_TRACES.items():
        bases = OSMO if chain == "osmosis" else NEUT
        for h in hashes:
            r = try_ep(bases, f"/ibc/apps/transfer/v1/denom_traces/{h}", tries=4)
            tr = r.get("denom_trace", r)
            out["denoms"].setdefault(chain, {})[h] = tr
            save()
            print(f"[denom/{chain}] {h[:12]}: {json.dumps(tr)[:160]}", file=sys.stderr)
    print("saved")

if __name__ == "__main__":
    main()
