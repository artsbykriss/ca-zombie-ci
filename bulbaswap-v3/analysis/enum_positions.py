#!/usr/bin/env python3
"""Enumerate every BulbaSwap V3 position NFT (owner + liquidity + tokensOwed).
Read-only, keyless RPC. Writes positions.json (or $1)."""
import json, subprocess, sys, time

RPC = "https://rpc.morphl2.io"
NPM = "0xc6b60ee77854b7c11c39b6e3f5bcfe1866cbc20a"
OUT = sys.argv[1] if len(sys.argv) > 1 else "positions.json"

def rpc(method, params):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    for a in range(5):
        try:
            o = json.loads(subprocess.run(["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
                                           "--data", payload, RPC], capture_output=True, text=True, timeout=60).stdout)
            if "result" in o:
                return o["result"]
        except Exception:
            pass
        time.sleep(1.5*(a+1))

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
                    out.extend([x.get("result", "0x") for x in j])
                    break
            except Exception:
                pass
            time.sleep(1.5*(a+1))
        else:
            out.extend(["0x"]*len(chunk))
    return out

def u(h):
    return int(h, 16) if h and h != "0x" else 0

blk = int(rpc("eth_blockNumber", []), 16)
total = u(rpc("eth_call", [{"to": NPM, "data": "0x18160ddd"}, "latest"]))
print("block", blk, "totalSupply", total, flush=True)

ids = list(range(1, total+1))
calls = []
for i in ids:
    h = hex(i)[2:].rjust(64, "0")
    calls.append((NPM, "0x99fbab88" + h))   # positions(uint256)
    calls.append((NPM, "0x6352211e" + h))   # ownerOf(uint256)
res = batch(calls)

pos = []
for k, i in enumerate(ids):
    w = [res[2*k][2:][j:j+64] for j in range(0, len(res[2*k][2:]), 64)]
    owner = "0x" + res[2*k+1][-40:] if len(res[2*k+1]) >= 42 else None
    if len(w) < 12:
        pos.append({"tokenId": i, "err": True})
        continue
    pos.append({
        "tokenId": i,
        "token0": "0x" + w[2][-40:], "token1": "0x" + w[3][-40:], "fee": int(w[4], 16),
        "tickLower": int(w[5], 16) - (1 << 256) if int(w[5], 16) >= (1 << 255) else int(w[5], 16),
        "tickUpper": int(w[6], 16) - (1 << 256) if int(w[6], 16) >= (1 << 255) else int(w[6], 16),
        "liquidity": str(u("0x" + w[7])),
        "feeGrowthInside0LastX128": w[8], "feeGrowthInside1LastX128": w[9],
        "tokensOwed0": str(u("0x" + w[10])), "tokensOwed1": str(u("0x" + w[11])),
        "owner": owner,
    })
json.dump({"block": blk, "totalSupply": total, "positions": pos}, open(OUT, "w"), indent=1)
live = [p for p in pos if int(p.get("liquidity", 0)) > 0]
owed = [p for p in pos if int(p.get("tokensOwed0", 0)) > 0 or int(p.get("tokensOwed1", 0)) > 0]
print(f"positions={len(pos)} withLiquidity={len(live)} withTokensOwed={len(owed)}")
from collections import Counter
print("top owners:", Counter(p.get("owner") for p in live).most_common(10))
