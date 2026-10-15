#!/usr/bin/env python3
"""Batch eth_call helper for BSC. Public RPC only. Usage: bsc.py <jsonfile>
jsonfile: [{"to":..,"data":..,"tag":"name"}] -> prints results keyed by tag.
"""
import json, sys, time, urllib.request

RPCS = [
    "https://bsc-mainnet.public.blastapi.io",
    "https://bsc-rpc.publicnode.com",
    "https://bsc.publicnode.com",
]

def batch(calls, retries=6):
    reqs = [{"jsonrpc": "2.0", "id": i, "method": "eth_call",
             "params": [{"to": c["to"], "data": c["data"]}, c.get("block", "latest")]}
            for i, c in enumerate(calls)]
    body = json.dumps(reqs).encode()
    last = None
    for i in range(retries):
        rpc = RPCS[i % len(RPCS)]
        try:
            req = urllib.request.Request(rpc, data=body, headers={
                "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read())
            res = {}
            for d in out:
                res[d["id"]] = d.get("result") if "result" in d else {"error": d.get("error")}
            return res
        except Exception as e:
            last = e
            time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"batch failed: {last}")

def sel(sig):
    """keccak selector via local cast"""
    import subprocess
    return subprocess.check_output(["cast", "sig", sig]).decode().strip()

def main():
    calls = json.load(open(sys.argv[1]))
    res = batch(calls)
    out = {}
    for i, c in enumerate(calls):
        r = res.get(i)
        if isinstance(r, dict) and "error" in r:
            out[c.get("tag", i)] = {"error": r["error"].get("message", str(r["error"]))}
        else:
            out[c.get("tag", i)] = r
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
