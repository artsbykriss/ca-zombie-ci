#!/usr/bin/env python3
"""Fetch verified sources for all Horizon Protocol contracts from BSCScan V2.
Requires ETHERSCANV2_API_KEY env. Saves to sources/<addr>-<name>.sol and abis/.
No secrets written."""
import json, os, time, urllib.request, urllib.parse

KEY = os.environ["ETHERSCANV2_API_KEY"]
OUT = "sources"
os.makedirs(OUT, exist_ok=True)
os.makedirs("abis", exist_ok=True)

res = json.load(open("resolver-enum.json"))
addrs = sorted(set(list(res.values()) + [
    "0xc0eff7749b125444953ef89682201fb8c6a917cd",  # HZN proxy
    "0x0409633a72d846fc5bbe2f98d88564d35987904d",  # PHB
    "0xa1771dcfb7822c8853d7e64b86e58f7f1eb5e33e",
    "0x67d5a94f444df4bba254645065a4137fc665bf98",
    "0x84838d0ab37857fad5979fcf6bddf8ddb1cc1da8",
    "0x5646aa2f9408c7c2ee1dc7db813c8b687a959a85",
    "0xdc9a574b9b341d4a98ce29005b614e1e27430e74",  # LP
    "0xc3bf4e0ea6b76c8edd838e14be2116c862c88bdf",  # LP
]))

def fetch(a):
    url = ("https://api.etherscan.io/v2/api?chainid=56&module=contract&action=getsourcecode"
           f"&address={a}&apikey={KEY}")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        d = json.loads(r.read())
    if d.get("status") != "1":
        return {"addr": a, "error": d.get("result")}
    x = d["result"][0]
    name = (x.get("ContractName") or "Unknown").replace("/", "_")
    src = x.get("SourceCode") or ""
    abi = x.get("ABI") or "[]"
    if src:
        with open(f"{OUT}/{a}-{name}.sol", "w") as f:
            f.write(src)
    if abi and abi != "Contract source code not verified":
        with open(f"abis/{a}-{name}.json", "w") as f:
            f.write(abi)
    return {"addr": a, "name": name, "src_len": len(src), "proxy": x.get("Proxy"),
            "impl": x.get("Implementation"), "compiler": x.get("CompilerVersion")}

out = []
for a in addrs:
    try:
        r = fetch(a)
    except Exception as e:
        r = {"addr": a, "error": str(e)}
    out.append(r)
    print(json.dumps(r), flush=True)
    time.sleep(0.4)
json.dump(out, open("sources-index.json", "w"), indent=1)
print("done", len(out))
