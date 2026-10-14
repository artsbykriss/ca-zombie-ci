#!/usr/bin/env python3
"""Robust multi-RPC fetch with retry + fallback; saves bytecode/state to files."""
import json, subprocess, sys, time, os

RPCS = [
    "https://rpc.ankr.com/kaia",
    "https://kaia.drpc.org",
    "https://klaytn.drpc.org",
    "https://public-en.node.kaia.io",
]

def rpc(method, params, tries=8, timeout=12):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    last = None
    for t in range(tries):
        for u in RPCS:
            try:
                p = subprocess.run(["curl", "-s", "-m", str(timeout), "-X", "POST",
                                    "-H", "Content-Type: application/json",
                                    "--data-binary", payload, u],
                                   capture_output=True, text=True, timeout=timeout + 8)
                d = json.loads(p.stdout)
                if "error" in d:
                    return {"__error__": d["error"]}
                return d.get("result")
            except Exception as e:
                last = str(e)[:80]
                time.sleep(0.3)
    raise RuntimeError(f"rpc failed after {tries} tries: {last}")

def eth_call(to, data, block="latest"):
    return rpc("eth_call", [{"to": to, "data": data}, block])

if __name__ == "__main__":
    print(rpc("eth_blockNumber", []))
