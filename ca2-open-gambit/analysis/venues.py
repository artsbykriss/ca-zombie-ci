#!/usr/bin/env python3
"""Enumerate every plausible USDG DEX venue on BSC at a pinned block.

Read-only eth_call. No keys. Output: analysis/venues.json
"""
import json, os, urllib.request

RPC = os.environ.get("BSC_RPC_URL", "https://bsc-rpc.publicnode.com")
BLOCK = int(os.environ.get("PIN_BLOCK", "131443197"))
USDG = "0x85E76cbf4893c1fbcB34dCF1239A91CE2A4CF5a7"
HERE = os.path.dirname(os.path.abspath(__file__))

COUNTER = {
    "WBNB": "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
    "USDT": "0x55d398326f99059fF775485246999027B3197955",
    "USDC": "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",
    "BUSD": "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56",
    "CAKE": "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82",
    "ETH":  "0x2170Ed0880ac9A755fd29B2688956BD959F933F8",
    "BTCB": "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c",
    "FDUSD":"0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409",
}
V2 = {
    "PancakeV2": "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73",
    "BiswapV2": "0x858E3312ed3A876947EA49d572A7C42DE08af7EE",
    "ApeSwapV2": "0x0841BD0B734E4F5853f0dD8d7Ea041c241fb0Da6",
    "BakeryV2": "0x01bF7C66c6BD861915CdaaE475042d3c4BaE16A7",
    "ThenaV2": "0xAFD89d21BdB66d00817d4153E055830B1c2B3970",
    "UniswapV2BSC": "0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6",
}
V3 = {
    "PancakeV3": "0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865",
    "UniswapV3BSC": "0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7",
}
FEES = [100, 500, 2500, 10000]


def call(to, data):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": to, "data": data}, hex(BLOCK)]}).encode()
    req = urllib.request.Request(RPC, body, {"Content-Type": "application/json", "User-Agent": "ca/1.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        d = json.load(r)
    if "error" in d:
        return None
    return d["result"]


def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def enc_u24(n):
    return hex(n)[2:].rjust(64, "0")


def dec_addr(r):
    if not r or r == "0x":
        return None
    return "0x" + r[-40:]


res = {"block": BLOCK, "usdg": USDG, "v2": {}, "v3": {}, "pairs_found": []}
for name, fac in V2.items():
    for sym, tok in COUNTER.items():
        data = "0xe6a43905" + enc_addr(USDG) + enc_addr(tok)  # getPair(address,address)
        r = call(fac, data)
        p = dec_addr(r)
        res["v2"][f"{name}:{sym}"] = p
        if p and int(p, 16) != 0:
            res["pairs_found"].append({"factory": name, "kind": "v2", "counter": sym, "pair": p})

for name, fac in V3.items():
    for sym, tok in COUNTER.items():
        for fee in FEES:
            data = "0x1698ee82" + enc_addr(USDG) + enc_addr(tok) + enc_u24(fee)  # getPool(address,address,uint24)
            r = call(fac, data)
            p = dec_addr(r)
            res["v3"][f"{name}:{sym}:{fee}"] = p
            if p and int(p, 16) != 0:
                res["pairs_found"].append({"factory": name, "kind": "v3", "fee": fee, "counter": sym, "pool": p})

# Algebra / Thena V3 poolByPair(address,address)
for name, fac in {"ThenaV3Algebra": "0x306F06C147f064A010530292A1EB6737c3e378e4"}.items():
    for sym, tok in COUNTER.items():
        data = "0xd9a641e1" + enc_addr(USDG) + enc_addr(tok)  # poolByPair(address,address)
        r = call(fac, data)
        p = dec_addr(r)
        res.setdefault("algebra", {})[f"{name}:{sym}"] = p
        if p and int(p, 16) != 0:
            res["pairs_found"].append({"factory": name, "kind": "algebra", "counter": sym, "pool": p})

json.dump(res, open(os.path.join(HERE, "venues.json"), "w"), indent=1)
print(f"pairs found: {len(res['pairs_found'])}")
for p in res["pairs_found"]:
    print(p)
print("v2 non-zero:", {k: v for k, v in res["v2"].items() if v and int(v, 16) != 0})
print("v3 non-zero:", {k: v for k, v in res["v3"].items() if v and int(v, 16) != 0})
