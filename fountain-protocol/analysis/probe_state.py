#!/usr/bin/env python3
"""Fountain Protocol (Oasis Emerald) — read-only state probe.

Reads comptroller/cToken/oracle state at a pinned block via public RPC.
No keys, no transactions. Output: JSON to stdout (redact nothing: public RPC only).
"""
import json, sys, time, urllib.request

RPC = "https://emerald.oasis.dev"
COMPTROLLERS = {
    "classic": "0xA7684aE7e07Dac91113900342b3ef25B9Fd1D841",
    "usd":     "0x1C0C30795802Bf2B3232a824f41629BbBCF63127",
    "lpt":     "0x7c4d0c834701C6E7F57b8c1424d30aDC46eA0840",
}

_id = 0
def rpc(method, params):
    global _id
    _id += 1
    req = urllib.request.Request(RPC, data=json.dumps({
        "jsonrpc": "2.0", "id": _id, "method": method, "params": params
    }).encode(), headers={"Content-Type": "application/json", "User-Agent": "fountain-probe/1.0"})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read())
            if "error" in out:
                return {"error": out["error"]}
            return out.get("result")
        except Exception as e:
            if attempt == 4:
                return {"error": str(e)}
            time.sleep(1.5 * (attempt + 1))

# selectors (verified with `cast sig`)
SEL = {
    "admin()": "f851a440",
    "pendingAdmin()": "26782247",
    "oracle()": "7dc0d1d0",
    "closeFactorMantissa()": "e8755446",
    "liquidationIncentiveMantissa()": "4ada90af",
    "pauseGuardian()": "24a3d622",
    "getAllMarkets()": "b0772d0b",
    "getAssetsIn(address)": None,  # per-address; skip
    "mintGuardianPaused(address)": "731f0c2b",
    "borrowGuardianPaused(address)": "6d154ea5",
    "transferGuardianPaused(address)": "a3690086",
    "seizeGuardianPaused(address)": "934356cc",
    "marketPaused(address)": None,  # may not exist; probe raw
    "markets(address)": "8e8f294b",
    "compRate()": "aa900754",
    "compAccrued(address)": "cc7ebdc4",
    "compSpeeds(address)": "c6c06f39",
    "compSupplySpeeds(address)": "6aa875b5",
    "compBorrowSpeeds(address)": "f4a433c0",
    "supplyCaps(address)": "02c3bcbb",
    "borrowCaps(address)": "4a584432",
    "compAddress()": "7d3ab61a",
    "isComptroller()": "1bce1950",
    "liquidityMining()": None,
}
# cToken selectors
CSEL = {
    "symbol()": "95d89b41",
    "name()": "06fdde03",
    "underlying()": "6f307dc3",
    "exchangeRateStored()": "182df0f5",
    "exchangeRateCurrent()": "bd6d894d",
    "totalSupply()": "18160ddd",
    "totalBorrows()": "47bd3718",
    "totalReserves()": "8f840ddd",
    "getCash()": "3b1d21a2",
    "cash()": "961be391",
    "reserveFactorMantissa()": "173b9904",
    "interestRateModel()": "f3fdb15a",
    "comptroller()": "5fe3b567",
    "admin()": "f851a440",
    "accrualBlockNumber()": "6c540baf",
    "initialExchangeRateMantissa()": "675d972c",
    "decimals()": "313ce567",
    "isCToken()": "fe9c44ae",
    "borrowRatePerBlock()": "f8f9da28",
    "supplyRatePerBlock()": "ae9d70b0",
    "exchangeRateMaximizer()": None,
    "isCEther()": None,
    "mintPaused()": None,
    "paused()": "5c975abb",
    "getAccountSnapshot(address)": None,
}
# oracle selectors
OSEL = {
    "getUnderlyingPrice(address)": "fc57d4df",
    "getPrice(address)": "41976e09",
    "getPrice(string)": None,
}

def call(to, selector, block):
    data = "0x" + selector
    r = rpc("eth_call", [{"to": to, "data": data}, hex(block)])
    return r

def dec_uint(hexstr):
    if not isinstance(hexstr, str) or hexstr == "0x":
        return None
    try:
        return int(hexstr, 16)
    except Exception:
        return None

def dec_addr(hexstr):
    if not isinstance(hexstr, str) or len(hexstr) < 42:
        return None
    return "0x" + hexstr[-40:]

def dec_str(hexstr):
    if not isinstance(hexstr, str) or hexstr == "0x":
        return None
    b = bytes.fromhex(hexstr[2:])
    try:
        if len(b) >= 64:
            off = int.from_bytes(b[:32], "big")
            ln = int.from_bytes(b[off:off+32], "big")
            return b[off+32:off+32+ln].decode("utf-8", "replace")
        return b.decode("utf-8", "replace")
    except Exception:
        return None

def main():
    latest = int(rpc("eth_blockNumber", []), 16)
    # pin slightly behind head for consistency
    block = latest - 2
    out = {"rpc": RPC, "chain_id": 42262, "latest": latest, "pinned_block": block, "comptrollers": {}, "markets": {}, "raw": {}}
    for label, comp in COMPTROLLERS.items():
        c = {"address": comp}
        for name, sel in [("admin()", SEL["admin()"]), ("pendingAdmin()", SEL["pendingAdmin()"]),
                          ("oracle()", SEL["oracle()"]), ("closeFactorMantissa()", SEL["closeFactorMantissa()"]),
                          ("liquidationIncentiveMantissa()", SEL["liquidationIncentiveMantissa()"]),
                          ("pauseGuardian()", SEL["pauseGuardian()"]), ("compAddress()", SEL["compAddress()"])]:
            r = call(comp, sel, block)
            c[name] = r
        r = call(comp, SEL["getAllMarkets()"], block)
        c["getAllMarkets_raw"] = r
        markets = []
        if isinstance(r, str) and r != "0x":
            b = bytes.fromhex(r[2:])
            off = int.from_bytes(b[:32], "big")
            n = int.from_bytes(b[off:off+32], "big")
            for i in range(n):
                item = b[off+32+i*32: off+64+i*32]
                markets.append("0x" + item[12:].hex())
        c["markets"] = markets
        # comptroller pause flags per market
        c["pause_flags"] = {}
        for m in markets:
            mhex = m[2:].lower().rjust(64, "0")
            flags = {}
            for fname, fsel in [("mint", SEL["mintGuardianPaused(address)"]),
                                ("borrow", SEL["borrowGuardianPaused(address)"]),
                                ("transfer", SEL["transferGuardianPaused(address)"]),
                                ("seize", SEL["seizeGuardianPaused(address)"])]:
                r = call(comp, fsel + mhex, block)
                flags[fname] = dec_uint(r) if isinstance(r, str) and not isinstance(r, dict) else r
            r = call(comp, SEL["markets(address)"] + mhex, block)
            flags["markets_raw"] = r
            if isinstance(r, str) and len(r) >= 194:
                flags["isListed"] = dec_uint("0x" + r[2:66])
                flags["collateralFactorMantissa"] = dec_uint("0x" + r[66:130])
                flags["isComped"] = dec_uint("0x" + r[130:194])
            c["pause_flags"][m] = flags
        out["comptrollers"][label] = c
        # cToken reads
        for m in markets:
            t = {}
            for name, sel in CSEL.items():
                if sel is None:
                    continue
                r = call(m, sel, block)
                t[name] = r
            out["markets"][m] = t
        # oracle reads for each market
        oracle = dec_addr(c.get("oracle()")) if isinstance(c.get("oracle()"), str) else None
        if oracle:
            for m in markets:
                mhex = m[2:].lower().rjust(64, "0")
                r = call(oracle, OSEL["getUnderlyingPrice(address)"] + mhex, block)
                out["markets"][m]["oracle_getUnderlyingPrice"] = r
                und = dec_addr(t.get("underlying()")) if isinstance(t.get("underlying()"), str) else None
                if und:
                    uhex = und[2:].lower().rjust(64, "0")
                    r2 = call(oracle, OSEL["getPrice(address)"] + uhex, block)
                    out["markets"][m]["oracle_getPrice_underlying"] = r2
    out["raw"]["code"] = {a: rpc("eth_getCode", [a, hex(block)]) for a in
                          list(COMPTROLLERS.values()) + ["0xd7d588babfb99e82cd6dd0ca7677a5599aa678b5"]}
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
