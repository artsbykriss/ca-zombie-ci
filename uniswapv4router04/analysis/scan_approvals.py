#!/usr/bin/env python3
"""
scan_approvals.py — enumerate every ERC20 Approval(owner, spender=ROUTER) event for the
UniswapV4Router04 target, then read live allowance/balance for each distinct (token, owner).

Read-only. RPC endpoint comes from the environment (RPC / NODEREAL_ETH_RPC_URL / RPC_URL);
the URL/key is NEVER written to disk. Output JSON is written next to this script.

Usage:
    export RPC=<keyless-or-keyed ethereum rpc>   # required
    python3 scan_approvals.py [--out approvals_raw.json]
"""
import os, sys, json, time, urllib.request

ROUTER = "0x00000000000044a361ae3cac094c9d1b14eece97"
TOPIC0_APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
TOPIC2_ROUTER = "0x000000000000000000000000" + ROUTER[2:]
DEPLOY_BLOCK = 22281170

RPC = os.environ.get("RPC") or os.environ.get("NODEREAL_ETH_RPC_URL") or os.environ.get("RPC_URL")
assert RPC, "set RPC (or NODEREAL_ETH_RPC_URL / RPC_URL) in the environment"


def rpc(method, params, _retry=5):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for a in range(_retry):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"content-type": "application/json"})
            r = json.load(urllib.request.urlopen(req, timeout=90))
            if "error" in r:
                raise RuntimeError(r["error"])
            return r["result"]
        except Exception as e:
            if a == _retry - 1:
                raise
            time.sleep(1.5 * (a + 1))


def main():
    out = sys.argv[sys.argv.index("--out") + 1] if "--out" in sys.argv else "approvals_raw.json"
    head = int(rpc("eth_blockNumber", []), 16)
    print(f"[scan] head block {head}")
    logs = []
    CHUNK = 50000  # nodereal public cap
    b = DEPLOY_BLOCK
    t0 = time.time()
    while b <= head:
        to = min(b + CHUNK - 1, head)
        got = rpc("eth_getLogs", [{
            "fromBlock": hex(b), "toBlock": hex(to),
            "topics": [TOPIC0_APPROVAL, None, TOPIC2_ROUTER],
        }])
        logs.extend(got)
        print(f"[scan] {hex(b)}..{hex(to)} -> {len(got)} (total {len(logs)}) {time.time()-t0:.0f}s", flush=True)
        b = to + 1
    # split ERC20 (3 topics) vs ERC721 (4 topics)
    erc20 = [l for l in logs if len(l["topics"]) == 3]
    erc721 = [l for l in logs if len(l["topics"]) == 4]
    print(f"[scan] total {len(logs)}  erc20-approvals {len(erc20)}  erc721-approvals {len(erc721)}")
    res = {"router": ROUTER, "head_block": head, "deploy_block": DEPLOY_BLOCK,
           "n_logs": len(logs), "n_erc20": len(erc20), "n_erc721": len(erc721),
           "erc20": erc20, "erc721": erc721}
    with open(out, "w") as f:
        json.dump(res, f)
    print(f"[scan] wrote {out}")


if __name__ == "__main__":
    main()
