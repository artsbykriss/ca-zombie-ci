#!/usr/bin/env python3
"""Aperture Finance router 0xD83d960deBEC397fB149b51F8F37DD3B5CFA8913
Live approval / reachable-value enumeration (read-only).

For every Approval(owner, spender=router, value) log ever emitted on
Ethereum / Arbitrum / Optimism / Polygon, take the LAST approval per
(token, owner), then read live allowance + balance at the chain head.
ERC-721 approvals are the Uniswap V3 NonfungiblePositionManager; those are
resolved to ownerOf/getApproved/positions(liquidity,tokensOwed).

Outputs analysis/live_approvals.json (no secrets, public RPCs only).
"""
import json, os, time, urllib.request, urllib.error

ROUTER = "0xD83d960deBEC397fB149b51F8F37DD3B5CFA8913"
NFPM = "0xC36442b4a4522e871399cd717aBDD847Ab11FE88"
T_APPROVAL = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925"
T2 = "0x" + ROUTER[2:].lower().rjust(64, "0")

CHAINS = {
    1: dict(name="ethereum", llama="ethereum", deploy=24020090,
            rpc="https://eth.drpc.org",
            rpc2=["https://1rpc.io/eth","https://ethereum-rpc.publicnode.com"],
            scan="etherscan"),
    42161: dict(name="arbitrum", llama="arbitrum", deploy=410993527,
                rpc="https://arb1.arbitrum.io/rpc",
                rpc2=["https://arbitrum.drpc.org"],
                scan="etherscan"),
    10: dict(name="optimism", llama="optimism", deploy=0,
             rpc="https://optimism-rpc.publicnode.com",
             rpc2=["https://optimism.drpc.org"],
             scan="blockscout", bs="https://explorer.optimism.io"),
    137: dict(name="polygon", llama="polygon", deploy=80238140,
              rpc="https://polygon-bor-rpc.publicnode.com",
              rpc2=["https://polygon.drpc.org"],
              scan="etherscan"),
}

ES_KEY = os.environ.get("ETHERSCANV2_API_KEY", "")


def http(url, data=None, timeout=90):
    last = None
    for attempt in range(3):
        try:
            req = urllib.request.Request(url, data=data,
                                         headers={"content-type": "application/json",
                                                  "user-agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode())
        except Exception as e:
            last = e
            time.sleep(2 + attempt * 3)
    raise last


def rpc(url, method, params):
    r = http(url, json.dumps({"jsonrpc": "2.0", "id": 1, "method": method,
                              "params": params}).encode())
    if "error" in r:
        raise RuntimeError(f"{method}: {r['error']}")
    return r["result"]


def rpc_multi(c, method, params):
    last = None
    for url in [c["rpc"]] + c.get("rpc2", []):
        try:
            return rpc(url, method, params)
        except Exception as e:
            last = e
    raise last


def get_logs(chain):
    c = CHAINS[chain]
    out = []
    if c["scan"] == "etherscan":
        page = 1
        while True:
            url = (f"https://api.etherscan.io/v2/api?chainid={chain}"
                   f"&module=logs&action=getLogs&fromBlock={c['deploy']}"
                   f"&toBlock=latest&topic0={T_APPROVAL}&topic2={T2}"
                   f"&topic0_2_opr=and&page={page}&offset=1000&apikey={ES_KEY}")
            r = http(url)
            if r.get("status") != "1":
                if r.get("message") == "No records found":
                    break
                raise RuntimeError(f"etherscan {chain}: {r}")
            batch = r["result"]
            out += batch
            if len(batch) < 1000:
                break
            page += 1
            time.sleep(0.3)
    else:
        page = 1
        while True:
            url = (f"{c['bs']}/api?module=logs&action=getLogs&fromBlock=0"
                   f"&toBlock=latest&topic0={T_APPROVAL}&topic2={T2}"
                   f"&topic0_2_opr=and&page={page}&offset=1000")
            r = http(url)
            batch = r.get("result") or []
            if not isinstance(batch, list):
                break
            out += batch
            if len(batch) < 1000:
                break
            page += 1
            time.sleep(0.3)
    return out


def latest_per_pair(logs):
    best = {}
    for lg in logs:
        token = lg["address"].lower()
        owner = "0x" + lg["topics"][1][-40:]
        key = (token, owner)
        li = lg.get("logIndex", "0")
        try:
            li = int(li, 16) if str(li).startswith("0x") else int(li)
        except ValueError:
            li = 0
        marker = (int(lg["blockNumber"], 16), li)
        if key not in best or marker > best[key][0]:
            best[key] = (marker, lg)
    return {k: v[1] for k, v in best.items()}


def eth_calls(url, calls, fallbacks=None):
    """calls = [(to, data)] -> list of hex strings"""
    res = [None] * len(calls)
    for i in range(0, len(calls), 40):
        chunk = calls[i:i + 40]
        payload = [{"jsonrpc": "2.0", "id": j,
                    "method": "eth_call",
                    "params": [{"to": to, "data": data}, "latest"]}
                   for j, (to, data) in enumerate(chunk)]
        try:
            rr = http(url, json.dumps(payload).encode())
            for j, r in enumerate(rr):
                res[i + j] = r.get("result")
        except Exception:
            for j, (to, data) in enumerate(chunk):
                res[i + j] = None
                for u in [url] + (fallbacks or []):
                    try:
                        res[i + j] = rpc(u, "eth_call", [{"to": to, "data": data}, "latest"])
                        break
                    except Exception:
                        continue
        time.sleep(0.15)
    return res


def uint(h):
    return int(h, 16) if h and h != "0x" else 0


def main():
    out = {"router": ROUTER, "nfpm": NFPM, "chains": {}}
    for chain, c in CHAINS.items():
        logs = get_logs(chain)
        pairs = latest_per_pair(logs)
        head = int(rpc_multi(c, "eth_blockNumber", []), 16)
        # split ERC20 vs ERC721-NFPM
        erc20 = [(t, o) for (t, o) in pairs if t != NFPM.lower()]
        nft = [(t, o, int(pairs[(t, o)]["topics"][3], 16))
               for (t, o) in pairs if t == NFPM.lower()]

        calls = []
        for t, o in erc20:
            calls.append((t, "0x70a08231" + o[2:].rjust(64, "0")))          # balanceOf(owner)
            calls.append((t, "0xdd62ed3e" + o[2:].rjust(64, "0") + ROUTER[2:].lower().rjust(64, "0")))  # allowance
        for t, o, tid in nft:
            calls.append((t, "0x6352211e" + hex(tid)[2:].rjust(64, "0")))   # ownerOf
            calls.append((t, "0x081812fc" + hex(tid)[2:].rjust(64, "0")))   # getApproved
            calls.append((t, "0x99fbab88" + hex(tid)[2:].rjust(64, "0")))   # positions
        vals = eth_calls(c["rpc"], calls, c.get("rpc2", []))

        i = 0
        erc20_rows = []
        for t, o in erc20:
            bal, allow = uint(vals[i]), uint(vals[i + 1]); i += 2
            erc20_rows.append({"token": t, "owner": o, "balance_raw": str(bal),
                               "allowance_raw": str(allow),
                               "reachable_raw": str(min(bal, allow))})
        nft_rows = []
        for t, o, tid in nft:
            own, appr, pos = vals[i], vals[i + 1], vals[i + 2]; i += 3
            liquidity = 0
            owed0 = owed1 = 0
            if pos and pos != "0x" and len(pos) >= 2 + 64 * 12:
                w = [pos[2 + 64 * k:2 + 64 * (k + 1)] for k in range(12)]
                liquidity = int(w[7], 16)
                owed0, owed1 = int(w[10], 16), int(w[11], 16)
            nft_rows.append({"token": t, "owner": o, "tokenId": tid,
                             "ownerOf": ("0x" + own[-40:]) if own and own != "0x" else None,
                             "getApproved": ("0x" + appr[-40:]) if appr and appr != "0x" else None,
                             "liquidity": str(liquidity),
                             "tokensOwed0": str(owed0), "tokensOwed1": str(owed1)})

        out["chains"][chain] = {
            "name": c["name"], "head": head, "approval_logs": len(logs),
            "distinct_pairs": len(pairs), "erc20_pairs": len(erc20),
            "nft_pairs": len(nft),
            "erc20_live_allowance": sum(1 for r in erc20_rows if int(r["allowance_raw"]) > 0),
            "erc20_live_both": sum(1 for r in erc20_rows if int(r["reachable_raw"]) > 0),
            "nft_live_approved": sum(1 for r in nft_rows
                                     if r["getApproved"] and r["getApproved"].lower() == ROUTER.lower()),
            "nft_live_approved_with_liquidity": sum(1 for r in nft_rows
                                                    if r["getApproved"] and r["getApproved"].lower() == ROUTER.lower()
                                                    and int(r["liquidity"]) > 0),
            "erc20": erc20_rows, "nft": nft_rows,
        }
        print(f"chain {chain} {c['name']}: logs={len(logs)} pairs={len(pairs)} "
              f"erc20_both={out['chains'][chain]['erc20_live_both']} "
              f"nft_approved_liq={out['chains'][chain]['nft_live_approved_with_liquidity']} head={head}",
              flush=True)

    os.makedirs("analysis", exist_ok=True)
    with open("analysis/live_approvals.json", "w") as f:
        json.dump(out, f, indent=1)
    print("wrote analysis/live_approvals.json")


if __name__ == "__main__":
    main()
