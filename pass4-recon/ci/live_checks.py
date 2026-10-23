#!/usr/bin/env python3
"""pass4-recon — re-read the OPEN-list funds at public RPCs (read-only).
No keys. Writes ci-out/live_checks.json."""
import json, os, urllib.request, socket

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)
socket.setdefaulttimeout(20)

RPCS = {
    "monad": "https://rpc.monad.xyz",
    "base": "https://base-rpc.publicnode.com",
    "sonic": "https://rpc.soniclabs.com",
    "world": "https://worldchain-mainnet.g.alchemy.com/public",
    "mantle": "https://rpc.mantle.xyz",
}

def rpc(url, method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json",
                                                          "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as r:
        return json.load(r).get("result")

def code_len(url, addr):
    c = rpc(url, "eth_getCode", [addr, "latest"]) or "0x"
    return (len(c) - 2) // 2

def call(url, to, data):
    return rpc(url, "eth_call", [{"to": to, "data": data}, "latest"])

def blk(url):
    r = rpc(url, "eth_blockNumber", [])
    return int(r, 16) if r else None

res = {"note": "read-only public-RPC re-reads; no keys", "targets": {}}

# shMonad totalAssets()
try:
    u = RPCS["monad"]; a = "0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c"
    ta = call(u, a, "0x01e1d114")  # totalAssets()
    res["targets"]["shMonad"] = {"chain": "monad", "address": a, "block": blk(u),
                                 "code_bytes": code_len(u, a),
                                 "totalAssets_wei": int(ta, 16) if ta and ta != "0x" else None}
except Exception as e:
    res["targets"]["shMonad"] = {"error": str(e)}

# Kipseli Base reserve
try:
    u = RPCS["base"]; a = "0xbee3211ab312a8d065c4fef0247448e17a8da000"
    usdc = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
    bal = call(u, usdc, "0x70a08231" + "0" * 24 + a[2:])
    res["targets"]["kipseli_base"] = {"chain": "base", "address": a, "block": blk(u),
                                      "code_bytes": code_len(u, a),
                                      "usdc_raw": int(bal, 16) if bal and bal != "0x" else None}
except Exception as e:
    res["targets"]["kipseli_base"] = {"error": str(e)}

# Metropolis factory
try:
    u = RPCS["sonic"]; a = "0x197d40B36677248E82939f96930bf4E7Fe8aD1c2"
    res["targets"]["metropolis_factory"] = {"chain": "sonic", "address": a, "block": blk(u),
                                            "code_bytes": code_len(u, a)}
except Exception as e:
    res["targets"]["metropolis_factory"] = {"error": str(e)}

# World chain AgentBank/Morpho vault totalAssets()
try:
    u = RPCS["world"]; a = "0x5C6F9354b6176C14f7dF1C1e16a0DC4A0Ff9c3E1"
    ta = call(u, a, "0x01e1d114")
    res["targets"]["world_vault"] = {"chain": "world", "address": a, "block": blk(u),
                                     "code_bytes": code_len(u, a),
                                     "totalAssets": int(ta, 16) if ta and ta != "0x" else None}
except Exception as e:
    res["targets"]["world_vault"] = {"error": str(e)}

# CIAN vaults (README-CLOSED, but confirm live)
try:
    u = RPCS["mantle"]
    out = {}
    for name, a in [("usdc", "0x6B2BA8F249cC1376f2A02A9FaF8BEcA5D7718DCf"),
                    ("usdt0", "0x74D2Bef5Afe200DaCC76FE2D3C4022435b54CdbB")]:
        ta = call(u, a, "0x01e1d114")
        out[name] = {"address": a, "totalAssets": int(ta, 16) if ta and ta != "0x" else None}
    res["targets"]["cian"] = {"chain": "mantle", "block": blk(u), "vaults": out}
except Exception as e:
    res["targets"]["cian"] = {"error": str(e)}

# Cabal — DefiLlama only (non-EVM)
try:
    req = urllib.request.Request("https://api.llama.fi/protocol/cabal",
                                 headers={"User-Agent": "Mozilla/5.0"})
    d = json.load(urllib.request.urlopen(req))
    res["targets"]["cabal"] = {"chain": "initia(non-EVM)", "currentChainTvls": d.get("currentChainTvls")}
except Exception as e:
    res["targets"]["cabal"] = {"error": str(e)}

json.dump(res, open(os.path.join(OUT, "live_checks.json"), "w"), indent=2)
print(json.dumps(res, indent=2))
