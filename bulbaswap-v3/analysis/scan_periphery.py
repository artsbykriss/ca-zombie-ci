#!/usr/bin/env python3
"""Measure token + native balances held by BulbaSwap V3 periphery contracts.
Read-only, keyless RPC. Any nonzero ERC20/ETH here is sweepable by ANY caller
(canonical UniV3 PeripheryPayments.sweepToken/unwrapWETH9/refundETH are public)."""
import json, subprocess, time

RPC = "https://rpc.morphl2.io"
WETH = "0x5300000000000000000000000000000000000011"

PERIPHERY = {
    "NonfungiblePositionManager": "0xc6b60ee77854b7c11c39b6e3f5bcfe1866cbc20a",
    "SwapRouter02": "0xa7304d322219553d4a85c9ce8eb7462dcaf6453c",
    "V3Migrator": "0xe87c01ca304d69a94c4e079275b276be659ee5ef",
    "UniswapV3Staker": "0x192122e28e45923cabdcc40232a278867a432c2b",
    "QuoterV2": "0xc312e6417d07ae7ba73fef0832b1811194a7bbef",
    "V2Router02": "0x81606e6f8aad6c75c2f383ea595c2b9f8ce8ae3a",
    "V2Factory": "0x8d2a8b8f7d200d75bf5f9e84e01f9272f90efb8b",
    "V3Factory": "0xff8578c2949148a6f19b7958ae86caab2779cddd",
    "UniversalRouter_A": "0x1741c206b94a7f15103c6f42263231c742182cfa",
    "UniversalRouter_B": "0xc4ac26dc862fa3147a324ed8766eb5f862ba6841",
    "UniversalRouter_C": "0x913d6c77f0648b6c8ab856040d189427c7ed9f06",
    "UniversalRouter_D": "0xb789922d715475f419b7cb47b6155bf7a2acecd6",
    "TransparentProxy_4c78": "0x4c78d19c7e589cd3a9036c36cca815fbf0fd15e2",
    "TransparentProxy_dbd0": "0xdbd064f9e41db9f08cb9f481c72a2eeb29afc9a4",
    "ProxyAdmin_c665": "0xc6650253e9b0de7acf69abbba903665b1b576d4b",
    "NFTDescriptor": "0x783a211c5ef452210416358a35570db5c15d4916",
    "NFTPositionDescriptor": "0x60dfd4286b408f8510d0ad9da642f63026506afa",
    "TickLens": "0xa8da1415a3310d4b3759a683839947e6f8223ee2",
    "GnosisSafe_owner": "0x9876097201662D70A63C935c2f7576B35D6f45e7",
    "deployer_EOA": "0x502Dc547576265661A1986c38369A6eb23B17172",
}

pools = json.load(open("pools_state.json"))
tokens = json.load(open("tokens.json"))
meta = json.load(open("token_meta.json"))
prices = json.load(open("prices.json"))
watch = sorted(set(tokens) | {WETH})

def batch(calls):
    out = []
    for i in range(0, len(calls), 40):
        chunk = calls[i:i+40]
        payload = json.dumps([{"jsonrpc": "2.0", "id": k, "method": "eth_call",
                               "params": [{"to": c[0], "data": c[1]}, "latest"]}
                              for k, c in enumerate(chunk)])
        for attempt in range(5):
            try:
                raw = subprocess.run(["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
                                      "--data", payload, RPC], capture_output=True, text=True, timeout=90).stdout
                j = json.loads(raw)
                if isinstance(j, list):
                    j.sort(key=lambda x: x["id"])
                    out.extend([x.get("result", "0x") for x in j])
                    break
            except Exception:
                pass
            time.sleep(1.5*(attempt+1))
    return out

def dec_uint(h):
    return int(h, 16) if h and h != "0x" else 0

def enc_addr(a):
    return "0x70a08231" + "0"*24 + a[2:].lower()

calls = []
for name, a in PERIPHERY.items():
    for t in watch:
        calls.append((t, enc_addr(a)))
res = batch(calls)

def block_number():
    raw = subprocess.run(["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
                          "--data", json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}),
                          RPC], capture_output=True, text=True).stdout
    return int(json.loads(raw)["result"], 16)

BLK = block_number()

# native balances
nat = {}
for name, a in PERIPHERY.items():
    raw = subprocess.run(["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
                          "--data", json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_getBalance",
                                                "params": [a, "latest"]}), RPC], capture_output=True, text=True).stdout
    nat[name] = dec_uint(json.loads(raw)["result"])

k = 0
findings = []
for name, a in PERIPHERY.items():
    hits = []
    for t in watch:
        v = dec_uint(res[k]); k += 1
        if v > 0:
            dec = meta.get(t, {}).get("decimals", 18)
            pr = prices.get(t.lower(), {}).get("price")
            amt = v / 10**dec if dec else 0
            hits.append({"token": t, "symbol": meta.get(t, {}).get("symbol"),
                         "raw": str(v), "amount": amt, "price": pr, "usd": (amt*pr if pr else None)})
    eth = nat[name] / 1e18
    findings.append({"contract": name, "address": a, "eth": eth, "tokens": hits})
    if hits or eth > 0:
        print(f"{name} {a}: ETH={eth:.6f}")
        for h in hits:
            print(f"    {h['symbol']} {h['amount']:.6f}  usd={h['usd']}")

json.dump({"block": BLK, "findings": findings}, open("periphery_balances.json", "w"), indent=1)
print("block", BLK)
