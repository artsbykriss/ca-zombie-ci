#!/usr/bin/env python3
"""
MinMax Finance (IoTeX) — live extractability simulation at a pinned block.

For every MinMax pool and every ordered token pair, finds the best closed cycle
    WIOTX --(Mimo V2)--> token_in --(MinMax Saddle pool)--> token_out --(Mimo V2)--> WIOTX
using:
  * the live Saddle contract's own calculateSwap() via eth_call at the pinned block, and
  * exact Uniswap-V2 constant-product math with the empirically verified 0.3% fee (Mimo legs).

Also: XIM conditional analysis via the only XIM exit (MAX/XIM pair).

Read-only. Public RPC only. Outputs JSON.
"""
import json, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

RPC = "https://babel-api.mainnet.iotex.io"
PIN_BLOCK = "latest"

def rpc(method, params, retries=3):
    for _ in range(retries + 1):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(0.3)
    return {}

def call(to, data):
    d = rpc("eth_call", [{"to": to, "data": data}, PIN_BLOCK])
    return d.get("result") if "result" in d else None

def words(h):
    if not h or h == "0x": return []
    h = h[2:]
    return [int(h[i:i+64], 16) for i in range(0, len(h), 64)]

def addr(w): return "0x" + f"{w:040x}"[-40:]

SYM = {
 "0xa00744882684c3e4747faefd68d283ea44099d03": "WIOTX",
 "0xacee9b11cd4b3f57e58880277ac72c8c41abe4e4": "ioBUSD",
 "0x3b2bf2b523f54c4e454f08aa286d03115aff326c": "ioUSDC",
 "0x6fbcdc1169b5130c59e72e51ed68a84841c98cd1": "ioUSDT",
 "0x1cbad85aa66ff3c12dc84c5881886eeb29c1bb9b": "ioDAI",
 "0x84abcb2832be606341a50128aeb1db43aa017449": "BUSD-bsc",
 "0x037346e5a5722957ac2cab6ceb8c74fc18cea91d": "USDC_b",
 "0x42c9255d5e522e83b16ea11a3ba04c2d3afca079": "USDT_b",
 "0x3cdb7c48e70b854ed2fa392e21687501d84b3afc": "USDT-matic",
 "0x62a9d987cbf4c45a550deed5b57b200d7a319632": "DAI-matic",
 "0xc04da3a99d17135857bb937d2fbb321d3b6c6a81": "USDC-matic",
 "0xec690cdd448e3cbb51ed135df72301c3265a8f80": "XIM",
 "0xb62171f7c637707c9bd8d300c92137c47f63065e": "XIM-old",
 "0xe45d95a66cff6ab5e9b796cf5a36f0669af3ec98": "MAX",
}

WIOTX = "0xa00744882684c3e4747faefd68d283ea44099d03"
MIMO_WIOTX = {
 "ioUSDC":     "0x68bf247e1F763cB157b2B5F1B927DFf4522723D5",
 "ioBUSD":     "0x2a7775e754ca239c54030d7d804c7cb49cb38567",
 "ioUSDT":     "0xe82b7054471d3f5cc825c50350da3bca64f7be4e",
 "BUSD-bsc":   "0x6bdefe87c4b18726002d3505b3251c89c8004c6a",
 "USDT_b":     "0x9e774a0c1e61c415e2a9f3c020caae8701c6122e",
 "BNB-bsc":    "0xa1313c9e020df867d90afb72a19882f5dd81a3f9",
 "DAI-matic":  "0xd40bfd9bffc798b5183cbe27d877562fb09c8958",
 "USDT-matic": "0xb30ddcc6df9839669f50ec9202828826ec36ef7c",
 "MAX":        "0xd27f9437f800d2cadfc0f687ab208dde4d1fb0a7",
}
MAX_XIM_PAIR = "0xde7399ec841627bc68243832572086b9d2d41404"
FEE_NUM, FEE_DEN = 997, 1000

POOLS = [
 ("P1_E4",  "0x89963FCD25Cd3b369A2e0642521BCA7Cf0B9d547", False),
 ("P2_XIM", "0x2c1B1DE747043f7C7c8e0896EB33b09eD9ED55c5", False),
 ("P3_E3",  "0xC264ED05ed2aF451732EF05C480d9e51b92a07aC", False),
 ("P5_B3",  "0x09A1B7d922BcfECa097b06498Bc992A83b0BCc42", False),
 ("P6_XIM", "0xe409587F043f74e47eFB0C10aAf40808D4e037cE", False),
 ("P7_USDT", "0x074ec23e80bd1fd26b822305614fb10b97847a35", False),
 ("P9_M3",  "0xdab7B4D2CA330dde50ce611E2177271fD3Eb3F5F", False),
 ("P11_XIM", "0x73541e9ffb9F4B8d13C2E5621b1Cede1981aD0d9", False),
 ("A8D_io3", "0xA8D60c3574f2A3f32bA6226939Df15092DD03617", False),
 ("P4_META", "0x8360D306Be83f9A992b1657Ad68fe08Ca6f2757A", True),
 ("P8_META", "0x833d89FA7dD693035678AB53Be792F6F4B352C01", True),
 ("P10_META", "0x7B24cAA6a497bc79FDfBAeb8A71a38F15eB3d7F7", True),
 ("M22_oldXIM_P5LP", "0x22CB23Cb5F5Da3547F51909fEC8b3aE83589CE07", True),
 ("M55_oldXIM_P3LP", "0x55Ce939A353dFED2B898C6EFcD8994ee414df7a8", True),
 ("M70_oldXIM_P9LP", "0x70CDfb660835a80BFADCc2BB0c17ac15245C9890", True),
 ("M5F_ioUSDT_P9LP", "0x5F0273ABD7754EF42a4eC320c97d5Eb1e270e54c", False),
 ("M88_DAIm_P1LP", "0x886fA6ca90750ddd53E74217Be01eDF9049dAc2f", True),
 ("MA6_BUSD_P1LP", "0xA63B7e43F4cb7C4E366e5524849a8eAc1086D33e", True),
 ("MEd_ioUSDT_P5LP", "0xEd01d84879D56Eb4e0969007ab8aF0e1996353A2", False),
]

def pair_reserves(pair):
    r = call(pair, "0x0902f1ac")
    w = words(r) if r else []
    t0 = words(call(pair, "0x0dfe1681") or "0x")[0]
    t1 = words(call(pair, "0xd21220a7") or "0x")[0]
    return {"t0": addr(t0), "t1": addr(t1), "r0": w[0], "r1": w[1]}

def cp_out(r_in, r_out, dx):
    if dx <= 0 or r_in <= 0 or r_out <= 0: return 0
    dxf = dx * FEE_NUM
    return (r_out * dxf) // (r_in * FEE_DEN + dxf)

def mimo_buy(sym, wiotx_in, pi):
    p = pi[sym]
    r_w, r_t = (p["r0"], p["r1"]) if p["t0"] == WIOTX else (p["r1"], p["r0"])
    return cp_out(r_w, r_t, wiotx_in)

def mimo_sell(sym, token_in, pi):
    p = pi[sym]
    r_w, r_t = (p["r0"], p["r1"]) if p["t0"] == WIOTX else (p["r1"], p["r0"])
    return cp_out(r_t, r_w, token_in)

def saddle_calc(pool, i, j, dx):
    data = "0xa95b089f" + f"{i:064x}" + f"{j:064x}" + f"{dx:064x}"
    r = call(pool, data)
    return words(r)[0] if r else None

def get_token_dec(pool, i):
    r = call(pool, "0x82b86600" + f"{i:064x}")
    return addr(words(r)[0]) if r else None

def main():
    global PIN_BLOCK
    bn = rpc("eth_blockNumber", {})
    if isinstance(bn, dict):
        h = bn.get("result")
        PIN_BLOCK = h if h else "latest"
    print("pinned block:", PIN_BLOCK, flush=True)

    # 1) pair reserves
    with ThreadPoolExecutor(max_workers=10) as ex:
        pi = dict(zip(MIMO_WIOTX.keys(), ex.map(lambda s: pair_reserves(MIMO_WIOTX[s]), MIMO_WIOTX.keys())))
        pi["MAX_XIM"] = pair_reserves(MAX_XIM_PAIR)

    # 2) pool tokens
    def toks_for(p):
        return [get_token_dec(p, i) for i in range(4)]
    with ThreadPoolExecutor(max_workers=10) as ex:
        pool_toks = dict(zip([n for n, _, _ in POOLS], ex.map(lambda t: toks_for(t[1]), POOLS)))

    # 3) build the work list of (pool, i, j, sizes)
    grid = [10**16, 10**17, 3 * 10**17, 10**18, 3 * 10**18, 10**19, 3 * 10**19, 10**20, 3 * 10**20, 10**21]
    work = []
    for name, pool, paused in POOLS:
        toks = [t for t in pool_toks[name] if t]
        syms = [SYM.get(t) for t in toks]
        if paused:
            continue
        for i in range(len(toks)):
            if syms[i] not in MIMO_WIOTX: continue
            for j in range(len(toks)):
                if i == j or syms[j] not in MIMO_WIOTX: continue
                for w in grid:
                    work.append((name, pool, i, j, syms[i], syms[j], w))
    print("work items:", len(work), flush=True)

    def run_item(it):
        name, pool, i, j, si, sj, w = it
        t_in = mimo_buy(si, w, pi)
        if t_in <= 0: return None
        t_out = saddle_calc(pool, i, j, t_in)
        if not t_out: return None
        w_out = mimo_sell(sj, t_out, pi)
        return {"pool": name, "from": si, "to": sj, "wiotx_in": w, "t_in": t_in, "t_out": t_out,
                "wiotx_out": w_out, "profit_wei": w_out - w}
    with ThreadPoolExecutor(max_workers=14) as ex:
        items = list(ex.map(run_item, work))
    items = [x for x in items if x]

    # 4) aggregate per pool/pair
    best = {}
    for x in items:
        k = (x["pool"], x["from"], x["to"])
        if k not in best or x["profit_wei"] > best[k]["profit_wei"]:
            best[k] = x

    # 5) refinement around the best input for each (pool, pair)
    ref_items = []
    for k, b in best.items():
        name = b["pool"]
        pool = dict((n, p) for n, p, _ in POOLS)[name]
        toks = [t for t in pool_toks[name] if t]
        syms = [SYM.get(t) for t in toks]
        i = syms.index(b["from"]); j = syms.index(b["to"])
        w0 = b["wiotx_in"]
        for f in [0.25, 0.4, 0.55, 0.7, 0.85, 1.0, 1.2, 1.5, 2.0]:
            ref_items.append((name, pool, i, j, b["from"], b["to"], int(w0 * f)))
    with ThreadPoolExecutor(max_workers=14) as ex:
        ref = list(ex.map(run_item, ref_items))
    for x in [r for r in ref if r]:
        k = (x["pool"], x["from"], x["to"])
        if x["profit_wei"] > best[k]["profit_wei"]:
            best[k] = x

    # 6) XIM conditional: MAX/XIM pair exit
    px = pi["MAX_XIM"]
    r_xim, r_max = (px["r0"], px["r1"]) if px["t0"] != WIOTX else (px["r1"], px["r0"])
    # find which side is XIM
    xim_addr = "0xec690cdd448e3cbb51ed135df72301c3265a8f80"
    if px["t0"].lower() == xim_addr:
        r_xim, r_max = px["r0"], px["r1"]
    elif px["t1"].lower() == xim_addr:
        r_xim, r_max = px["r1"], px["r0"]
    max_wiotx_out = mimo_sell("MAX", cp_out(r_xim, r_max, 10**18 * 500), pi)  # sell 500 XIM into MAX/XIM then MAX->WIOTX

    out = {
        "block": PIN_BLOCK,
        "pair_reserves": {k: {kk: (str(vv) if isinstance(vv, int) else vv) for kk, vv in v.items()} for k, v in pi.items()},
        "pool_tokens": {k: v for k, v in pool_toks.items()},
        "best_per_pair": {f"{k[0]}|{k[1]}->{k[2]}": v for k, v in sorted(best.items(), key=lambda kv: -kv[1]["profit_wei"])},
        "xim_exit": {"max_xim_sell_500_wiotx_out_wei": max_wiotx_out,
                     "note": "500 XIM sold through MAX/XIM then MAX->WIOTX; the only XIM exit on IoTeX"},
    }
    # USD conversion (keyless public API)
    try:
        req = urllib.request.Request("https://coins.llama.fi/prices/current/coingecko:iotex",
                                     headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as r:
            iotx_usd = json.loads(r.read())["coins"]["coingecko:iotex"]["price"]
    except Exception:
        iotx_usd = None
    out["iotx_usd"] = iotx_usd
    dst = sys.argv[1] if len(sys.argv) > 1 else "extract_sim_out.json"
    json.dump(out, open(dst, "w"), indent=1)
    # print summary
    print("\n=== best cycle profit per pool (WIOTX wei) ===")
    for k, v in sorted(best.items(), key=lambda kv: -kv[1]["profit_wei"])[:30]:
        usd = (v["profit_wei"] / 1e18 * iotx_usd) if iotx_usd else 0
        print(f"{k[0]:16s} {k[1]:11s}->{k[2]:11s} in={v['wiotx_in']/1e18:12.5f} out={v['wiotx_out']/1e18:12.5f} profit={v['profit_wei']/1e18:+.8f} WIOTX (${usd:+.4f})")
    print("\nXIM exit (500 XIM -> WIOTX):", (max_wiotx_out or 0) / 1e18, "WIOTX",
          f"(${(max_wiotx_out or 0)/1e18*iotx_usd:.4f})" if iotx_usd else "")

if __name__ == "__main__":
    main()
