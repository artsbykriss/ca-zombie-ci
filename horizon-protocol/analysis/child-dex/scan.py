#!/usr/bin/env python3
"""Independent DEX-market scan for Horizon Protocol zAsset synths on BSC.

Stage 0: factory sanity checks (validate each factory address by round-tripping
         getPair/getPool then factory() on the returned pair).
Stage 1: PancakeSwap V2-style getPair(synth, quote) across 7 factories x 27 synth
         addresses (26 registered + alternate zUSD proxy) x 6 quote tokens.
Stage 2: PancakeSwap V3 getPool(synth, quote, fee) for fee in 100/500/2500/10000.
Stage 3: detail reads (token0/token1/getReserves|totalSupply or liquidity/slot0).
Writes raw_scan.json in child-dex/. Public RPCs only, no keys.
"""
import json, os, sys, time
sys.path.insert(0, "/home/heisenberg/CA/horizon-protocol/analysis")
import rpcmulti as R

BASE = "/home/heisenberg/CA/horizon-protocol/analysis"
OUT = os.path.join(BASE, "child-dex")
os.makedirs(OUT, exist_ok=True)

en = json.load(open(os.path.join(BASE, "synth-enum.json")))
SYNTHS = {a.lower(): v["currencyKey"] for a, v in en["synths"].items()}
ALT_ZUSD = "0xf0186490b18cb74619816cfc7feb51cdbe4ae7b9"
SYNTHS[ALT_ZUSD] = "zUSD_alt"

QUOTES = {
    "WBNB": "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",
    "BUSD": "0xe9e7cea3dedca5984780bafc599bd69add087d56",
    "USDT": "0x55d398326f99059ff775485246999027b3197955",
    "BTCB": "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c",
    "ETH":  "0x2170ed0880ac9a755fd29b2688956bd959f933f8",
    "CAKE": "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82",
}

V2_FACTORIES = {
    "pancakeswap_v2": "0xca143ce32fe78f1f7019d7d551a6402fc5350c73",
    "pancakeswap_v1": "0xbcfccbde45ce874adcb698cc183debcf17952812",
    "apeswap":        "0x0841bd0b734e4f5853f0dd8d7ea041c241fb0da6",
    "biswap":         "0x858e3312ed3a876947ea49d572a7c42de08af7ee",
    "mdex":           "0x3cd1c46068daea5ebb0d3f55f6915b10648062b8",
    "babyswap":       "0x86407bea2078ea5f5eb5a52b2caa963bc1f889da",
    "bakeryswap":     "0x01bf7c66c6bd861915cdaae475042d3c4bae16a7",
}

V3_FACTORY = "0x0bfbcf9fa4f9c56b0f40a671ad40e0805a091865"
V3_FEES = [100, 500, 2500, 10000]
V3_QUOTES = {"WBNB": QUOTES["WBNB"], "USDT": QUOTES["USDT"]}

ZUSD_BUSD_PAIR = "0xc3bf4e0ea6b76c8edd838e14be2116c862c88bdf"

SEL = {
    "getPair": "e6a43905", "getPool": "1698ee82",
    "token0": "0dfe1681", "token1": "d21220a7",
    "getReserves": "0902f1ac", "totalSupply": "18160ddd",
    "factory": "c45a0155", "symbol": "95d89b41",
    "decimals": "313ce567", "liquidity": "1a686502", "slot0": "3850c7bd",
}

def waddr(a):
    return a.lower().replace("0x", "").rjust(64, "0")

def wint(i):
    return format(i, "x").rjust(64, "0")

def call(to, sel, *args):
    """Returns (result_hex, error)."""
    r = R.call(to.lower(), "0x" + SEL[sel] + "".join(args))
    if isinstance(r, dict):
        return None, str(r.get("error"))
    return r, None

def dec_addr(res):
    if not res or len(res) < 66:
        return None
    a = "0x" + res[2:].lstrip("0").lower() if res[2:].strip("0") else None
    if not a:
        return None
    return "0x" + res[2:][24:64].lower()

def dec_word(res, i=0):
    return res[2 + i*64: 2 + (i+1)*64]

def multi_jobs(jobs, workers=12):
    """jobs: list of (tag, fn). Runs threaded, returns {tag: result}."""
    fns = [j[1] for j in jobs]
    res = R.multi(fns, workers=workers)
    return dict((jobs[i][0], res[i]) for i in range(len(jobs)))

t0 = time.time()
out = {"block": R.block(), "synth_count": len(SYNTHS), "sanity": {}, "v2": {}, "v3": {}, "details": {}}
print("block", out["block"])

# ---------- Stage 0: factory sanity ----------
sanity_jobs = []
for name, f in V2_FACTORIES.items():
    sanity_jobs.append(("v2probe:" + name, lambda f=f: call(f, "getPair", waddr(QUOTES["WBNB"]), waddr(QUOTES["BUSD"]))))
sanity_jobs.append(("v3probe", lambda: call(V3_FACTORY, "getPool", waddr(QUOTES["WBNB"]), waddr(QUOTES["USDT"]), wint(500))))
sanity_res = multi_jobs(sanity_jobs, workers=7)

factory_ok = {}
probe_roundtrip = []
for name, f in V2_FACTORIES.items():
    res, err = sanity_res["v2probe:" + name]
    if err or res is None:
        factory_ok[name] = {"ok": False, "error": err}
        continue
    pair = dec_addr(res)
    if pair in (None, "0x0000000000000000000000000000000000000000"):
        factory_ok[name] = {"ok": False, "error": "probe pair (WBNB/BUSD) is zero", "raw": res}
        continue
    probe_roundtrip.append((name, f, pair))
out["sanity"]["v2_factories"] = {}

def rt_job(item):
    name, f, pair = item
    res, err = call(pair, "factory")
    got = dec_addr(res) if res else None
    return (name, {"probe_pair": pair, "factory_of_pair": got, "ok": (got == f.lower()), "error": err})

rt = multi_jobs([("rt%d" % i, (lambda it=it: rt_job(it))) for i, it in enumerate(probe_roundtrip)], workers=7)
for i, item in enumerate(probe_roundtrip):
    name, f, pair = item
    out["sanity"]["v2_factories"][name] = rt["rt%d" % i][1]

v3res, v3err = sanity_res["v3probe"]
out["sanity"]["v3_factory"] = {
    "factory": V3_FACTORY, "probe": "getPool(WBNB,USDT,500)",
    "pool": dec_addr(v3res) if v3res else None, "error": v3err}

for name, f in V2_FACTORIES.items():
    factory_ok[name] = {"ok": out["sanity"]["v2_factories"].get(name, {}).get("ok", False)}
print("factory sanity:", json.dumps(out["sanity"], indent=1)[:1200])
print("elapsed %.1fs" % (time.time() - t0))

# ---------- Stage 1: V2 getPair scan ----------
v2_jobs = []
for name, f in V2_FACTORIES.items():
    if not factory_ok[name]["ok"]:
        out["v2"][name] = {"skipped": "factory sanity failed"}
        continue
    for saddr, skey in SYNTHS.items():
        for qkey, qaddr in QUOTES.items():
            tag = "v2:%s:%s:%s" % (name, saddr, qkey)
            v2_jobs.append((tag, (lambda f=f, s=saddr, q=qaddr: call(f, "getPair", waddr(s), waddr(q)))))
v2_res = multi_jobs(v2_jobs, workers=12)

v2_found = []
v2_zero_count = 0
v2_err_count = 0
for tag, (res, err) in v2_res.items():
    _, name, saddr, qkey = tag.split(":")
    if err or res is None:
        v2_err_count += 1
        out["v2"].setdefault("_errors", []).append({"tag": tag, "error": err})
        continue
    pair = dec_addr(res)
    if pair in (None, "0x0000000000000000000000000000000000000000"):
        v2_zero_count += 1
        continue
    v2_found.append({"dex": name, "synth": saddr, "synth_key": SYNTHS[saddr],
                     "quote": qkey, "quote_addr": QUOTES[qkey], "pair": pair})
out["v2"]["_summary"] = {"jobs": len(v2_jobs), "found": len(v2_found), "zero": v2_zero_count, "errors": v2_err_count}
out["v2"]["pairs"] = v2_found
print("V2 scan: %d jobs, %d pairs found, %d zero, %d errors (%.1fs)" % (
    len(v2_jobs), len(v2_found), v2_zero_count, v2_err_count, time.time() - t0))
for p in v2_found:
    print("  ", p["dex"], p["synth_key"], p["synth"], "/", p["quote"], "->", p["pair"])

# sanity: expected zUSD/BUSD pair
sanity_hit = any(p["pair"] == ZUSD_BUSD_PAIR for p in v2_found)
out["sanity"]["zUSD_BUSD_expected_pair_found"] = sanity_hit
print("sanity zUSD/BUSD expected pair found:", sanity_hit)

# ---------- Stage 2: V3 getPool scan ----------
v3_jobs = []
for saddr, skey in SYNTHS.items():
    for qkey, qaddr in V3_QUOTES.items():
        for fee in V3_FEES:
            tag = "v3:%s:%s:%d" % (saddr, qkey, fee)
            v3_jobs.append((tag, (lambda s=saddr, q=qaddr, f=fee: call(V3_FACTORY, "getPool", waddr(s), waddr(q), wint(f)))))
v3_res = multi_jobs(v3_jobs, workers=12)

v3_found = []
v3_zero = 0
v3_err = 0
for tag, (res, err) in v3_res.items():
    _, saddr, qkey, fee = tag.split(":")
    if err or res is None:
        v3_err += 1
        out["v3"].setdefault("_errors", []).append({"tag": tag, "error": err})
        continue
    pool = dec_addr(res)
    if pool in (None, "0x0000000000000000000000000000000000000000"):
        v3_zero += 1
        continue
    v3_found.append({"dex": "pancakeswap_v3", "synth": saddr, "synth_key": SYNTHS[saddr],
                     "quote": qkey, "quote_addr": V3_QUOTES[qkey], "fee": int(fee), "pool": pool})
out["v3"]["_summary"] = {"jobs": len(v3_jobs), "found": len(v3_found), "zero": v3_zero, "errors": v3_err}
out["v3"]["pools"] = v3_found
print("V3 scan: %d jobs, %d pools found, %d zero, %d errors (%.1fs)" % (
    len(v3_jobs), len(v3_found), v3_zero, v3_err, time.time() - t0))
for p in v3_found:
    print("  ", p["synth_key"], p["synth"], "/", p["quote"], "fee", p["fee"], "->", p["pool"])

# ---------- Stage 3: details ----------
det_jobs = []
all_pairs = [("v2", p) for p in v2_found] + [("v3", p) for p in v3_found]
for i, (kind, p) in enumerate(all_pairs):
    addr = p.get("pair") or p.get("pool")
    det_jobs.append(("d%d:token0" % i, (lambda a=addr: call(a, "token0"))))
    det_jobs.append(("d%d:token1" % i, (lambda a=addr: call(a, "token1"))))
    det_jobs.append(("d%d:totalSupply" % i, (lambda a=addr: call(a, "totalSupply"))))
    if kind == "v2":
        det_jobs.append(("d%d:getReserves" % i, (lambda a=addr: call(a, "getReserves"))))
    else:
        det_jobs.append(("d%d:liquidity" % i, (lambda a=addr: call(a, "liquidity"))))
        det_jobs.append(("d%d:slot0" % i, (lambda a=addr: call(a, "slot0"))))
# synth decimals (dedup addresses used in found pairs)
synth_addrs_used = sorted(set(p["synth"] for _, p in all_pairs))
for s in synth_addrs_used:
    det_jobs.append(("dec:" + s, (lambda a=s: call(a, "decimals"))))
    det_jobs.append(("sym:" + s, (lambda a=s: call(a, "symbol"))))

det_res = multi_jobs(det_jobs, workers=12)
details = []
for i, (kind, p) in enumerate(all_pairs):
    d = dict(p)
    d["kind"] = kind
    addr = p.get("pair") or p.get("pool")
    d["addr"] = addr
    d["token0"] = dec_addr(det_res["d%d:token0" % i][0]) if not det_res["d%d:token0" % i][1] else None
    d["token1"] = dec_addr(det_res["d%d:token1" % i][0]) if not det_res["d%d:token1" % i][1] else None
    ts, tserr = det_res["d%d:totalSupply" % i]
    d["totalSupply_wei"] = str(int(ts, 16)) if (ts and not tserr) else None
    if kind == "v2":
        rres, rerr = det_res["d%d:getReserves" % i]
        if rres and not rerr:
            d["reserve0_wei"] = str(int(dec_word(rres, 0), 16))
            d["reserve1_wei"] = str(int(dec_word(rres, 1), 16))
            d["blockTimestampLast"] = int(dec_word(rres, 2), 16)
        else:
            d["reserves_error"] = rerr
    else:
        lres, lerr = det_res["d%d:liquidity" % i]
        d["liquidity_wei"] = str(int(lres, 16)) if (lres and not lerr) else None
        sres, serr = det_res["d%d:slot0" % i]
        if sres and not serr:
            d["sqrtPriceX96"] = str(int(dec_word(sres, 0), 16))
    details.append(d)

dec_map, sym_map = {}, {}
for s in synth_addrs_used:
    dd = det_res["dec:" + s]
    dec_map[s] = int(dd[0], 16) if dd[0] and not dd[1] else None
    ss = det_res["sym:" + s]
    if ss[0] and not ss[1]:
        try:
            raw = bytes.fromhex(ss[0][2:])
            sym_map[s] = raw.split(b"\x00")[0].decode("utf8", "ignore") if raw[32:64] == b"\x00"*32 else None
        except Exception:
            sym_map[s] = None
out["details"] = details
out["synth_decimals"] = dec_map
out["synth_symbols"] = sym_map

json.dump(out, open(os.path.join(OUT, "raw_scan.json"), "w"), indent=1)
print("wrote raw_scan.json; total elapsed %.1fs" % (time.time() - t0))
