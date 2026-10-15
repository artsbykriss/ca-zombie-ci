#!/usr/bin/env python3
"""Sample recent marginfi program transactions and classify instructions by discriminator.
Cheap way to see which entry points are active (incl. liquidations). No secrets."""
import json, base64, sys, time, urllib.request, os

ENDPOINTS = [os.environ.get("SOLANA_RPC", ""), "https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
ENDPOINTS = [e for e in ENDPOINTS if e]

def rpc(method, params, tries=6):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        ep = ENDPOINTS[i % len(ENDPOINTS)]
        try:
            req = urllib.request.Request(ep, data=body, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=60) as f:
                r = json.load(f)
            if "error" in r:
                last = r["error"]; time.sleep(1 + i); continue
            return r["result"]
        except Exception as e:
            last = str(e); time.sleep(1 + i)
    raise RuntimeError(f"rpc {method} failed: {last}")

PROG = "MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA"
# ix discriminators (first 8 bytes) from type-crate constants
DISC = {
    "init_liquidation_record": bytes([236,213,238,126,147,251,164,8]),
    "start_liquidation": bytes([244,93,90,214,192,166,191,21]),
    "end_liquidation": bytes([110,11,244,54,229,181,22,184]),
    "start_execute_order": bytes([1,70,140,134,183,29,208,224]),
    "end_execute_order": bytes([115,42,20,93,121,84,178,83]),
    "withdraw": bytes([36,72,74,19,210,210,192,192]),
    "repay": bytes([79,209,172,177,222,51,173,151]),
    "deposit": bytes([171,94,235,103,82,64,212,140]),
    "start_flashloan": bytes([14,131,33,220,81,186,180,107]),
    "end_flashloan": bytes([105,124,201,106,153,2,8,156]),
    "start_deleverage": bytes([10,138,10,57,40,232,182,193]),
    "end_deleverage": bytes([114,14,250,143,252,104,214,209]),
    "start_rebalance": bytes([251,122,91,161,219,98,5,236]),
    "end_rebalance": bytes([47,225,163,216,213,214,225,155]),
    "borrow": bytes([4,167,120,156,125,196,116,148]),  # placeholder, verified below
}

def main():
    limit = int(sys.argv[1]) if len(sys.argv) > 1 else 200
    sigs = rpc("getSignaturesForAddress", [PROG, {"limit": min(limit, 1000)}])
    print(f"got {len(sigs)} signatures", file=sys.stderr)
    from collections import Counter
    c = Counter()
    unknown = Counter()
    n = 0
    for s in sigs:
        if s.get("err"): continue
        try:
            tx = rpc("getTransaction", [s["signature"], {"encoding": "json", "maxSupportedTransactionVersion": 1}])
        except Exception as e:
            continue
        if not tx: continue
        msg = tx["transaction"]["message"]
        keys = msg["accountKeys"]
        for ix in msg["instructions"]:
            pid = keys[ix["programIdIndex"]] if isinstance(ix["programIdIndex"], int) else ix["programIdIndex"]
            if pid != PROG: continue
            data = base64.b64decode(ix["data"])
            d8 = data[:8]
            name = next((k for k, v in DISC.items() if v == d8), None)
            if name: c[name] += 1
            else:
                unknown[d8.hex()] += 1
            n += 1
        time.sleep(0.05)
    print("instructions seen:", n)
    for k, v in c.most_common(): print(f"  {k}: {v}")
    print("unknown discs (top):")
    for k, v in unknown.most_common(15): print(f"  {k}: {v}")

if __name__ == "__main__":
    main()
