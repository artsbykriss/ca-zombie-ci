#!/usr/bin/env python3
"""Enumerate FilDA markets on BTTC (chainid 199). Read-only. No secrets."""
import json, sys, hashlib, time
sys.path.insert(0, "/home/heisenberg/CA/bttc-viction-aurora/analysis")
from rpclib import rpc, batch, eth_call, block_number, get_code, pad32, dec_uint, dec_addr

COMPTROLLER = "0xe52792e024697a6be770e5d6f1c455550265b2cd"

def sel(sig):
    # keccak256 via pysha3 if available, else fallback list provided
    try:
        import sha3
        k = sha3.keccak_256()
        k.update(sig.encode())
        return "0x" + k.hexdigest()[:8]
    except Exception:
        raise

SEL = {
 "allMarkets(uint256)": "0x8e8f294b",  # placeholder replaced below
}

def k4(sig):
    import subprocess
    return subprocess.run(["cast","keccak",sig], capture_output=True, text=True).stdout.strip()[:10]

# pre-compute selectors with cast (keccak)
S = {}
for name in ["allMarkets(uint256)","markets(address)","collateralFactorMantissa(address)",
             "mintGuardianPaused(address)","borrowGuardianPaused(address)","transferGuardianPaused(address)",
             "seizeGuardianPaused(address)","oracle()","closeFactorMantissa()","liquidationIncentiveMantissa()",
             "pauseGuardian()","admin()","owner()","getAllMarkets()","protocolPaused()",
             "supplyCaps(address)","borrowCaps(address)","compRate(address,address)","compAccrued(address)"]:
    S[name] = k4(name)

S["underlying()"]            = "0x6f307dc3"
S["symbol()"]                = "0x95d89b41"
S["decimals()"]              = "0x313ce567"
S["exchangeRateStored()"]    = "0x182df0f5"
S["totalSupply()"]           = "0x18160ddd"
S["totalBorrows()"]          = "0x47bd3718"
S["totalReserves()"]         = "0x8f840ddd"
S["getCash()"]               = "0x3b1d21a2"
S["accrualBlockNumber()"]    = "0x6c540baf"
S["comptroller()"]           = "0x5fe3b567"
S["interestRateModel()"]     = "0xf3fdb15a"
S["reserveFactorMantissa()"] = "0x173b9904"
S["borrowRatePerBlock()"]    = "0xf8f9da28"
S["supplyRatePerBlock()"]    = "0xae9d70b0"
S["implementation()"]        = "0x5c60da1b"
S["admin()"]                 = "0xf851a440"

def main():
    blk = block_number("bttc")
    out = {"block": blk, "chain_id": 199, "comptroller": COMPTROLLER}

    # iterate allMarkets(uint256)
    markets = []
    i = 0
    while i < 60:
        try:
            r = eth_call("bttc", COMPTROLLER, S["allMarkets(uint256)"] + pad32(i))
            if r in (None, "0x"):
                break
            a = dec_addr(r)
            if a is None or int(a,16)==0:
                break
            markets.append(a)
            i += 1
        except Exception as e:
            break
    out["markets_allMarkets"] = markets

    # also try getAllMarkets()
    try:
        r = eth_call("bttc", COMPTROLLER, S["getAllMarkets()"])
        h = r[2:]
        n = int(h[64:128],16)
        arr = []
        for j in range(n):
            arr.append("0x"+h[128+j*64+24:128+(j+1)*64])
        out["markets_getAllMarkets"] = arr
    except Exception as e:
        out["markets_getAllMarkets_error"] = str(e)[:200]

    # comptroller globals
    cg = {}
    for name in ["oracle()","closeFactorMantissa()","liquidationIncentiveMantissa()","pauseGuardian()",
                 "admin()","owner()","protocolPaused()"]:
        try:
            r = eth_call("bttc", COMPTROLLER, S[name])
            cg[name] = r if name in ("oracle()","pauseGuardian()","admin()","owner()") else (dec_uint(r) if r and r!="0x" else None)
            if name in ("oracle()","pauseGuardian()","admin()","owner()") and r and len(r)>=42:
                cg[name] = dec_addr(r)
        except Exception as e:
            cg[name] = "REVERT:"+str(e)[:80]
    out["comptroller_globals"] = cg
    out["comptroller_code_len"] = len(get_code("bttc", COMPTROLLER))//2 - 1

    # per-market reads
    per = []
    for m in markets:
        d = {"address": m}
        calls = [
            ("symbol()", m),
            ("underlying()", m),
            ("decimals()", m),
            ("exchangeRateStored()", m),
            ("totalSupply()", m),
            ("totalBorrows()", m),
            ("totalReserves()", m),
            ("getCash()", m),
            ("accrualBlockNumber()", m),
            ("comptroller()", m),
            ("reserveFactorMantissa()", m),
            ("borrowRatePerBlock()", m),
            ("supplyRatePerBlock()", m),
            ("interestRateModel()", m),
            ("implementation()", m),
            ("admin()", m),
        ]
        # batch in chunks of 10
        vals = {}
        for chunk_start in range(0, len(calls), 8):
            chunk = calls[chunk_start:chunk_start+8]
            res = batch("bttc", [("eth_call", [{"to": t, "data": S[n]}, hex(blk)]) for n, t in chunk])
            for (n, t), r in zip(chunk, res):
                vals[n] = r
        def u(k):
            v = vals.get(k)
            if v in (None, "0x"): return None
            try: return dec_uint(v)
            except Exception: return None
        d["symbol"] = None
        try:
            v = vals.get("symbol()")
            if v and v != "0x":
                h = v[2:]
                ln = int(h[64:128],16) if len(h) >= 128 else 0
                d["symbol"] = bytes.fromhex(h[128:128+ln*2]).decode("utf-8","replace")
        except Exception as e:
            d["symbol_err"] = str(e)[:60]
        d["underlying"] = dec_addr(vals["underlying()"]) if vals.get("underlying()") not in (None,"0x") else None
        d["decimals"] = u("decimals()")
        d["exchangeRateStored"] = u("exchangeRateStored()")
        d["totalSupply"] = u("totalSupply()")
        d["totalBorrows"] = u("totalBorrows()")
        d["totalReserves"] = u("totalReserves()")
        d["getCash"] = u("getCash()")
        d["accrualBlockNumber"] = u("accrualBlockNumber()")
        d["comptroller"] = dec_addr(vals["comptroller()"]) if vals.get("comptroller()") not in (None,"0x") else None
        d["reserveFactorMantissa"] = u("reserveFactorMantissa()")
        d["borrowRatePerBlock"] = u("borrowRatePerBlock()")
        d["supplyRatePerBlock"] = u("supplyRatePerBlock()")
        d["interestRateModel"] = dec_addr(vals["interestRateModel()"]) if vals.get("interestRateModel()") not in (None,"0x") else None
        d["implementation"] = dec_addr(vals["implementation()"]) if vals.get("implementation()") not in (None,"0x") else None
        d["cToken_admin"] = dec_addr(vals["admin()"]) if vals.get("admin()") not in (None,"0x") else None
        d["code_len"] = len(get_code("bttc", m))//2 - 1
        per.append(d)
    out["markets"] = per
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
