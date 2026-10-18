import json, os, sys, time
from harness import *

BASE_FIELDS = [
 ("asset", "asset()", "addr"),
 ("oracle", "oracle()", "addr"),
 ("ltvlist", "LTVList()", "addrs"),
 ("totalAssets", "totalAssets()", "uint"),
 ("totalBorrows", "totalBorrows()", "uint"),
 ("totalSupply", "totalSupply()", "uint"),
 ("cash", "cash()", "uint"),
 ("irm", "interestRateModel()", "addr"),
 ("hooks", "hooks()", "addr"),
 ("governorAdmin", "governorAdmin()", "addr"),
 ("unitOfAccount", "unitOfAccount()", "addr"),
 ("name", "name()", "str"),
 ("symbol", "symbol()", "str"),
]

def decode(kind, h):
    if kind == "addr": return dec_addr(h)
    if kind == "uint": return dec_uint(h)
    if kind == "addrs": return dec_addrs(h)
    if kind == "str": return dec_str(h)
    return None

def collect_chain(name, proxies):
    c = CHAINS[name]; r = RPC(c["rpc"])
    r.block = None
    blk = r.blocknum()
    vs = proxies["proxies"]
    out = []
    # base fields; order = vault-major batches
    for i in range(0, len(vs), 60):
        part = vs[i:i+60]
        calls = []
        for v in part:
            for (_, sig, _) in BASE_FIELDS:
                calls.append((v, sel(sig)))
        res = r.mc(calls, chunksz=180)
        for j, v in enumerate(part):
            rec = {"chain": name, "address": v}
            for k, (fld, sig, kind) in enumerate(BASE_FIELDS):
                ok, h = res[j*len(BASE_FIELDS)+k]
                rec[fld] = decode(kind, h) if ok else None
            out.append(rec)
        print(f"[{name}] {min(i+60,len(vs))}/{len(vs)}", flush=True)
    # balances of asset held by vault
    calls = [(rec["asset"], sel("balanceOf(address)") + enc_addr(rec["address"])) if rec.get("asset") else None for rec in out]
    idx = [i for i, c in enumerate(calls) if c]
    res = r.mc([calls[i] for i in idx], chunksz=180)
    for jj, i in enumerate(idx):
        ok, h = res[jj]
        out[i]["assetBalance"] = dec_uint(h) if ok else None
    # per-collateral LTV
    pairs = []
    for rec in out:
        for col in (rec.get("ltvlist") or []):
            if col and col != "0x" + "0"*40:
                pairs.append((rec["address"], col))
    callmap = []
    for (v, col) in pairs:
        callmap.append((v, sel("LTVBorrow(address)") + enc_addr(col)))
        callmap.append((v, sel("LTVLiquidation(address)") + enc_addr(col)))
    res = r.mc(callmap, chunksz=180)
    ltv = {}
    for j, (v, col) in enumerate(pairs):
        okb, hb = res[2*j]; okl, hl = res[2*j+1]
        ltv.setdefault(v, {})[col] = {"borrow": dec_uint(hb) if okb else None,
                                      "liq": dec_uint(hl) if okl else None}
    for rec in out:
        rec["ltv"] = ltv.get(rec["address"], {})
    return {"chain": name, "block": blk, "vaults": out}

if __name__ == "__main__":
    names = sys.argv[1:] or list(CHAINS)
    pr = json.load(open(os.path.join(HERE, "raw_proxies.json")))
    fn = os.path.join(HERE, "raw_vaults.json")
    allout = json.load(open(fn)) if os.path.exists(fn) else {}
    for nm in names:
        if nm not in pr: continue
        try:
            allout[nm] = collect_chain(nm, pr[nm])
            json.dump(allout, open(fn, "w"))
            nz = sum(1 for v in allout[nm]["vaults"] if (v.get("totalAssets") or 0) > 0)
            print(f"[{nm}] done vaults={len(allout[nm]['vaults'])} nonzero={nz}", flush=True)
        except Exception as e:
            print(f"[{nm}] FAIL {type(e).__name__} {e}", flush=True)
    print("TOTAL", sum(len(v["vaults"]) for v in allout.values()))
