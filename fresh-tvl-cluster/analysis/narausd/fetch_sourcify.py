#!/usr/bin/env python3
"""Fetch verified sources from Sourcify v2 (Etherscan V2 key expired 2026-10-16).
Saves: <out>/<tag>.json (metadata incl. sources), <out>/<tag>_src/<file> (flattened).
Resolves EIP-1967/beacon proxies one level and fetches implementation too.
Read-only; no keys used. Usage: fetch_sourcify.py <outdir> <chainId> tag=addr [tag=addr ...]
"""
import json, sys, os, urllib.request, urllib.parse

BASE = "https://sourcify.dev/server/v2/contract"

def get(chain, addr, fields="proxyResolution,compilation,sources,abi"):
    url = f"{BASE}/{chain}/{addr}?fields={urllib.parse.quote(fields)}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research read-only"})
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.load(r)

def save(outdir, tag, chain, addr, depth=0):
    try:
        d = get(chain, addr)
    except Exception as e:
        print(f"{tag} {addr}: FETCH-ERR {e}")
        return None
    d["_address"] = addr
    with open(os.path.join(outdir, f"{tag}.json"), "w") as f:
        json.dump(d, f, indent=1)
    src = d.get("sources", {})
    if src:
        sdir = os.path.join(outdir, f"{tag}_src")
        os.makedirs(sdir, exist_ok=True)
        for path, body in src.items():
            rel = path.replace("../", "_up_/").lstrip("/")
            fp = os.path.join(sdir, rel)
            os.makedirs(os.path.dirname(fp), exist_ok=True)
            with open(fp, "w") as f:
                f.write(body.get("content", "") if isinstance(body, dict) else str(body))
    comp = d.get("compilation", {})
    pr = d.get("proxyResolution", {})
    print(f"{tag} {addr}: match={d.get('match')} name={comp.get('name')} solc={comp.get('compilerVersion')} "
          f"srcs={len(src)} proxy={pr.get('isProxy')} impls={[i.get('address') for i in pr.get('implementations', [])]}")
    if pr.get("isProxy") and depth == 0:
        for i, impl in enumerate(pr.get("implementations", [])):
            ia = impl.get("address")
            if ia:
                save(outdir, f"{tag}_impl{i}", chain, ia, depth + 1)
    return d

if __name__ == "__main__":
    outdir, chain = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    for pair in sys.argv[3:]:
        tag, addr = pair.split("=")
        save(outdir, tag, chain, addr)
