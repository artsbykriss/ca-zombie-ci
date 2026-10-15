#!/usr/bin/env python3
"""Read-only state dump for Deepr Finance IOTA EVM comptroller + markets.
Uses keyless public RPC via urllib (stdlib only). Outputs JSON to stdout."""
import json, sys, urllib.request, time

RPC = "https://rpc.ankr.com/iota_evm"
COMPTROLLER = "0xee07121d97FDEA35675e02017837a7a43aeDa48F"

def rpc(method, params):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                out = json.loads(r.read())
            if "result" in out and out["result"] is not None:
                return out["result"]
            err = out.get("error", {})
            # return error marker
            return {"__error__": err}
        except Exception as e:
            if attempt == 2:
                raise
            time.sleep(1)

def call(to, data, block="latest", from_="0x0000000000000000000000000000000000000000"):
    return rpc("eth_call", [{"to":to,"from":from_,"data":data}, block])

def word(hexstr, idx):
    h = hexstr[2:] if hexstr.startswith("0x") else hexstr
    return h[idx*64:(idx+1)*64]

def addr(hexstr, idx):
    w = word(hexstr, idx)
    return "0x" + w[24:]

def uint(hexstr, idx):
    w = word(hexstr, idx)
    return int(w, 16) if w else None

def uint_solo(hexstr):
    if isinstance(hexstr, dict): return hexstr
    if not hexstr or hexstr == "0x": return None
    return int(hexstr[2:].rjust(64,'0'), 16)

def call_uint(to, data):
    r = call(to, data)
    if isinstance(r, dict): return r
    return uint_solo(r)

def call_addr(to, data):
    r = call(to, data)
    if isinstance(r, dict): return r
    return "0x" + r[-40:]

def call_str(to, data):
    r = call(to, data)
    if isinstance(r, dict): return r
    h = r[2:]
    # offset 0x20, len, data
    ln = int(h[64:128], 16)
    s = bytes.fromhex(h[128:128+ln*2]).decode('utf-8', 'replace')
    return s

SEL = {
 "underlying": "0x6f307dc3",
 "symbol": "0x95d89b41",
 "decimals": "0x313ce567",
 "exchangeRateStored": "0x182df0f5",
 "exchangeRateCurrent": "0xbd6d894d",
 "totalSupply": "0x18160ddd",
 "totalBorrows": "0x47bd3718",
 "totalReserves": "0x8f840ddd",
 "getCash": "0x3b1d21a2",
 "accrualBlockNumber": "0x6c540baf",
 "interestRateModel": "0xf3fdb15a",
 "reserveFactorMantissa": "0x173b9904",
 "comptroller": "0x5fe3b567",
 "admin": "0xf851a440",
 "pendingAdmin": "0x26782247",
 "closeFactorMantissa": "0xe8755446",
 "liquidationIncentiveMantissa": "0x4ada90af",
 "pauseGuardian": "0x24aaa5eb",
 "oracle": "0x7dc0d1d0",
 "transferGuardianPaused": "0xdcfbc0c7",
 "seizeGuardianPaused": "0xeabe7d91",
 "mintGuardianPaused": "0x731f0c2b",   # mintGuardianPaused(address)
 "borrowGuardianPaused": "0x94b2294b", # borrowGuardianPaused(address)
 "markets": "0x8e8f294b",              # markets(address)
 "compRate": "0xf4a433c0",
 "compAccrued": "0x7b5e8bd1",          # compAccrued(address)
 "compSpeeds": "0x1d7b33d7",           # compSpeeds(address)
 "compSupplySpeeds": "0x6aa875b5",     # compSupplySpeeds(address)
 "compBorrowSpeeds": "0xa36bc1c3",     # compBorrowSpeeds(address)
 "compBorrowerIndex": "0xc4b62806",    # borrow index for account? (varies)
 "borrowCaps": "0xd9c47cbc",           # borrowCaps(address)
 "supplyCaps": "0xc6cdc0a7",           # supplyCaps(address)
 "getAllBorrowers": "0x4bd7d7c0",
 "liquidateCalculateSeizeTokens": "0xc488847b",
 "getAccountLiquidity": "0x5ec88c79",
 "rewardDistributor": "0xbf20781d",
 "getCompAddress": "0x6af167ad",
 "seizeAllowed": "0x94b2294b",
}

def main():
    out = {"block": rpc("eth_blockNumber", []), "comptroller": COMPTROLLER, "markets": {}}
    out["block_hex"] = out["block"]
    out["block_dec"] = int(out["block"], 16)
    c = COMPTROLLER
    # comptroller-level
    comp = {}
    for name, sel in [("closeFactorMantissa",SEL["closeFactorMantissa"]),
                      ("liquidationIncentiveMantissa",SEL["liquidationIncentiveMantissa"]),
                      ("transferGuardianPaused",SEL["transferGuardianPaused"]),
                      ("seizeGuardianPaused",SEL["seizeGuardianPaused"])]:
        comp[name] = call_uint(c, sel)
    for name, sel in [("admin",SEL["admin"]),("pendingAdmin",SEL["pendingAdmin"]),
                      ("pauseGuardian",SEL["pauseGuardian"]),("oracle",SEL["oracle"])]:
        comp[name] = call_addr(c, sel)
    # comp-like reward
    for name, sel in [("compRate",SEL["compRate"]),("getCompAddress",SEL["getCompAddress"])]:
        comp[name] = call(c, sel)
    # markets list
    raw = call(c, "0xb0772d0b")
    if isinstance(raw, dict):
        print(json.dumps({"error":"getAllMarkets failed", "raw":raw})); return
    h = raw[2:]
    count = int(h[64:128], 16)
    addrs = ["0x" + h[(2+i)*64+24:(2+i)*64+64] for i in range(count)]
    out["market_count"] = count
    for m in addrs:
        d = {}
        d["underlying"] = call_addr(m, SEL["underlying"])
        d["symbol"] = call_str(m, SEL["symbol"])
        d["decimals"] = call_uint(m, SEL["decimals"])
        d["exchangeRateStored"] = call_uint(m, SEL["exchangeRateStored"])
        d["totalSupply"] = call_uint(m, SEL["totalSupply"])
        d["totalBorrows"] = call_uint(m, SEL["totalBorrows"])
        d["totalReserves"] = call_uint(m, SEL["totalReserves"])
        d["getCash"] = call_uint(m, SEL["getCash"])
        d["accrualBlockNumber"] = call_uint(m, SEL["accrualBlockNumber"])
        d["interestRateModel"] = call_addr(m, SEL["interestRateModel"])
        d["reserveFactorMantissa"] = call_uint(m, SEL["reserveFactorMantissa"])
        d["comptroller"] = call_addr(m, SEL["comptroller"])
        # comptroller.markets(cToken)
        data = SEL["markets"] + "0"*24 + m[2:]
        r = call(c, data)
        if not isinstance(r, dict) and len(r) >= 2+64*3:
            nwords = (len(r)-2)//64
            d["markets_"] = {
                "isListed": uint(r,0) != 0,
                "collateralFactorMantissa": uint(r,1),
                "isComped": uint(r,2) != 0 if nwords > 2 else None,
                "borrowCap": uint(r,3) if nwords > 3 else None,
                "words_returned": nwords,
            }
        d["mintGuardianPaused"] = call_uint(c, SEL["mintGuardianPaused"] + "0"*24 + m[2:])
        d["borrowGuardianPaused"] = call_uint(c, SEL["borrowGuardianPaused"] + "0"*24 + m[2:])
        d["borrowCaps"] = call_uint(c, SEL["borrowCaps"] + "0"*24 + m[2:]) if SEL["borrowCaps"] else None
        d["supplyCaps"] = call_uint(c, SEL["supplyCaps"] + "0"*24 + m[2:]) if SEL["supplyCaps"] else None
        d["compSpeeds"] = call(c, SEL["compSpeeds"] + "0"*24 + m[2:])
        d["compSupplySpeeds"] = call(c, SEL["compSupplySpeeds"] + "0"*24 + m[2:])
        d["compBorrowSpeeds"] = call(c, SEL["compBorrowSpeeds"] + "0"*24 + m[2:])
        # underlying balanceOf(cToken)
        if isinstance(d["underlying"], str) and d["underlying"].startswith("0x"):
            ub = call_uint(d["underlying"], "0x70a08231" + "0"*24 + m[2:])
            d["underlying_balanceOf_cToken"] = ub
        out["markets"][m] = d
    # compAccrued on comptroller for random check
    out["comptroller_state"] = comp
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
