#!/usr/bin/env python3
"""Probe which RPC per chain can serve a full-range eth_getLogs (Approval to router).
Prints one line per (chain, rpc): OK <n> or the error. Read-only."""
import json, os, sys, urllib.request, urllib.error

APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120 Safari/537.36"
H = {"Content-Type": "application/json", "User-Agent": UA}


def post(url, body, timeout=60):
    req = urllib.request.Request(url, data=body, headers=H)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def full_range(url, router):
    topic2 = "0x" + router.lower().replace("0x", "").rjust(64, "0")
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_getLogs",
                       "params": [{"fromBlock": "0x0", "toBlock": "latest", "topics": [APPROVAL, None, topic2]}]}).encode()
    d = post(url, body)
    if "result" in d:
        return f"OK {len(d['result'])}"
    return "ERR " + json.dumps(d.get("error"))[:90]


cfg = json.load(open(sys.argv[1]))
names = sys.argv[2].split(",") if len(sys.argv) > 2 else None
for c in cfg:
    if names and c["name"] not in names:
        continue
    for e in c.get("rpc_env", []):
        u = os.environ.get(e, "")
        if not u:
            continue
        try:
            print(f"{c['name']:14} {e:22} {full_range(u, c['router'])}", flush=True)
        except Exception as ex:
            print(f"{c['name']:14} {e:22} EXC {str(ex)[:80]}", flush=True)
    for u in c.get("rpc_default", []):
        host = u.split("/")[2]
        try:
            print(f"{c['name']:14} {host:22} {full_range(u, c['router'])}", flush=True)
        except Exception as ex:
            print(f"{c['name']:14} {host:22} EXC {str(ex)[:80]}", flush=True)
