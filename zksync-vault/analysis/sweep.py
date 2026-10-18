#!/usr/bin/env python3
"""Reserves-vs-balance sweep of SyncSwap Vault V1 on zkSync Era (read-only).

Reads every ERC-20 token returned by the Blockscout tokenlist, then batch-calls
  token.balanceOf(vault)      (actual custody)
  vault.reserves(token)       (attributed ledger)
at one pinned block via Multicall3.  excess = actual - attributed is the only
permissionless value-capture primitive in the published source (deposit()).

No secrets: uses public RPC endpoints only.
"""
import json, sys, time
import requests
from eth_abi import encode, decode

V = "0x621425a1Ef6abE91058E9712575dcc4258F8d091"
MULTICALL3 = "0xcA11bde05977b3631167028862bE2a173976CA11"
RPCS = ["https://mainnet.era.zksync.io", "https://zksync.drpc.org", "https://1rpc.io/zksync2-era"]
PAGE = 300

rpc_i = 0
def rpc(method, params):
    global rpc_i
    last = None
    for attempt in range(6):
        url = RPCS[rpc_i % len(RPCS)]
        try:
            r = requests.post(url, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params}, timeout=60)
            j = r.json()
            if "result" in j:
                return j["result"]
            last = j
        except Exception as e:
            last = str(e)
        rpc_i += 1
        time.sleep(1.5)
    raise RuntimeError(f"rpc failed: {last}")

def call(to, data, block):
    return rpc("eth_call", [{"to": to, "data": data if isinstance(data,str) else data.hex()}, hex(block)])

def sel(sig):
    from eth_utils import keccak
    return keccak(text=sig)[:4]

BAL_SEL = sel("balanceOf(address)")
RES_SEL = sel("reserves(address)")
AGG3_SEL = bytes.fromhex("82ad56cb")

def enc_agg3(calls):
    # calls: list of (target, calldata)
    tuples = []
    for target, data in calls:
        tuples.append((target, True, data))
    return "0x" + (AGG3_SEL + encode(["(address,bool,bytes)[]"], [tuples])).hex()

def dec_agg3(raw):
    # returns [(success, bytes)]
    out = decode(["(bool,bytes)[]"], raw)[0]
    return out

def main():
    block = int(rpc("eth_blockNumber", []), 16)
    tl = requests.get(
        "https://zksync.blockscout.com/api?module=account&action=tokenlist&address=" + V,
        headers={"User-Agent": "Mozilla/5.0"}, timeout=60,
    ).json()["result"]
    tokens = {}
    for t in tl:
        if t.get("type") != "ERC-20":
            continue
        try:
            bal = int(t["balance"])
        except Exception:
            continue
        if bal == 0:
            continue
        a = t["contractAddress"].lower()
        tokens[a] = {"symbol": t.get("symbol"), "decimals": int(t.get("decimals") or 18), "api_balance": str(bal)}
    addrs = sorted(tokens)
    print(f"block={block} erc20_nonzero={len(addrs)}", flush=True)

    results = {}
    for i in range(0, len(addrs), PAGE):
        chunk = addrs[i:i + PAGE]
        calls = [(a, BAL_SEL + encode(["address"], [V])) for a in chunk]
        calls += [(V, RES_SEL + encode(["address"], [a])) for a in chunk]
        raw = call(MULTICALL3, enc_agg3(calls), block)
        dec = dec_agg3(bytes.fromhex(raw[2:]) if raw.startswith("0x") else raw)
        for j, a in enumerate(chunk):
            ok_b, ret_b = dec[j]
            ok_r, ret_r = dec[len(chunk) + j]
            b = int.from_bytes(ret_b, "big") if ok_b and len(ret_b) >= 32 else None
            r = int.from_bytes(ret_r, "big") if ok_r and len(ret_r) >= 32 else None
            results[a] = {**tokens[a], "balance": b, "reserves": r}
        print(f"  {min(i+PAGE,len(addrs))}/{len(addrs)}", flush=True)

    excess = []
    for a, d in results.items():
        if d["balance"] is None or d["reserves"] is None:
            continue
        e = d["balance"] - d["reserves"]
        if e > 0:
            excess.append({"token": a, "symbol": d["symbol"], "decimals": d["decimals"],
                           "balance_raw": str(d["balance"]), "reserves_raw": str(d["reserves"]),
                           "excess_raw": str(e),
                           "excess_human": e / (10 ** d["decimals"]) if d["decimals"] < 60 else None})
    excess.sort(key=lambda x: (x["excess_raw"]), reverse=True)
    out = {"block": block, "vault": V, "tokens_checked": len(addrs),
           "tokens_with_read_failure": sum(1 for d in results.values() if d["balance"] is None or d["reserves"] is None),
           "tokens_with_excess": len(excess), "excess": excess, "results": results}
    json.dump(out, open("analysis/sweep.json", "w"), indent=1)
    print("excess tokens:", len(excess))
    for e in excess[:40]:
        print(e["token"], e["symbol"], e["decimals"], e["excess_raw"], e["excess_human"])

if __name__ == "__main__":
    main()
