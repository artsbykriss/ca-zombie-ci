#!/usr/bin/env python3
"""Scan BSC logs in small chunks over public RPC (read-only)."""
import json, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

RPCS = ["https://bsc-rpc.publicnode.com"]
UA = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def rpc(url, method, params, timeout=25):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())

def get_logs(url, address, topics, lo, hi, tries=3):
    for i in range(tries):
        try:
            r = rpc(url, "eth_getLogs", [{
                "address": address,
                "fromBlock": hex(lo), "toBlock": hex(hi),
                "topics": topics,
            }])
            if "result" in r:
                return r["result"]
            err = r.get("error", {})
            if "rate" in str(err).lower() or "limit" in str(err).lower():
                time.sleep(1.5 * (i + 1)); continue
            return {"__error__": err}
        except Exception as e:
            if i == tries - 1:
                return {"__error__": str(e)}
            time.sleep(1.5 * (i + 1))
    return {"__error__": "exhausted"}

def scan(address, topics, start, end, chunk=5000, workers=6):
    tasks = [(b, min(b + chunk - 1, end)) for b in range(start, end + 1, chunk)]
    out, errors = [], []
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(get_logs, RPCS[0], address, topics, lo, hi): (lo, hi) for lo, hi in tasks}
        for f in as_completed(futs):
            lo, hi = futs[f]
            res = f.result()
            if isinstance(res, dict):
                errors.append({"from": lo, "to": hi, "error": res.get("__error__")})
            else:
                out.extend(res)
    out.sort(key=lambda x: int(x["blockNumber"], 16))
    return out, errors

if __name__ == "__main__":
    address = sys.argv[1]
    topic0 = sys.argv[2] if sys.argv[2] != "-" else None
    start, end = int(sys.argv[3]), int(sys.argv[4])
    topics = [topic0] if topic0 else []
    logs, errors = scan(address, topics, start, end)
    print(json.dumps({"address": address, "topic0": topic0, "from": start, "to": end,
                      "count": len(logs), "errors": errors, "logs": logs}))
