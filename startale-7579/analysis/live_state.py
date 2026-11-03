#!/usr/bin/env python3
"""Live-state dump for the Startale ERC-7579 re-initialization re-check.

Read-only. RPC URL comes from the environment (FORK_RPC_URL / RPC_URL) with a keyless
public fallback; no URL or key is ever written to disk. Etherscan key is optional.
"""
import json
import os
import urllib.request
import urllib.error

RPC = os.environ.get("FORK_RPC_URL") or os.environ.get("RPC_URL") or "https://ethereum-rpc.publicnode.com"
ES_KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
IMPL = "0x000000b8f5f723A680d3D7EE624Fe0bC84a6E05A"
FACTORY = "0x0000003B3E7b530b4f981aE80d9350392Defef90"
TOPIC = "0x47e5b5fc3bda028416e26dcf66ca5186488c0717e8ab55bb01806113f1839d58"
OUT = os.path.join(os.path.dirname(__file__), "..", "ci-out", "live-state.json")


ENDPOINTS = [RPC, "https://ethereum-rpc.publicnode.com", "https://1rpc.io/eth", "https://eth.drpc.org"]
_state = {"i": 0}


def rpc(method, params):
    last = None
    for _ in range(len(ENDPOINTS) * 2):
        url = ENDPOINTS[_state["i"] % len(ENDPOINTS)]
        try:
            req = urllib.request.Request(
                url,
                data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"},
            )
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.load(r)
            if "result" in out:
                return out["result"]
            last = out.get("error")
        except Exception as e:  # rotate endpoint on any transport/HTTP error
            last = e
        _state["i"] += 1
    raise RuntimeError(f"all RPC endpoints failed: {last}")


def es(params):
    if not ES_KEY:
        return None
    url = "https://api.etherscan.io/v2/api?chainid=1&" + params + "&apikey=" + ES_KEY
    try:
        with urllib.request.urlopen(url, timeout=45) as r:
            return json.load(r).get("result")
    except Exception:
        return None


def main():
    head = int(rpc("eth_blockNumber", []), 16)
    impl_code = rpc("eth_getCode", [IMPL, "latest"])
    fac_code = rpc("eth_getCode", [FACTORY, "latest"])
    out = {
        "chain": "ethereum",
        "block": head,
        "impl": IMPL,
        "impl_code_bytes": (len(impl_code) - 2) // 2,
        "factory": FACTORY,
        "factory_code_bytes": (len(fac_code) - 2) // 2,
        "note": "keccak256(codehash) constants are asserted inside the Foundry tests",
        "recent_accounts_200k_blocks": None,
        "recent_window": [head - 200000, head],
    }
    if ES_KEY:
        logs = es(
            "module=logs&action=getLogs&fromBlock=%d&toBlock=%d&address=%s&topic0=%s"
            % (head - 200000, head, FACTORY, TOPIC)
        )
        out["recent_accounts_200k_blocks"] = len(logs) if isinstance(logs, list) else None
    # residual balances of the 13 accounts that still hold ETH (from analysis/prefund_scan.json)
    try:
        scan = json.load(open(os.path.join(os.path.dirname(__file__), "prefund_scan.json")))
        holding = [o for o in scan if (o.get("now_wei") or 0) > 0]
        out["accounts_still_holding_eth"] = [
            {"account": o["account"], "wei": o["now_wei"]} for o in holding
        ]
        out["accounts_scanned"] = len(scan)
        out["prefund_eth_total"] = sum((o.get("prefund_wei") or 0) for o in scan) / 1e18
        out["prefund_eth_max"] = max(((o.get("prefund_wei") or 0) for o in scan), default=0) / 1e18
    except Exception as e:
        out["prefund_note"] = str(e)
    # ETH/USD from Chainlink (on-chain, no external price API needed)
    try:
        ans = rpc("eth_call", [{"to": "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419", "data": "0x50d25bcd"}, "latest"])
        out["eth_usd_chainlink"] = int(ans, 16) / 1e8
    except Exception:
        pass
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, "w"), indent=2)
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
