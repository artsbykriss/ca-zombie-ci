#!/usr/bin/env python3
"""Check which of the pool counterparties are contracts (glif RPC), with balances. Read-only."""
import json, urllib.request, time

ENDPOINTS = ["https://api.node.glif.io/rpc/v1", "https://filecoin.chainup.net/rpc/v1",
             "https://filecoin.blockscout.com/api/eth-rpc"]
HDRS = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def rpc(method, params, tries=4):
    last = None
    for i in range(tries):
        ep = ENDPOINTS[min(i, len(ENDPOINTS) - 1)]
        try:
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
            req = urllib.request.Request(ep, data=body, headers=HDRS)
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read().decode())
            if "error" in out:
                last = out["error"]; time.sleep(1); continue
            return out.get("result")
        except Exception as e:
            last = str(e); time.sleep(2 + 2 * i)
    return "RPCFAIL:" + str(last)

def main():
    cps = json.load(open("pool_counterparties.json"))
    addrs = [a for a in cps if a.lower() != "0x587a7eae9b461ad724391aa7195210e0547ed11d"]
    out = {}
    for a in sorted(addrs, key=lambda x: -cps[x]):
        code = rpc("eth_getCode", [a, "latest"])
        bal = rpc("eth_getBalance", [a, "latest"])
        n = (len(code) - 2) // 2 if isinstance(code, str) and code.startswith("0x") else -1
        out[a] = {"code_bytes": n, "balance_wei": bal, "tx_count_with_pool": cps[a]}
        json.dump(out, open("counterparty_codes.json", "w"), indent=1)
        print(a, "code", n, "bal", bal, "n", cps[a], flush=True)

if __name__ == "__main__":
    main()
