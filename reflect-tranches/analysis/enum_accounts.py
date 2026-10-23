#!/usr/bin/env python3
"""Enumerate all accounts owned by the RLP and proxy programs (light: dataSlice=0)."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

PROGS = {"rlp": "JrXLmS6aYJNJDVxdAfjNJE5wikT8ubf3TA9iL2JA9Av",
         "proxy": "pRoxYU64BSjv8HbhENna8a7LVCrkzzNrnvbYuTwas8C"}

res = {}
for name, prog in PROGS.items():
    r = rpc("getProgramAccounts", [prog, {"encoding": "base64", "dataSlice": {"offset": 0, "length": 0}}])
    if "error" in r:
        print(name, "ERR", json.dumps(r["error"])[:300]); res[name] = {"error": r["error"]}; continue
    accs = r["result"]
    lst = [{"pubkey": a["pubkey"], "lamports": a["account"]["lamports"],
            "size": a["account"]["space"] if "space" in a["account"] else len(a["account"]["data"][0]) // 4 * 3}
           for a in accs]
    res[name] = lst
    print(f"{name}: {len(lst)} accounts")
    for a in sorted(lst, key=lambda x: x["size"]):
        print(f"  {a['pubkey']}  size={a['size']} lamports={a['lamports']}")

json.dump(res, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "program_accounts.json"), "w"), indent=2)
