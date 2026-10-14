"""Enumerate live state of Orbit Protocol comptrollers/markets on Blast at a pinned block.

Read-only. Keyless public RPCs only. Writes analysis/live_state.json.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc_blast import rpc, call, call_ok, code, bal, to_int, addr_from_word, words  # noqa: E402

# --- selectors ---
S = {
    "getAllMarkets": "0xb0772d0b",
    "closeFactorMantissa": "0xe8755446",
    "liquidationIncentiveMantissa": "0x4ada90af",
    "oracle": "0x7dc0d1d0",
    "admin": "0xf851a440",
    "pendingAdmin": "0x26782247",
    "pauseGuardian": "0x24a3d622",
    "comptrollerImplementation": "0xbb82aa5e",
    "markets": "0x8e8f294b",
    "borrowGuardianPaused": "0x6d154ea5",
    "mintGuardianPaused": "0x731f0c2b",
    "transferGuardianPaused": "0x1e5f6a04",
    "seizeGuardianPaused": "0x9a5a5c5e",
    "borrowCaps": "0x4a584432",
    "supplyCaps": "0x02c3bcbb",
    "compRate": "0xaa900754",
    "comp": "0xacc2166a",
    "compAccrued": "0x6d35bf91",
    "rewardDistributor": "0x109d0af8",
    "getCompAddress": "0x4f95e9ba",
    # cToken
    "underlying": "0x6f307dc3",
    "getCash": "0x3b1d21a2",
    "totalBorrows": "0x47bd3718",
    "totalSupply": "0x18160ddd",
    "totalReserves": "0x8f840ddd",
    "exchangeRateStored": "0x182df0f5",
    "exchangeRateCurrent": "0xbd6d894d",
    "reserveFactorMantissa": "0x173b9904",
    "interestRateModel": "0xf3fdb15a",
    "comptroller": "0x5fe3b567",
    "implementation": "0x5c60da1b",
    "accrualBlockNumber": "0x6c540baf",
    "decimals": "0x313ce567",
    "name": "0x06fdde03",
    "symbol": "0x95d89b41",
    "isCToken": "0xfe9c44ae",
    "borrowRatePerBlock": "0xf8f9da28",
    "supplyRatePerBlock": "0xae9d70b0",
    # oracle
    "getUnderlyingPrice": "0xfc57d4df",
    "getAssetPrice": "0xb3596f07",
    "owner": "0x8da5cb5b",
}


def dec_str(h):
    """Decode a solidity string return."""
    if not h or h == "0x":
        return None
    try:
        w = words(h)
        if len(w) < 2:
            return None
        off = int(w[0], 16)
        ln = int(w[off // 32], 16)
        data = h[2 + off * 2: 2 + off * 2 + ln * 2]
        return bytes.fromhex(data).decode("utf-8", "replace")
    except Exception:  # noqa: BLE001
        return None


def u(h):
    return to_int(h) if h and h != "0x" else None


def main():
    blk = int(rpc("eth_blockNumber", []), 16)
    print(f"latest block: {blk}", flush=True)

    comptrollers = {
        "c1": "0x1E18C3cb491D908241D0db14b081B51be7B6e652",
        "c2": "0x273683CA19D9CF827628EE216E4a9604EfB077A3",
        "c3": "0xe9266ae95bB637A7Ad598CB0390d44262130F433",
        "c4": "0xfFF8Fc176697D04607cF4e23E91c65aeD1c3d3F5",
    }
    out = {"block": blk, "comptrollers": {}}
    market_addrs = []

    for label, c in comptrollers.items():
        print(f"== {label} {c}", flush=True)
        ce = {
            "address": c,
            "code_size": len(code(c, blk).removeprefix("0x")) // 2,
            "admin": None,
            "pendingAdmin": None,
            "pauseGuardian": None,
            "oracle": None,
            "closeFactorMantissa": None,
            "liquidationIncentiveMantissa": None,
            "comptrollerImplementation": None,
            "transferGuardianPaused": None,
            "seizeGuardianPaused": None,
            "compRate": None,
            "comp": None,
            "rewardDistributor": None,
            "markets": [],
        }
        for k in ("admin", "pendingAdmin", "pauseGuardian", "oracle"):
            h = call_ok(c, S[k], blk)
            ce[k] = addr_from_word(words(h)[0]) if h and len(h) > 42 else None
        for k in ("closeFactorMantissa", "liquidationIncentiveMantissa"):
            ce[k] = u(call_ok(c, S[k], blk))
        h = call_ok(c, S["comptrollerImplementation"], blk)
        ce["comptrollerImplementation"] = addr_from_word(words(h)[0]) if h and len(h) > 42 else None
        for k in ("transferGuardianPaused", "seizeGuardianPaused", "compRate"):
            h = call_ok(c, S[k], blk)
            ce[k] = u(h)
        for k in ("comp", "rewardDistributor"):
            h = call_ok(c, S[k], blk)
            ce[k] = addr_from_word(words(h)[0]) if h and len(h) > 42 else None

        mkts_h = call(c, S["getAllMarkets"], blk)
        w = words(mkts_h)
        n = int(w[1], 16) if len(w) > 1 else 0
        mkts = [addr_from_word(x) for x in w[2:2 + n]]
        ce["market_count"] = len(mkts)
        for m in mkts:
            if m not in market_addrs:
                market_addrs.append(m)
            md = {"market": m}
            md["code_size"] = len(code(m, blk).removeprefix("0x")) // 2
            h = call_ok(m, S["underlying"], blk)
            md["underlying"] = addr_from_word(words(h)[0]) if h and len(h) > 42 else None
            md["eth_balance"] = bal(m, blk)
            for k in ("getCash", "totalBorrows", "totalSupply", "totalReserves",
                      "exchangeRateStored", "exchangeRateCurrent", "reserveFactorMantissa",
                      "accrualBlockNumber"):
                md[k] = u(call_ok(m, S[k], blk))
            for k in ("interestRateModel", "comptroller", "admin", "pendingAdmin", "implementation"):
                h = call_ok(m, S[k], blk)
                md[k] = addr_from_word(words(h)[0]) if h and len(h) > 42 else None
            md["decimals"] = u(call_ok(m, S["decimals"], blk))
            md["name"] = dec_str(call_ok(m, S["name"], blk))
            md["symbol"] = dec_str(call_ok(m, S["symbol"], blk))
            md["isCToken"] = u(call_ok(m, S["isCToken"], blk))
            md["borrowRatePerBlock"] = u(call_ok(m, S["borrowRatePerBlock"], blk))
            md["supplyRatePerBlock"] = u(call_ok(m, S["supplyRatePerBlock"], blk))
            # comptroller views
            h = call_ok(c, S["markets"] + m[2:].rjust(64, "0"), blk)
            if h and len(h) >= 130:
                w = words(h)
                md["isListed"] = int(w[0], 16) == 1
                md["collateralFactorMantissa"] = int(w[1], 16)
                md["isComped"] = int(w[2], 16) == 1
            md["borrowCap"] = u(call_ok(c, S["borrowCaps"] + m[2:].rjust(64, "0"), blk))
            md["supplyCap"] = u(call_ok(c, S["supplyCaps"] + m[2:].rjust(64, "0"), blk))
            md["mintGuardianPaused"] = u(call_ok(c, S["mintGuardianPaused"] + m[2:].rjust(64, "0"), blk))
            md["borrowGuardianPaused"] = u(call_ok(c, S["borrowGuardianPaused"] + m[2:].rjust(64, "0"), blk))
            ce["markets"].append(md)
            print(f"   mkt {m} cash={md['getCash']} borr={md['totalBorrows']} "
                  f"supply={md['totalSupply']} eth={md['eth_balance']} sym={md['symbol']} "
                  f"und={md['underlying']}", flush=True)
        out["comptrollers"][label] = ce

    # oracle deep-dive
    oracles = sorted({v["oracle"] for v in out["comptrollers"].values() if v["oracle"]})
    out["oracles"] = {}
    for o in oracles:
        print(f"== oracle {o}", flush=True)
        od = {"address": o, "code_size": len(code(o, blk).removeprefix("0x")) // 2}
        for k in ("owner", "admin", "pendingAdmin"):
            h = call_ok(o, S[k], blk)
            od[k] = addr_from_word(words(h)[0]) if h and len(h) > 42 else None
        od["prices"] = {}
        for m in market_addrs:
            h = call_ok(o, S["getUnderlyingPrice"] + m[2:].rjust(64, "0"), blk)
            od["prices"][m] = u(h)
        out["oracles"][o] = od

    # underlying token metadata
    out["underlyings"] = {}
    for v in out["comptrollers"].values():
        for md in v["markets"]:
            t = md["underlying"]
            if not t or t in out["underlyings"]:
                continue
            td = {"symbol": dec_str(call_ok(t, S["symbol"], blk)),
                  "decimals": u(call_ok(t, S["decimals"], blk))}
            td["balance_of_market"] = u(call_ok(t, "0x70a08231" + md["market"][2:].rjust(64, "0"), blk))
            out["underlyings"][t] = td
            print(f"   tok {t} {td['symbol']} dec={td['decimals']}", flush=True)

    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "live_state.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("wrote live_state.json", flush=True)


if __name__ == "__main__":
    main()
