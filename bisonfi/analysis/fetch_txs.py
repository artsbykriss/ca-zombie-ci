#!/usr/bin/env python3
"""Fetch the 2026-03-28 BisonFi/GoonFi exploit tx + related txs via api.mainnet-beta (read-only).
No secrets involved (public endpoint)."""
import json, os, sys, urllib.request, time

OUT = os.path.dirname(os.path.abspath(__file__))
URL = "https://api.mainnet-beta.solana.com"

def rpc(method, params, retries=8):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for a in range(retries):
        try:
            req = urllib.request.Request(URL, data=payload, headers={"Content-Type": "application/json", "User-Agent": "zombie-research/1.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                out = json.loads(r.read())
            if "error" in out and ("rate" in str(out["error"]).lower() or out["error"].get("code") == 429):
                time.sleep(2 * (a + 1)); last = out["error"]; continue
            return out
        except Exception as ex:
            last = str(ex); time.sleep(1.5 * (a + 1))
    return {"error": {"code": -1, "message": f"failed: {last}"}}

def get_tx(sig):
    for ver in (0, 1):
        r = rpc("getTransaction", [sig, {"encoding": "json", "maxSupportedTransactionVersion": ver, "commitment": "confirmed"}])
        if r.get("result"):
            return r["result"]
    return None

if __name__ == "__main__":
    sigs = {
        "exploit-tx": "5A1YuYHff5RYiZd57M4Ko7PaqoX1GMsYGny9AVaVn826bS1w4nxwbRDyHs4bqJgV6yZfRVQAjmGFDRp9kL6aMGV2",
    }
    for name, sig in sigs.items():
        tx = get_tx(sig)
        if not tx:
            print(name, "NOT FOUND"); continue
        with open(os.path.join(OUT, f"{name}.json"), "w") as f:
            json.dump(tx, f, indent=1)
        print(name, "slot", tx["slot"], "err", tx["meta"].get("err"), "blockTime", tx.get("blockTime"),
              "cu", tx["meta"].get("computeUnitsConsumed"), "logLines", len(tx["meta"].get("logMessages", [])))
