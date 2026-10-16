#!/usr/bin/env python3
"""Simulate historical txs against CURRENT chain state (sigVerify=false). Read-only."""
import sys, json, base64
import sol_rpc as S

def get_raw_tx(sig):
    t = S.rpc("getTransaction", [sig, {"encoding": "base64", "maxSupportedTransactionVersion": 0, "commitment": "finalized"}])
    if not t:
        return None
    return t["transaction"][0]

def simulate(tx_b64, accounts_cfg=None):
    cfg = {"encoding": "base64", "sigVerify": False, "replaceRecentBlockhash": True, "commitment": "finalized"}
    if accounts_cfg:
        cfg["accounts"] = accounts_cfg
    return S.rpc("simulateTransaction", [tx_b64, cfg])

if __name__ == "__main__":
    for sig in sys.argv[1:]:
        raw = get_raw_tx(sig)
        if raw is None:
            print(sig, "NOT FOUND"); continue
        print(f"\n===== simulating {sig[:24]}… against current state =====")
        try:
            r = simulate(raw)
        except Exception as e:
            print("  simulate error:", str(e)[:300]); continue
        v = r["value"]
        print("  err:", v.get("err"))
        print("  unitsConsumed:", v.get("unitsConsumed"))
        for l in (v.get("logs") or [])[-25:]:
            print("   ", l[:200])
