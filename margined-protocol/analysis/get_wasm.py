#!/usr/bin/env python3
"""Download CosmWasm code binaries for Margined contracts (public chain data)."""
import json, base64, urllib.request, urllib.error, sys, os

UA = {"User-Agent": "Mozilla/5.0 (research)"}
ENDPOINTS = {
    "osmosis": ["https://osmosis-api.polkachu.com", "https://osmosis-rest.publicnode.com"],
    "neutron": ["https://lcd-neutron.keplr.app", "https://neutron-api.polkachu.com"],
}
CODES = {
    "osmosis": [1457, 1049, 1295, 1887],
    "neutron": [5221, 1825, 3387, 3383, 3385],
}
OUT = "/home/heisenberg/CA/margined-protocol/analysis/wasm"

def http_get(url, timeout=60):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def main():
    os.makedirs(OUT, exist_ok=True)
    for chain, ids in CODES.items():
        for cid in ids:
            fn = f"{OUT}/{chain}-{cid}.wasm"
            if os.path.exists(fn) and os.path.getsize(fn) > 1000:
                print(f"skip {fn}", file=sys.stderr); continue
            for base in ENDPOINTS[chain]:
                try:
                    d = http_get(f"{base}/cosmwasm/wasm/v1/code/{cid}")
                    data = d.get("data")
                    if not data:
                        print(f"no data for {cid}", file=sys.stderr); continue
                    wasm = base64.b64decode(data)
                    open(fn, "wb").write(wasm)
                    print(f"{chain} {cid}: {len(wasm)} bytes -> {fn}", file=sys.stderr)
                    break
                except Exception as e:
                    print(f"{chain} {cid} @ {base}: {e}", file=sys.stderr)
    # also store code hashes
    meta = {}
    for chain, ids in CODES.items():
        for cid in ids:
            for base in ENDPOINTS[chain]:
                try:
                    d = http_get(f"{base}/cosmwasm/wasm/v1/code/{cid}")
                    meta[f"{chain}-{cid}"] = d.get("code_info")
                    break
                except Exception:
                    pass
    json.dump(meta, open(f"{OUT}/code-meta.json", "w"), indent=1)
    print("done")

if __name__ == "__main__":
    main()
