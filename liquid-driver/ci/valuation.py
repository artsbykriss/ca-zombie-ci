#!/usr/bin/env python3
"""
CI valuation for Liquid Driver (READ ONLY): computes USD values of all live custody
using DefiLlama/DexScreener prices, Balancer/Beethoven pool tokens, and reads rewarders.
Writes ci-out/valuation.json
"""
import json, os, subprocess, urllib.request, time
from concurrent.futures import ThreadPoolExecutor

FANTOM = os.environ.get("FANTOM_RPC_URL") or "https://fantom.drpc.org"
BSC = os.environ.get("BSC_RPC_URL") or "https://bsc-rpc.publicnode.com"
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")
os.makedirs(OUTDIR, exist_ok=True)
STATE = os.path.join(OUTDIR, "live-state.json")
ATK = "0x1111111111111111111111111111111111111111"
VAULT = "0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce"
MC = "0x742474dae70fa2ab063ab786b1fbe5704e861a0c"
MINI = "0x6e2ad6527901c9664f016466b8da1357a004db0f"

def post(url, payload, timeout=30):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc(url, method, params, retries=3):
    for a in range(retries):
        try:
            d = post(url, {"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
            if "result" in d: return d["result"]
        except Exception:
            pass
        time.sleep(0.4 * (a + 1))
    return None

def call(url, to, data, frm=None):
    p = {"to": to, "data": data}
    if frm: p["from"] = frm
    return rpc(url, "eth_call", [p, "latest"])

def sig(s):
    return subprocess.run(["cast", "sig", s], capture_output=True, text=True).stdout.strip()

def addr(r):
    return "0x" + r[-40:] if isinstance(r, str) and len(r) >= 42 else None

def uint(r):
    try:
        return int(r, 16) if isinstance(r, str) and r != "0x" else None
    except Exception:
        return None

def enc_addr(a): return a[2:].lower().rjust(64, "0")
def enc_uint(n): return hex(n)[2:].rjust(64, "0")

def multi(url, items, workers=6):
    out = [None] * len(items)
    def w(i):
        to, data = items[i]
        out[i] = call(url, to, data)
    with ThreadPoolExecutor(max_workers=workers) as ex:
        list(ex.map(w, range(len(items))))
    return out

def main():
    state = json.load(open(STATE))
    F, B = FANTOM, BSC
    out = {"blocks": state["blocks"]}

    # ---------- prices: gather all underlyings ----------
    toks = set()
    for lp, m in state["lpmeta"].items():
        for k in ("token0", "token1"):
            if m.get(k): toks.add(m[k].lower())
    for t in ["0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83", "0x04068da6c83afcfa0e13ba15a6696662335d5b75",
              "0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9", "0xd7028092c830b5c8fce061af2e593413ebbc1fc1",
              "0x049d68029688eabf473097a2fc38ef61633a3c7a"]:
        toks.add(t)
    toks = sorted(toks)
    prices = {}
    for i in range(0, len(toks), 40):
        batch = toks[i:i+40]
        url = "https://coins.llama.fi/prices/current/" + ",".join(f"fantom:{t}" for t in batch)
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=40) as r:
                pd = json.loads(r.read().decode())
            for k, v in (pd.get("coins") or {}).items():
                prices[k] = {"usd": v["price"], "symbol": v.get("symbol")}
        except Exception as e:
            out.setdefault("errors", []).append(f"llama {i}: {e}")
    # DexScreener LQDR
    try:
        req = urllib.request.Request(f"https://api.dexscreener.com/latest/dex/tokens/0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9",
                                     headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            dd = json.loads(r.read().decode())
        pairs = sorted([p for p in (dd.get("pairs") or []) if p.get("priceUsd")],
                       key=lambda p: float(p.get("liquidity", {}).get("usd") or 0), reverse=True)
        out["dexscreener_lqdr"] = [{"dex": p.get("dexId"), "pair": p.get("pairAddress"), "priceUsd": p.get("priceUsd"),
                                    "liqUsd": (p.get("liquidity") or {}).get("usd")} for p in pairs[:5]]
        if pairs:
            prices["fantom:0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9"] = {"usd": float(pairs[0]["priceUsd"]), "symbol": "LQDR", "src": "dexscreener"}
    except Exception as e:
        out.setdefault("errors", []).append(f"dexscreener: {e}")
    out["prices"] = prices

    def px(t):
        p = prices.get(f"fantom:{t.lower()}") if t else None
        return p["usd"] if p else None

    # ---------- MasterChef LP balances ----------
    pl = uint(call(F, MC, sig("poolLength()"))) or 0
    items = []
    for i in range(pl):
        items.append((MC, sig("poolInfo(uint256)") + enc_uint(i)))
    res = multi(F, items)
    mcpools = []
    for i, r in enumerate(res):
        if not isinstance(r, str) or len(r) < 66: continue
        lp = "0x" + r[2:66][24:64]
        bal = uint(call(F, lp, sig("balanceOf(address)") + enc_addr(MC)))
        mcpools.append({"pid": i, "lpToken": lp, "chefBalance": bal})
    out["mc_pools"] = mcpools

    # ---------- MiniChef rewarders + BSC minichef + BSC xLQDR ----------
    rew = []
    for i in range(state["minichef_fantom"]["poolLength"]):
        r = call(F, MINI, sig("rewarder(uint256)") + enc_uint(i))
        a = addr(r)
        if a and a != "0x" + "0"*40:
            rew.append({"pid": i, "rewarder": a})
    out["rewarders"] = rew

    bsc_extra = {}
    bsc_extra["minichef_bsc_pools"] = state.get("minichef_bsc", {}).get("pools")
    xl_bsc = "0x3ae658656d1c526144db371faef2fff7170654ee"
    bsc_extra["xlqdr_bsc"] = {
        "supply": uint(call(B, xl_bsc, sig("supply()"))),
        "totalSupply": uint(call(B, xl_bsc, sig("totalSupply()"))),
        "lqdrBalance": uint(call(B, "0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9", sig("balanceOf(address)") + enc_addr(xl_bsc))),
    }
    out["bsc_extra"] = bsc_extra

    # ---------- BPT resolution (Beethoven vault) ----------
    t0 = subprocess.run(["cast", "keccak", "PoolRegistered(bytes32,address,uint8)"], capture_output=True, text=True).stdout.strip()
    bpts = ["0xcdf68a4d525ba2e90fe959c74330430a5a6b8226", "0xc0064b291bd3d4ba0e44ccfc81bf8e7f7a579cd2",
            "0x30a92a4eeca857445f41e4bb836e64d66920f1c0", "0x8f6a658056378558ff88265f7c9444a0fb4db4be",
            "0x8b858eaf095a7337de6f9bc212993338773ca34e", "0x4e415957aa4fd703ad701e43ee5335d1d7891d83",
            "0x56ad84b777ff732de69e85813daee1393a9ffe10", "0xeadcfa1f34308b144e96fcd7a07145e027a8467d",
            "0xf6b8d1167aa8e0f070c50ca3552106e7604c6640", "0x95f959994df1d5df422f814641d0d1c93b621f62",
            "0x72bc4be6642355e820318f696340bfd8f2c7aa4e"]
    poolids = {}
    for bpt in bpts:
        logs = rpc(F, "eth_getLogs", [{"address": VAULT, "topics": [t0, None, "0x" + bpt[2:].lower().rjust(64, "0")],
                                       "fromBlock": "0x0", "toBlock": "latest"}])
        if isinstance(logs, list) and logs:
            poolids[bpt] = logs[-1]["topics"][1]
    out["poolids"] = poolids
    pooltokens = {}
    for bpt, pid in poolids.items():
        r = call(F, VAULT, sig("getPoolTokens(bytes32)") + pid[2:])
        if isinstance(r, str) and len(r) > 2:
            b = bytes.fromhex(r[2:])
            off_t = int.from_bytes(b[0:32], "big"); off_bal = int.from_bytes(b[32:64], "big")
            n = int.from_bytes(b[off_t:off_t+32], "big")
            toks = ["0x" + b[off_t+32+32*i+12:off_t+64+32*i].hex() for i in range(n)]
            nb = int.from_bytes(b[off_bal:off_bal+32], "big")
            bals = [int.from_bytes(b[off_bal+32+32*i:off_bal+64+32*i], "big") for i in range(nb)]
            pooltokens[bpt] = {"tokens": toks, "balances": bals}
    out["pooltokens"] = pooltokens

    # ---------- compute values ----------
    def lp_usd(lp, amount):
        m = state["lpmeta"].get(lp.lower(), {})
        ts, r0, r1 = m.get("totalSupply"), m.get("reserve0"), m.get("reserve1")
        if not ts or not amount:
            return None
        if r0 is None:
            return bpt_usd(lp, amount)
        d0 = state.get("token_decimals", {}).get((m.get("token0") or "").lower(), 18)
        d1 = state.get("token_decimals", {}).get((m.get("token1") or "").lower(), 18)
        v0 = (px(m.get("token0")) or 0) * r0 / 10**d0
        v1 = (px(m.get("token1")) or 0) * r1 / 10**d1
        return (v0 + v1) * amount / ts

    def bpt_usd(bpt, amount):
        pt = pooltokens.get(bpt)
        if not pt or not amount: return None
        m = state["lpmeta"].get(bpt.lower(), {})
        ts = m.get("totalSupply")
        if not ts: return None
        v = 0
        for t, b in zip(pt["tokens"], pt["balances"]):
            d = 18
            v += (px(t) or 0) * b / 10**d
        return v * amount / ts

    vals = {"masterchef_lp": [], "minichef_chef_lp": [], "minichef_strategy_lp": [], "shadow": [], "hundred": []}
    for p in mcpools:
        u = lp_usd(p["lpToken"], p["chefBalance"])
        vals["masterchef_lp"].append({**p, "usd": u})
    for p in state["minichef_fantom"]["pools"]:
        cb = p.get("chefBalance") or 0
        sb = p.get("strategyBalance") or 0
        if cb:
            u = lp_usd(p["lpToken"], cb)
            vals["minichef_chef_lp"].append({"pid": p["pid"], "lpToken": p["lpToken"], "amount": cb, "usd": u})
        if sb:
            u = lp_usd(p["lpToken"], sb)
            vals["minichef_strategy_lp"].append({"pid": p["pid"], "lpToken": p["lpToken"], "amount": sb, "usd": u})
    # strategy balanceOf() = want held + LP staked in external farms (Pickle-style)
    strat_bals = []
    srows = state.get("strategies", [])
    if srows:
        items = [(s["strategy"], sig("balanceOf()")) for s in srows if s.get("strategy")]
        res2 = multi(F, items)
        for s, r in zip(srows, res2):
            b = uint(r)
            if b:
                strat_bals.append({"strategy": s["strategy"], "want": s.get("want"), "balanceOf": b})
                u = lp_usd(s.get("want"), b) if s.get("want") else None
                vals["minichef_strategy_lp"].append({"pid": s.get("pid"), "lpToken": s.get("want"), "amount": b, "usd": u})
    out["strategy_balances"] = strat_bals
    for r in state["shadow"]:
        amt = (r.get("strategyBalance") or 0) + (r.get("farmBalance") or 0)
        if amt:
            u = lp_usd(r["lpToken"], amt)
            vals["shadow"].append({"addr": r["addr"], "lpToken": r["lpToken"], "amount": amt, "usd": u})
    for r in state["hundred"]:
        vals["hundred"].append(r)

    def s(key):
        return sum((x.get("usd") or 0) for x in vals[key])
    mc_lqdr = state["masterchef"]["lqdrBalance"] / 1e18
    lqdr_price = px("0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9")
    vals["totals"] = {
        "masterchef_lp_usd": s("masterchef_lp"),
        "masterchef_lqdr": mc_lqdr,
        "masterchef_lqdr_usd": mc_lqdr * (lqdr_price or 0),
        "minichef_chef_lp_usd": s("minichef_chef_lp"),
        "minichef_strategy_lp_usd": s("minichef_strategy_lp"),
        "shadow_usd": s("shadow"),
        "hundred_usd": s("hundred"),
        "xlqdr_lqdr": state["xlqdr"]["supply"] / 1e18,
        "xlqdr_usd_nominal": state["xlqdr"]["supply"] / 1e18 * (lqdr_price or 0),
    }
    vals["totals"]["grand_nominal_usd"] = sum(v for k, v in vals["totals"].items() if k.endswith("_usd"))
    out["values"] = vals
    out["lqdr_price_used"] = lqdr_price

    with open(os.path.join(OUTDIR, "valuation.json"), "w") as f:
        json.dump(out, f, indent=1)
    print(json.dumps(vals["totals"], indent=1))
    print("rewarders:", rew)
    print("saved ci-out/valuation.json")

if __name__ == "__main__":
    main()
