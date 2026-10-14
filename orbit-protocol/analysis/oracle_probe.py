"""Oracle configuration + current values for all Orbit Protocol markets (Blast).

Self-sufficient: reads markets from core_state.json when present, else on-chain.
Writes ci-out/oracle_state.json (or analysis/oracle_state.json locally).

Read-only, keyless RPCs (BLAST_RPC_URL honored).
"""
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from enumerate_live2 import batch, words, a20, u  # noqa: E402

OUTDIR = os.environ.get("CI_OUT", HERE)

COMPTROLLERS = {
    "c1": "0x1E18C3cb491D908241D0db14b081B51be7B6e652",
    "c2": "0x273683CA19D9CF827628EE216E4a9604EfB077A3",
    "c3": "0xe9266ae95bB637A7Ad598CB0390d44262130F433",
    "c4": "0xfFF8Fc176697D04607cF4e23E91c65aeD1c3d3F5",
}
ROUTER = "0x8240881C0731a84F44b69a221871bBD88E8ca711"
ETH_PSEUDO = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

SEL = {
    "oracle": "0x7dc0d1d0",
    "getAllMarkets": "0xb0772d0b",
    "routerMap": "0x16a833d3",        # oTokenToOracleAddress(address)
    "pyth": "0x2d1aa3e8",             # pyth()
    "feed": "0xaafe21c5",             # addressToPriceFeedID(address)
    "getPriceUnsafe": "0x96834ad3",   # getPriceUnsafe(bytes32)
    "redstoneMap": "0xdb245bb6",      # underlyingToOracleAddress(address)
    "api3Map": "0x231ed505",          # underlyingToAPI3Address(address)
    "latestRoundData": "0xfeaf968c",
    "read": "0x57de26a4",
    "owner": "0x8da5cb5b",
    "getUnderlyingPrice": "0xfc57d4df",
    "decimals": "0x313ce567",
    "symbol": "0x95d89b41",
    "underlying": "0x6f307dc3",
}


def w(a):
    return a[2:].rjust(64, "0") if isinstance(a, str) and a.startswith("0x") and len(a) == 42 else None


def addr(h):
    if h and h != "__REVERT__" and words(h) and len(words(h)[0]) >= 40:
        return a20(words(h)[0])
    return None


def main():
    # markets: from core_state.json if present
    markets = {}
    cs = None
    for f in (os.path.join(OUTDIR, "core_state.json"), os.path.join(HERE, "core_state.json")):
        if os.path.exists(f):
            cs = json.load(open(f))
            break
    if cs:
        for lab, c in cs["comptrollers"].items():
            for m in c["markets"]:
                markets.setdefault(lab, []).append(m)
    blk = (cs or {}).get("block") or None

    # oracle per comptroller
    items = [(c, SEL["oracle"]) for c in COMPTROLLERS.values()]
    r = batch(items, blk or "latest")
    oracle_of = {lab: addr(h) for lab, h in zip(COMPTROLLERS, r)}

    out = {"block": blk, "oracle_of": oracle_of, "router_map": {}, "oracle_cfg": {},
           "prices": {}, "pyth_state": {}}

    all_markets = []
    for lab, mks in markets.items():
        all_markets.extend(mks)

    # router map (if c1 uses router)
    rmap = {}
    if oracle_of.get("c1") == ROUTER:
        items = [(ROUTER, SEL["routerMap"] + w(m)) for m in markets.get("c1", [])]
        r = batch(items, blk or "latest")
        for m, h in zip(markets.get("c1", []), r):
            rmap[m] = addr(h)
        out["router_map"] = rmap

    # effective per-asset oracle for each market
    eff = {}
    for lab, mks in markets.items():
        for m in mks:
            eff[m] = rmap.get(m) if oracle_of.get(lab) == ROUTER else oracle_of.get(lab)
    out["effective_oracle"] = eff

    # per-oracle config
    uniq = sorted({o for o in eff.values() if o})
    assets_of = {}  # oracle -> set of assets (ETH pseudo + underlyings)
    for m, o in eff.items():
        if not o:
            continue
        s = assets_of.setdefault(o, {ETH_PSEUDO})
        if cs:
            und = (cs["markets"].get(m) or {}).get("underlying")
            if und and und.startswith("0x") and len(und) == 42:
                s.add(und.lower())
    cfg = {}
    items, keys = [], []
    for o in uniq:
        items.append((o, SEL["owner"])); keys.append((o, "owner"))
        items.append((o, SEL["pyth"])); keys.append((o, "pyth"))
        for a in sorted(assets_of.get(o, {ETH_PSEUDO})):
            items.append((o, SEL["feed"] + w(a))); keys.append((o, "feed", a))
            items.append((o, SEL["redstoneMap"] + w(a))); keys.append((o, "redstone", a))
            items.append((o, SEL["api3Map"] + w(a))); keys.append((o, "api3", a))
    r = batch(items, blk or "latest")
    for k, h in zip(keys, r):
        o = k[0]
        c = cfg.setdefault(o, {"feeds": {}, "redstone": {}, "api3": {}})
        if len(k) == 2:
            c[k[1]] = addr(h)
        else:
            c[k[1]][k[2]] = h if h and h != "__REVERT__" else None
    out["oracle_cfg"] = cfg

    # feed reads
    items, keys = [], []
    for o, c in cfg.items():
        pyth_addr = c.get("pyth")
        for a, fid in c["feeds"].items():
            if fid and pyth_addr:
                items.append((pyth_addr, SEL["getPriceUnsafe"] + fid[2:]))
                keys.append(("pyth", o, a, fid))
        for a, addr_ in c["redstone"].items():
            if addr_:
                items.append((addr_, SEL["latestRoundData"])); keys.append(("redstone", o, a, addr_))
                items.append((addr_, SEL["decimals"])); keys.append(("redstone_dec", o, a, addr_))
        for a, addr_ in c["api3"].items():
            if addr_:
                items.append((addr_, SEL["read"])); keys.append(("api3", o, a, addr_))
    r = batch(items, blk or "latest")
    for k, h in zip(keys, r):
        if k[0] == "pyth":
            _, o, a, fid = k
            e = out["pyth_state"].setdefault(f"{o}:{fid}", {"asset": a})
            if h and h != "__REVERT__" and words(h):
                ws = words(h)
                price = int(ws[0], 16); price = price - 2**64 if price >= 2**63 else price
                expo = int(ws[2], 16); expo = expo - 2**32 if expo >= 2**31 else expo
                e.update({"price": price, "conf": int(ws[1], 16), "expo": expo,
                          "publishTime": int(ws[3], 16)})
            else:
                e["raw"] = h
        elif k[0] in ("redstone", "redstone_dec", "api3"):
            _, o, a, addr_ = k
            kind = k[0]
            c = out["oracle_cfg"].setdefault(o, {"feeds": {}, "redstone": {}, "api3": {}})
            c.setdefault("feeds_read", {})
            if kind == "redstone" and h and h != "__REVERT__" and words(h):
                ws = words(h)
                ans = int(ws[1], 16); ans = ans - 2**256 if ans >= 2**255 else ans
                c["feeds_read"][f"redstone:{addr_}"] = {
                    "answer": ans, "startedAt": int(ws[2], 16), "updatedAt": int(ws[3], 16),
                    "answeredInRound": int(ws[4], 16), "roundId": int(ws[0], 16)}
            elif kind == "redstone_dec":
                c.setdefault("decimals", {})[addr_] = u(h)
            elif kind == "api3":
                if h and h != "__REVERT__" and words(h):
                    ws = words(h)
                    val = int(ws[0], 16); val = val - 2**224 if val >= 2**223 else val
                    c["feeds_read"][f"api3:{addr_}"] = {"value": val, "timestamp": int(ws[1], 16)}
                else:
                    c["feeds_read"][f"api3:{addr_}"] = {"raw": h}

    # getUnderlyingPrice per market through effective oracle
    items, keys = [], []
    for lab, mks in markets.items():
        for m in mks:
            o = eff.get(m)
            if o:
                items.append((o, SEL["getUnderlyingPrice"] + w(m)))
                keys.append((lab, m))
    r = batch(items, blk or "latest")
    for (lab, m), h in zip(keys, r):
        out["prices"].setdefault(lab, {})[m] = u(h) if h and h != "__REVERT__" else h

    os.makedirs(OUTDIR, exist_ok=True)
    with open(os.path.join(OUTDIR, "oracle_state.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("wrote oracle_state.json", flush=True)
    # console summary
    for o, c in cfg.items():
        print(f"oracle {o}: pyth={c.get('pyth')} owner={c.get('owner')} "
              f"feeds={len([1 for v in c['feeds'].values() if v])} "
              f"redstone={len([1 for v in c['redstone'].values() if v])} "
              f"api3={len([1 for v in c['api3'].values() if v])}", flush=True)
    for lab, pr in out["prices"].items():
        ok = sum(1 for v in pr.values() if isinstance(v, int))
        print(f"prices {lab}: {ok}/{len(pr)} readable", flush=True)


if __name__ == "__main__":
    main()
