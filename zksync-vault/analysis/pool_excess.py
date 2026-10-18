#!/usr/bin/env python3
"""Per-pool excess scan: pool.getReserves() vs vault.balanceOf(token, pool).

A pool whose vault balance exceeds its own reserve has unattributed tokens that
anyone can capture with pool.mint() (see SyncSwapClassicPool.mint: amount0 =
balance0 - reserve0, liquidity minted against the invariant increase).
Read-only, public RPC only.
"""
import json, time, requests
from eth_abi import encode, decode

V = "0x621425a1Ef6abE91058E9712575dcc4258F8d091"
MC = "0xcA11bde05977b3631167028862bE2a173976CA11"
RPCS = ["https://mainnet.era.zksync.io", "https://zksync.drpc.org", "https://1rpc.io/zksync2-era"]
CHUNK = 180

rpc_i = 0
def rpc(method, params):
    global rpc_i
    last = None
    for _ in range(6):
        try:
            r = requests.post(RPCS[rpc_i % len(RPCS)], json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params}, timeout=90)
            j = r.json()
            if "result" in j:
                return j["result"]
            last = j
        except Exception as e:
            last = str(e)
        rpc_i += 1
        time.sleep(1.5)
    raise RuntimeError(last)

def call(to, data, block):
    return rpc("eth_call", [{"to": to, "data": data}, hex(block)])

def selector(sig):
    from eth_utils import keccak
    return keccak(text=sig)[:4]

BAL = selector("balanceOf(address)")
RES = selector("getReserves()")
AGG = bytes.fromhex("82ad56cb")

def enc(calls):
    return "0x" + (AGG + encode(["(address,bool,bytes)[]"], [[(t, True, d) for t, d in calls]])).hex()

def dec(raw):
    return decode(["(bool,bytes)[]"], bytes.fromhex(raw[2:]))[0]

def main():
    block = int(rpc("eth_blockNumber", []), 16)
    pools = json.load(open("analysis/pools.json"))
    allp = []
    for kind, d in pools.items():
        for p, meta in d.items():
            allp.append({"pool": p, "kind": kind, **meta})
    print(f"block {block} pools {len(allp)}", flush=True)

    out = []
    BAL2 = selector("balanceOf(address,address)")
    for i in range(0, len(allp), CHUNK):
        chunk = allp[i:i + CHUNK]
        calls = []
        for p in chunk:
            calls.append((p["pool"], RES))
        for p in chunk:
            calls.append((V, BAL2 + encode(["address", "address"], [p["token0"], p["pool"]])))
        for p in chunk:
            calls.append((V, BAL2 + encode(["address", "address"], [p["token1"], p["pool"]])))
        raw = call(MC, enc(calls), block)
        res = dec(raw)
        for j, p in enumerate(chunk):
            okr, retr = res[j]
            ok0, ret0 = res[len(chunk) + j]
            ok1, ret1 = res[2 * len(chunk) + j]
            r0 = int.from_bytes(retr[:32], "big") if okr and len(retr) >= 64 else None
            r1 = int.from_bytes(retr[32:64], "big") if okr and len(retr) >= 64 else None
            b0 = int.from_bytes(ret0, "big") if ok0 and len(ret0) >= 32 else None
            b1 = int.from_bytes(ret1, "big") if ok1 and len(ret1) >= 32 else None
            out.append({**p, "reserve0": r0, "reserve1": r1, "vault0": b0, "vault1": b1})
        print(f"  {min(i+CHUNK,len(allp))}/{len(allp)}", flush=True)

    bad = []
    for p in out:
        for side, tok in (("0", p["token0"]), ("1", p["token1"])):
            r = p["reserve" + side]
            b = p["vault" + side]
            if r is None or b is None:
                continue
            if b > r:
                bad.append({"pool": p["pool"], "kind": p["kind"], "token": tok,
                            "reserve": str(r), "vault_balance": str(b), "excess": str(b - r)})
    bad.sort(key=lambda x: int(x["excess"]), reverse=True)
    json.dump({"block": block, "pools": out, "excess": bad}, open("analysis/pool_excess.json", "w"), indent=1)
    print(f"pools with excess: {len(bad)}")
    for x in bad[:25]:
        print(x)

if __name__ == "__main__":
    main()
