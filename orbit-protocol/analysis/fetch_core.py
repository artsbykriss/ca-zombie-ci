"""Targeted core-state fetch for Orbit Protocol (Blast). Threaded, retrying, bounded.

Writes analysis/core_state.json. Read-only, keyless RPCs.
"""
import json
import os
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from enumerate_live2 import RPCS as _RPCS0, words, a20, u, dec_str  # noqa: E402
import etherscan_rpc as ES  # noqa: E402

RPCS = ([os.environ["BLAST_RPC_URL"]] if os.environ.get("BLAST_RPC_URL") else []) + \
       ["https://81457.rpc.thirdweb.com", "https://blast-rpc.publicnode.com",
        "https://blast.drpc.org"]
FALLBACK = "https://rpc.blast.io"
OUTDIR = os.environ.get("CI_OUT", HERE)

_ORDER = []


def pick_rpc():
    """Order RPCs by observed latency (fastest first)."""
    global _ORDER
    if _ORDER:
        return _ORDER
    probe = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                        "params": [{"to": "0x9aecedcd6a82d26f2f86d331b17a1c1676442a87",
                                    "data": "0x3b1d21a2"}, "latest"]}).encode()
    lat = []
    for url in RPCS:
        times = []
        for _ in range(2):
            t0 = time.time()
            try:
                req = urllib.request.Request(url, data=probe, headers={
                    "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=6) as r:
                    if "result" in json.loads(r.read()):
                        times.append(time.time() - t0)
            except Exception:  # noqa: BLE001
                times.append(99.0)
        if times and max(times) < 5:
            lat.append((sum(times) / len(times), url))
    lat.sort()
    _ORDER = [u for _, u in lat] + [u for u in RPCS if u not in [x for _, x in lat]]
    return _ORDER

SEL = {
    "getAllMarkets": "0xb0772d0b", "closeFactorMantissa": "0xe8755446",
    "liquidationIncentiveMantissa": "0x4ada90af", "oracle": "0x7dc0d1d0",
    "admin": "0xf851a440", "pendingAdmin": "0x26782247", "pauseGuardian": "0x24a3d622",
    "comptrollerImplementation": "0xbb82aa5e", "markets": "0x8e8f294b",
    "borrowGuardianPaused": "0x6d154ea5", "mintGuardianPaused": "0x731f0c2b",
    "transferGuardianPaused": "0x1e5f6a04", "seizeGuardianPaused": "0x9a5a5c5e",
    "borrowCaps": "0x4a584432", "compRate": "0xaa900754", "comp": "0xacc2166a",
    "rewardDistributor": "0x109d0af8",
    "underlying": "0x6f307dc3", "getCash": "0x3b1d21a2", "totalBorrows": "0x47bd3718",
    "totalSupply": "0x18160ddd", "totalReserves": "0x8f840ddd",
    "exchangeRateStored": "0x182df0f5", "exchangeRateCurrent": "0xbd6d894d",
    "reserveFactorMantissa": "0x173b9904", "interestRateModel": "0xf3fdb15a",
    "comptroller": "0x5fe3b567", "implementation": "0x5c60da1b",
    "accrualBlockNumber": "0x6c540baf", "decimals": "0x313ce567",
    "name": "0x06fdde03", "symbol": "0x95d89b41", "initialExchangeRateMantissa": "0x6752e702",
    "getUnderlyingPrice": "0xfc57d4df",
    "balanceOf": "0x70a08231", "totalBorrowsCurrent": "0x73acee98",
    "getAccountLiquidity": "0x5ec88c79", "borrowBalanceStored": "0x95dd9193",
}

COMPTROLLERS = {
    "c1": "0x1E18C3cb491D908241D0db14b081B51be7B6e652",
    "c2": "0x273683CA19D9CF827628EE216E4a9604EfB077A3",
    "c3": "0xe9266ae95bB637A7Ad598CB0390d44262130F433",
    "c4": "0xfFF8Fc176697D04607cF4e23E91c65aeD1c3d3F5",
}


_LATEST_OK = [False]


def _rpc_once(url, body, timeout=10):
    req = urllib.request.Request(url, data=body, headers={
        "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def call1(to, data, block, tries=2):
    """eth_call via Etherscan proxy first, then public RPCs."""
    r = ES.eth_call(to, data, "latest")
    if r is not None:
        return r
    tags = ("latest",) if _LATEST_OK[0] else (hex(block), "latest")
    for tag in tags:
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                           "params": [{"to": to, "data": data}, tag]}).encode()
        for i in range(tries):
            for url in pick_rpc() + [FALLBACK]:
                try:
                    out = _rpc_once(url, body)
                    if "result" in out:
                        if tag == "latest":
                            _LATEST_OK[0] = True
                        return out["result"]
                    err = out.get("error") or {}
                    msg = (err.get("message") or "") + str(err.get("data") or "")
                    if err.get("code") == 3 or "revert" in msg.lower() or "invalid opcode" in msg.lower():
                        return "__REVERT__"
                    if ("missing trie node" in msg or "Unknown state" in msg
                            or "header not found" in msg or "not found" in msg):
                        break  # try next tag (latest)
                except Exception:  # noqa: BLE001
                    continue
            else:
                time.sleep(0.3 * (i + 1))
                continue
            break  # inner url loop broke for tag switch
    return None


def w(a):
    return a[2:].rjust(64, "0") if isinstance(a, str) and a.startswith("0x") and len(a) == 42 else None


def main():
    blk = None
    # block number: use the MINIMUM height across RPCs so every node can serve the pinned block
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode()
    h0 = ES.block_number()
    heights = [h0] if h0 else []
    if not heights:
        for url in RPCS:
            try:
                req = urllib.request.Request(url, data=body, headers={
                    "Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=10) as r:
                    heights.append(int(json.loads(r.read())["result"], 16))
            except Exception:  # noqa: BLE001
                continue
    blk = (min(heights) - 5) if heights else None
    if blk is None:
        raise RuntimeError("no block number")
    print("heights", heights, "-> pinned", blk, flush=True)
    print("block", blk, flush=True)

    jobs = []  # (key, to, data)

    def add(key, to, data):
        jobs.append((key, to, data))

    for lab, c in COMPTROLLERS.items():
        for k in ("admin", "pendingAdmin", "pauseGuardian", "oracle", "comptrollerImplementation",
                  "closeFactorMantissa", "liquidationIncentiveMantissa", "transferGuardianPaused",
                  "seizeGuardianPaused", "compRate", "comp", "rewardDistributor", "getAllMarkets"):
            add((lab, k), c, SEL[k])

    # markets first (need market list before market reads) - do comptroller pass
    results = {}
    with ThreadPoolExecutor(max_workers=4) as ex:
        futs = {ex.submit(call1, to, data, blk): key for key, to, data in jobs}
        for f in futs:
            results[futs[f]] = f.result()
    markets = {}
    for lab in COMPTROLLERS:
        h = results.get((lab, "getAllMarkets"))
        mk = []
        if h and h != "__REVERT__" and words(h):
            ws = words(h)
            n = int(ws[1], 16)
            mk = [a20(x) for x in ws[2:2 + n]]
        markets[lab] = mk
        print(lab, "markets:", len(mk), flush=True)

    # market reads
    jobs = []
    for lab, mks in markets.items():
        for m in mks:
            for k in ("underlying", "getCash", "totalBorrows", "totalSupply", "totalReserves",
                      "exchangeRateStored", "exchangeRateCurrent", "reserveFactorMantissa",
                      "interestRateModel", "comptroller", "implementation", "accrualBlockNumber",
                      "decimals", "name", "symbol", "initialExchangeRateMantissa"):
                add((m, k), m, SEL[k])
            add((lab, "mkt." + m + ".cfg"), COMPTROLLERS[lab], SEL["markets"] + w(m))
            add((lab, "mkt." + m + ".borrowCap"), COMPTROLLERS[lab], SEL["borrowCaps"] + w(m))
            add((lab, "mkt." + m + ".mintPaused"), COMPTROLLERS[lab], SEL["mintGuardianPaused"] + w(m))
            add((lab, "mkt." + m + ".borrowPaused"), COMPTROLLERS[lab], SEL["borrowGuardianPaused"] + w(m))
            add((lab, "mkt." + m + ".price"), COMPTROLLERS[lab], SEL["getUnderlyingPrice"] + w(m))
            add((m, "balanceOf.comptroller"), m, SEL["balanceOf"] + w(COMPTROLLERS[lab]))
    with ThreadPoolExecutor(max_workers=4) as ex:
        futs = {ex.submit(call1, to, data, blk): key for key, to, data in jobs}
        for f in futs:
            results[futs[f]] = f.result()

    out = {"block": blk, "comptrollers": {}, "markets": {}}
    for lab, c in COMPTROLLERS.items():
        ce = {"address": c, "markets": markets[lab]}
        for k in ("admin", "pendingAdmin", "pauseGuardian", "oracle", "comptrollerImplementation"):
            h = results.get((lab, k))
            ce[k] = a20(words(h)[0]) if h and h != "__REVERT__" and words(h) and len(words(h)[0]) >= 40 else None
        for k in ("closeFactorMantissa", "liquidationIncentiveMantissa", "transferGuardianPaused",
                  "seizeGuardianPaused", "compRate"):
            ce[k] = u(results.get((lab, k)))
        for k in ("comp", "rewardDistributor"):
            h = results.get((lab, k))
            ce[k] = a20(words(h)[0]) if h and h != "__REVERT__" and words(h) and len(words(h)[0]) >= 40 else None
        out["comptrollers"][lab] = ce

    seen = set()
    for lab, mks in markets.items():
        for m in mks:
            md = out["markets"].setdefault(m, {"market": m})
            if m in seen:
                continue
            seen.add(m)
            for k in ("underlying", "getCash", "totalBorrows", "totalSupply", "totalReserves",
                      "exchangeRateStored", "exchangeRateCurrent", "reserveFactorMantissa",
                      "accrualBlockNumber", "decimals", "initialExchangeRateMantissa"):
                md[k] = u(results.get((m, k)))
            for k in ("interestRateModel", "comptroller", "implementation"):
                h = results.get((m, k))
                md[k] = a20(words(h)[0]) if h and h != "__REVERT__" and words(h) and len(words(h)[0]) >= 40 else None
            md["name"] = dec_str(results.get((m, "name")) if results.get((m, "name")) != "__REVERT__" else None)
            md["symbol"] = dec_str(results.get((m, "symbol")) if results.get((m, "symbol")) != "__REVERT__" else None)
            h = results.get((lab, "mkt." + m + ".cfg"))
            if h and h != "__REVERT__" and words(h) and len(words(h)) >= 3:
                ws = words(h)
                md["isListed"] = int(ws[0], 16) == 1
                md["collateralFactorMantissa"] = int(ws[1], 16)
                md["isComped"] = int(ws[2], 16) == 1
            md["borrowCap"] = u(results.get((lab, "mkt." + m + ".borrowCap")))
            md["mintGuardianPaused"] = u(results.get((lab, "mkt." + m + ".mintPaused")))
            md["borrowGuardianPaused"] = u(results.get((lab, "mkt." + m + ".borrowPaused")))
            md["oracle_price_raw"] = results.get((lab, "mkt." + m + ".price"))
            md["comptroller_cToken_balance"] = u(results.get((m, "balanceOf.comptroller")))
            md.setdefault("eth_balance", None)

    # ETH balances
    addrs = [m for m in out["markets"]]
    for a in addrs:
        b = ES.get_balance(a, "latest")
        if b is not None:
            out["markets"][a]["eth_balance"] = b
    reqs = []

    os.makedirs(OUTDIR, exist_ok=True)
    with open(os.path.join(OUTDIR, "core_state.json"), "w") as f:
        json.dump(out, f, indent=1)
    with open(os.path.join(HERE, "core_state.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("wrote core_state.json", flush=True)


if __name__ == "__main__":
    main()
