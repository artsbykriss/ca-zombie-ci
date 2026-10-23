#!/usr/bin/env python3
"""BulbaSwap V3 pool scan (read-only).
Reads token0/token1/fee/liquidity/slot0 + ERC20 balanceOf(pool) for every pool
created by the factory, at a pinned block. Keyless public RPC only.
Outputs analysis/pools_state.json
"""
import json, subprocess, sys, time

RPC = "https://rpc.morphl2.io"
FACTORY = "0xff8578c2949148a6f19b7958ae86caab2779cddd"
BLOCK = int(sys.argv[1]) if len(sys.argv) > 1 else None

def rpc(method, params):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    for attempt in range(5):
        try:
            out = subprocess.run(
                ["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
                 "--data", payload, RPC],
                capture_output=True, text=True, timeout=60).stdout
            j = json.loads(out)
            if "result" in j:
                return j["result"]
            if "error" in j:
                raise RuntimeError(j["error"])
        except Exception as e:
            if attempt == 4:
                raise
            time.sleep(1.5 * (attempt + 1))

def batch(calls):
    """calls: list of (to, data) -> list of results in order"""
    out = []
    for i in range(0, len(calls), 40):
        chunk = calls[i:i+40]
        payload = json.dumps([{"jsonrpc": "2.0", "id": k, "method": "eth_call",
                               "params": [{"to": c[0], "data": c[1]}, BLOCK_TAG]}
                              for k, c in enumerate(chunk)])
        for attempt in range(5):
            try:
                raw = subprocess.run(
                    ["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
                     "--data", payload, RPC],
                    capture_output=True, text=True, timeout=90).stdout
                j = json.loads(raw)
                if isinstance(j, list):
                    j.sort(key=lambda x: x["id"])
                    out.extend([x.get("result", "0x") for x in j])
                    break
            except Exception:
                pass
            if attempt == 4:
                out.extend(["0x"] * len(chunk))
            time.sleep(1.5 * (attempt + 1))
    return out

def enc_addr(a):
    return "0x70a08231" + "0" * 24 + a[2:].lower()  # balanceOf(address)

def dec_uint(h):
    return int(h, 16) if h and h != "0x" else 0

def dec_words(h):
    b = h[2:] if h.startswith("0x") else h
    return [b[i:i+64] for i in range(0, len(b), 64)]

pools = json.load(open("pools.json"))
pools.sort(key=lambda p: p["block"])

if BLOCK is None:
    BLOCK = int(rpc("eth_blockNumber", []), 16)
BLOCK_TAG = hex(BLOCK)
print(f"block {BLOCK}, {len(pools)} pools", flush=True)

# 1. static pool state: token0, token1, fee, liquidity, slot0
static_calls = []
for p in pools:
    a = p["pool"]
    static_calls += [
        (a, "0x0dfe1681"),  # token0()
        (a, "0xd21220a7"),  # token1()
        (a, "0xddca3f43"),  # fee()
        (a, "0x1a686502"),  # liquidity()
        (a, "0x3850c7bd"),  # slot0()
        (a, "0x70cf754a"),  # maxLiquidityPerTick()
    ]
res = batch(static_calls)
for i, p in enumerate(pools):
    o = i * 6
    p["token0"] = "0x" + res[o][-40:]
    p["token1"] = "0x" + res[o+1][-40:]
    p["fee_onchain"] = dec_uint(res[o+2])
    p["liquidity"] = str(dec_uint(res[o+3]))
    w = dec_words(res[o+4])
    p["slot0"] = {
        "sqrtPriceX96": str(dec_uint("0x" + w[0])) if w else "0",
        "tick": int(w[1], 16) if len(w) > 1 else 0,
        "observationIndex": int(w[2], 16) if len(w) > 2 else 0,
        "observationCardinality": int(w[3], 16) if len(w) > 3 else 0,
        "observationCardinalityNext": int(w[4], 16) if len(w) > 4 else 0,
        "feeProtocol": int(w[5], 16) if len(w) > 5 else 0,
        "unlocked": int(w[6], 16) if len(w) > 6 else 0,
    }
    p["maxLiquidityPerTick"] = str(dec_uint(res[o+5]))
    print(f"  {p['pool']} fee={p['fee_onchain']} liq={p['liquidity']} cardNext={p['slot0']['observationCardinalityNext']} unlocked={p['slot0']['unlocked']}", flush=True)

# 2. balances of token0/token1 held by each pool
bal_calls = []
for p in pools:
    bal_calls += [(p["token0"], enc_addr(p["pool"])), (p["token1"], enc_addr(p["pool"]))]
res = batch(bal_calls)
for i, p in enumerate(pools):
    p["bal0"] = str(dec_uint(res[2*i]))
    p["bal1"] = str(dec_uint(res[2*i+1]))

json.dump(pools, open("pools_state.json", "w"), indent=1)
print("wrote pools_state.json")

tokens = sorted({p["token0"] for p in pools} | {p["token1"] for p in pools})
print(f"{len(tokens)} unique tokens")
json.dump(tokens, open("tokens.json", "w"), indent=1)
