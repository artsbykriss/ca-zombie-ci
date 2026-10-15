#!/usr/bin/env python3
"""FilDA BTTC: comptroller per-market config + oracle prices + underlying token metadata. Read-only."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/bttc-viction-aurora/analysis")
from rpclib import rpc, batch, eth_call, block_number, get_code, pad32, dec_uint, dec_addr

COMPTROLLER = "0xe52792e024697a6be770e5d6f1c455550265b2cd"
ORACLE      = "0xb2f0fef3631bc222df0e669e39582119804db72b"

S = {
 "markets(address)": "0x8e8f294b",
 "collateralFactorMantissa(address)": "0x6adf796f",
 "mintGuardianPaused(address)": "0x731f0c2b",
 "borrowGuardianPaused(address)": "0x6d154ea5",
 "transferGuardianPaused(address)": "0xa3690086",
 "seizeGuardianPaused(address)": "0x934356cc",
 "supplyCaps(address)": "0x02c3bcbb",
 "borrowCaps(address)": "0x4a584432",
 "getAssetsIn(address)": "0xabfceffc",
 "getUnderlyingPrice(address)": "0xfc57d4df",
 "decimals()": "0x313ce567",
 "symbol()": "0x95d89b41",
 "totalBorrowsCurrent()": "0x73acee98",
 "exchangeRateCurrent()": "0xbd6d894d",
 "totalReserves()": "0x8f840ddd",
 "accrualBlockNumber()": "0x6c540baf",
 "totalBorrows()": "0x47bd3718",
 "exchangeRateStored()": "0x182df0f5",
 "totalSupply()": "0x18160ddd",
 "getCash()": "0x3b1d21a2",
 "borrowIndex()": "0xaa5af0fd",
}

def decode_str(h):
    if not h or h == "0x": return None
    h = h[2:]
    if len(h) < 128: return None
    ln = int(h[64:128],16)
    try: return bytes.fromhex(h[128:128+ln*2]).decode("utf-8","replace")
    except Exception: return None

def main():
    d = json.load(open("/home/heisenberg/CA/bttc-viction-aurora/analysis/filda_markets.json"))
    blk = d["block"]
    markets = [m["address"] for m in d["markets"]]

    out = {"block": blk, "comptroller": COMPTROLLER, "oracle": ORACLE}

    # oracle code + globals
    out["oracle_code_len"] = len(get_code("bttc", ORACLE))//2 - 1
    # guess oracle type by trying several selectors on the first market
    m0 = markets[0]
    price_calls = {}
    for name, sel in [("getUnderlyingPrice(address)","0xfc57d4df"),("getPrice(address)","0x41976e09"),
                      ("latestAnswer()","0x50d25bcd"),("getAssetPrice(address)","0xb3596f07"),
                      ("peek()","0x59e02dd7"),("getPriceUSD()","0x57a9579e"),("price(address)","0xaea91078")]:
        try:
            data = sel + (pad32(m0) if "address" in name else "")
            r = eth_call("bttc", ORACLE, data, block=hex(blk))
            price_calls[name] = r
        except Exception as e:
            price_calls[name] = "REVERT:" + str(e)[:100]
    out["oracle_probe_on_"+m0] = price_calls

    # per-market
    per = []
    for m in markets:
        calls = ["collateralFactorMantissa(address)","mintGuardianPaused(address)","borrowGuardianPaused(address)",
                 "transferGuardianPaused(address)","seizeGuardianPaused(address)","supplyCaps(address)","borrowCaps(address)"]
        res = batch("bttc", [("eth_call",[{"to":COMPTROLLER,"data":S[c]+pad32(m)},hex(blk)]) for c in calls])
        e = {"address": m, "comptroller_cfg": {}}
        for c, r in zip(calls, res):
            e["comptroller_cfg"][c] = None if r in (None,"0x") else (dec_uint(r) if r and len(r)>42 else r)
        # markets(address) struct decode
        try:
            r = eth_call("bttc", COMPTROLLER, S["markets(address)"]+pad32(m), block=hex(blk))
            h = r[2:]
            w = [int(h[i*64:(i+1)*64],16) for i in range(len(h)//64)]
            e["markets_struct_words"] = w
        except Exception as ex:
            e["markets_struct_err"] = str(ex)[:100]
        # oracle price
        try:
            r = eth_call("bttc", ORACLE, S["getUnderlyingPrice(address)"]+pad32(m), block=hex(blk))
            e["oracle_price_raw"] = int(r,16) if r and r!="0x" else None
        except Exception as ex:
            e["oracle_price_err"] = str(ex)[:100]
        # underlying meta
        mk = next(x for x in d["markets"] if x["address"]==m)
        u = mk["underlying"]
        r1, r2 = batch("bttc", [("eth_call",[{"to":u,"data":S["decimals()"]},hex(blk)]),
                                ("eth_call",[{"to":u,"data":S["symbol()"]},hex(blk)])])
        e["underlying"] = u
        e["underlying_decimals"] = int(r1,16) if r1 and r1!="0x" else None
        e["underlying_symbol"] = decode_str(r2)
        # live accrual reads (state-changing calls as eth_call -> may revert or return uint)
        for name, sel in [("totalBorrowsCurrent()","0x73acee98"),("exchangeRateCurrent()","0xbd6d894d"),("borrowIndex()","0xaa5af0fd")]:
            try:
                r = eth_call("bttc", m, sel, block=hex(blk))
                e[name] = int(r,16) if r and r!="0x" else None
            except Exception as ex:
                e[name] = "REVERT:"+str(ex)[:80]
        per.append(e)
    out["markets"] = per
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
