#!/usr/bin/env python3
"""Threaded selective follow-up detail reads — READ-ONLY, keyless RPCs.
Only markets with value (attributions/supply>0) get the expensive detail set."""
import json
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/124 Safari/537.36"

RPCS = {
    "arbitrum": ["https://arb1.arbitrum.io/rpc", "https://arbitrum-one.publicnode.com"],
    "optimism": ["https://mainnet.optimism.io", "https://optimism.publicnode.com"],
    "astar": ["https://evm.astar.network", "https://astar.api.onfinality.io/public"],
}

SEL = {
    "attributionDebt": "0xefb6f55c",
    "lockedAmount": "0x6ab28bc8",
    "totalCredit": "0xa43d6404",
    "rewardPerCredit": "0x1e34b3d7",
    "pendingEnd": "0xca145f34",
    "allInsuranceCount": "0x9d4c6d91",
    "totalAllocatedCredit": "0xb1b044de",
    "totalAllocPoint": "0x17caf6f1",
    "targetLev": "0x5b4fb573",
    "marketStatus": "0xe0e081d7",
    "paused": "0x5c975abb",
    "locked": "0xcf309012",
    "totalLiquidity": "0x15770f92",
    "originalLiquidity": "0x00d89ed6",
    "availableBalance": "0xab2f0e51",
    "debts": "0x2ecd4e7d",
    "attributions": "0x6b4067af",
    "underlyingValue": "0x2f9ef012",
}
EXTRA_INDEX = ["totalAllocatedCredit", "totalAllocPoint", "targetLev"]


def rpc_call(rpcs, method, params, timeout=40, retries=3):
    last = None
    for _ in range(retries):
        for url in rpcs:
            try:
                payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
                req = urllib.request.Request(
                    url, data=json.dumps(payload).encode(),
                    headers={"Content-Type": "application/json", "User-Agent": UA},
                )
                with urllib.request.urlopen(req, timeout=timeout) as r:
                    body = json.load(r)
                if "result" in body:
                    return body["result"], None
                last = f"{url}: {body.get('error', {}).get('message')}"
            except Exception as e:
                last = f"{url}: {e!r}"
    return None, last


def eth_call(rpcs, to, data):
    return rpc_call(rpcs, "eth_call", [{"to": to, "data": data}, "latest"])


def dec(h):
    if h is None or h == "0x":
        return None
    try:
        return int(h, 16)
    except Exception:
        return None


def pad(a):
    return a.lower().replace("0x", "").rjust(64, "0")


def fetch_market(chain, rpcs, m, info, vault):
    det = {}
    keys = ["attributionDebt", "lockedAmount", "totalCredit", "rewardPerCredit",
            "pendingEnd", "allInsuranceCount", "marketStatus", "paused", "locked",
            "totalLiquidity", "originalLiquidity", "availableBalance"]
    if info.get("symbol") == "iIndex":
        keys += EXTRA_INDEX
    for key in keys:
        res, _ = eth_call(rpcs, m, SEL[key])
        det[key] = dec(res)
    det["vault_debts_live"] = dec(eth_call(rpcs, vault, SEL["debts"] + pad(m))[0])
    det["vault_attributions_live"] = dec(eth_call(rpcs, vault, SEL["attributions"] + pad(m))[0])
    det["vault_underlyingValue_live"] = dec(eth_call(rpcs, vault, SEL["underlyingValue"] + pad(m))[0])
    return m, det


def main():
    state = json.load(open("state.json"))
    for chain, v in state.items():
        rpcs = RPCS[chain]
        bn, _ = rpc_call(rpcs, "eth_blockNumber", [])
        v["followup_block"] = int(bn, 16) if bn else None
        vault = v["vault"]
        targets = []
        for m, info in v["markets_info"].items():
            if (info.get("vault_attributions") or 0) > 0 or (info.get("totalSupply") or 0) > 0:
                targets.append((m, info))
        print(f"##### {chain} block {v['followup_block']} — {len(targets)} active markets #####", flush=True)
        with ThreadPoolExecutor(max_workers=8) as ex:
            futs = [ex.submit(fetch_market, chain, rpcs, m, info, vault) for m, info in targets]
            for f in as_completed(futs):
                m, det = f.result()
                v["markets_info"][m]["detail"] = det
                print(f"  {m} status={det['marketStatus']} attrDebt={det['attributionDebt']} "
                      f"locked={det['lockedAmount']} credit={det['totalCredit']} OL={det['originalLiquidity']} "
                      f"TL={det['totalLiquidity']} vDebt={det['vault_debts_live']}", flush=True)
        json.dump(state, open("state.json", "w"), indent=1, default=str)
    print("DONE", flush=True)


if __name__ == "__main__":
    main()
