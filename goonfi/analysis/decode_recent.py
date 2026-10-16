#!/usr/bin/env python3
"""Fetch + decode a recent GoonFi tx (instruction data, accounts, logs, balances)."""
import json, os, sys, base64, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc as _rpc

OUT = os.path.dirname(os.path.abspath(__file__))
RPC = os.environ.get("SOLANA_RPC_URL", "https://api.mainnet-beta.solana.com")


def call(method, params, retries=6):
    r = _rpc(method, params, retries=retries)
    time.sleep(0.6)
    return r


def main():
    sigs = json.load(open(os.path.join(OUT, "recent-program-sigs.json")))
    # pick a few diverse sigs
    picks = [sigs[0], sigs[5], sigs[20], sigs[40]]
    out = []
    for s in picks:
        r = call("getTransaction", [s["signature"], {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
        if "result" in r:
            out.append(r["result"])
        time.sleep(0.5)
    with open(os.path.join(OUT, "recent-txs.json"), "w") as f:
        json.dump(out, f, indent=1)
    for tx in out:
        print("=" * 100)
        print("sig", tx["transaction"]["signatures"][0], "slot", tx["slot"])
        msg = tx["transaction"]["message"]
        print("accounts:", len(msg["accountKeys"]))
        for i, k in enumerate(msg["accountKeys"]):
            mark = "S" if k.get("signer") else " "
            mark += "W" if k.get("writable") else " "
            print(f"  [{i:2d}] {mark} {k['pubkey']}")
        print("instructions:")
        for ix in msg["instructions"]:
            if ix.get("programId"):
                print("  top:", ix["programId"], "data:", str(ix.get("data"))[:120], "accounts:", ix.get("accounts"))
        logs = tx.get("meta", {}).get("logMessages", [])
        for l in logs:
            if "Program log" in l or "invoke [" in l or "success" in l:
                print("   LOG:", l)


if __name__ == "__main__":
    main()
