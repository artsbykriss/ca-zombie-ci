#!/usr/bin/env python3
"""
Liquid Driver full live-state enumeration for CI (READ ONLY).
Reads only; writes ci-out/live-state.json and ci-out/values.json.
Uses FANTOM_RPC_URL / BSC_RPC_URL from env with public fallbacks.
"""
import json, os, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

FANTOM = os.environ.get("FANTOM_RPC_URL") or "https://fantom.drpc.org"
BSC = os.environ.get("BSC_RPC_URL") or "https://bsc-rpc.publicnode.com"
RPC = {"fantom": FANTOM, "bsc": BSC}
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")
os.makedirs(OUTDIR, exist_ok=True)

def post(url, payload, timeout=30):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc_one(chain, method, params, retries=3):
    last = None
    for a in range(retries):
        try:
            d = post(RPC[chain], {"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
            if "result" in d:
                return d["result"]
            last = d.get("error")
        except Exception as e:
            last = str(e)
        time.sleep(0.4 * (a + 1))
    return {"__error__": str(last)}

def eth_call(chain, to, data, frm=None, blk="latest"):
    p = {"to": to, "data": data}
    if frm:
        p["from"] = frm
    return rpc_one(chain, "eth_call", [p, blk])

def multi(chain, items, workers=6):
    """items: list of (to, data, from_or_None). Returns list of results in order."""
    out = [None] * len(items)
    def work(i):
        to, data, frm = items[i]
        out[i] = eth_call(chain, to, data, frm)
    with ThreadPoolExecutor(max_workers=workers) as ex:
        list(ex.map(work, range(len(items))))
    return out

def sel(sig):
    import subprocess
    return subprocess.run(["cast", "sig", sig], capture_output=True, text=True).stdout.strip()

def addr(r):
    return "0x" + r[-40:] if isinstance(r, str) and len(r) >= 42 else None

def uint(r):
    try:
        return int(r, 16) if isinstance(r, str) and r != "0x" else None
    except Exception:
        return None

def enc_addr(a):
    return a[2:].lower().rjust(64, "0")

def enc_uint(n):
    return hex(n)[2:].rjust(64, "0")

SIG = {}
for s in ["poolLength()", "poolInfo(uint256)", "lpToken(uint256)", "strategies(uint256)",
          "balanceOf(address)", "totalSupply()", "token0()", "token1()", "getReserves()",
          "decimals()", "exchangeRateStored()", "lpToken()", "strategy()", "owner()",
          "want()", "depositor()", "treasury()", "harvesters(address)", "withdraw(uint256)",
          "harvest()", "deposit()", "getHarvestable()", "balanceOfWant()", "balanceOfPool()",
          "userInfo(uint256,address)", "pendingLqdr(uint256,address)", "withdraw(uint256,uint256,address)",
          "emergencyWithdraw(uint256,address)", "harvest(uint256,address)", "lqdrPerSecond()",
          "totalAllocPoint()", "supply()", "token()", "locked(address)"]:
    SIG[s] = sel(s)

ATK = "0x1111111111111111111111111111111111111111"
MC = "0x742474dae70fa2ab063ab786b1fbe5704e861a0c"
MINI_FTM = "0x6e2ad6527901c9664f016466b8da1357a004db0f"
MINI_BSC = "0xd46db083de31c64af3f680f139a31ff37bac004f"
XL = "0x3ae658656d1c526144db371faef2fff7170654ee"
LQDR = "0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9"
SHADOW = ["0x59ab3c33e75C91B2B632d51144e57293EF64E556","0xDC5bDd3966884a2b1cfFd4213DaE925778786f97",
 "0xFfa8B88160Bd847a3bF032B78c8967DCa877981C","0x767e4Dc3EA4FF70D97BDEEF086e4B021923E4BdD",
 "0xA7cB4E3Ea2d6B44F4109970d7E9E7B7aBa372Eb5","0x9CD5ab5b2c00560E93Bb89174078a05b03Eb469e",
 "0x477A71A9154050DFbC497B9F782CC5169f7BDDf5","0xc43a1555554FF87f957c0DD5B80ab54951265c2E",
 "0xf4987eE98881ded997D1F3389B82ADF99e6592ed","0x3F576a5a3eb52e658bc88c23d8478Ac67eC90aeE",
 "0x3Ce75C35AF2DD29D76C7C8521c218c5A0f2826A8","0x71943a80a81c64235fC45DE4BD06638556fC773E",
 "0x3beFeA69e89931b70B80231389F97A9bF6827B2E","0x62A8bB540e52eDfFa5F71B9Ad6BEF52600A1e247",
 "0xDcBd61032cF40C16f6d7B124676C89a0e2e874c4","0xBb07eBA448e404B56Ba1273B762d690A57F7f84f",
 "0x5bC0F62BfBAc6C5f977BaC73EdC8FbCED89Ba8EC","0x4423Ca3dB49914c13068C484F9D341D636A515dd",
 "0x22214b00318300e0D046feD2D9CB166cBb48Ba60","0xA8E6F303092F0c345eEc9f780d72A8Bf56C54DF0",
 "0x04C4244F6b497343e2CcD6f3fE992910c8557dCE","0x46F8546E33900CcdB5D5FBE80af2449ecAe42128",
 "0xD75d45215a5E8E484F1f094f15b2f626A953456e","0x9757fd7d3B6281218E11Bab3b550eab8C4eF5eA9",
 "0xa0AC54644dfCE40F83F3B1BC941c234532B4B8e1","0x763caa35565d457AD4231E089C3E8fb3d0fa3d56",
 "0xf2c00E3ee1c67aAD4169bD041aFd3B7ff98b2775","0x57B57A9a34de8547EC4a26b4bded6e78c92C9A76",
 "0x948dbcf4595366297E5F2c1baD1593dBBDe875C6","0x1c9c9d2A73A07F2cbAaa7C086a2DA70f155667d6",
 "0x0f45B4A89AAb28f4C4dC2d08ebAD277983d4B67a","0x0BF91d2e547A07A41d48817bDD28cb331227d945",
 "0x762C8112207820d60FbB9894D429A60c570Ab574","0xD354908d297ce9a348b417d2e0F561EE7D11de5E"]
HUNDRED = ["0x79364E45648Db09eE9314E47b2fD31c199Eb03B9","0x9A07fB107b9d8eA8B82ECF453Efb7cFb85A66Ce9",
           "0xeD566B089Fc80Df0e8D3E0AD3aD06116433Bf4a7","0x669F5f289A5833744E830AD6AB767Ea47A3d6409"]

def log(*a):
    print(*a, flush=True)

def main():
    state = {"blocks": {}, "errors": []}
    for ch in ("fantom", "bsc"):
        r = rpc_one(ch, "eth_blockNumber", [])
        state["blocks"][ch] = int(r, 16) if isinstance(r, str) else r
    log("blocks:", state["blocks"])

    # ---- MasterChef ----
    pl = uint(eth_call("fantom", MC, SIG["poolLength()"])) or 0
    pools = []
    items = []
    for i in range(pl):
        items.append((MC, SIG["poolInfo(uint256)"] + enc_uint(i), None))
    res = multi("fantom", items)
    for i, r in enumerate(res):
        if not isinstance(r, str) or len(r) < 2 + 64*5:
            pools.append({"pid": i, "error": str(r)[:60]})
            continue
        b = bytes.fromhex(r[2:])
        pools.append({"pid": i, "lpToken": "0x" + b[12:32].hex(),
                      "allocPoint": int.from_bytes(b[32:64], "big"),
                      "lastRewardBlock": int.from_bytes(b[64:96], "big"),
                      "accLqdrPerShare": int.from_bytes(b[96:128], "big"),
                      "depositFeeBP": int.from_bytes(b[128:160], "big")})
    state["masterchef"] = {"address": MC, "poolLength": pl, "pools": pools,
                           "lqdrBalance": uint(eth_call("fantom", LQDR, SIG["balanceOf(address)"] + enc_addr(MC)))}
    log("masterchef pools:", pl)

    # ---- MiniChefs ----
    for nm, ch, chef in (("fantom", "fantom", MINI_FTM), ("bsc", "bsc", MINI_BSC)):
        pl = uint(eth_call(ch, chef, SIG["poolLength()"])) or 0
        rows = []
        items = []
        for i in range(pl):
            items.append((chef, SIG["lpToken(uint256)"] + enc_uint(i), None))
            items.append((chef, SIG["strategies(uint256)"] + enc_uint(i), None))
        res = multi(ch, items)
        for i in range(pl):
            rows.append({"pid": i, "lpToken": addr(res[2*i]), "strategy": addr(res[2*i+1])})
        # balances of strategies + chef
        items = []
        for r in rows:
            if r["strategy"] and r["strategy"] != "0x" + "0"*40 and r["lpToken"]:
                items.append((r["lpToken"], SIG["balanceOf(address)"] + enc_addr(r["strategy"]), None))
            else:
                items.append(None)
        got = multi(ch, [x for x in items if x]) if any(items) else []
        k = 0
        for j, r in enumerate(rows):
            if items[j] is not None:
                r["strategyBalance"] = uint(got[k]); k += 1
            if r["lpToken"]:
                r["chefBalance"] = uint(eth_call(ch, r["lpToken"], SIG["balanceOf(address)"] + enc_addr(chef)))
        state["minichef_" + nm] = {"address": chef, "poolLength": pl, "pools": rows}
        log(f"minichef {nm} pools:", pl)

    # ---- strategies detail (fantom) ----
    strategies = []
    seen = set()
    for r in state["minichef_fantom"]["pools"]:
        st = r.get("strategy")
        if st and st != "0x" + "0"*40 and st not in seen:
            seen.add(st)
            strategies.append(st)
    log("unique strategies:", len(strategies))
    srows = []
    items = []
    for st in strategies:
        items.append((st, SIG["want()"], None))
        items.append((st, SIG["balanceOfWant()"], None))
        items.append((st, SIG["depositor()"], None))
        items.append((st, SIG["harvesters(address)"] + enc_addr(ATK), None))
        items.append((st, SIG["withdraw(uint256)"] + enc_uint(0), ATK))
        items.append((st, SIG["harvest()"], ATK))
        items.append((st, SIG["getHarvestable()"], None))
    res = multi("fantom", items, workers=6)
    for i, st in enumerate(strategies):
        b = res[7*i:7*i+7]
        srows.append({"strategy": st, "want": addr(b[0]), "balanceOfWant": uint(b[1]),
                      "depositor": addr(b[2]), "attacker_is_harvester": b[3],
                      "sim_withdraw0_from_attacker": b[4] if isinstance(b[4], str) else str(b[4]),
                      "sim_harvest_from_attacker": b[5] if isinstance(b[5], str) else str(b[5]),
                      "getHarvestable": uint(b[6])})
    state["strategies"] = srows
    log("strategies probed")

    # ---- shadow farms ----
    items = []
    for a in SHADOW:
        items.append((a, SIG["lpToken()"], None))
        items.append((a, SIG["strategy()"], None))
        items.append((a, SIG["owner()"], None))
    res = multi("fantom", items)
    sh = []
    for i, a in enumerate(SHADOW):
        sh.append({"addr": a, "lpToken": addr(res[3*i]), "strategy": addr(res[3*i+1]), "owner": addr(res[3*i+2])})
    # balances
    items = []
    idx = []
    for j, r in enumerate(sh):
        if r["lpToken"] and r["strategy"] and r["strategy"] != "0x" + "0"*40:
            items.append((r["lpToken"], SIG["balanceOf(address)"] + enc_addr(r["strategy"]), None)); idx.append((j, "strategyBalance"))
        if r["lpToken"]:
            items.append((r["lpToken"], SIG["balanceOf(address)"] + enc_addr(r["addr"]), None)); idx.append((j, "farmBalance"))
    res = multi("fantom", items)
    for (j, k), v in zip(idx, res):
        sh[j][k] = uint(v)
    state["shadow"] = sh
    log("shadow probed:", len(sh))

    # ---- hundredchef ----
    h = []
    items = []
    for a in HUNDRED:
        items.append((a, SIG["lpToken(uint256)"] + enc_uint(0), None))
        items.append((a, SIG["strategies(uint256)"] + enc_uint(0), None))
        items.append((a, SIG["owner()"], None))
    res = multi("fantom", items)
    for i, a in enumerate(HUNDRED):
        h.append({"addr": a, "hToken": addr(res[3*i]), "strategy": addr(res[3*i+1]), "owner": addr(res[3*i+2])})
    items = []
    idx = []
    for j, r in enumerate(h):
        if r["hToken"] and r["strategy"] and r["strategy"] != "0x" + "0"*40:
            items.append((r["hToken"], SIG["balanceOf(address)"] + enc_addr(r["strategy"]), None)); idx.append((j, "strategyBalance"))
            items.append((r["hToken"], SIG["balanceOf(address)"] + enc_addr(r["addr"]), None)); idx.append((j, "farmBalance"))
            items.append((r["hToken"], SIG["exchangeRateStored()"], None)); idx.append((j, "exchangeRate"))
    res = multi("fantom", items)
    for (j, k), v in zip(idx, res):
        h[j][k] = uint(v)
    state["hundred"] = h
    log("hundred probed")

    # ---- xLQDR ----
    state["xlqdr"] = {
        "address": XL,
        "supply": uint(eth_call("fantom", XL, SIG["supply()"])),
        "totalSupply": uint(eth_call("fantom", XL, SIG["totalSupply()"])),
        "lqdrBalance": uint(eth_call("fantom", LQDR, SIG["balanceOf(address)"] + enc_addr(XL))),
    }

    # ---- LP token metadata (unique) ----
    lps = set()
    for p in state["masterchef"]["pools"]:
        if p.get("lpToken"): lps.add(p["lpToken"].lower())
    for k in ("minichef_fantom", "minichef_bsc"):
        for p in state[k]["pools"]:
            if p.get("lpToken"): lps.add(p["lpToken"].lower())
    for r in sh:
        if r.get("lpToken"): lps.add(r["lpToken"].lower())
    lps = sorted(lps)
    log("unique lp tokens:", len(lps))
    items = []
    for lp in lps:
        items += [(lp, SIG["totalSupply()"], None), (lp, SIG["token0()"], None),
                  (lp, SIG["token1()"], None), (lp, SIG["getReserves()"], None), (lp, SIG["decimals()"], None)]
    res = multi("fantom", items, workers=8)
    lpmeta = {}
    for i, lp in enumerate(lps):
        b = res[5*i:5*i+5]
        m = {"totalSupply": uint(b[0]), "token0": addr(b[1]), "token1": addr(b[2]), "decimals": uint(b[4])}
        if isinstance(b[3], str) and len(b[3]) >= 2 + 64*3:
            bb = bytes.fromhex(b[3][2:])
            m["reserve0"] = int.from_bytes(bb[0:32], "big")
            m["reserve1"] = int.from_bytes(bb[32:64], "big")
        lpmeta[lp] = m
    state["lpmeta"] = lpmeta
    log("lpmeta done")

    # underlying token decimals
    underlyings = set()
    for m in lpmeta.values():
        if m.get("token0"): underlyings.add(m["token0"].lower())
        if m.get("token1"): underlyings.add(m["token1"].lower())
    underlyings = sorted(underlyings)
    res = multi("fantom", [(t, SIG["decimals()"], None) for t in underlyings], workers=8)
    tdec = {}
    for t, r in zip(underlyings, res):
        tdec[t] = uint(r) if uint(r) is not None else 18
    state["token_decimals"] = tdec

    # ---- prices ----
    prices = {}
    llama_ids = []
    tokmap = {}
    def add_tok(chain, t, nm):
        key = f"{chain}:{t}"
        tokmap[key] = nm
        llama_ids.append(key)
    add_tok("fantom", "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83", "WFTM")
    add_tok("fantom", "0x04068da6c83afcfa0e13ba15a6696662335d5b75", "USDC")
    add_tok("fantom", LQDR, "LQDR")
    add_tok("fantom", "0xd7028092c830b5c8fce061af2e593413ebbc1fc1", "sFTMX")
    add_tok("bsc", "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", "USDC_BSC")
    add_tok("bsc", "0xe9e7cea3dedca5984780bafc599bd69add087d56", "BUSD")
    add_tok("bsc", "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c", "WBNB")
    for lp in lps:
        m = lpmeta.get(lp) or {}
        if m.get("token0"):
            add_tok("fantom", m["token0"], m["token0"])
        if m.get("token1"):
            add_tok("fantom", m["token1"], m["token1"])
    try:
        url = "https://coins.llama.fi/prices/current/" + ",".join(llama_ids)
        d = post(url, None) if False else None
    except Exception:
        pass
    try:
        req = urllib.request.Request("https://coins.llama.fi/prices/current/" + ",".join(llama_ids),
                                     headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=40) as r:
            pdata = json.loads(r.read().decode())
        for k, v in (pdata.get("coins") or {}).items():
            prices[k] = {"usd": v["price"], "symbol": v.get("symbol")}
    except Exception as e:
        state["errors"].append(f"llama: {e}")
    # DexScreener LQDR fallback
    try:
        req = urllib.request.Request(f"https://api.dexscreener.com/latest/dex/tokens/{LQDR}",
                                     headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            dd = json.loads(r.read().decode())
        pairs = [p for p in (dd.get("pairs") or []) if p.get("priceUsd")]
        pairs.sort(key=lambda p: float(p.get("liquidity", {}).get("usd") or 0), reverse=True)
        if pairs:
            prices[f"fantom:{LQDR}"] = {"usd": float(pairs[0]["priceUsd"]), "symbol": "LQDR", "src": "dexscreener"}
            prices["dexscreener_lqdr_pairs"] = [{"dex": p.get("dexId"), "pair": p.get("pairAddress"),
                "priceUsd": p.get("priceUsd"), "liqUsd": (p.get("liquidity") or {}).get("usd"),
                "vol24h": (p.get("volume") or {}).get("h24")} for p in pairs[:5]]
    except Exception as e:
        state["errors"].append(f"dexscreener: {e}")
    state["prices"] = prices
    log("prices:", json.dumps({k: v for k, v in prices.items() if k != "dexscreener_lqdr_pairs"})[:400])

    # ---- values ----
    def price_of(chain, t):
        p = prices.get(f"{chain}:{t.lower()}")
        return p["usd"] if p else None
    def lp_value(lp, amount):
        m = lpmeta.get(lp.lower()) or {}
        ts = m.get("totalSupply")
        if not ts or not m.get("reserve0"):
            return None
        d0 = tdec.get((m.get("token0") or "").lower(), 18)
        d1 = tdec.get((m.get("token1") or "").lower(), 18)
        v0 = (price_of("fantom", m["token0"]) or 0) * m["reserve0"] / (10 ** d0)
        v1 = (price_of("fantom", m["token1"]) or 0) * m["reserve1"] / (10 ** d1)
        return (v0 + v1) * (amount / ts)
    values = {"masterchef": [], "minichef_fantom": [], "minichef_bsc": [], "shadow": [], "hundred": [], "xlqdr": None}
    for p in state["masterchef"]["pools"]:
        if p.get("lpToken") and p.get("chefBalance"):
            v = lp_value(p["lpToken"], p["chefBalance"])
            values["masterchef"].append({"pid": p["pid"], "lpToken": p["lpToken"],
                                         "amount": p["chefBalance"], "usd": v})
    for k in ("minichef_fantom", "minichef_bsc"):
        for p in state[k]["pools"]:
            tot = (p.get("strategyBalance") or 0) + (p.get("chefBalance") or 0)
            if p.get("lpToken") and tot:
                v = lp_value(p["lpToken"], tot)
                values[k].append({"pid": p["pid"], "lpToken": p["lpToken"], "amount": tot, "usd": v})
    for r in sh:
        tot = (r.get("strategyBalance") or 0) + (r.get("farmBalance") or 0)
        if r.get("lpToken") and tot:
            v = lp_value(r["lpToken"], tot)
            values["shadow"].append({"addr": r["addr"], "lpToken": r["lpToken"], "amount": tot, "usd": v})
    HUSDC = "0x9a07fb107b9d8ea8b82ecf453efb7cfb85a66ce9"
    for r in h:
        if r.get("hToken") and r.get("strategyBalance") and r.get("exchangeRate"):
            # underlyingRaw = cTokenRaw * exchangeRate / 1e18 (Compound exchangeRate scaling)
            underlying_raw = r["strategyBalance"] * r["exchangeRate"] / 1e18
            udec = 6 if r["addr"].lower() == HUSDC else 18
            usd = underlying_raw / (10 ** udec) * (price_of("fantom", "0x04068da6c83afcfa0e13ba15a6696662335d5b75") or 0)
            values["hundred"].append({"addr": r["addr"], "hToken": r["hToken"],
                                      "stratBalance": r["strategyBalance"],
                                      "underlyingRaw": underlying_raw, "underlyingDecimals": udec,
                                      "usd": usd})
    if state["xlqdr"].get("lqdrBalance"):
        values["xlqdr"] = {"lqdr": state["xlqdr"]["lqdrBalance"],
                           "usd": state["xlqdr"]["lqdrBalance"] / 1e18 * (price_of("fantom", LQDR) or 0)}
    def total(key):
        return sum(x["usd"] or 0 for x in values[key]) if isinstance(values[key], list) else (values[key] or {}).get("usd", 0)
    values["totals"] = {k: total(k) for k in ("masterchef", "minichef_fantom", "minichef_bsc", "shadow", "hundred")}
    values["totals"]["xlqdr"] = (values["xlqdr"] or {}).get("usd", 0)
    values["totals"]["grand"] = sum(values["totals"].values())
    state["values"] = values
    log("values totals:", json.dumps(values["totals"]))

    with open(os.path.join(OUTDIR, "live-state.json"), "w") as f:
        json.dump(state, f, indent=1)
    log("saved ci-out/live-state.json")

if __name__ == "__main__":
    main()
