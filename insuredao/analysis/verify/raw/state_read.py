#!/usr/bin/env python3
"""
InsureDAO verification - independent live state reader.
READ-ONLY. Keyless public RPC. Writes JSON to stdout (caller redirects).
"""
import json, sys, urllib.request

RPC = "https://ethereum-rpc.publicnode.com"
FALLBACK_RPC = "https://eth.drpc.org"
BLOCK = None  # latest; set to int to pin

def _post(url, payload):
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json",
                 "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) verification-readonly"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())

def rpc(method, params):
    payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
    if BLOCK is not None and method == "eth_call":
        params = list(params)
        # params = [tx, block]
        params[1] = hex(BLOCK)
        payload["params"] = params
    try:
        d = _post(RPC, payload)
    except Exception:
        d = _post(FALLBACK_RPC, payload)
    if "error" in d:
        raise RuntimeError(d["error"])
    return d["result"]

def call(to, sig, args=()):
    sel = "0x" + __import__("eth_utils").keccak(text=sig)[:4].hex()
    data = sel + "".join(a.rjust(64, "0") if isinstance(a, str) and a.startswith("0x") is False else a for a in [])
    # encode args with eth_abi
    from eth_abi import encode
    types = []
    for t in sig[sig.index("(")+1:-1].split(","):
        t = t.strip()
        if not t:
            continue
        if t.startswith("uint") or t.startswith("int"):
            types.append("uint256")
        elif t == "bool":
            types.append("bool")
        elif t == "address":
            types.append("address")
        elif t.endswith("]"):
            types.append("bytes32")  # not used
        else:
            types.append(t)
    enc = encode(types, list(args)) if types else b""
    return rpc("eth_call", [{"to": to, "data": sel + enc.hex()}, "latest"])

def u(to, sig, args=()):
    r = call(to, sig, args)
    if r in (None, "0x"):
        return None
    return int(r, 16)

def a(to, sig, args=()):
    r = call(to, sig, args)
    if r in (None, "0x"):
        return None
    return "0x" + r[-40:]

def b(to, sig, args=()):
    return bool(u(to, sig, args))

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

out = {"rpc": RPC, "block": int(rpc("eth_blockNumber", []), 16)}

# ---- registry markets
n = u(REGISTRY, "getAllMarkets()")
print("n markets", n, file=sys.stderr)
# getAllMarkets returns array: decode manually
raw = call(REGISTRY, "getAllMarkets()")
body = raw[2:]
off = int(body[0:64], 16) * 2
ln = int(body[off:off+64], 16)
markets = []
for i in range(ln):
    w = body[off+64+i*64: off+128+i*64]
    markets.append("0x" + w[-40:])
out["markets"] = markets

# ---- vault
v = {}
v["valueAll"] = u(VAULT, "valueAll()")
v["balance"] = u(VAULT, "balance()")
v["totalAttributions"] = u(VAULT, "totalAttributions()")
v["totalDebt"] = u(VAULT, "totalDebt()")
v["controller"] = a(VAULT, "controller()")
v["keeper"] = a(VAULT, "keeper()")
v["token"] = a(VAULT, "token()")
v["registry"] = a(VAULT, "registry()")
v["ownership"] = a(VAULT, "ownership()")
v["usdcBalance"] = u(USDC, "balanceOf(address)", [VAULT])
v["usdcBalPoolProxy"] = u(USDC, "balanceOf(address)", [POOLPROXY])
v["attrib"] = {}
for m in markets:
    v["attrib"][m] = u(VAULT, "attributions(address)", [m])
v["attribPoolProxy"] = u(VAULT, "attributions(address)", [POOLPROXY])
out["vault"] = v

# ---- per-market detail
def market_detail(m, kind):
    d = {"kind": kind}
    d["totalSupply"] = u(m, "totalSupply()")
    d["attributionDebt"] = u(m, "attributionDebt()")
    d["totalCredit"] = u(m, "totalCredit()")
    d["lockedAmount"] = u(m, "lockedAmount()")
    d["marketStatus"] = u(m, "marketStatus()")
    d["paused"] = b(m, "paused()")
    d["pendingEnd"] = u(m, "pendingEnd()")
    d["origLiq"] = u(m, "originalLiquidity()")
    d["totLiq"] = u(m, "totalLiquidity()")
    d["allInsuranceCount"] = u(m, "allInsuranceCount()")
    d["vaultAttrib"] = v["attrib"][m]
    idx = []
    for i in range(10):
        try:
            ix = a(m, "indexList(uint256)", [i])
        except Exception:
            ix = None
        if ix is None or ix == "0x" + "0"*40:
            idx.append(None)
            continue
        inf = call(m, "indices(address)", [ix])
        infb = inf[2:]
        credit = int(infb[0:64], 16)
        rewardDebt = int(infb[64:128], 16)
        index = int(infb[128:192], 16)
        exist = int(infb[192:256], 16) == 1
        try:
            pp = u(m, "pendingPremium(address)", [ix])
        except Exception:
            pp = None
        idx.append({"index": ix, "credit": credit, "rewardDebt": rewardDebt,
                    "idx": index, "exist": exist, "pendingPremium": pp})
    d["indexList"] = idx
    return d

md = {}
for m in markets:
    # classify by probing functions that only one impl has
    kind = "unknown"
    if u(m, "attributionDebt()") is not None:
        kind = "pool"
    else:
        # index has allocPoints/targetLev; cds has crowdPool
        try:
            cp = u(m, "crowdPool()")
            if cp is not None:
                kind = "cds"
            else:
                kind = "index"
        except Exception:
            kind = "index"
    if kind == "pool":
        md[m] = market_detail(m, kind)
    elif kind == "index":
        d = {"kind": kind}
        d["totalSupply"] = u(m, "totalSupply()")
        d["totLiq"] = u(m, "totalLiquidity()")
        d["totalAllocatedCredit"] = u(m, "totalAllocatedCredit()")
        d["totalAllocPoint"] = u(m, "totalAllocPoint()")
        d["targetLev"] = u(m, "targetLev()")
        d["locked"] = b(m, "locked()")
        d["paused"] = b(m, "paused()")
        d["vaultAttrib"] = v["attrib"][m]
        try:
            d["withdrawable"] = u(m, "withdrawable()")
        except Exception:
            d["withdrawable"] = None
        pools = []
        for i in range(20):
            try:
                p = a(m, "poolList(uint256)", [i])
            except Exception:
                break
            if p is None or p == "0x" + "0"*40:
                break
            ap = u(m, "allocPoints(address)", [p])
            try:
                pp = u(p, "pendingPremium(address)", [m])
            except Exception:
                pp = None
            pools.append({"pool": p, "allocPoints": ap, "pendingPremium": pp})
        d["poolList"] = pools
        md[m] = d
    else:  # cds
        d = {"kind": kind}
        d["totalSupply"] = u(m, "totalSupply()")
        d["crowdPool"] = u(m, "crowdPool()")
        d["surplusPool"] = u(m, "surplusPool()")
        d["paused"] = b(m, "paused()")
        d["vaultAttrib"] = v["attrib"][m]
        md[m] = d
out["marketDetail"] = md

# ---- parameters
pm = {}
for tok, name in [(USDC, "USDC"), ("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "WETH"),
                  ("0x6B175474E89094C44Da98b954EedeAC495271d0F", "DAI"),
                  ("0xdAC17F958D2ee523a2206206994597C13D831ec7", "USDT"),
                  (INSURE, "INSURE"), ("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", "WBTC"),
                  (LP, "LP-INSURE/WETH")]:
    try:
        pm[name] = {"token": tok, "vault": a(PARAMETERS, "getVault(address)", [tok])}
    except Exception as e:
        pm[name] = {"token": tok, "error": str(e)}
out["paramVaults"] = pm
out["paramOwner"] = a(PARAMETERS, "getOwner()")
for m in markets:
    try:
        out.setdefault("paramPerMarket", {})[m] = {
            "lockup": u(PARAMETERS, "getLockup(address)", [m]),
            "withdrawable": u(PARAMETERS, "getWithdrawable(address)", [m]),
            "grace": u(PARAMETERS, "getGrace(address)", [m]),
            "maxList": u(PARAMETERS, "getMaxList(address)", [m]),
            "feeRate": u(PARAMETERS, "getFeeRate(address)", [m]),
        }
    except Exception as e:
        pass

# ---- poolproxy
pp = {"ownership_admin": a(POOLPROXY, "ownership_admin()"),
      "parameter_admin": a(POOLPROXY, "parameter_admin()"),
      "emergency_admin": a(POOLPROXY, "emergency_admin()"),
      "default_reporting_admin": a(POOLPROXY, "default_reporting_admin()"),
      "distributor_kill": b(POOLPROXY, "distributor_kill()"),
      "tokens": {}}
for tok, name in [(USDC, "USDC"), ("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "WETH"),
                  ("0x6B175474E89094C44Da98b954EedeAC495271d0F", "DAI"),
                  ("0xdAC17F958D2ee523a2206206994597C13D831ec7", "USDT"),
                  (INSURE, "INSURE"), (LP, "LP-INSURE/WETH")]:
    try:
        nd = u(POOLPROXY, "n_distributors(address)", [tok])
        tw = u(POOLPROXY, "total_weights(address)", [tok])
        ds = []
        for i in range(nd or 0):
            raw = call(POOLPROXY, "distributors(address,uint256)", [tok, i])
            rb = raw[2:]
            # struct: string name (dynamic) + address
            # ABI: offset to string, address
            off = int(rb[0:64], 16)
            addr = "0x" + rb[64:128][-40:]
            # name
            sl = int(rb[off*2:off*2+64], 16)
            nm = bytes.fromhex(rb[off*2+64:off*2+64+sl*2]).decode(errors="replace")
            w = u(POOLPROXY, "distributor_weight(address,uint256)", [tok, i])
            dd = u(POOLPROXY, "distributable(address,uint256)", [tok, i])
            ds.append({"id": i, "name": nm, "addr": addr, "weight": w, "distributable": dd})
        pp["tokens"][name] = {"token": tok, "n": nd, "total_weights": tw, "distributors": ds}
    except Exception as e:
        pp["tokens"][name] = {"token": tok, "error": str(e)}
out["poolProxy"] = pp
out["reportingAdmins"] = {m: a(POOLPROXY, "reporting_admin(address)", [m]) for m in markets}

# ---- gauges (controller)
ng = u(GAUGECTRL, "n_gauges()")
gs = []
for i in range(ng):
    g = a(GAUGECTRL, "gauges(uint256)", [i])
    if not g:
        continue
    gd = {"gauge": g}
    try:
        gd["template"] = a(g, "template()")
        gd["totalSupply"] = u(g, "totalSupply()")
        gd["is_killed"] = b(g, "is_killed()")
        gd["minter"] = a(g, "minter()")
        gd["working_supply"] = u(g, "working_supply()")
        gd["ownership"] = a(g, "ownership()")
        # balance held by gauge of template token
        if gd["template"]:
            gd["tokenBalance"] = u(gd["template"], "balanceOf(address)", [g])
        # ownership owner
        try:
            gd["owner"] = a(gd["ownership"], "owner()")
        except Exception:
            pass
    except Exception as e:
        gd["error"] = str(e)
    gs.append(gd)
out["gauges"] = gs

# ---- vlINSURE / escrow / minter
vd = {}
vd["insureBalance"] = u(INSURE, "balanceOf(address)", [VLINSURE])
vd["lockIncentive"] = u(VLINSURE, "lockIncentive()")
vd["incentiveInsure"] = u(VLINSURE, "incentiveInsure()")
vd["unlockTime"] = u(VLINSURE, "unlockTime()")
vd["gauge"] = a(VLINSURE, "gauge()")
vd["escrow"] = a(VLINSURE, "escrow()")
vd["ownership"] = a(VLINSURE, "ownership()")
try:
    vd["owner"] = a(vd["ownership"], "owner()")
except Exception:
    pass
vd["totalSupply"] = u(VLINSURE, "totalSupply()")
vd["escrowInsureBalance"] = u(INSURE, "balanceOf(address)", [ESCROW])
out["vlInsure"] = vd

# ---- minter / insure token
md2 = {}
md2["minter"] = a(INSURE, "minter()")
md2["emergency_module"] = a(INSURE, "emergency_module()")
try:
    md2["minter_owner"] = a(MINTER, "owner()")
except Exception:
    pass
try:
    md2["minter_insure"] = a(MINTER, "insure_token()")
except Exception:
    pass
try:
    md2["minter_ctrl"] = a(MINTER, "gauge_controller()")
except Exception:
    pass
out["insureToken"] = md2

# ---- factory templates: enumerate from known list + try common
tpl = {}
for name, t in [("PoolTemplate_open", "0x1dcd35cFfF8a9B44aECc4087c7847Fb7A5BE56F9"),
                ("IndexTemplate", "0x2B16Be3caCAeA56A6FBE613031C0F6b641DF828E"),
                ("CDSTemplate", "0x99f790AdA7FA1BDC2a6B976293273EE51f10a10e")]:
    try:
        raw = call(FACTORY, "templates(address)", [t])
        rb = raw[2:]
        tpl[name] = {"addr": t, "approval": int(rb[0:64], 16) == 1,
                     "isOpen": int(rb[64:128], 16) == 1,
                     "allowDuplicate": int(rb[128:192], 16) == 1}
    except Exception as e:
        tpl[name] = {"addr": t, "error": str(e)}
out["templates"] = tpl

# ---- LP pair
pair = {}
pair["reserves"] = None
try:
    raw = call(LP, "getReserves()")
    rb = raw[2:]
    pair["reserve0"] = int(rb[0:64], 16)
    pair["reserve1"] = int(rb[64:128], 16)
    pair["token0"] = a(LP, "token0()")
    pair["token1"] = a(LP, "token1()")
    pair["totalSupply"] = u(LP, "totalSupply()")
    pair["gaugeBalance"] = u(LP, "balanceOf(address)", ["0xbCBCf05F2f77E2c223334368162D88f5d6032699"])
except Exception as e:
    pair["error"] = str(e)
out["lp"] = pair

print(json.dumps(out, indent=1))
