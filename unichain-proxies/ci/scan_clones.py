#!/usr/bin/env python3
"""CI: re-scan the 299 named ImmutableProxy clones on Unichain (chain 130) live.
READ-ONLY (eth_call/eth_getBalance only). Public RPC. No secrets.
Writes ci-out/immutableproxy_scan.json
"""
import json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "ci-out")
os.makedirs(OUT, exist_ok=True)
RPC = os.environ.get("UNICHAIN_RPC_URL") or "https://mainnet.unichain.org"
USDC = "0x078D782b760474a361dDA0AF3839290b0EF57AD6"
ADDRS = [a.strip() for a in open(os.path.join(HERE, "clones.txt")) if a.strip()]


def rpc_batch(calls, tries=6):
    body = json.dumps([{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)]).encode()
    for _ in range(tries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "research"})
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.loads(r.read())
            by = {x["id"]: x for x in d}
            return [by.get(i, {}).get("result") for i in range(len(calls))]
        except Exception:
            time.sleep(1.5)
    return [None] * len(calls)


def pad(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def main():
    res = {}
    for i in range(0, len(ADDRS), 3):
        chunk = ADDRS[i:i + 3]
        calls = []
        for a in chunk:
            calls.append(("eth_call", [{"to": USDC, "data": "0x70a08231" + pad(a)}, "latest"]))
            calls.append(("eth_getBalance", [a, "latest"]))
            calls.append(("eth_getCode", [a, "latest"]))
        r = rpc_batch(calls)
        for j, a in enumerate(chunk):
            code = r[3 * j + 2] or ""
            # runtime = PUSH32 <impl> GAS DELEGATECALL ...; impl (20B) at byte offset 33 -> hex [68:108]
            impl = ("0x" + code[68:108]) if len(code) >= 108 else None
            res[a.lower()] = {
                "usdc_raw": int(r[3 * j], 16) if r[3 * j] and r[3 * j] != "0x" else 0,
                "native_wei": int(r[3 * j + 1], 16) if r[3 * j + 1] else 0,
                "impl": impl,
            }
        time.sleep(0.1)
    blk = rpc_batch([("eth_blockNumber", [])])[0]
    funded = {k: v for k, v in res.items() if v["usdc_raw"] > 0 or v["native_wei"] > 0}
    import collections
    impls = collections.Counter(v["impl"] for v in res.values())
    out = {
        "block": blk, "block_dec": int(blk, 16) if blk else None,
        "n_clones": len(res), "impls": impls,
        "funded": funded,
        "total_usdc": sum(v["usdc_raw"] for v in res.values()) / 1e6,
        "total_native_wei": sum(v["native_wei"] for v in res.values()),
    }
    json.dump(out, open(os.path.join(OUT, "immutableproxy_scan.json"), "w"), indent=1)
    print(json.dumps({k: out[k] for k in ("block_dec", "n_clones", "impls", "total_usdc", "total_native_wei")}, indent=1))
    print("funded clones:", len(funded))
    for k, v in list(funded.items())[:20]:
        print(" ", k, v)


if __name__ == "__main__":
    main()
