#!/usr/bin/env python3
"""MiniSwap Phase-2 CI enumeration:
 - enumerates factory1 (plain V2 pairs) and factory2 (mining V1 pairs)
 - reserves, balances, excess, LP supply, feeTemp MINI balances, whitelist status, mineInfo
 - DefiLlama pricing -> ci-out/summary.json
Read-only. Writes only under ci-out/."""
import json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rpc_ci as R

F1 = "0x1e2c2102cf8efcaaaf20ffe926469ec7cd0d0f6e"
F2 = "0x2294577031f113df4782b881cf0b140e94209a6f"
MINER1 = "0xcdd8dec17622468a1775d18bb4fcfe8be8ba8b68"
MINI = "0x4d953cf077c0c95ba090226e59a18fcf97db44ec"
OUT = "ci-out"

def dec_str(h):
    if not h or len(h) < 130: return None
    try:
        b = bytes.fromhex(h[2:]); off = int.from_bytes(b[0:32],'big')
        if off+32 > len(b): return None
        ln = int.from_bytes(b[off:off+32],'big')
        if ln > 64 or off+32+ln > len(b): return None
        return b[off+32:off+32+ln].decode('utf-8','replace')
    except Exception: return None

def U(h): return int(h,16) if h and h != "0x" else None

def enumerate_factory(factory, is_v1):
    n = int(R.eth_call(factory, R.SEL["allPairsLength"]) or "0x0", 16)
    pairs = []
    for i in range(n):
        r = R.eth_call(factory, "0x1e3dd18b" + f"{i:064x}")
        if r: pairs.append("0x" + r[-40:])
    recs = {}
    items, meta = [], []
    for p in pairs:
        for sel in ["token0","token1","getReserves","totalSupply","symbol"]:
            items.append((p, R.SEL[sel])); meta.append((p, sel))
        if is_v1:
            for sel in ["feeTemp","miner"]:
                items.append((p, R.SEL[sel])); meta.append((p, sel))
    res = R.calls_batched(items, chunk=10)
    for (p, sel), r in zip(meta, res): recs.setdefault(p, {})[sel] = r
    # balances + feeTemp MINI
    items2, meta2 = [], []
    for p in pairs:
        t0 = "0x"+(recs[p].get("token0") or "0x"+"0"*40)[-40:]
        t1 = "0x"+(recs[p].get("token1") or "0x"+"0"*40)[-40:]
        items2.append((t0, R.SEL["balanceOf"]+R.pad(p))); meta2.append((p,"bal0"))
        items2.append((t1, R.SEL["balanceOf"]+R.pad(p))); meta2.append((p,"bal1"))
        if is_v1 and recs[p].get("feeTemp"):
            ft = "0x"+recs[p]["feeTemp"][-40:]
            items2.append((MINI, R.SEL["balanceOf"]+R.pad(ft))); meta2.append((p,"feeTempMINI"))
            items2.append((ft, "0x8da5cb5b"))  # owner()
            meta2.append((p,"feeTempOwner"))
    res2 = R.calls_batched(items2, chunk=10)
    for (p,k), r in zip(meta2, res2): recs[p][k] = r
    # token meta
    tset = set()
    for p in pairs:
        tset.add("0x"+(recs[p].get("token0") or "0x"+"0"*40)[-40:])
        tset.add("0x"+(recs[p].get("token1") or "0x"+"0"*40)[-40:])
    items3, meta3 = [], []
    for t in tset:
        items3.append((t, R.SEL["symbol"])); meta3.append((t,"symbol"))
        items3.append((t, R.SEL["decimals"])); meta3.append((t,"decimals"))
    res3 = R.calls_batched(items3, chunk=10)
    tmeta = {t:{} for t in tset}
    for (t,k), r in zip(meta3, res3): tmeta[t][k] = r

    out = []
    for p in pairs:
        r = recs[p]
        t0 = "0x"+(r.get("token0") or "0x"+"0"*40)[-40:]
        t1 = "0x"+(r.get("token1") or "0x"+"0"*40)[-40:]
        g = r.get("getReserves") or ""
        rec = {"pair": p, "token0": t0, "token1": t1,
               "sym0": dec_str(tmeta[t0].get("symbol")), "sym1": dec_str(tmeta[t1].get("symbol")),
               "dec0": U(tmeta[t0].get("decimals")), "dec1": U(tmeta[t1].get("decimals")),
               "r0": U(g[2:66]) if len(g)>=130 else None, "r1": U(g[66:130]) if len(g)>=130 else None,
               "ts": U(r.get("totalSupply")), "bal0": U(r.get("bal0")), "bal1": U(r.get("bal1"))}
        rec["excess0"] = (rec["bal0"]-rec["r0"]) if rec["bal0"] is not None and rec["r0"] is not None else None
        rec["excess1"] = (rec["bal1"]-rec["r1"]) if rec["bal1"] is not None and rec["r1"] is not None else None
        if is_v1:
            rec["feeTemp"] = "0x"+r["feeTemp"][-40:] if r.get("feeTemp") else None
            rec["miner"] = "0x"+r["miner"][-40:] if r.get("miner") else None
            rec["feeTempMINI"] = U(r.get("feeTempMINI"))
            rec["feeTempOwner"] = "0x"+r["feeTempOwner"][-40:] if r.get("feeTempOwner") else None
        out.append(rec)
    return out

def price_all(pairs):
    toks = set()
    for p in pairs: toks.add(p["token0"]); toks.add(p["token1"])
    toks = sorted(toks)
    prices = {}
    for i in range(0, len(toks), 60):
        addrs = ",".join(f"ethereum:{t}" for t in toks[i:i+60])
        out = subprocess.run(["curl","-s","--max-time","60",f"https://coins.llama.fi/prices/current/{addrs}"],
                             capture_output=True).stdout
        try: prices.update(json.loads(out).get("coins", {}))
        except Exception as e: print("price err", e)
    def price(t):
        c = prices.get(f"ethereum:{t}"); return c["price"] if c else None
    tot = 0.0
    for p in pairs:
        d0 = p["dec0"] if p["dec0"] is not None else 18
        d1 = p["dec1"] if p["dec1"] is not None else 18
        p0, p1 = price(p["token0"]), price(p["token1"])
        v0 = (p["r0"]/10**d0)*p0 if (p0 and p["r0"] is not None) else None
        v1 = (p["r1"]/10**d1)*p1 if (p1 and p["r1"] is not None) else None
        p["usd0"], p["usd1"] = v0, v1
        p["usd"] = (v0 or 0)+(v1 or 0)
        tot += p["usd"]
    return tot

def main():
    os.makedirs(OUT, exist_ok=True)
    bn = R.rpc_batch([("eth_blockNumber", [])])[0]
    block = int(bn, 16)
    print(f"block={block}")
    f1 = enumerate_factory(F1, False)
    f2 = enumerate_factory(F2, True)
    print(f"factory1 pairs={len(f1)} factory2 pairs={len(f2)}")
    t1 = price_all(f1); t2 = price_all(f2)
    # mining state
    day = (block - 10804094)//6000
    mine = {}
    for d in [day-1, day, day+1]:
        mine[str(d)] = U(R.eth_call(MINER1, "0x5487aae2" + f"{d:064x}"))
    wl = {}
    for p in f2:
        wl[p["pair"]] = U(R.eth_call(MINER1, "0x32531c3c" + R.pad(p["pair"])))
    summary = {
        "block": block,
        "factory1": {"address": F1, "pairs": len(f1), "priced_usd": t1},
        "factory2": {"address": F2, "pairs": len(f2), "priced_usd": t2},
        "total_priced_usd": t1 + t2,
        "mineInfo": mine, "day_estimate": day, "daily_limit": 18000e18,
        "whitelisted": {k:v for k,v in wl.items() if v},
        "feeTempMINI_total": sum((p.get("feeTempMINI") or 0) for p in f2),
        "excess_total_usd_approx": sum(((p.get("excess0") or 0)+(p.get("excess1") or 0)) for p in f1+f2),  # raw units, not USD
    }
    json.dump(summary, open(f"{OUT}/summary.json","w"), indent=1)
    json.dump(f1, open(f"{OUT}/pairs_f1.json","w"), indent=1)
    json.dump(f2, open(f"{OUT}/pairs_f2.json","w"), indent=1)
    print(json.dumps({k:v for k,v in summary.items() if k not in ("whitelisted",)}, indent=1))
    print("feeTemp MINI total:", summary["feeTempMINI_total"]/1e18)
    print("saved ci-out/{summary,pairs_f1,pairs_f2}.json")

if __name__ == "__main__":
    main()
