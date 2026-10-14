"""Fast batched live-state enumeration for Orbit Protocol (Blast). Read-only, keyless RPCs."""
import json
import os
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import os as _os
RPCS = ([_os.environ["BLAST_RPC_URL"]] if _os.environ.get("BLAST_RPC_URL") else []) + \
       ["https://81457.rpc.thirdweb.com", "https://blast-rpc.publicnode.com",
        "https://blast.drpc.org", "https://rpc.blast.io"]
_PREFERRED = []


def pick_rpc():
    """Probe RPCs once; return an ordered list starting with healthy endpoints."""
    global _PREFERRED
    if _PREFERRED:
        return _PREFERRED
    ok = []
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode()
    for url in RPCS:
        try:
            req = urllib.request.Request(url, data=body, headers={
                "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=8) as r:
                if "result" in json.loads(r.read()):
                    ok.append(url)
        except Exception:  # noqa: BLE001
            continue
    _PREFERRED = ok + [u for u in RPCS if u not in ok]
    return _PREFERRED

S = {
    "getAllMarkets": "0xb0772d0b", "closeFactorMantissa": "0xe8755446",
    "liquidationIncentiveMantissa": "0x4ada90af", "oracle": "0x7dc0d1d0",
    "admin": "0xf851a440", "pendingAdmin": "0x26782247", "pauseGuardian": "0x24a3d622",
    "comptrollerImplementation": "0xbb82aa5e", "markets": "0x8e8f294b",
    "borrowGuardianPaused": "0x6d154ea5", "mintGuardianPaused": "0x731f0c2b",
    "transferGuardianPaused": "0x1e5f6a04", "seizeGuardianPaused": "0x9a5a5c5e",
    "borrowCaps": "0x4a584432", "supplyCaps": "0x02c3bcbb",
    "compRate": "0xaa900754", "comp": "0xacc2166a", "rewardDistributor": "0x109d0af8",
    "underlying": "0x6f307dc3", "getCash": "0x3b1d21a2", "totalBorrows": "0x47bd3718",
    "totalSupply": "0x18160ddd", "totalReserves": "0x8f840ddd",
    "exchangeRateStored": "0x182df0f5", "exchangeRateCurrent": "0xbd6d894d",
    "reserveFactorMantissa": "0x173b9904", "interestRateModel": "0xf3fdb15a",
    "comptroller": "0x5fe3b567", "implementation": "0x5c60da1b",
    "accrualBlockNumber": "0x6c540baf", "decimals": "0x313ce567",
    "name": "0x06fdde03", "symbol": "0x95d89b41",
    "borrowRatePerBlock": "0xf8f9da28", "supplyRatePerBlock": "0xae9d70b0",
    "getUnderlyingPrice": "0xfc57d4df", "getAssetPrice": "0xb3596f07",
    "owner": "0x8da5cb5b", "isPriceOracle": "0x99e937aa",
    "getAccountLiquidity": "0x5ec88c79", "getHypotheticalAccountLiquidity": "0x6a56947e",
    "totalBorrowsCurrent": "0x73acee98",
}


def batch(items, block, chunk=40, retries=3):
    """items: list of (to, data). Returns list of hex results.

    A returned None means transport failure (unknown); the string "__REVERT__"
    means the node executed the call and it reverted (definitive).
    """
    REVERT = "__REVERT__"

    def classify_err(err):
        if not isinstance(err, dict):
            return None
        msg = (err.get("message") or "") + " " + str(err.get("data") or "")
        code = err.get("code")
        if code == 3 or "revert" in msg.lower() or "invalid opcode" in msg.lower():
            return REVERT
        return None  # retryable (header not found, rate limit, etc.)

    res = [None] * len(items)
    for i, (t0, d0) in enumerate(items):
        if not t0 or not d0:
            res[i] = REVERT
    for i in range(0, len(items), chunk):
        part = items[i:i + chunk]
        reqs = [{"jsonrpc": "2.0", "id": j, "method": "eth_call",
                 "params": [{"to": t, "data": d}, hex(block)]} for j, (t, d) in enumerate(part)]
        body = json.dumps(reqs).encode()
        got = False
        for attempt in range(retries):
            print(f"    batch {i//chunk+1}/{(len(items)+chunk-1)//chunk} try {attempt+1}", file=__import__('sys').stderr, flush=True)
            for url in pick_rpc():
                try:
                    req = urllib.request.Request(url, data=body, headers={
                        "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                    with urllib.request.urlopen(req, timeout=20) as r:
                        out = json.loads(r.read())
                    if isinstance(out, list):
                        for o in out:
                            if "result" in o:
                                res[i + o["id"]] = o["result"]
                            elif "error" in o:
                                res[i + o["id"]] = classify_err(o["error"])
                        got = True
                        break
                except Exception:  # noqa: BLE001
                    continue
            if got:
                break
            time.sleep(1.5 * (attempt + 1))
    # retry transport-missing entries individually (reverts are definitive)
    for _ in range(2):
        missing = [k for k, v in enumerate(res) if v is None]
        if not missing:
            break
        for k in missing:
            t, d = items[k]
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                               "params": [{"to": t, "data": d}, hex(block)]}).encode()
            for url in pick_rpc():
                try:
                    req = urllib.request.Request(url, data=body, headers={
                        "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                    with urllib.request.urlopen(req, timeout=15) as r:
                        out = json.loads(r.read())
                    if "result" in out:
                        res[k] = out["result"]
                        break
                    if "error" in out:
                        res[k] = classify_err(out["error"]) or res[k]
                        break
                except Exception:  # noqa: BLE001
                    continue
        time.sleep(0.3)
    return res


def latest():
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode()
    for url in pick_rpc():
        try:
            req = urllib.request.Request(url, data=body, headers={
                "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=20) as r:
                return int(json.loads(r.read())["result"], 16)
        except Exception:  # noqa: BLE001
            continue
    raise RuntimeError("no rpc")


def bal_batch(addrs, block):
    reqs = [{"jsonrpc": "2.0", "id": j, "method": "eth_getBalance", "params": [a, hex(block)]}
            for j, a in enumerate(addrs)]
    body = json.dumps(reqs).encode()
    for url in pick_rpc():
        try:
            req = urllib.request.Request(url, data=body, headers={
                "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                out = json.loads(r.read())
            if isinstance(out, list):
                res = [None] * len(addrs)
                for o in out:
                    if "result" in o:
                        res[o["id"]] = int(o["result"], 16)
                return res
        except Exception:  # noqa: BLE001
            continue
    return [None] * len(addrs)


def words(h):
    h = h[2:] if h.startswith("0x") else h
    return [h[i:i + 64] for i in range(0, len(h) - 63, 64)]


def u(h):
    if not h or h == "0x" or h == "__REVERT__":
        return None
    return int(h, 16)


def a20(h):
    return "0x" + h[-40:] if h and len(h) >= 40 else None


def a20s(h):
    w = words(h) if h and h != "__REVERT__" else []
    return a20(w[0]) if w and len(w[0]) >= 40 else None


def dec_str(h):
    if not h or h == "0x":
        return None
    try:
        w = words(h)
        off = int(w[0], 16)
        ln = int(w[off // 32], 16)
        return bytes.fromhex(h[2 + off * 2: 2 + off * 2 + ln * 2]).decode("utf-8", "replace")
    except Exception:  # noqa: BLE001
        return None


def word_addr(a):
    if not (isinstance(a, str) and a.startswith("0x") and len(a) == 42):
        return None
    return a[2:].rjust(64, "0")


COMPTROLLERS = {
    "c1": "0x1E18C3cb491D908241D0db14b081B51be7B6e652",
    "c2": "0x273683CA19D9CF827628EE216E4a9604EfB077A3",
    "c3": "0xe9266ae95bB637A7Ad598CB0390d44262130F433",
    "c4": "0xfFF8Fc176697D04607cF4e23E91c65ed"[:0] + "0xfFF8Fc176697D04607cF4e23E91c65aeD1c3d3F5",
}


def main():
    blk = latest()
    print(f"block {blk}", flush=True)
    out = {"block": blk, "comptrollers": {}, "oracles": {}, "underlyings": {}}

    # 1) comptroller-level reads
    items = []
    keys = []
    for lab, c in COMPTROLLERS.items():
        for k in ("admin", "pendingAdmin", "pauseGuardian", "oracle", "comptrollerImplementation"):
            items.append((c, S[k])); keys.append((lab, k))
        for k in ("closeFactorMantissa", "liquidationIncentiveMantissa",
                  "transferGuardianPaused", "seizeGuardianPaused", "compRate"):
            items.append((c, S[k])); keys.append((lab, k))
        items.append((c, S["getAllMarkets"])); keys.append((lab, "getAllMarkets"))
    r = batch(items, blk)
    cm = {lab: {"address": c, "markets": []} for lab, c in COMPTROLLERS.items()}
    market_order = []
    for (lab, k), h in zip(keys, r):
        if k == "getAllMarkets":
            if not h:
                continue
            w = words(h)
            n = int(w[1], 16)
            mk = [a20(x) for x in w[2:2 + n]]
            cm[lab]["markets"] = mk
            for m in mk:
                if m not in market_order:
                    market_order.append(m)
        elif k in ("closeFactorMantissa", "liquidationIncentiveMantissa",
                   "transferGuardianPaused", "seizeGuardianPaused", "compRate"):
            cm[lab][k] = u(h)
        else:
            cm[lab][k] = a20(words(h)[0]) if h and len(h) >= 66 else None
    print("markets:", len(market_order), flush=True)

    # 2) market-level reads
    items = []
    keys = []
    mkeys = ("underlying", "getCash", "totalBorrows", "totalSupply", "totalReserves",
             "exchangeRateStored", "exchangeRateCurrent", "reserveFactorMantissa",
             "interestRateModel", "comptroller", "admin", "pendingAdmin", "implementation",
             "accrualBlockNumber", "decimals", "borrowRatePerBlock", "supplyRatePerBlock")
    for m in market_order:
        for k in mkeys:
            items.append((m, S[k])); keys.append((m, k))
        items.append((m, S["name"])); keys.append((m, "name"))
        items.append((m, S["symbol"])); keys.append((m, "symbol"))
    r = batch(items, blk)
    mstate = {}
    for (m, k), h in zip(keys, r):
        mstate.setdefault(m, {})[k] = h
    # ETH balances for all markets (CEther cash)
    eth = bal_batch(market_order, blk)

    # 3) comptroller views on markets
    items = []
    keys = []
    for lab, c in COMPTROLLERS.items():
        for m in cm[lab]["markets"]:
            items.append((c, S["markets"] + word_addr(m))); keys.append((lab, m, "markets"))
            items.append((c, S["borrowCaps"] + word_addr(m))); keys.append((lab, m, "borrowCap"))
            items.append((c, S["supplyCaps"] + word_addr(m))); keys.append((lab, m, "supplyCap"))
            items.append((c, S["mintGuardianPaused"] + word_addr(m))); keys.append((lab, m, "mintPaused"))
            items.append((c, S["borrowGuardianPaused"] + word_addr(m))); keys.append((lab, m, "borrowPaused"))
    r = batch(items, blk)
    cviews = {}
    for (lab, m, k), h in zip(keys, r):
        cviews.setdefault((lab, m), {})[k] = h

    # 4) oracle reads
    oracles = sorted({cm[l]["oracle"] for l in cm if cm[l].get("oracle")})
    items = []
    keys = []
    for o in oracles:
        for k in ("owner", "admin", "pendingAdmin"):
            items.append((o, S[k])); keys.append((o, k))
        for m in market_order:
            items.append((o, S["getUnderlyingPrice"] + word_addr(m))); keys.append((o, "price", m))
    r = batch(items, blk)
    for (o, k, *rest), h in zip(keys, r):
        od = out["oracles"].setdefault(o, {"address": o, "prices": {}})
        if k == "price":
            od["prices"][rest[0]] = u(h)
        else:
            od[k] = a20(words(h)[0]) if h and len(h) >= 66 else None

    # 5) underlying token metadata
    underlyings = sorted({x for x in (a20s(mstate[m].get("underlying")) for m in market_order) if x})
    items = []
    keys = []
    for t in underlyings:
        items.append((t, S["symbol"])); keys.append((t, "symbol"))
        items.append((t, S["decimals"])); keys.append((t, "decimals"))
        items.append((t, S["totalSupply"])); keys.append((t, "totalSupply"))
    r = batch(items, blk)
    for (t, k), h in zip(keys, r):
        out["underlyings"].setdefault(t, {})[k] = dec_str(h) if k == "symbol" else u(h)

    # assemble
    for lab, c in COMPTROLLERS.items():
        ce = cm[lab]
        ce["code_size"] = None
        ce["compRate"] = ce.get("compRate")
        ce["comp"] = ce.get("comp")
        ce["rewardDistributor"] = ce.get("rewardDistributor")
        ce["markets_detail"] = []
        for m in ce["markets"]:
            st = mstate.get(m, {})
            cv = cviews.get((lab, m), {})
            md = {"market": m, "symbol": dec_str(st.get("symbol")), "name": dec_str(st.get("name")),
                  "decimals": u(st.get("decimals")),
                  "underlying": a20s(st.get("underlying")),
                  "eth_balance": eth[market_order.index(m)] if m in market_order else None,
                  "getCash": u(st.get("getCash")), "totalBorrows": u(st.get("totalBorrows")),
                  "totalSupply": u(st.get("totalSupply")), "totalReserves": u(st.get("totalReserves")),
                  "exchangeRateStored": u(st.get("exchangeRateStored")),
                  "exchangeRateCurrent": u(st.get("exchangeRateCurrent")),
                  "reserveFactorMantissa": u(st.get("reserveFactorMantissa")),
                  "interestRateModel": a20s(st.get("interestRateModel")),
                  "cTokenAdmin": a20s(st.get("admin")),
                  "cTokenPendingAdmin": a20s(st.get("pendingAdmin")),
                  "implementation": a20s(st.get("implementation")),
                  "accrualBlockNumber": u(st.get("accrualBlockNumber")),
                  "borrowRatePerBlock": u(st.get("borrowRatePerBlock")),
                  "supplyRatePerBlock": u(st.get("supplyRatePerBlock"))}
            if cv.get("markets") and cv["markets"] != "__REVERT__" and words(cv["markets"]):
                w = words(cv["markets"])
                md["isListed"] = int(w[0], 16) == 1
                md["collateralFactorMantissa"] = int(w[1], 16)
                md["isComped"] = int(w[2], 16) == 1
            md["borrowCap"] = u(cv.get("borrowCap"))
            md["supplyCap"] = u(cv.get("supplyCap"))
            md["mintGuardianPaused"] = u(cv.get("mintPaused"))
            md["borrowGuardianPaused"] = u(cv.get("borrowPaused"))
            ce["markets_detail"].append(md)
        del ce["markets"]
        ce["markets"] = [md["market"] for md in ce["markets_detail"]]
        out["comptrollers"][lab] = ce

    # code sizes
    reqs = [{"jsonrpc": "2.0", "id": j, "method": "eth_getCode", "params": [a, hex(blk)]}
            for j, a in enumerate(list(COMPTROLLERS.values()) + market_order + oracles)]
    body = json.dumps(reqs).encode()
    for url in RPCS:
        try:
            req = urllib.request.Request(url, data=body, headers={
                "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=40) as r2:
                lst = json.loads(r2.read())
            sizes = {}
            alladdrs = list(COMPTROLLERS.values()) + market_order + oracles
            for o in lst:
                if "result" in o:
                    sizes[alladdrs[o["id"]]] = (len(o["result"]) - 2) // 2
            for lab, c in COMPTROLLERS.items():
                out["comptrollers"][lab]["code_size"] = sizes.get(c)
            for m in market_order:
                for lab in out["comptrollers"]:
                    for md in out["comptrollers"][lab]["markets_detail"]:
                        if md["market"] == m:
                            md["code_size"] = sizes.get(m)
            for o in oracles:
                out["oracles"][o]["code_size"] = sizes.get(o)
            break
        except Exception:  # noqa: BLE001
            continue

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "live_state.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("wrote live_state.json", flush=True)


if __name__ == "__main__":
    main()
