#!/usr/bin/env python3
"""
InsureDAO verification - batched live state reader (READ-ONLY, keyless RPC).
3 rounds of JSON-RPC batch calls. Outputs JSON.
"""
import json, sys, urllib.request
from eth_utils import keccak
from eth_abi import encode

RPC = "https://ethereum-rpc.publicnode.com"
FALLBACK_RPC = "https://eth.drpc.org"

def _post(url, payload):
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json",
                 "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) verification-readonly"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read())

def rpc_batch(calls, chunk=80):
    """calls: list of (to, sig, args). returns list of hex results or Exception."""
    results = []
    for i in range(0, len(calls), chunk):
        part = calls[i:i+chunk]
        payload = []
        for j, (to, sig, args) in enumerate(part):
            sel = "0x" + keccak(text=sig)[:4].hex()
            types = []
            for t in sig[sig.index("(")+1:-1].split(","):
                t = t.strip()
                if not t:
                    continue
                types.append("uint256" if (t.startswith("uint") or t.startswith("int")) else t)
            enc = encode(types, list(args)) if types else b""
            payload.append({"jsonrpc": "2.0", "id": i + j, "method": "eth_call",
                            "params": [{"to": to, "data": sel + enc.hex()}, "latest"]})
        try:
            resp = _post(RPC, payload)
        except Exception:
            resp = _post(FALLBACK_RPC, payload)
        byid = {d["id"]: d for d in resp}
        for k in range(len(part)):
            d = byid.get(i + k)
            if d is None or "error" in d:
                results.append(Exception(str(d.get("error") if d else "missing")))
            else:
                results.append(d["result"])
    return results

def dec_u(r):
    if isinstance(r, Exception) or r in (None, "0x") or not isinstance(r, str):
        return None
    return int(r, 16)

def dec_a(r):
    if isinstance(r, Exception) or r in (None, "0x") or not isinstance(r, str):
        return None
    return "0x" + r[-40:]

def dec_b(r):
    v = dec_u(r)
    return None if v is None else bool(v)

ZERO = "0x" + "0" * 40
VAULT = "0x131fb74C6fEdE6D6710FF224E07cE0eD8123f144"
USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
REGISTRY = "0xA035Dfd0D16F238493b374a1743B77448D9C8524"
FACTORY = "0x01e6916CcFe3630364b4538d0f8C1c22E20d0F6b"
PARAMETERS = "0xdDAA6ee776B701a7729D72BBd0d4FBe4bBb66476"
OWNERSHIP = "0xf4dB9926aE02469D730A25AD7422764BBD45d36F"
POOLPROXY = "0xF4d046D8FaC6dc37b5eAFAdd34407b19De3Ba350"
SAFE = "0x54bE2f27E95BdAA5104960aAE7816554C0e3F056"
GAUGECTRL = "0x297ea2afcE594149Cd31a9b11AdBAe82fa1Ddd04"
MINTER = "0x76E8B82EA3450fA598E5e164c7E28af172deBDC0"
ESCROW = "0x3dc07E60ecB3d064d20c386217ceeF8e3905916b"
VLINSURE = "0xA12ab76a82D118e33682AcB242180B4cc0d19E29"
VLINS_OWNERSHIP = "0x56246e83F3148B05Ce2D90B44fbb4e9fa9EAF5bb"
LP = "0x1b459aec393D604Ae6468Ae3f7D7422eFA2Af1ca"
INSURE = "0xd83AE04c9eD29d6D3E6Bf720C71bc7BeB424393E"
OPEN_TPL = "0x1dcd35cFfF8a9B44aECc4087c7847Fb7A5BE56F9"
INDEX_TPL = "0x2B16Be3caCAeA56A6FBE613031C0F6b641DF828E"
CDS_TPL = "0x99f790AdA7FA1BDC2a6B976293273EE51f10a10e"

out = {}

# ---------- ROUND 1 ----------
r1 = []
def add1(to, sig, args=()):
    r1.append((to, sig, args))
    return len(r1) - 1

i_marks = add1(REGISTRY, "getAllMarkets()")
i_val = [add1(VAULT, s) for s in ["valueAll()", "balance()", "totalAttributions()", "totalDebt()",
                                  "controller()", "keeper()", "token()", "registry()", "ownership()"]]
i_usdc_v = add1(USDC, "balanceOf(address)", [VAULT])
i_usdc_p = add1(USDC, "balanceOf(address)", [POOLPROXY])
i_pp_attr = add1(VAULT, "attributions(address)", [POOLPROXY])

# market probes: pool -> attributionDebt; index -> totalAllocPoint; cds -> crowdPool
base_sigs = ["totalSupply()", "attributionDebt()", "totalCredit()", "lockedAmount()",
             "marketStatus()", "paused()", "pendingEnd()", "originalLiquidity()",
             "totalLiquidity()", "allInsuranceCount()", "crowdPool()", "surplusPool()",
             "totalAllocPoint()", "targetLev()", "locked()", "totalAllocatedCredit()",
             "withdrawable()"]
# We don't know markets yet; fetch markets first in a small batch.
mk_raw = rpc_batch([(REGISTRY, "getAllMarkets()", ())])[0]
body = mk_raw[2:]
off = int(body[0:64], 16) * 2
ln = int(body[off:off+64], 16)
markets = ["0x" + body[off+64+i*64: off+128+i*64][-40:] for i in range(ln)]
out["markets"] = markets
out["block"] = int(_post(RPC, {"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []})["result"], 16)

r1 = []
def add1(to, sig, args=()):
    r1.append((to, sig, args))
    return len(r1) - 1

i_marks = add1(REGISTRY, "getAllMarkets()")
i_val = [add1(VAULT, s) for s in ["valueAll()", "balance()", "totalAttributions()", "totalDebt()",
                                  "controller()", "keeper()", "token()", "registry()", "ownership()"]]
i_usdc_v = add1(USDC, "balanceOf(address)", [VAULT])
i_usdc_p = add1(USDC, "balanceOf(address)", [POOLPROXY])
i_pp_attr = add1(VAULT, "attributions(address)", [POOLPROXY])
probe = {}
for m in markets:
    probe[m] = {}
    for s in ["attributionDebt()", "totalAllocPoint()", "crowdPool()"]:
        probe[m][s] = add1(m, s)
    probe[m]["attrib"] = add1(VAULT, "attributions(address)", [m])
    for s in base_sigs:
        if s in ("attributionDebt()", "crowdPool()", "totalAllocPoint()"):
            continue
        probe[m][s] = add1(m, s)
    for k in range(10):
        probe[m][f"indexList({k})"] = add1(m, "indexList(uint256)", [k])
    for k in range(20):
        probe[m][f"poolList({k})"] = add1(m, "poolList(uint256)", [k])
    probe[m]["indicesProbe"] = add1(m, "indices(address)", [ZERO])  # dummy to learn type ok

res1 = rpc_batch(r1)
def g1(i):
    return res1[i]

vault = {
    "valueAll": dec_u(g1(i_val[0])), "balance": dec_u(g1(i_val[1])),
    "totalAttributions": dec_u(g1(i_val[2])), "totalDebt": dec_u(g1(i_val[3])),
    "controller": dec_a(g1(i_val[4])), "keeper": dec_a(g1(i_val[5])),
    "token": dec_a(g1(i_val[6])), "registry": dec_a(g1(i_val[7])), "ownership": dec_a(g1(i_val[8])),
    "usdcBalance": dec_u(g1(i_usdc_v)), "usdcBalPoolProxy": dec_u(g1(i_usdc_p)),
    "attribPoolProxy": dec_u(g1(i_pp_attr)),
    "attrib": {m: dec_u(g1(probe[m]["attrib"])) for m in markets},
}
out["vault"] = vault

mkind = {}
for m in markets:
    if dec_u(g1(probe[m]["attributionDebt()"])) is not None:
        mkind[m] = "pool"
    elif dec_u(g1(probe[m]["crowdPool()"])) is not None:
        mkind[m] = "cds"
    elif dec_u(g1(probe[m]["totalAllocPoint()"])) is not None:
        mkind[m] = "index"
    else:
        mkind[m] = "unknown"
out["marketKind"] = mkind

md = {}
for m in markets:
    d = {"kind": mkind[m]}
    for s in base_sigs:
        key = s[:-2].replace("()", "")
        d[key] = dec_u(g1(probe[m][s])) if s not in ("paused()", "locked()") else dec_b(g1(probe[m][s]))
    d["vaultAttrib"] = vault["attrib"][m]
    d["indexList"] = [dec_a(g1(probe[m][f"indexList({k})"])) for k in range(10)]
    d["poolList"] = [dec_a(g1(probe[m][f"poolList({k})"])) for k in range(20)]
    md[m] = d
out["marketDetail"] = md

# ---------- ROUND 2: indices() for found indexList entries; poolList entries; gauges ----------
r2 = []
def add2(to, sig, args=()):
    r2.append((to, sig, args))
    return len(r2) - 1

i_idx = {}
i_pp = {}
for m in markets:
    for ix in md[m]["indexList"]:
        if ix and ix != ZERO and ix not in i_idx:
            i_idx[ix] = (add2(m, "indices(address)", [ix]), m)
            i_pp[ix] = (add2(m, "pendingPremium(address)", [ix]), m)
i_alloc = {}
i_poolpp = {}
for m in markets:
    if mkind[m] != "index":
        continue
    for p in md[m]["poolList"]:
        if p and p != ZERO:
            i_alloc[(m, p)] = add2(m, "allocPoints(address)", [p])
            i_poolpp[(m, p)] = add2(p, "pendingPremium(address)", [m])
i_ng = add2(GAUGECTRL, "n_gauges()")
res2 = rpc_batch(r2)

idxinfo = {}
for ix, (i, m) in i_idx.items():
    r = res2[i]
    if isinstance(r, Exception) or r in (None, "0x"):
        idxinfo[ix] = None
        continue
    b = r[2:]
    idxinfo[ix] = {"pool": m, "credit": int(b[0:64], 16), "rewardDebt": int(b[64:128], 16),
                   "idx": int(b[128:192], 16), "exist": int(b[192:256], 16) == 1,
                   "pendingPremium": dec_u(res2[i_pp[ix][0]])}
out["indexInfo"] = idxinfo
alloc = {}
for (m, p), i in i_alloc.items():
    alloc[f"{m}|{p}"] = {"allocPoints": dec_u(res2[i]), "pendingPremium": dec_u(res2[i_poolpp[(m, p)]])}
out["allocPoints"] = alloc

ng = dec_u(res2[i_ng]) or 0
# gauges
r2b = []
def add2b(to, sig, args=()):
    r2b.append((to, sig, args))
    return len(r2b) - 1
ig = [add2b(GAUGECTRL, "gauges(uint256)", [k]) for k in range(ng)]
res2b = rpc_batch(r2b)
gauges = [dec_a(x) for x in res2b]
gauges = [x for x in gauges if x and x != ZERO]
r3 = []
def add3(to, sig, args=()):
    r3.append((to, sig, args))
    return len(r3) - 1
gd = {}
for g in gauges:
    gd[g] = {}
    for s in ["template()", "totalSupply()", "is_killed()", "minter()", "working_supply()", "ownership()"]:
        gd[g][s] = add3(g, s)
res3 = rpc_batch(r3)
gtok = {}
for g in gauges:
    d = {}
    for s in gd[g]:
        r = res3[gd[g][s]]
        if s in ("is_killed()",):
            d[s[:-2].replace("()", "")] = dec_b(r)
        elif s == "template()" or s == "minter()" or s == "ownership()":
            d[s[:-2].replace("()", "")] = dec_a(r)
        else:
            d[s[:-2].replace("()", "")] = dec_u(r)
    gtok[g] = d
    # token balance held by gauge + ownership owner
    if d.get("template"):
        gtok[g]["tokenBalance"] = dec_u(rpc_batch([(d["template"], "balanceOf(address)", [g])])[0])
    if d.get("ownership"):
        gtok[g]["owner"] = dec_a(rpc_batch([(d["ownership"], "owner()", ())])[0])
out["gauges"] = gtok

# ---------- ROUND 3: parameters, poolproxy, vlinsure, insure, factory ----------
r4 = []
def add4(to, sig, args=()):
    r4.append((to, sig, args))
    return len(r4) - 1

params = {}
for name, tok in [("USDC", USDC), ("WETH", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"),
                  ("DAI", "0x6B175474E89094C44Da98b954EedeAC495271d0F"),
                  ("USDT", "0xdAC17F958D2ee523a2206206994597C13D831ec7"),
                  ("INSURE", INSURE), ("WBTC", "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"),
                  ("LP", LP), ("iToken2245", "0x22453153978D0C25f86010c0fd405527feD9764b"),
                  ("iIndex7E08", "0x7E08daB409Ad1bCeBc5bE5674CB2C0f3540A4d3d"),
                  ("iToken8C49", "0x8c4943100bEc96e3381a544Da82B91713a4BC062")]:
    params[name] = {"token": tok, "getVault": add4(PARAMETERS, "getVault(address)", [tok])}
p_owner = add4(PARAMETERS, "getOwner()")
p_pp = {}
for name, tok in [("USDC", USDC), ("WETH", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"),
                  ("DAI", "0x6B175474E89094C44Da98b954EedeAC495271d0F"),
                  ("USDT", "0xdAC17F958D2ee523a2206206994597C13D831ec7"),
                  ("INSURE", INSURE), ("LP", LP)]:
    p_pp[name] = {
        "n": add4(POOLPROXY, "n_distributors(address)", [tok]),
        "tw": add4(POOLPROXY, "total_weights(address)", [tok]),
    }
pp_admin = [add4(POOLPROXY, s) for s in ["ownership_admin()", "parameter_admin()", "emergency_admin()",
                                          "default_reporting_admin()", "distributor_kill()"]]
rep_admins = {m: add4(POOLPROXY, "reporting_admin(address)", [m]) for m in markets}
vli = {}
for s in ["lockIncentive()", "incentiveInsure()", "unlockTime()", "totalSupply()"]:
    vli[s] = add4(VLINSURE, s)
vli_g = add4(VLINSURE, "gauge()")
vli_e = add4(VLINSURE, "escrow()")
vli_o = add4(VLINSURE, "ownership()")
vli_bal = add4(INSURE, "balanceOf(address)", [VLINSURE])
ins_minter = add4(INSURE, "minter()")
ins_em = add4(INSURE, "emergency_module()")
esc_bal = add4(INSURE, "balanceOf(address)", [ESCROW])
tpl = {}
for name, t in [("PoolTemplate", OPEN_TPL), ("IndexTemplate", INDEX_TPL), ("CDSTemplate", CDS_TPL)]:
    tpl[name] = add4(FACTORY, "templates(address)", [t])
for slot in range(4):
    for tgt in [ZERO, USDC, REGISTRY, PARAMETERS, "0x000000000000000000000000000000000000dEaD"]:
        tpl[f"ref_open_{slot}_{tgt[-6:]}"] = add4(FACTORY, "reflist(address,uint256,address)", [OPEN_TPL, slot, tgt])
for slot in range(3):
    tpl[f"cond_open_{slot}"] = add4(FACTORY, "conditionlist(address,uint256)", [OPEN_TPL, slot])
pair_res = add4(LP, "getReserves()")
pair_ts = add4(LP, "totalSupply()")
pair_t0 = add4(LP, "token0()")
pair_t1 = add4(LP, "token1()")
# LP balance of every gauge
lp_gauge_bal = {g: add4(LP, "balanceOf(address)", [g]) for g in gauges}
res4 = rpc_batch(r4)

pv = {}
for name, d in params.items():
    pv[name] = {"token": d["token"], "vault": dec_a(res4[d["getVault"]])}
out["paramVaults"] = pv
out["paramOwner"] = dec_a(res4[p_owner])
ppx = {"ownership_admin": dec_a(res4[pp_admin[0]]), "parameter_admin": dec_a(res4[pp_admin[1]]),
       "emergency_admin": dec_a(res4[pp_admin[2]]), "default_reporting_admin": dec_a(res4[pp_admin[3]]),
       "distributor_kill": dec_b(res4[pp_admin[4]]),
       "reporting_admin": {m: dec_a(res4[rep_admins[m]]) for m in markets},
       "tokens": {}}
# distributor details for each token: need n first, then second batch
r5 = []
def add5(to, sig, args=()):
    r5.append((to, sig, args))
    return len(r5) - 1
dist_calls = {}
for name, tok in [("USDC", USDC), ("WETH", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"),
                  ("DAI", "0x6B175474E89094C44Da98b954EedeAC495271d0F"),
                  ("USDT", "0xdAC17F958D2ee523a2206206994597C13D831ec7"),
                  ("INSURE", INSURE), ("LP", LP)]:
    nd = dec_u(res4[p_pp[name]["n"]]) or 0
    ppx["tokens"][name] = {"token": tok, "n": nd, "total_weights": dec_u(res4[p_pp[name]["tw"]]), "distributors": []}
    for k in range(nd):
        dist_calls[(name, k)] = {
            "dist": add5(POOLPROXY, "distributors(address,uint256)", [tok, k]),
            "w": add5(POOLPROXY, "distributor_weight(address,uint256)", [tok, k]),
            "d": add5(POOLPROXY, "distributable(address,uint256)", [tok, k]),
        }
res5 = rpc_batch(r5)
for (name, k), dc in dist_calls.items():
    r = res5[dc["dist"]]
    if isinstance(r, Exception) or r in (None, "0x"):
        ppx["tokens"][name]["distributors"].append({"id": k, "error": str(r)})
        continue
    b = r[2:]
    soff = int(b[0:64], 16) * 2
    addr = "0x" + b[64:128][-40:]
    sl = int(b[soff:soff+64], 16)
    nm = bytes.fromhex(b[soff+64:soff+64+sl*2]).decode(errors="replace")
    ppx["tokens"][name]["distributors"].append({
        "id": k, "name": nm, "addr": addr,
        "weight": dec_u(res5[dc["w"]]), "distributable": dec_u(res5[dc["d"]])})
out["poolProxy"] = ppx

out["vlInsure"] = {
    "lockIncentive": dec_u(res4[vli["lockIncentive()"]]),
    "incentiveInsure": dec_u(res4[vli["incentiveInsure()"]]),
    "unlockTime": dec_u(res4[vli["unlockTime()"]]),
    "totalSupply": dec_u(res4[vli["totalSupply()"]]),
    "gauge": dec_a(res4[vli_g]), "escrow": dec_a(res4[vli_e]), "ownership": dec_a(res4[vli_o]),
    "insureBalance": dec_u(res4[vli_bal]),
}
out["insureToken"] = {"minter": dec_a(res4[ins_minter]), "emergency_module": dec_a(res4[ins_em]),
                      "escrowInsureBalance": dec_u(res4[esc_bal])}
out["templates"] = {}
for name, t in [("PoolTemplate", OPEN_TPL), ("IndexTemplate", INDEX_TPL), ("CDSTemplate", CDS_TPL)]:
    r = res4[tpl[name]]
    if isinstance(r, Exception) or r in (None, "0x"):
        out["templates"][name] = {"addr": t, "error": str(r)}
    else:
        b = r[2:]
        out["templates"][name] = {"addr": t, "approval": int(b[0:64], 16) == 1,
                                  "isOpen": int(b[64:128], 16) == 1,
                                  "allowDuplicate": int(b[128:192], 16) == 1}
out["factoryOpenRefs"] = {k: dec_b(v) for k, v in tpl.items() if k.startswith("ref_open_")}
out["factoryOpenConds"] = {k: dec_u(v) for k, v in tpl.items() if k.startswith("cond_open_")}
rr = res4[pair_res]
if isinstance(rr, Exception) or rr in (None, "0x"):
    out["lp"] = {"error": str(rr)}
else:
    b = rr[2:]
    out["lp"] = {"reserve0": int(b[0:64], 16), "reserve1": int(b[64:128], 16),
                 "totalSupply": dec_u(res4[pair_ts]),
                 "token0": dec_a(res4[pair_t0]), "token1": dec_a(res4[pair_t1]),
                 "gaugeLpBalances": {g: dec_u(res4[lp_gauge_bal[g]]) for g in gauges}}

json.dump(out, open("/home/heisenberg/CA/insuredao/analysis/verify/raw/state.json", "w"), indent=1)
print("OK block", out["block"], "markets", len(markets), "gauges", len(gauges))
