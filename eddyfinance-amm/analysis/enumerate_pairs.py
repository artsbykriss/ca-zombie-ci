#!/usr/bin/env python3
"""Read-only enumeration of EddyFinance AMM (UniswapV2 fork) on ZetaChain.
Uses keyless public RPC. No secrets. Saves analysis/pairs_live.json + tokens_live.json."""
import json, time, urllib.request, sys

RPCS = [
    "https://zetachain-evm.blockpi.network/v1/rpc/public",
    "https://7000.rpc.thirdweb.com",
    "https://zeta-chain.drpc.org",
]
FACTORY = "0x9fd96203f7b22bCF72d9DCb40ff98302376cE09c"
UA = {"User-Agent": "Mozilla/5.0"}

_rid = [0]
def rpc_batch(calls, rpc_idx=0):
    """calls: list of (to, data) tuples -> list of hex results"""
    payload = []
    for to, data in calls:
        _rid[0] += 1
        payload.append({"jsonrpc": "2.0", "id": _rid[0], "method": "eth_call",
                        "params": [{"to": to, "data": data}, "latest"]})
    body = json.dumps(payload).encode()
    last_err = None
    for attempt in range(6):
        rpc = RPCS[(rpc_idx + attempt) % len(RPCS)]
        try:
            req = urllib.request.Request(rpc, data=body, headers={**UA, "Content-Type": "application/json"})
            out = json.load(urllib.request.urlopen(req, timeout=40))
            res = {}
            for item in out:
                res[item["id"]] = item.get("result") if "result" in item else ("ERR:" + str(item.get("error"))[:120])
            # map back in order
            ordered = []
            for p in payload:
                ordered.append(res.get(p["id"]))
            return ordered
        except Exception as e:
            last_err = e
            time.sleep(1.5 + attempt)
    raise RuntimeError(f"rpc failed: {last_err}")

def enc_sig(sig):
    # minimal keccak via hashlib not available; use known selectors hardcoded
    return sig

SEL = {
    "allPairs(uint256)": "0x1e3dd18b",
    "token0()": "0x0dfe1681",
    "token1()": "0xd21220a7",
    "getReserves()": "0x0902f1ac",
    "totalSupply()": "0x18160ddd",
    "balanceOf(address)": "0x70a08231",
    "kLast()": "0x7464fc3d",
    "symbol()": "0x95d89b41",
    "decimals()": "0x313ce567",
    "name()": "0x06fdde03",
    "factory()": "0x45df9339" if False else "0xc45a0155",
    "feeTo()": "0x017e7e58",
    "feeToSetter()": "0xf46901ed",
    "allPairsLength()": "0x574f2ba3",
    "getPair(address,address)": "0xe6a43905",
}

def pad32(h):
    h = h.lower().replace("0x", "")
    return h.rjust(64, "0")

def call1(to, sig, arg=None):
    data = SEL[sig] + (pad32(arg) if arg else "")
    r = rpc_batch([(to, data)])[0]
    return r

def callN(to, sig, args=None, n=1):
    data = SEL[sig] + "".join(pad32(a) for a in (args or []))
    r = rpc_batch([(to, data)] * n)
    return r

def decode_uint(h):
    return int(h, 16)

def decode_addr(h):
    return "0x" + h[-40:]

def decode_string(h):
    if not h or h == "0x":
        return ""
    b = bytes.fromhex(h[2:])
    if len(b) >= 64:
        # offset-based
        off = int.from_bytes(b[0:32], "big")
        ln = int.from_bytes(b[off:off+32], "big")
        return b[off+32:off+32+ln].decode("utf-8", "replace")
    return b.decode("utf-8", "replace")

def main():
    latest = json.load(urllib.request.urlopen(urllib.request.Request(
        RPCS[0], data=json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}).encode(),
        headers={**UA, "Content-Type": "application/json"}), timeout=30))
    block = int(latest["result"], 16)
    print("latest block:", block)

    n = decode_uint(call1(FACTORY, "allPairsLength()"))
    print("pairs:", n)
    pairs = []
    for i in range(0, n, 10):
        idxs = list(range(i, min(i + 10, n)))
        rs = rpc_batch([(FACTORY, SEL["allPairs(uint256)"] + pad32(hex(j))) for j in idxs])
        pairs += [decode_addr(r) for r in rs]
    print("pair list ok:", len(pairs))

    # per pair reads
    out = []
    for i, p in enumerate(pairs):
        r = rpc_batch([
            (p, SEL["token0()"]),
            (p, SEL["token1()"]),
            (p, SEL["getReserves()"]),
            (p, SEL["totalSupply()"]),
            (p, SEL["kLast()"]),
        ])
        t0 = decode_addr(r[0]); t1 = decode_addr(r[1])
        res = r[2][2:]
        r0 = int(res[0:64], 16); r1 = int(res[64:128], 16); ts = int(res[128:192], 16)
        tsupply = decode_uint(r[3]); klast = decode_uint(r[4])
        # balances + LP held by pair
        rb = rpc_batch([
            (t0, SEL["balanceOf(address)"] + pad32(p)),
            (t1, SEL["balanceOf(address)"] + pad32(p)),
            (p, SEL["balanceOf(address)"] + pad32(p)),
        ])
        b0 = decode_uint(rb[0]); b1 = decode_uint(rb[1]); lp_self = decode_uint(rb[2])
        out.append({"pair": p, "token0": t0, "token1": t1, "reserve0": r0, "reserve1": r1,
                    "blockTimestampLast": ts, "totalSupply": tsupply, "kLast": klast,
                    "balance0": b0, "balance1": b1, "lp_held_by_pair": lp_self,
                    "excess0": b0 - r0, "excess1": b1 - r1})
        if i % 7 == 0:
            print(f"[{i+1}/{n}] {p} ok")
    json.dump({"block": block, "factory": FACTORY, "pairs": out}, open("pairs_live.json", "w"), indent=1)
    print("saved pairs_live.json")

    # token metadata for distinct tokens
    toks = sorted({x for e in out for x in (e["token0"], e["token1"])})
    meta = {}
    for i in range(0, len(toks), 8):
        chunk = toks[i:i+8]
        rs = rpc_batch([(t, SEL["symbol()"]) for t in chunk])
        for t, r in zip(chunk, rs):
            meta[t] = {"symbol": decode_string(r)}
        rs = rpc_batch([(t, SEL["decimals()"]) for t in chunk])
        for t, r in zip(chunk, rs):
            try:
                meta[t]["decimals"] = decode_uint(r)
            except Exception:
                meta[t]["decimals"] = None
        print(f"tokens {i+len(chunk)}/{len(toks)}")
    json.dump(meta, open("tokens_live.json", "w"), indent=1)
    print("saved tokens_live.json")

if __name__ == "__main__":
    main()
