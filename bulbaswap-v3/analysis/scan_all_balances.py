#!/usr/bin/env python3
"""Exhaustive ERC20 balance sweep over EVERY contract deployed by the BulbaSwap
deployer (0x502dc547...), for every token that appears in a BulbaSwap V3 pool
plus WETH. Read-only, keyless RPC. Any nonzero balance is a potential
sweep/drain target; zero everywhere = nothing to extract from periphery."""
import json, subprocess, sys, time

RPC = "https://rpc.morphl2.io"
OUT = sys.argv[1] if len(sys.argv) > 1 else "all_contract_balances.json"
WETH = "0x5300000000000000000000000000000000000011"

CONTRACTS = {
    "V2Factory": "0x8d2a8b8f7d200d75bf5f9e84e01f9272f90efb8b",
    "V2Router02": "0x81606e6f8aad6c75c2f383ea595c2b9f8ce8ae3a",
    "V3Factory_a": "0xd7fc34345ec9dd48dd635ad02f5b960fd2cb08a7",
    "V3Factory_b": "0x7cb2b4552f00da7ae5e1932d3f710a9651ee13ec",
    "V3Factory_c": "0x530b746f2943d7fbbfa2f4b991094acb86766fba",
    "QubeMulticall_a": "0x0cede1cd794f94aa6a5364a9897461e89b62842b",
    "ProxyAdmin_a": "0xc6650253e9b0de7acf69abbba903665b1b576d4b",
    "TickLens_a": "0xa8976a72426e4bf28cb2861fb00d5e32786af8fa",
    "NFTDescriptor_a": "0x519cb9ad18e1e5ce19e74ddafceace1e0e8a150e",
    "V3Factory_d": "0xfb0d1c3356a669d0b5986f3e0d4264ae7e02a885",
    "QubeMulticall_b": "0x0429336abcb9ceb8c223583b85a7c45ea56b4d1a",
    "ProxyAdmin_b": "0xaec3b9a9f6c7094a221ed8aa4c5f02c98901a69c",
    "TickLens_b": "0x478a9d6fa038324d7883d5547dee6870ab2dea8f",
    "NFTDescriptor_b": "0xcfbe4e78071e11697ec6639746cd309ceb260473",
    "V3Factory_main": "0xff8578c2949148a6f19b7958ae86caab2779cddd",
    "V3Factory_e": "0x3269e83b20c5c97183a283b13171888011aef07f",
    "QubeMulticall_c": "0xacd82113982479b25e7c1d09858f0130921dbbca",
    "ProxyAdmin_c": "0x7692c1f96103bcf597bddb179975e334afc5d652",
    "TickLens_c": "0xa8da1415a3310d4b3759a683839947e6f8223ee2",
    "NFTDescriptor_c": "0x783a211c5ef452210416358a35570db5c15d4916",
    "NFTPosDescriptor": "0x60dfd4286b408f8510d0ad9da642f63026506afa",
    "DescriptorProxy": "0x4c78d19c7e589cd3a9036c36cca815fbf0fd15e2",
    "NonfungiblePositionManager": "0xc6b60ee77854b7c11c39b6e3f5bcfe1866cbc20a",
    "V3Migrator": "0xe87c01ca304d69a94c4e079275b276be659ee5ef",
    "UniswapV3Staker": "0x192122e28e45923cabdcc40232a278867a432c2b",
    "QuoterV2": "0xc312e6417d07ae7ba73fef0832b1811194a7bbef",
    "SwapRouter02": "0xa7304d322219553d4a85c9ce8eb7462dcaf6453c",
    "Permit2": "0x90a8a8e2abb67d300593c714b687de109b4bce5e",
    "UnsupportedProtocol": "0xdf3494cf1423297f47759f7f851440d6bf7891e6",
    "NOVERIFY_0a5a": "0x0a5a963ffe8118d774bdc07b5c32bd961b4ad5bb",
    "UniversalRouter_a": "0x1741c206b94a7f15103c6f42263231c742182cfa",
    "UniversalRouter_b": "0xc4ac26dc862fa3147a324ed8766eb5f862ba6841",
    "UniversalRouter_c": "0x913d6c77f0648b6c8ab856040d189427c7ed9f06",
    "UniversalRouter_d": "0xb789922d715475f419b7cb47b6155bf7a2acecd6",
    "PointsRedemption_proxy": "0xdbd064f9e41db9f08cb9f481c72a2eeb29afc9a4",
    "PointsRedemption_impl": "0x8b4e589d7f345c5620454aa780a41604e5ea1740",
}

def batch(calls):
    out = []
    for i in range(0, len(calls), 40):
        chunk = calls[i:i+40]
        payload = json.dumps([{"jsonrpc": "2.0", "id": k, "method": "eth_call",
                               "params": [{"to": c[0], "data": c[1]}, "latest"]} for k, c in enumerate(chunk)])
        for a in range(5):
            try:
                j = json.loads(subprocess.run(["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
                                               "--data", payload, RPC], capture_output=True, text=True, timeout=90).stdout)
                if isinstance(j, list):
                    j.sort(key=lambda x: x["id"])
                    out.extend([x.get("result", "0x") for x in j]); break
            except Exception:
                pass
            time.sleep(1.5*(a+1))
        else:
            out.extend(["0x"]*len(chunk))
    return out

def u(h):
    return int(h, 16) if h and h != "0x" else 0

tokens = sorted(set(json.load(open("tokens.json"))) | {WETH})
meta = json.load(open("token_meta.json"))
prices = json.load(open("prices.json"))

calls = []
for name, a in CONTRACTS.items():
    for t in tokens:
        calls.append((t, "0x70a08231" + "0"*24 + a[2:].lower()))
res = batch(calls)

k = 0
hits = []
for name, a in CONTRACTS.items():
    for t in tokens:
        v = u(res[k]); k += 1
        if v > 0:
            dec = meta.get(t, {}).get("decimals", 18); pr = prices.get(t.lower(), {}).get("price")
            amt = v/10**dec if dec else 0
            hits.append({"contract": name, "address": a, "token": t,
                         "symbol": meta.get(t, {}).get("symbol"), "amount": amt,
                         "price": pr, "usd": (amt*pr if pr else None)})
json.dump({"contracts": CONTRACTS, "tokens": len(tokens), "hits": hits}, open(OUT, "w"), indent=1)
print(f"scanned {len(CONTRACTS)} contracts x {len(tokens)} tokens; nonzero balances: {len(hits)}")
for h in hits:
    print(f"  {h['contract']} {h['address']} {h['symbol']} {h['amount']:.6f} usd={h['usd']}")
