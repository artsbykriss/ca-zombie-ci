#!/usr/bin/env python3
"""Simulate a single MoveCall on Sui via GraphQL simulateTransaction (read-only).

usage: sim_movecall.py <package> <module> <function> [typeArgsCSV] [argsJSON]
  argsJSON: JSON list of Sui Argument encodings, e.g. '[{"input":0}]'
  Sender defaults to SUI_SENDER env or 0x...05 (a valid 32-byte address).

No signing, no sending. Proves whether the runtime accepts a given package VERSION.
"""
import sys, json, os, urllib.request

ENDPOINT = os.environ.get("SUI_GRAPHQL", "https://graphql.mainnet.sui.io/graphql")
SENDER = os.environ.get("SUI_SENDER", "0x0000000000000000000000000000000000000000000000000000000000000005")

def gql(q, v):
    req = urllib.request.Request(ENDPOINT, data=json.dumps({"query": q, "variables": v}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

def main():
    pkg, mod, fn = sys.argv[1], sys.argv[2], sys.argv[3]
    targs = [t for t in sys.argv[4].split(",") if t] if len(sys.argv) > 4 else []
    args = json.loads(sys.argv[5]) if len(sys.argv) > 5 else []
    cmd = {"moveCall": {"package": pkg, "module": mod, "function": fn,
                        "typeArguments": targs, "arguments": args}}
    tx = {"sender": SENDER, "kind": {"programmableTransaction": {"inputs": [], "commands": [cmd]}}}
    q = """query($t:JSON!){ simulateTransaction(transaction:$t, checksEnabled:true, doGasSelection:true){
      effects{ status
        executionError{ message abortCode identifier constant module{name} function{name} }
        events{ nodes{ contents{ type{repr} json } } }
        balanceChangesJson } } }"""
    out = gql(q, {"t": tx})
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
