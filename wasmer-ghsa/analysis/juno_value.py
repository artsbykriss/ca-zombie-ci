#!/usr/bin/env python3
"""Juno contract-held value measurement — read-only public LCD GETs.

Reproduces (or refutes) the CA2 figure of 14,417,519.86 JUNO held by CosmWasm contracts on
juno-1. Method: enumerate every holder of ujuno via /cosmos/bank/v1beta1/denom_owners/ujuno,
keep 32-byte (63-char bech32) addresses = CosmWasm contract addresses, verify a sample against
/cosmwasm/wasm/v1/contract/{addr}, sum their ujuno, then page each contract's full balance list
to report all denoms held by contracts.

No keys, no writes, no transactions. Output: JSON on stdout (and file given by --out).
"""
import argparse
import concurrent.futures as cf
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

UA = "Mozilla/5.0 (research; read-only)"
ENDPOINTS = [
    "https://juno-rest.publicnode.com",
    "https://rest.cosmos.directory/juno",
]


def get(base, path, tries=5, timeout=30):
    url = base + path
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode())
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"GET failed after {tries}: {url}: {last}")


def pick_endpoint():
    for b in ENDPOINTS:
        try:
            d = get(b, "/cosmos/base/tendermint/v1beta1/node_info", tries=2)
            net = (d.get("node_info") or d.get("default_node_info") or {}).get("network")
            if net == "juno-1":
                return b, d
        except Exception as e:  # noqa: BLE001
            print(f"[juno] endpoint {b} unavailable: {e}", file=sys.stderr)
    raise SystemExit("no working juno endpoint")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="ci-out/juno-contract-value.json")
    ap.add_argument("--max-pages", type=int, default=2000)
    ap.add_argument("--workers", type=int, default=8)
    a = ap.parse_args()

    base, node_info = pick_endpoint()
    ni = node_info.get("node_info") or node_info.get("default_node_info") or {}
    av = node_info.get("application_version") or {}
    deps = {d["path"]: d["version"] for d in av.get("build_deps", []) if "wasm" in d["path"].lower()}

    params = get(base, "/cosmwasm/wasm/v1/codes/params")
    height = int(get(base, "/cosmos/base/tendermint/v1beta1/blocks/latest")["block"]["header"]["height"])

    # ---- enumerate ujuno holders ----
    owners = []
    key = None
    pages = 0
    total_expected = None
    while pages < a.max_pages:
        q = "/cosmos/bank/v1beta1/denom_owners/ujuno?pagination.limit=1000"
        if key:
            q += "&pagination.key=" + urllib.parse.quote(key)
        d = get(base, q)
        batch = d.get("denom_owners", [])
        owners.extend(batch)
        pg = d.get("pagination") or {}
        if total_expected is None:
            total_expected = int(pg.get("total") or 0)
        pages += 1
        key = pg.get("next_key")
        if not key:
            break
        if pages % 50 == 0:
            print(f"[juno] pages={pages} owners={len(owners)}", file=sys.stderr)

    contracts = [o["address"] for o in owners if len(o["address"]) == 63]
    ujuno_by_contract = {o["address"]: int(o["balance"]["amount"]) for o in owners if len(o["address"]) == 63}
    ujuno_total = sum(ujuno_by_contract.values())

    # ---- verify that 63-char addresses really are contracts ----
    sample = contracts[:5] + contracts[len(contracts) // 2: len(contracts) // 2 + 3] + contracts[-3:]
    verified = []
    for addr in sample:
        try:
            ci = get(base, f"/cosmwasm/wasm/v1/contract/{addr}", tries=3)
            verified.append({
                "address": addr,
                "is_contract": True,
                "label": (ci.get("contract_info") or {}).get("label"),
                "code_id": (ci.get("contract_info") or {}).get("code_id"),
            })
        except Exception as e:  # noqa: BLE001
            verified.append({"address": addr, "is_contract": False, "error": str(e)[:200]})
    # negative control: a normal account must NOT resolve as a contract
    acct = next((o["address"] for o in owners if len(o["address"]) != 63), None)
    if acct:
        try:
            get(base, f"/cosmwasm/wasm/v1/contract/{acct}", tries=1)
            verified.append({"address": acct, "is_contract": True, "control": "ACCOUNT_RESOLVED_AS_CONTRACT"})
        except Exception:  # noqa: BLE001
            verified.append({"address": acct, "is_contract": False, "control": "account correctly rejected"})

    # ---- full balance lists for contracts (all denoms) ----
    denom_amount = {}
    denom_contracts = {}
    per_contract = {}

    def balances(addr):
        items, k = [], None
        for _ in range(20):
            q = f"/cosmos/bank/v1beta1/balances/{addr}?pagination.limit=1000"
            if k:
                q += "&pagination.key=" + urllib.parse.quote(k)
            d = get(base, q)
            items.extend(d.get("balances", []))
            k = (d.get("pagination") or {}).get("next_key")
            if not k:
                break
        return addr, items

    with cf.ThreadPoolExecutor(max_workers=a.workers) as ex:
        for addr, items in ex.map(balances, contracts):
            per_contract[addr] = items
            denom_amount["ujuno"] = denom_amount.get("ujuno", 0) + ujuno_by_contract.get(addr, 0)
            for it in items:
                dn, am = it["denom"], int(it["amount"])
                denom_amount[dn] = denom_amount.get(dn, 0) + am
                denom_contracts[dn] = denom_contracts.get(dn, 0) + 1

    # ---- price ----
    price, price_src = None, None
    for url, extract in [
        ("https://api.coingecko.com/api/v3/simple/price?ids=juno-network&vs_currencies=usd",
         lambda d: d["juno-network"]["usd"]),
        ("https://coins.llama.fi/prices/current/coingecko:juno-network",
         lambda d: d["coins"]["coingecko:juno-network"]["price"]),
    ]:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=20) as r:
                price = extract(json.loads(r.read().decode()))
                price_src = url.split("/")[2]
                break
        except Exception as e:  # noqa: BLE001
            print(f"[juno] price {url} failed: {e}", file=sys.stderr)

    top = sorted(denom_amount.items(), key=lambda kv: -denom_contracts.get(kv[0], 0))[:40]
    out = {
        "chain": "juno-1",
        "measured_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "endpoint": base,
        "block_height": height,
        "app_version": av.get("version"),
        "git_commit": av.get("git_commit"),
        "go_version": av.get("go_version"),
        "wasm_deps": deps,
        "wasm_params": params.get("params"),
        "holders_total_reported": total_expected,
        "holders_enumerated": len(owners),
        "pages": pages,
        "contract_addresses": len(contracts),
        "contract_ujuno": ujuno_total,
        "contract_juno": ujuno_total / 1e6,
        "juno_price_usd": price,
        "juno_price_source": price_src,
        "contract_usd_juno_only": (ujuno_total / 1e6 * price) if price else None,
        "denoms_held_by_contracts": len(denom_amount),
        "top_denoms": [
            {"denom": d, "amount": amt, "contracts_holding": denom_contracts.get(d, 0)}
            for d, amt in top
        ],
        "sample_verification": verified,
        "top_contracts_by_ujuno": [
            {"address": k, "ujuno": v} for k, v in sorted(ujuno_by_contract.items(), key=lambda kv: -kv[1])[:20]
        ],
    }
    with open(a.out, "w") as f:
        json.dump(out, f, indent=2)
    print(json.dumps({k: out[k] for k in [
        "chain", "block_height", "app_version", "git_commit", "wasm_deps", "wasm_params",
        "holders_total_reported", "holders_enumerated", "pages", "contract_addresses",
        "contract_ujuno", "contract_juno", "juno_price_usd", "juno_price_source",
        "contract_usd_juno_only", "denoms_held_by_contracts"]}, indent=2))
    print(f"[juno] wrote {a.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
