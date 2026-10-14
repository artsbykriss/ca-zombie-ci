#!/usr/bin/env python3
"""Probe Pala pools v3: single-threaded, official Kaia node only.
Reserves vs balances with confirmatory re-read for any positive excess."""
import json, time, urllib.request

RPC = "https://public-en.node.kaia.io"
OUT = "/home/heisenberg/CA/pala/analysis"

def call(to, data, tries=6):
    body = json.dumps({"jsonrpc": "2.0", "method": "eth_call", "params": [{"to": to, "data": data}, "latest"], "id": 1}).encode()
    for i in range(tries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=20) as r:
                d = json.loads(r.read().decode())
            if "result" in d and d["result"] not in (None, "0x"):
                return d["result"]
        except Exception:
            pass
        time.sleep(0.4 * (i + 1))
    raise RuntimeError(f"fail {to} {data[:18]}")

def word(x):
    return hex(x)[2:].rjust(64, "0")

def addr_from(h):
    return "0x" + h[-40:]

def block():
    return int(call("0x0000000000000000000000000000000000000000", "0x"), 16) if False else None

def main():
    pools = json.load(open(f"{OUT}/pool_list.json"))
    # block number
    for i in range(6):
        try:
            body = json.dumps({"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}).encode()
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=15) as r:
                blk = int(json.loads(r.read().decode())["result"], 16)
            break
        except Exception:
            time.sleep(1)
    print(f"block={blk} pools={len(pools)}", flush=True)
    out = []
    with open(f"{OUT}/pools_v3.jsonl", "w") as fh:
        for k, p in enumerate(pools):
            try:
                t0 = addr_from(call(p, "0x0dfe1681")).lower()
                t1 = addr_from(call(p, "0xd21220a7")).lower()
                res = call(p, "0x0902f1ac")[2:]
                r0, r1 = int(res[0:64], 16), int(res[64:128], 16)
                b0 = int(call(t0, "0x70a08231" + word(int(p, 16))), 16)
                b1 = int(call(t1, "0x70a08231" + word(int(p, 16))), 16)
                ts = int(call(p, "0x18160ddd"), 16)
                # confirm: re-read reserves after balances
                res2 = call(p, "0x0902f1ac")[2:]
                r0b, r1b = int(res2[0:64], 16), int(res2[64:128], 16)
                ex0, ex1 = b0 - r0b, b1 - r1b
                if ex0 > 0 or ex1 > 0:
                    # confirmatory re-reads (both orders)
                    b0b = int(call(t0, "0x70a08231" + word(int(p, 16))), 16)
                    b1b = int(call(t1, "0x70a08231" + word(int(p, 16))), 16)
                    res3 = call(p, "0x0902f1ac")[2:]
                    r0c, r1c = int(res3[0:64], 16), int(res3[64:128], 16)
                    ex0 = min(ex0, b0b - r0c)
                    ex1 = min(ex1, b1b - r1c)
                    b0, b1 = b0b, b1b
                r = {"pair": p, "token0": t0, "token1": t1, "reserve0": r0b, "reserve1": r1b,
                     "tsLast": int(res[128:192], 16), "totalSupply": ts, "bal0": b0, "bal1": b1,
                     "excess0": ex0, "excess1": ex1}
            except Exception as e:
                r = {"pair": p, "error": str(e)}
            out.append(r); fh.write(json.dumps(r) + "\n"); fh.flush()
            if (k + 1) % 10 == 0:
                print(f"  {k+1}/{len(pools)}", flush=True)
    out.sort(key=lambda x: x.get("pair", ""))
    json.dump({"block": blk, "pairs": out}, open(f"{OUT}/pools_v3.json", "w"), indent=1)
    ok = [r for r in out if "error" not in r]
    pos = [r for r in ok if r["excess0"] > 0 or r["excess1"] > 0]
    neg = [r for r in ok if r["excess0"] < 0 or r["excess1"] < 0]
    print(f"ok={len(ok)}/{len(out)} positive={len(pos)} negative={len(neg)}")
    for r in pos:
        print(f"  EXCESS {r['pair']} ex0={r['excess0']} ex1={r['excess1']}")
    for r in neg:
        print(f"  NEG {r['pair']} ex0={r['excess0']} ex1={r['excess1']}")

if __name__ == "__main__":
    main()
