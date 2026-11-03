#!/usr/bin/env python3
"""Record the exact on-chain revert for withdraw() on the top-funded expired pools
and confirm the largest open pool passes the expiry gate. Read-only."""
import json
import os
import urllib.request

U = os.environ.get("ARB_RPC_URL") or "https://arb1.arbitrum.io/rpc"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "expiry_gate.json")

POOLS = {
    "0xdcd2950eec35c7b2f802aa6938462eb460727bf6": "5138.12 USDC.e (2024-03-29)",
    "0x201e2ca8a7c7a6f09f20d80edbc9f9f6caec6614": "5127.39 USDC.e (2024-03-22)",
    "0xa56346b78deea5360e38a058438efc63ff85ed06": "1.8489 WETH (2023-09-15)",
    "0xcdaff5c0040be49e755cbbca2d08ca0c6b19931d": "0.0502 WBTC (2024-02-02)",
    "0x1b25f69cfc2b3a9fcc0a7c0944a81723d5dcd77d": "0.00843 WBTC OPEN (2026-11-06)",
}
# exact key used in the Solidity test: lower=1e15, upper=2e15
CALLDATA = (
    "0x61010234"
    + "0000000000000000000000000000000000000000000000000000000000000001"
    + "0000000000000000000000000000000000000000000000000000000000000001"
    + "00000000000000000000000000000000000000000000000000038d7ea4c68000"  # 1e15
    + "00000000000000000000000000000000000000000000000000071afd498d0000"  # 2e15
    + "0000000000000000000000000000000000000000000000000000000000000002"
    + "0000000000000000000000000000000000000000000000000000000000000001"
    + "0000000000000000000000000000000000000000000000000000000000000000"
    + "0000000000000000000000000000000000000000000000000de0b6b3a7640000"
)

ERR = {
    "0x9b395bce": "Pool__OptionExpired()",
    "0xa7e1bebe": "Pool__OptionNotExpired()",
    "0xc7cbdee3": "Pool__OperatorNotAuthorized(address)",
    "0x16057f52": "Pool__InvalidRange(uint256,uint256)",
    "0x79a41b8e": "Pool__PositionDoesNotExist(address,uint256)",
}


def rpc(method, params):
    req = urllib.request.Request(
        U,
        data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"},
    )
    with urllib.request.urlopen(req, timeout=40) as r:
        return json.loads(r.read())


def main():
    head = int(rpc("eth_blockNumber", [])["result"], 16)
    out = {"block": head, "calls": []}
    for pool, note in POOLS.items():
        d = rpc(
            "eth_call",
            [{"from": "0x0000000000000000000000000000000000000001", "to": pool, "data": CALLDATA}, hex(head)],
        )
        err = d.get("error", {})
        data = err.get("data", "")
        sel = data[:10] if isinstance(data, str) else ""
        out["calls"].append(
            {
                "pool": pool,
                "note": note,
                "revert_data": data,
                "revert": ERR.get(sel, err.get("message", "none")),
            }
        )
        print(pool, note, "->", out["calls"][-1]["revert"])
    json.dump(out, open(OUT, "w"), indent=1)


if __name__ == "__main__":
    main()
