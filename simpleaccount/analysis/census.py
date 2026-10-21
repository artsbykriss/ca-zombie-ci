#!/usr/bin/env python3
"""SimpleAccount census — read-only JSON-RPC reads (no signing; keyless public RPCs only).

Input : analysis/internal-txs-raw.json   (Etherscan internal txlist = factory creations)
Output: analysis/census.json

Phases: code size -> ETH balance -> USDC balance -> per-proxy state (owner/guardian/
phoneGuardian/factory/EntryPoint-deposit). Resumable: keeps partial phase files.
"""
import json, os, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
RPCS = ["https://arb1.arbitrum.io/rpc", "https://arbitrum.drpc.org",
        "https://arbitrum-one-rpc.publicnode.com"]
FACTORY = "0x47C705EAe895BfF833d95a9d2A0Daa31B25d2885".lower()
USDC = "0xaf88d065e77c8cc2239327c5edb3a432268e5831"
BATCH = 25
_rpc_i = [0]


def rpc_batch(calls, rpc):
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)]
    req = urllib.request.Request(rpc, data=json.dumps(payload).encode(),
                                headers={"content-type": "application/json", "user-agent": "zh4-census/1"})
    with urllib.request.urlopen(req, timeout=90) as r:
        out = json.load(r)
    if not isinstance(out, list):
        raise ValueError("non-list response")
    res = {o["id"]: o for o in out if isinstance(o, dict) and "id" in o}
    vals = []
    for i in range(len(calls)):
        o = res.get(i)
        if o is None or "result" not in o:
            raise ValueError("missing result")
        vals.append(o["result"])
    return vals


def batch_with_retry(calls):
    for attempt in range(10):
        rpc = RPCS[(_rpc_i[0] + attempt) % len(RPCS)]
        try:
            return rpc_batch(calls, rpc)
        except Exception as e:
            if attempt == 0:
                _rpc_i[0] += 1
            sys.stderr.write(f"  retry{attempt} {rpc.split('/')[2]} {type(e).__name__} {str(e)[:60]}\n")
            time.sleep(0.8 * (attempt + 1))
    return [None] * len(calls)


def chunks(seq, n):
    for i in range(0, len(seq), n):
        yield seq[i:i + n]


def phase(name, addrs, calls_for, conv, path):
    if os.path.exists(path):
        return json.load(open(path))
    out = {}
    for part in chunks(addrs, BATCH):
        for a, v in zip(part, batch_with_retry([calls_for(a) for a in part])):
            out[a] = conv(v)
    json.dump(out, open(path, "w"))
    print(f"{name}: {len(out)} (None={sum(1 for v in out.values() if v is None)})", file=sys.stderr)
    return out


def main():
    raw = json.load(open(os.path.join(HERE, "internal-txs-raw.json")))
    cre = [t for t in raw if t["from"].lower() == FACTORY]
    meta = {t["contractAddress"].lower(): {"block": int(t["blockNumber"]), "tx": t["hash"],
                                           "ts": int(t["timeStamp"])} for t in cre}
    addrs = sorted(meta)
    P = lambda n: os.path.join(HERE, f"census-{n}.json")

    codes = phase("code", addrs, lambda a: ("eth_getCode", [a, "latest"]),
                  lambda v: (len(v) // 2 - 1 if v and v != "0x" else 0), P("code"))
    bals = phase("eth", addrs, lambda a: ("eth_getBalance", [a, "latest"]),
                 lambda v: (int(v, 16) if v else None), P("eth"))
    usdc = phase("usdc", addrs,
                 lambda a: ("eth_call", [{"to": USDC, "data": "0x70a08231" + a[2:].rjust(64, "0")}, "latest"]),
                 lambda v: (int(v, 16) if v and v != "0x" else None), P("usdc"))

    proxies = [a for a in addrs if (codes.get(a) or 0) > 0 and (codes.get(a) or 0) < 400]
    sel = {"owner": "0x8da5cb5b", "guardian": "0x452a9320", "phoneGuardian": "0x8c44914d",
           "factory": "0xc45a0155", "deposit": "0xc399ec88"}
    state = {}
    sp = P("state")
    if os.path.exists(sp):
        state = json.load(open(sp))
    for addr in proxies:
        if addr in state:
            continue
        res = batch_with_retry([("eth_call", [{"to": addr, "data": d}, "latest"]) for d in sel.values()])
        state[addr] = {k: v for k, v in zip(sel, res)}
        if len(state) % 200 == 0:
            json.dump(state, open(sp, "w"))
            print(f"state {len(state)}/{len(proxies)}", file=sys.stderr)
    json.dump(state, open(sp, "w"))

    out = {"factory": FACTORY, "count": len(addrs), "note": "block tag latest at run time",
           "contracts": {a: {**meta[a], "code_size": codes.get(a), "eth_wei": bals.get(a),
                             "usdc": usdc.get(a), "state": state.get(a)} for a in addrs}}
    json.dump(out, open(os.path.join(HERE, "census.json"), "w"), indent=0)
    print("DONE created", len(addrs), "coded", sum(1 for a in addrs if (codes.get(a) or 0) > 0),
          "proxies", len(proxies), "eth>0", sum(1 for a in addrs if bals.get(a)),
          "usdc>0", sum(1 for a in addrs if usdc.get(a)), file=sys.stderr)


if __name__ == "__main__":
    main()
