#!/usr/bin/env python3
"""
scan_multichain.py — breadth note: the same UniswapV4Router04 runtime code is deployed at the same
address on several chains. Enumerate Approval(owner, spender=ROUTER) events on each, then read live
allowance/balance for every distinct (token, owner) pair.

Read-only. Etherscan V2 key is read from the environment (ETHERSCANV2_API_KEY); never written to disk.
"""
import os, sys, json, time, urllib.request, urllib.parse

ROUTER = "0x00000000000044a361ae3cac094c9d1b14eece97"
T0 = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
T2 = "0x000000000000000000000000" + ROUTER[2:]
EK = os.environ["ETHERSCANV2_API_KEY"]
CHAINS = {"base": 8453, "arbitrum": 42161, "optimism": 10, "polygon": 137, "unichain": 130}


def es(chain, params, retry=4):
    p = dict(params); p["chainid"] = chain; p["apikey"] = EK
    url = "https://api.etherscan.io/v2/api?" + urllib.parse.urlencode(p)
    for a in range(retry):
        try:
            return json.load(urllib.request.urlopen(url, timeout=60))
        except Exception:
            time.sleep(2 * (a + 1))
    return {"status": "0", "message": "ERR", "result": []}


def get_logs_range(chain, lo, hi, out):
    r = es(chain, {"module": "logs", "action": "getLogs", "fromBlock": lo, "toBlock": hi, "topic0": T0, "topic2": T2})
    res = r.get("result")
    if not isinstance(res, list):
        res = []
    if len(res) >= 1000 and hi > lo:
        mid = (lo + hi) // 2
        get_logs_range(chain, lo, mid, out)
        get_logs_range(chain, mid + 1, hi, out)
    else:
        out.extend(res)


def main():
    allres = {}
    for name, cid in CHAINS.items():
        out = []
        # find deployment via contract creation, else start at 0
        dep = 0
        cr = es(cid, {"module": "contract", "action": "getcontractcreation", "contractaddresses": ROUTER})
        try:
            dep = int(cr["result"][0]["blockNumber"])
        except Exception:
            dep = 0
        # head
        bn = es(cid, {"module": "proxy", "action": "eth_blockNumber", "apikey": EK})
        try:
            head = int(bn["result"], 16)
        except Exception:
            head = 30_000_000
        get_logs_range(cid, dep, head, out)
        erc20 = [l for l in out if len(l["topics"]) == 3]
        pairs = {}
        for l in erc20:
            tok = l["address"].lower()
            owner = "0x" + l["topics"][1][-40:]
            bn_ = int(l["blockNumber"], 16)
            prev = pairs.get((tok, owner))
            if prev is None or bn_ >= prev[0]:
                pairs[(tok, owner)] = (bn_, l["data"])
        allres[name] = {"chainid": cid, "deploy": dep, "head": head,
                        "n_logs": len(erc20), "pairs": [[k[0], k[1], v[1]] for k, v in pairs.items()]}
        print(f"[{name}] deploy {dep} head {head} approval-logs {len(erc20)} distinct-pairs {len(pairs)}", flush=True)
    json.dump(allres, open("multichain_approvals.json", "w"))


if __name__ == "__main__":
    main()
