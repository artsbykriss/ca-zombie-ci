#!/usr/bin/env python3
import json, urllib.request

RPCS = ["https://robinhood.drpc.org", "https://robinhood-chain.rpc.thirdweb.com"]
HDRS = {"Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36",
        "Accept": "application/json"}

def rpc(method, params, url=None):
    urls = [url] if url else RPCS
    last = None
    for u in urls:
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        req = urllib.request.Request(u, data=body, headers=HDRS)
        try:
            r = json.load(urllib.request.urlopen(req, timeout=30))
            if "error" in r:
                last = r["error"]; continue
            return r["result"]
        except Exception as e:
            last = str(e)
    return {"__error__": last}

ORACLE     = "0xCDE9599059f8Ae6D6B9F33A0aF7877827ec75F16"
PAIR       = "0x59F95461E68e0c77605299791E1449f175165B54"
PAIRORACLE = "0x929631b33F4070D6f54477fba3FD27566567dAca"
TREASURY   = "0x04822Ea321A0DEE6F40656172F29312104855d66"
SNET       = "0xb773ec2C326B7f98a5a83fc098825492F020a4c7"
SINGLETON  = "0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010"
MARKETID   = "0xaa586d26a6fe62d9c0f0948fede6e2130500ac7a655587447e2d4a37e6330589"

def h32(v): return "0x" + format(v, "064x")

def slot8(r0, r1, ts):
    v = (r0 & (2**112-1)) | ((r1 & (2**112-1)) << 112) | ((ts & (2**32-1)) << 224)
    return h32(v)

def stub_return(val):
    return "0x7f" + format(val, "064x") + "60005260206000f3"

def call_price(overrides, block="latest"):
    return rpc("eth_call", [{"to": ORACLE, "data": "0xa035b1fe"}, block, overrides])

def dec(x): return int(x, 16) if isinstance(x, str) and x.startswith("0x") else x

R0, R1, TS = 167547905113, 1061334432260, 1792960361
FLOOR = 162761756208124982090
INDEX = 4440900404
SLOT8 = "0x0000000000000000000000000000000000000000000000000000000000000008"

def ov_pair(r0, r1=R1, ts=TS):
    return {PAIR: {"stateDiff": {SLOT8: slot8(r0, r1, ts)}}}

def ov_both(twap, r0):
    return {PAIRORACLE: {"code": stub_return(twap)}, PAIR: {"stateDiff": {SLOT8: slot8(r0, R1, TS)}}}

out = {"pair": PAIR, "slot8_current": slot8(R0, R1, TS),
       "floor_backingPerToken": FLOOR, "index": INDEX}

base = call_price({})
out["baseline_price"] = base
out["baseline_price_dec"] = dec(base)

# 1. DOWN dump (spot halved) -> guard should revert 0xefac79d8
out["down_50pct_spot"] = call_price(ov_pair(R0 // 2))
out["down_10pct_spot"] = call_price(ov_pair(int(R0 * 0.9)))
out["down_14pct_spot"] = call_price(ov_pair(int(R0 * 0.86)))
out["down_16pct_spot"] = call_price(ov_pair(int(R0 * 0.84)))

# 2. UP pushes same-block (twap unchanged)
out["up_2x_sameblock"] = call_price(ov_pair(R0 * 2))
out["up_10x_sameblock"] = call_price(ov_pair(R0 * 10))
out["up_100x_sameblock"] = call_price(ov_pair(R0 * 100))

# 3. ceiling sweep: twap = mult*FLOOR, spot == twap (guard passes)
sweep = []
for mult in [0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 5.5, 6.0, 8.0, 10.0, 100.0]:
    T = int(FLOOR * mult)
    r0 = T * R1 // 10**21
    if r0 >= 2**112:
        sweep.append({"mult": mult, "skipped": "reserve overflow"}); continue
    res = call_price(ov_both(T, r0))
    sweep.append({"twap_over_floor": mult, "twap": T, "reserve0": r0,
                  "price": res, "price_dec": dec(res),
                  "ratio_vs_baseline": (dec(res)/dec(base) if isinstance(res, str) else None)})
out["ceiling_sweep_spot_eq_twap"] = sweep

# 4. guard boundary with large twap (would credit far above cap)
T = FLOOR * 20
boundary = []
for f in [0.80, 0.84, 0.849, 0.85, 0.851, 0.86, 0.90, 1.0]:
    r0 = int(T * f) * R1 // 10**21
    boundary.append({"spot_over_twap": f, "result": call_price(ov_both(T, r0))})
out["guard_boundary"] = boundary

print(json.dumps(out, indent=2))
