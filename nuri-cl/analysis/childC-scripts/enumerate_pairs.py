#!/usr/bin/env python3
"""Enumerate all pairs of the Nuri V2 factory on Scroll (read-only).
Saves analysis/childC-v2-pairs.json with raw state at a pinned block.
"""
import json, sys, time
import urllib.request

RPC = "https://rpc.scroll.io"
FACTORY = "0xAAA16c016BF556fcD620328f0759252E29b1AB57"
OUT = "/home/heisenberg/CA/nuri-cl/analysis/childC-v2-pairs.json"

def rpc_batch(calls):
    payload = []
    for i, c in enumerate(calls):
        if isinstance(c, tuple):
            to, data = c
            params = [{"to": to, "data": data}, BLOCK_TAG]
            method = "eth_call"
        else:
            params = c["params"]
            method = c.get("method", "eth_call")
        payload.append({"jsonrpc": "2.0", "id": i, "method": method, "params": params})
    body = json.dumps(payload).encode()
    req = urllib.request.Request(RPC, data=body, headers={
        "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    for attempt in range(5):
        try:
            resp = json.load(urllib.request.urlopen(req, timeout=60))
            out = {}
            for item in resp:
                out[item["id"]] = item.get("result", {"error": item.get("error")})
            return out
        except Exception as e:
            print("retry", attempt, e, file=sys.stderr)
            time.sleep(2)
    raise RuntimeError("rpc batch failed")

def rpc_single(to, data):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": to, "data": data}, BLOCK_TAG]}).encode()
    req = urllib.request.Request(RPC, data=body, headers={
        "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    resp = json.load(urllib.request.urlopen(req, timeout=60))
    return resp.get("result")

def block_number():
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode()
    req = urllib.request.Request(RPC, data=body, headers={
        "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=60))["result"]

def enc_uint(v):
    return hex(v)[2:].rjust(64, "0")

def enc_addr(a):
    return a.lower().replace("0x", "").rjust(64, "0")

def dec_uint(hexstr):
    if not hexstr or hexstr == "0x":
        return None
    try:
        return int(hexstr, 16)
    except Exception:
        return None

def dec_addr(hexstr):
    if not hexstr or len(hexstr) < 42:
        return None
    return "0x" + hexstr[-40:]

# selectors
SEL = {
    "allPairs": "0x1e3dd18b",
    "allPairsLength": "0x574f2ba3",
    "isPaused": "0xb187bd26",
    "implementation": "0x5c60da1b",
    "treasury": "0x61d027b3",
    "voter": "0x46c96aac",
    "getFee(bool)": "0x512b45ea",
    "token0": "0x0dfe1681",
    "token1": "0xd21220a7",
    "getReserves": "0x0902f1ac",
    "totalSupply": "0x18160ddd",
    "stable": "0x22be3de1",
    "fees": "0x9af1d35a",
    "feeSplit": "0x6373ea69",
    "decimals": "0x313ce567",
    "symbol": "0x95d89b41",
    "owner": "0x8da5cb5b",
    "getPoolFeeSplit": "0xe829263f",
    "feeManager": "0xd0fb0203",
    "pendingFeeManager": "0x8a4fa0d2",
}

def main():
    global BLOCK_TAG
    bn = block_number()
    BLOCK_TAG = bn
    print("block", int(bn, 16))
    res = {"factory": FACTORY, "block": int(bn, 16), "pairs": []}
    # factory basics
    basics = {}
    for name, sel in [("allPairsLength", SEL["allPairsLength"]), ("isPaused", SEL["isPaused"]),
                      ("implementation", SEL["implementation"]), ("treasury", SEL["treasury"]),
                      ("voter", SEL["voter"]), ("owner", SEL["owner"]),
                      ("feeManager", SEL["feeManager"]), ("pendingFeeManager", SEL["pendingFeeManager"]),
                      ("getFee(true)", SEL["getFee(bool)"] + enc_uint(1)),
                      ("getFee(false)", SEL["getFee(bool)"] + enc_uint(0))]:
        r = rpc_single(FACTORY, sel)
        basics[name] = r
    res["factory_basics"] = basics
    n = dec_uint(basics["allPairsLength"])
    print("num pairs", n)
    # enumerate pair addresses in batches
    addrs = {}
    for start in range(0, n, 8):
        batch = [(FACTORY, SEL["allPairs"] + enc_uint(i)) for i in range(start, min(start + 8, n))]
        out = rpc_batch(batch)
        for idx, (to, data) in enumerate(batch):
            i = start + idx
            addrs[i] = dec_addr(out.get(idx))
    res["pair_addresses"] = {str(k): v for k, v in addrs.items()}
    # per-pair reads
    calls = []
    meta = []
    for i in range(n):
        p = addrs[i]
        for f in ("token0", "token1", "getReserves", "totalSupply", "stable", "fees", "feeSplit", "decimals", "symbol"):
            calls.append((p, SEL[f]))
            meta.append((i, p, f))
        calls.append((p, SEL["getPoolFeeSplit"] + enc_addr(p)))
        meta.append((i, p, "getPoolFeeSplit"))
        calls.append({"method": "eth_getStorageAt",
                      "params": [p, "0x" + "2".rjust(64, "0"), BLOCK_TAG]})
        meta.append((i, p, "storage_slot2"))
    results = {}
    for start in range(0, len(calls), 8):
        out = rpc_batch(calls[start:start + 8])
        for idx in range(len(calls[start:start + 8])):
            j = start + idx
            results[j] = out.get(idx)
    pairdata = {}
    for j, (i, p, f) in enumerate(meta):
        d = pairdata.setdefault(i, {"pair": p})
        r = results[j]
        if isinstance(r, dict):  # error
            d[f] = {"error": r}
            continue
        if f in ("token0", "token1", "fees"):
            d[f] = dec_addr(r)
        elif f == "getReserves":
            if r and len(r) >= 2 + 64 * 3:
                h = r[2:]
                d["reserve0"] = int(h[0:64], 16)
                d["reserve1"] = int(h[64:128], 16)
                d["blockTimestampLast"] = int(h[128:192], 16)
            else:
                d[f] = r
        elif f == "stable":
            d[f] = dec_uint(r)
        elif f in ("feeSplit", "getPoolFeeSplit"):
            d[f] = dec_uint(r)
        elif f == "storage_slot2":
            if r and len(r) >= 66:
                v = int(r, 16)
                d["slot2_feeSplit"] = v & 0xff
                d["slot2_stable"] = (v >> 8) & 0xff
                d["slot2_hasActiveGauge"] = (v >> 16) & 0xff
            else:
                d[f] = r
        elif f == "symbol":
            try:
                h = r[2:]
                ln = int(h[64:128], 16)
                d[f] = bytes.fromhex(h[128:128 + ln * 2]).decode("utf-8", "replace")
            except Exception:
                d[f] = None
        else:
            d[f] = dec_uint(r)
    # token balances held by pairs + decimals/symbol of tokens
    tokens = set()
    for i, d in pairdata.items():
        for k in ("token0", "token1"):
            if d.get(k):
                tokens.add(d[k])
    res["tokens"] = {}
    tokmeta = []
    tok_calls = []
    for t in sorted(tokens):
        for f in ("decimals", "symbol"):
            tok_calls.append((t, SEL[f]))
            tokmeta.append((t, f))
    tokres = {}
    for start in range(0, len(tok_calls), 8):
        out = rpc_batch(tok_calls[start:start + 8])
        for idx in range(len(tok_calls[start:start + 8])):
            tokres[start + idx] = out.get(idx)
    for j, (t, f) in enumerate(tokmeta):
        d = res["tokens"].setdefault(t, {})
        r = tokres[j]
        if isinstance(r, dict):
            d[f] = {"error": r}
        elif f == "decimals":
            d[f] = dec_uint(r)
        else:
            try:
                h = r[2:]
                ln = int(h[64:128], 16)
                d[f] = bytes.fromhex(h[128:128 + ln * 2]).decode("utf-8", "replace")
            except Exception:
                d[f] = None
    # pair balances of its tokens
    bal_calls = []
    bal_meta = []
    for i, d in pairdata.items():
        for k in ("token0", "token1"):
            t = d.get(k)
            if t:
                bal_calls.append((t, "0x70a08231" + enc_addr(d["pair"])))
                bal_meta.append((i, t, k))
    balres = {}
    for start in range(0, len(bal_calls), 8):
        out = rpc_batch(bal_calls[start:start + 8])
        for idx in range(len(bal_calls[start:start + 8])):
            balres[start + idx] = out.get(idx)
    for j, (i, t, k) in enumerate(bal_meta):
        r = balres[j]
        pairdata[i]["balance_" + k] = dec_uint(r) if isinstance(r, str) else {"error": r}
    res["pairs"] = [pairdata[i] for i in sorted(pairdata)]
    with open(OUT, "w") as f:
        json.dump(res, f, indent=1)
    print("saved", OUT, "pairs:", len(res["pairs"]))

if __name__ == "__main__":
    main()
