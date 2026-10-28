#!/usr/bin/env python3
"""
live.py — Phase D: read-only public LCD/REST reads for the shortlisted chains.

For each chain: deployed build_deps (authoritative wasmvm/wasmd/SDK/Go), the wasm
code-upload / instantiate params, bonded validator count, and latest block height.
These are HTTP GETs to public block-explorer/LCD endpoints — read-only, no keys,
no signing, no transactions, no state change.
"""
import json, os, re, sys, time, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "ci-out"))
os.makedirs(OUT, exist_ok=True)
UA = {"User-Agent": "cwa006-crosschain-research/1.0"}

# chain-registry name -> public LCD REST base(s)
LCD = {
    "archway": ["https://api.mainnet.archway.io", "https://archway-api.polkachu.com"],
    "jackal": ["https://api.jackalprotocol.com", "https://jackal-api.polkachu.com"],
    "shido": ["https://api.shido.io", "https://shido-api.polkachu.com"],
    "nyx": ["https://api.nyx.nodes.guru", "https://nyx-api.chronatog.com"],
    "osmosis": ["https://lcd.osmosis.zone", "https://osmosis-api.polkachu.com"],
    "kujira": ["https://lcd.kaiyo.kujira.setten.io", "https://kujira-api.polkachu.com"],
    "neutron": ["https://rest-kralum.neutron-1.neutron.org", "https://neutron-api.polkachu.com"],
    "juno": ["https://lcd-juno.itastakers.com", "https://juno-api.polkachu.com"],
    "stargaze": ["https://rest.stargaze-apis.com", "https://stargaze-api.polkachu.com"],
    "terra": ["https://phoenix-lcd.terra.dev", "https://terra-api.polkachu.com"],
    "terra2": ["https://phoenix-lcd.terra.dev"],
    "secretnetwork": ["https://lcd.secret.express", "https://secret-api.polkachu.com"],
    "sei": ["https://rest.sei-apis.com"],
    "injective": ["https://sentry.lcd.injective.network", "https://injective-api.polkachu.com"],
    "persistence": ["https://rest.cosmos.directory/persistence", "https://persistence-api.polkachu.com"],
    "cheqd": ["https://api.cheqd.net"],
    "coreum": ["https://full-node.mainnet-1.coreum.dev:1317", "https://coreum-api.polkachu.com"],
    "comdex": ["https://rest.comdex.one"],
    "chihuahua": ["https://api.chihuahua.wtf", "https://chihuahua-api.polkachu.com"],
    "migaloo": ["https://api.migaloo.zone", "https://migaloo-api.polkachu.com"],
    "nois": ["https://api.nois.network"],
    "ojo": ["https://lcd.ojo.network"],
    "desmos": ["https://api.mainnet.desmos.network", "https://desmos-api.polkachu.com"],
    "assetmantle": ["https://rest.assetmantle.one"],
    "quicksilver": ["https://api.quicksilver.polkachu.com"],
    "provenance": ["https://api.provenance.io"],
    "aura": ["https://api.aura.network"],
    "ki": ["https://api.ki.network"],
    "kava": ["https://api.kava.io", "https://kava-api.polkachu.com"],
    "nolus": ["https://api.nolus.network"],
    "nibiru": ["https://api.nibiru.fi", "https://nibiru-api.polkachu.com"],
    "bitsong": ["https://api.explorebitsong.com"],
    "cerberus": ["https://api.cerberus.zone"],
    "omniflixhub": ["https://rest.omniflix.network"],
    "regen": ["https://regen-api.polkachu.com", "https://api.regen.network"],
    "umee": ["https://api.mainnet.network.umee.cc", "https://umee-api.polkachu.com"],
    "shentu": ["https://api.shentu.technology"],
    "sentinel": ["https://api.sentinel.quokkastake.io"],
    "bitcanna": ["https://api.bitcanna.io"],
    "finschia": ["https://lcd.finschia.network"],
    "lum-network": ["https://api.lum.network"],
    "irisnet": ["https://iris-api.polkachu.com"],
    "canto": ["https://api.canto.io"],
    "passage": ["https://api.passage.vitwit.com"],
    "emoney": ["https://api.emoney.network"],
    "noble": ["https://noble-api.polkachu.com"],
    "stride": ["https://stride-api.polkachu.com"],
    "dydx": ["https://dydx-rest.publicnode.com"],
    "celestia": ["https://celestia-rest.publicnode.com"],
    "babylon": ["https://babylon-api.polkachu.com"],
    "axelar": ["https://axelar-lcd.quickapi.com"],
    "saga": ["https://saga-api.polkachu.com"],
    "xion": ["https://xion-api.polkachu.com"],
    "cosmoshub": ["https://cosmos-rest.publicnode.com"],
    "akash": ["https://akash-rest.publicnode.com"],
    "sommelier": ["https://sommelier-api.polkachu.com"],
    "pundix": ["https://pundix-api.polkachu.com"],
}


def get(url, timeout=9):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "replace")


def get_json(url, timeout=9):
    try:
        return json.loads(get(url, timeout))
    except Exception as e:
        return {"_error": str(e)}


def pick(base, path):
    for b in base:
        d = get_json(b.rstrip("/") + path)
        if "_error" not in d:
            return b, d
    return None, {"_error": "all endpoints failed"}


def probe(name, bases):
    rec = {}
    b, ni = pick(bases, "/cosmos/base/tendermint/v1beta1/node_info")
    if "_error" not in ni:
        av = ni.get("application_version", {}) or {}
        rec["lcd"] = b
        rec["app_version"] = av.get("version")
        gv = av.get("go_version") or ""
        m = re.search(r"(go1\.\d+(?:\.\d+)?)", gv)
        rec["go_version"] = m.group(1) if m else gv
        wasm = {}
        for d in av.get("build_deps", []):
            p = d.get("path", "")
            if "wasm" in p.lower() or p == "github.com/cosmos/cosmos-sdk" or "ibc-go" in p:
                wasm[p] = d.get("version")
        rec["wasm_deps"] = wasm
        deps = {d.get("path"): d.get("version") for d in av.get("build_deps", [])}
        rec["wasmd"] = next((v for k, v in deps.items() if k.startswith("github.com/CosmWasm/wasmd")), None)
        rec["wasmvm"] = next((v for k, v in deps.items() if k.startswith("github.com/CosmWasm/wasmvm")), None)
        rec["cosmos_sdk"] = deps.get("github.com/cosmos/cosmos-sdk")
        rec["ibc_go"] = next((v for k, v in deps.items() if k.startswith("github.com/cosmos/ibc-go")), None)
        rec["deps_n"] = len(deps)
    else:
        rec["node_info_error"] = ni.get("_error")
    _, wp = pick(bases, "/cosmwasm/wasm/v1/codes/params")
    if "_error" not in wp:
        rec["code_upload_access"] = (wp.get("params") or {}).get("code_upload_access")
        rec["instantiate_default_permission"] = (wp.get("params") or {}).get("instantiate_default_permission")
    else:
        rec["wasm_params_error"] = wp.get("_error")
    _, cp = pick(bases, "/cosmwasm/wasm/v1/codes?pagination.limit=1&pagination.count_total=true")
    if "_error" not in cp:
        rec["codes_total"] = (cp.get("pagination") or {}).get("total")
    _, vp = pick(bases, "/cosmos/staking/v1beta1/validators?status=BOND_STATUS_BONDED&pagination.limit=1&pagination.count_total=true")
    if "_error" not in vp:
        rec["bonded_validators"] = (vp.get("pagination") or {}).get("total")
    _, bp = pick(bases, "/cosmos/base/tendermint/v1beta1/blocks/latest")
    if "_error" not in bp:
        hdr = ((bp.get("block") or {}).get("header") or {})
        rec["latest_height"] = hdr.get("height")
        rec["latest_time"] = hdr.get("time")
        rec["chain_id_live"] = hdr.get("chain_id")
    return name, rec


def main():
    # Build the probe list: registry.json (all enumerated candidates) + curated LCD fallbacks.
    probes = {}
    regp = os.path.join(OUT, "registry.json")
    if os.path.exists(regp):
        try:
            reg = json.load(open(regp))
            for n, rec in reg.items():
                if rec.get("_not_found"):
                    continue
                probes[n] = list(rec.get("rest") or [])
        except Exception:
            pass
    for n, bases in LCD.items():
        probes.setdefault(n, [])
        for b in bases:
            if b not in probes[n]:
                probes[n].append(b)
    items = [(n, b) for n, b in probes.items() if b]
    results = {}
    from concurrent.futures import ThreadPoolExecutor, as_completed
    with ThreadPoolExecutor(max_workers=16) as ex:
        futs = {ex.submit(probe, n, b): n for n, b in items}
        for f in as_completed(futs):
            try:
                name, rec = f.result()
            except Exception as e:
                name, rec = futs[f], {"_error": str(e)}
            results[name] = rec
            print(f"[D] {name}: app={rec.get('app_version')} wasmvm={rec.get('wasmvm')} wasmd={rec.get('wasmd')} sdk={rec.get('cosmos_sdk')} go={rec.get('go_version')} upload={rec.get('code_upload_access')} inst={rec.get('instantiate_default_permission')} vals={rec.get('bonded_validators')} h={rec.get('latest_height')}")
    json.dump(results, open(os.path.join(OUT, "live.json"), "w"), indent=1)
    print(f"\nwrote live.json ({len(results)})")


if __name__ == "__main__":
    main()
