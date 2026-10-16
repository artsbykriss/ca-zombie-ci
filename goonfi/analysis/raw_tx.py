#!/usr/bin/env python3
"""Fetch raw tx (base64) and decode ALL instructions incl. inner (GoonFi CPI data)."""
import json, os, sys, base64, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58d(s):
    n = 0
    for ch in s:
        n = n * 58 + B58.index(ch)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big")
    pad = 0
    for ch in s:
        if ch == "1":
            pad += 1
        else:
            break
    return b"\x00" * pad + b


def parse_tx(sig):
    r = rpc("getTransaction", [sig, {"encoding": "base64", "maxSupportedTransactionVersion": 0}])
    if "result" not in r or not r["result"]:
        return None
    return r["result"]


def main():
    sig = sys.argv[1]
    tx = parse_tx(sig)
    if not tx:
        print("no tx"); return
    msg = tx["transaction"]["message"]
    if isinstance(msg, list):
        # [header, accountKeys, recentBlockhash, instructions]  (legacy)
        # or versioned: [header, accountKeys, recentBlockhash, instructions, version]
        if isinstance(msg[0], dict) and "accountKeys" in msg[0]:
            msg = msg[0]
        else:
            raise SystemExit("unexpected message shape")
    keys = msg["accountKeys"]
    meta = tx["meta"]
    print("slot", tx["slot"], "err", meta.get("err"))
    print("=== TOP-LEVEL IX ===")
    for i, ix in enumerate(msg["instructions"]):
        pid = keys[ix["programIdIndex"]]
        data = base64.b64decode(ix["data"])
        print(f"[{i}] pid={pid} data={data.hex()} nacc={len(ix['accounts'])}")
        for a in ix["accounts"]:
            print(f"      {a} {keys[a]}")
    print("=== INNER IX ===")
    for grp in meta.get("innerInstructions", []):
        print(f"-- outer {grp['index']}")
        for ix in grp["instructions"]:
            pid = keys[ix["programIdIndex"]]
            data = base64.b64decode(ix["data"])
            print(f"   pid={pid} data={data.hex()} nacc={len(ix['accounts'])}")
            for a in ix["accounts"]:
                print(f"      {a} {keys[a]}")
    print("=== LOGS (tail) ===")
    for l in meta.get("logMessages", []):
        if "goonuddt" in l or "Goonfi" in l or "amount_out" in l or "Program log: 0000" in l or "invoke [2]" in l:
            print("  ", l)


if __name__ == "__main__":
    main()
