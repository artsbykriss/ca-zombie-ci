#!/usr/bin/env python3
"""Fetch a full tx (jsonParsed) for a given signature and print structure. Read-only."""
import sys, json, time
from rpc import call

def main():
    sig = sys.argv[1]
    tx = call("getTransaction", [sig, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
    print("slot", tx["slot"])
    msg = tx["transaction"]["message"]
    print("version:", tx["transaction"].get("message", {}).get("version"))
    for i, k in enumerate(msg["accountKeys"]):
        if isinstance(k, dict):
            print(f"  {i:2d} {k['pubkey']} signer={k['signer']} writable={k['writable']} src={k.get('source')}")
        else:
            print(f"  {i:2d} {k}")
    print("lookups:", json.dumps(msg.get("addressTableLookups")))
    for j, ix in enumerate(msg["instructions"]):
        print(f"IX{j} pid={ix.get('programId')} data={ix.get('data')}")
        print("   accounts:", ix.get("accounts"))
    for bi, inner in enumerate(tx["meta"].get("innerInstructions", []) or []):
        for j, ix in enumerate(inner["instructions"]):
            print(f"INNER idx={inner['index']}.{j} pid={ix.get('programId')} data={ix.get('data')}")
            print("   accounts:", ix.get("accounts"))

if __name__ == "__main__":
    main()
