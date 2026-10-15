#!/usr/bin/env python3
"""Patient retry loop for INDEXED RPC calls (getTokenLargestAccounts, getProgramAccounts).
Keyless public endpoints only. Saves raw JSON. Read-only."""
import json, sys, time, urllib.request, os

OUTDIR = "/home/heisenberg/CA/phase-stake/analysis"
MINT = "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG"
PROG = "SPMBzsVUuoHA4Jm6KunbsotaahvVikZs1JyTW6iJvbn"

ENDPOINTS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-mainnet.rpc.extrnode.com",
    "https://solana.api.onfinality.io/public",
]

CALLS = {
    "tla_raw.json": ("getTokenLargestAccounts", [MINT]),
    "gpa_type1.json": ("getProgramAccounts", [PROG, {
        "encoding": "base64",
        "filters": [{"dataSize": 611}, {"memcmp": {"offset": 0, "bytes": "2"}}],
        "dataSlice": {"offset": 0, "length": 300},
    }]),
}

def post(url, method, params, timeout=45):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def main():
    budget = float(sys.argv[1]) if len(sys.argv) > 1 else 600.0
    start = time.time()
    pending = dict(CALLS)
    done = {}
    # load prior successes
    for fn in CALLS:
        p = os.path.join(OUTDIR, fn)
        if os.path.exists(p):
            try:
                d = json.load(open(p))
                if "result" in d:
                    done[fn] = d
            except Exception:
                pass
    for fn in list(done):
        pending.pop(fn, None)
    attempt = 0
    while pending and time.time() - start < budget:
        for fn, (method, params) in list(pending.items()):
            for url in ENDPOINTS:
                attempt += 1
                try:
                    d = post(url, method, params)
                    if "result" in d:
                        json.dump({"endpoint": url, "method": method, "params": params, "response": d},
                                  open(os.path.join(OUTDIR, fn), "w"), indent=2)
                        print(f"[{time.strftime('%H:%M:%S')}] OK {fn} via {url} after {attempt} attempts", flush=True)
                        pending.pop(fn)
                        break
                    else:
                        msg = json.dumps(d.get("error", d))[:110]
                        print(f"[{time.strftime('%H:%M:%S')}] {fn} {url} -> {msg}", flush=True)
                except Exception as e:
                    print(f"[{time.strftime('%H:%M:%S')}] {fn} {url} -> exc {str(e)[:90]}", flush=True)
                time.sleep(12)
        if pending:
            time.sleep(20)
    print("DONE. pending:", list(pending), "elapsed %.0fs" % (time.time() - start), flush=True)

if __name__ == "__main__":
    main()
