#!/usr/bin/env python3
"""Loopscale Curation recon — read-only Solana RPC. Keyless public endpoint only.
Program: sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD (Exponent strategy vaults)
Curator: bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN (Loopscale Asset Curation)
"""
import json, sys, base64, urllib.request

RPC = "https://api.mainnet-beta.solana.com"
PROGRAM = "sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD"
CURATOR = "bs1PuRvB9rBBZkryBjADYvxc2qYh51EVW2fsb1uTiBN"
STRATEGY_VAULT_DISC = bytes([98, 228, 39, 201, 116, 210, 39, 11])

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "research"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

def b58encode(b):
    # minimal base58
    alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    n = int.from_bytes(b, "big")
    out = ""
    while n > 0:
        n, rem = divmod(n, 58)
        out = alphabet[rem] + out
    pad = 0
    for c in b:
        if c == 0:
            pad += 1
        else:
            break
    return "1" * pad + out

if __name__ == "__main__":
    out = {}
    acct = rpc("getAccountInfo", [PROGRAM, {"encoding": "base64"}])
    v = acct.get("result", {}).get("value")
    out["program_account"] = {
        "executable": v.get("executable"),
        "owner": v.get("owner"),
        "lamports": v.get("lamports"),
        "data_len": len(base64.b64decode(v["data"][0])) if v and v.get("data") else 0,
    }
    print(json.dumps(out["program_account"], indent=2))
    # vault accounts filtered by discriminator
    accs = rpc("getProgramAccounts", [PROGRAM, {
        "encoding": "base64",
        "filters": [{"memcmp": {"offset": 0, "bytes": b58encode(STRATEGY_VAULT_DISC)}}],
    }])
    res = accs.get("result", [])
    print("strategy vault accounts:", len(res))
    out["vault_count_all_curators"] = len(res)
    # keep raw sizes
    out["vault_sizes"] = sorted({len(base64.b64decode(a["account"]["data"][0])) for a in res})
    print("sizes:", out["vault_sizes"])
    with open("/home/heisenberg/CA/loopscale/analysis/vault_accounts_raw.json", "w") as f:
        json.dump(res, f)
