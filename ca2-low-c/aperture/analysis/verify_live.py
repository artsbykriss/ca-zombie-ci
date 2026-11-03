#!/usr/bin/env python3
"""Aperture — CI live-state verifier (no Etherscan key needed).

Uses the committed full enumeration (analysis/live_approvals.json) as the pair
set, then re-reads every live balance / allowance / NFT approval / position at
the current head via public RPCs. This is the reproducible CI half; the full
historical log sweep was done once with Etherscan V2 (see enumerate_approvals.py).
"""
import json, os, sys, time, urllib.request

ROUTER = "0xD83d960deBEC397fB149b51F8F37DD3B5CFA8913"
NFPM = "0xC36442b4a4522e871399cd717aBDD847Ab11FE88"
CHAINS = {
    1: ("ethereum", ["https://eth.drpc.org", "https://1rpc.io/eth", "https://ethereum-rpc.publicnode.com"]),
    42161: ("arbitrum", ["https://arb1.arbitrum.io/rpc", "https://arbitrum.drpc.org"]),
    10: ("optimism", ["https://optimism-rpc.publicnode.com", "https://optimism.drpc.org"]),
    137: ("polygon", ["https://polygon-bor-rpc.publicnode.com", "https://polygon.drpc.org"]),
}
HERE = os.path.dirname(os.path.abspath(__file__))


def http(url, data=None, timeout=60):
    last = None
    for a in range(3):
        try:
            req = urllib.request.Request(url, data=data,
                                         headers={"content-type": "application/json",
                                                  "user-agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode())
        except Exception as e:
            last = e
            time.sleep(2 + 2 * a)
    raise last


def rpc(urls, method, params):
    last = None
    for u in urls:
        try:
            r = http(u, json.dumps({"jsonrpc": "2.0", "id": 1, "method": method,
                                    "params": params}).encode())
            if "error" in r:
                raise RuntimeError(r["error"])
            return r["result"]
        except Exception as e:
            last = e
    raise last


def calls(urls, items):
    res = [None] * len(items)
    for i in range(0, len(items), 40):
        chunk = items[i:i + 40]
        payload = [{"jsonrpc": "2.0", "id": j, "method": "eth_call",
                    "params": [{"to": t, "data": d}, "latest"]}
                   for j, (t, d) in enumerate(chunk)]
        try:
            rr = http(urls[0], json.dumps(payload).encode())
            for j, r in enumerate(rr):
                res[i + j] = r.get("result")
        except Exception:
            for j, (t, d) in enumerate(chunk):
                try:
                    res[i + j] = rpc(urls, "eth_call", [{"to": t, "data": d}, "latest"])
                except Exception:
                    res[i + j] = None
        time.sleep(0.1)
    return res


def u(h):
    return int(h, 16) if h and h != "0x" else 0


def main():
    src = json.load(open(os.path.join(HERE, "live_approvals.json")))
    out = {"router": ROUTER, "chains": {}}
    for cid, (name, urls) in CHAINS.items():
        rows = src["chains"][str(cid)]
        head = int(rpc(urls, "eth_blockNumber", []), 16)
        erc20 = rows["erc20"]
        nft = rows["nft"]
        items = []
        for r in erc20:
            o = r["owner"]
            items.append((r["token"], "0x70a08231" + o[2:].rjust(64, "0")))
            items.append((r["token"], "0xdd62ed3e" + o[2:].rjust(64, "0") +
                          ROUTER[2:].lower().rjust(64, "0")))
        for r in nft:
            tid = int(r["tokenId"])
            items.append((NFPM, "0x6352211e" + hex(tid)[2:].rjust(64, "0")))
            items.append((NFPM, "0x081812fc" + hex(tid)[2:].rjust(64, "0")))
            items.append((NFPM, "0x99fbab88" + hex(tid)[2:].rjust(64, "0")))
        vals = calls(urls, items)
        i = 0
        live_both = []
        for r in erc20:
            bal, allow = u(vals[i]), u(vals[i + 1]); i += 2
            if bal > 0 and allow > 0:
                live_both.append({"token": r["token"], "owner": r["owner"],
                                  "balance_raw": str(bal), "allowance_raw": str(allow),
                                  "reachable_raw": str(min(bal, allow))})
        approved_liq = 0
        approved = 0
        for r in nft:
            own, appr, pos = vals[i], vals[i + 1], vals[i + 2]; i += 3
            is_appr = bool(appr and appr != "0x" and "0x" + appr[-40:] == ROUTER.lower())
            approved += 1 if is_appr else 0
            if pos and pos != "0x" and len(pos) >= 2 + 64 * 12:
                w = [pos[2 + 64 * k:2 + 64 * (k + 1)] for k in range(12)]
                liq, owed0, owed1 = int(w[7], 16), int(w[10], 16), int(w[11], 16)
                if is_appr and (liq > 0 or owed0 > 0 or owed1 > 0):
                    approved_liq += 1
        # For any funded ERC-20 approval, check whether the token is globally paused.
        for x in live_both:
            try:
                pr = rpc(urls, "eth_call", [{"to": x["token"], "data": "0x5c975abb"}, "latest"])
                x["token_paused"] = (pr not in (None, "0x") and int(pr, 16) == 1)
            except Exception:
                x["token_paused"] = None
        native = int(rpc(urls, "eth_getBalance", [ROUTER, "latest"]), 16)
        code = rpc(urls, "eth_getCode", [ROUTER, "latest"])
        out["chains"][str(cid)] = {
            "name": name, "head": head, "code_hex_chars": len(code),
            "native_wei": str(native),
            "erc20_pairs": len(erc20), "nft_pairs": len(nft),
            "erc20_live_both": len(live_both), "live_both": live_both,
            "nft_approved": approved, "nft_approved_with_value": approved_liq,
        }
        print(f"{name}: head={head} erc20_both={len(live_both)} "
              f"nft_approved={approved} approved_value={approved_liq}", file=sys.stderr, flush=True)
    print(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
