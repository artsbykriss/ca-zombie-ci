#!/usr/bin/env python3
"""Fetch verified sources from Etherscan V2 (multichain) and split standard-json bundles.
Keyless-independent: reads ETHERSCANV2_API_KEY from env; never writes the key.
Usage: es_sources.py <chainid> <address> <outdir> [label]
"""
import json, os, sys, urllib.request, re, time

CHAIN, ADDR, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
LABEL = sys.argv[4] if len(sys.argv) > 4 else ADDR[:10]
KEY = os.environ["ETHERSCANV2_API_KEY"]
os.makedirs(OUT, exist_ok=True)
url = f"https://api.etherscan.io/v2/api?chainid={CHAIN}&module=contract&action=getsourcecode&address={ADDR}&apikey={KEY}"
r = json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "zh4"}), timeout=90))
res = r["result"][0]
meta = {k: v for k, v in res.items() if k != "SourceCode"}
src = res["SourceCode"]
json.dump(meta, open(f"{OUT}/{LABEL}.meta.json", "w"), indent=1)
print(json.dumps(meta, indent=1)[:1500])
if src.startswith("{{"):
    bundle = json.loads(src[1:-1])
    for path, content in bundle["sources"].items():
        p = os.path.join(OUT, path.replace("../", "_").lstrip("/"))
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, "w").write(content["content"])
    print("files:", len(bundle["sources"]))
    json.dump(bundle.get("settings", {}), open(f"{OUT}/{LABEL}.settings.json", "w"), indent=1)
elif src.startswith("{"):
    print("raw json (not standard bundle), len", len(src))
    open(f"{OUT}/{LABEL}.raw.json", "w").write(src)
else:
    open(f"{OUT}/{LABEL}.sol", "w").write(src)
    print("single file len", len(src))
