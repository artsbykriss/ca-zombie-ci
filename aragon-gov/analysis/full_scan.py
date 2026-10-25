#!/usr/bin/env python3
"""
Aragon-gov — full enumeration scan (runs in CI; heavy, ~20k eth_calls).

A. Re-reads the Voting<->holding TRANSFER_ROLE permission-manager relationship on-chain
   for EVERY funded DAO (not a sample), plus the vote-creation gate.
B. Scans EVERY manager-funded DAO token for an AMM pool across Uniswap V2/V3 + Sushi V2.
Writes ci-out/aragon_full_scan.json and ci-out/aragon_at_risk.json.

Keyless / env RPC only (no secrets embedded).
"""
import json, os, sys, urllib.request, collections, time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get("CI_OUT") or os.path.join(HERE, "..", "ci-out")
os.makedirs(OUT, exist_ok=True)

RPCS = []
# Prefer keyed endpoints injected into the CI environment (constructed at runtime;
# NO key is ever written into this file or any artifact).
for key, tmpl in [
    ("ALCHEMY_API_KEY", "https://eth-mainnet.g.alchemy.com/v2/{}"),
    ("ANKR_API_KEY", "https://rpc.ankr.com/eth/{}"),
    ("DRPC_API_KEY", "https://lb.drpc.org/ogrpc?network=ethereum&dkey={}"),
    ("INFURA_API_KEY", "https://mainnet.infura.io/v3/{}"),
]:
    v = os.environ.get(key)
    if v:
        RPCS.append(tmpl.format(v))
for k in ("FORK_RPC_URL", "RPC_URL", "BLOCKPI_RPC_URL", "NODEREAL_ETH_RPC_URL"):
    v = os.environ.get(k)
    if v and v.startswith("http") and "flashbots" not in v and "wss" not in v:
        RPCS.append(v)
RPCS += ["https://eth.drpc.org", "https://1rpc.io/eth", "https://ethereum-rpc.publicnode.com"]
_seen = set(); RPCS = [u for u in RPCS if not (u in _seen or _seen.add(u))]


def _probe(url):
    # require a real eth_call result (not just eth_blockNumber) so archive/limited
    # endpoints that 403 or hang on calls are dropped.
    try:
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                           "params": [{"to": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
                                       "data": "0x18160ddd"}, "latest"]}).encode()
        req = urllib.request.Request(url, data=body, headers={"content-type": "application/json",
                                                              "User-Agent": "aragon-gov/1"})
        r = json.load(urllib.request.urlopen(req, timeout=8))
        return "result" in r
    except Exception:
        return False


def _healthy():
    good = [u for u in RPCS if _probe(u)]
    return good or RPCS

from Crypto.Hash import keccak
def kh(b):
    h = keccak.new(digest_bits=256); h.update(b); return h.hexdigest()
def nh(name):
    node = b"\x00" * 32
    for label in reversed(name.split(".")):
        node = bytes.fromhex(kh(node + bytes.fromhex(kh(label.encode()))))
    return node.hex()
S = lambda sig: "0x" + kh(sig.encode())[:8]
PAD = lambda a: a.lower().replace("0x", "").rjust(64, "0")
ZERO = "0" * 64
ANY = "ff" * 20
TR = kh(b"TRANSFER_ROLE")
CV = kh(b"CREATE_VOTES_ROLE")
HP = S("hasPermission(address,address,bytes32,bytes)")
GPM = S("getPermissionManager(address,bytes32)")

_ri = [0]
def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for attempt in range(6):
        u = RPCS[(_ri[0] + attempt) % len(RPCS)]
        try:
            req = urllib.request.Request(u, data=body, headers={"content-type": "application/json",
                                                                "User-Agent": "aragon-gov/1"})
            r = json.load(urllib.request.urlopen(req, timeout=25))
            if "result" in r:
                return r["result"]
            if "error" in r:
                msg = str(r["error"]).lower()
                if "revert" in msg or "execution" in msg:
                    return None  # a genuine revert (e.g. no code) — do not retry
        except Exception:
            pass
        _ri[0] += 1
        time.sleep(0.05 * attempt)
    return None

def call(to, data):
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])
def addr(x):
    return "0x" + x[-40:] if isinstance(x, str) and x != "0x" and len(x) >= 42 else None
def dec(x):
    try:
        return int(x, 16)
    except Exception:
        return None
def has_perm(acl, who, where, what):
    return dec(call(acl, HP + PAD(who) + PAD(where) + what + PAD("80") + PAD("0")))

APPS = json.load(open(os.path.join(HERE, "aragon_apps.json")))
JOIN = json.load(open(os.path.join(HERE, "aragon_join.json")))
TM_ID = nh("token-manager.aragonpm.eth")
RM = {nh("voting.aragonpm.eth"): "voting", nh("vault.aragonpm.eth"): "vault",
      nh("agent.aragonpm.eth"): "agent", nh("acl.aragonpm.eth"): "acl", TM_ID: "token-manager"}

# factory addresses (mainnet)
UNIV2 = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"
SUSHI = "0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac"
UNIV3 = "0x1F98431c8aD98523631AE4a59f267346ea31F984"
WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
GETPAIR = S("getPair(address,address)")
GETPOOL = S("getPool(address,address,uint24)")


def scan_pm(r):
    dao = r["dao"].lower()
    m = APPS.get(dao)
    if not m:
        return {"dao": dao, "eth": r["eth"], "minAQ": r["minAQ"], "token": r["token"], "err": "no_apps"}
    named = {RM[k]: v for k, v in m.items() if k in RM}
    voting = named.get("voting")
    hold = named.get("agent") or named.get("vault")
    if not (voting and hold):
        return {"dao": dao, "eth": r["eth"], "minAQ": r["minAQ"], "token": r["token"], "err": "no_voting_or_holding"}
    acl = addr(call(dao, S("acl()")))
    if not acl:
        return {"dao": dao, "eth": r["eth"], "minAQ": r["minAQ"], "token": r["token"], "err": "no_acl"}
    mgr = addr(call(acl, GPM + PAD(hold) + TR))
    out = {"dao": dao, "holding_kind": "agent" if "agent" in named else "vault", "holding": hold,
           "voting": voting, "acl": acl, "eth": r["eth"], "minAQ": r["minAQ"], "token": r["token"],
           "transfer_mgr": mgr, "isMgr": (mgr == voting),
           "anyCanCreate": has_perm(acl, ANY, voting, CV),
           "votingCanCreate": has_perm(acl, voting, voting, CV),
           "tmCanCreate": has_perm(acl, named["token-manager"], voting, CV) if named.get("token-manager") else None,
           "create_votes_mgr": addr(call(acl, GPM + PAD(voting) + CV)),
           "has_token_manager": "token-manager" in named}
    return out


def scan_liq(row):
    t = row["token"]
    if not t or len(t) != 42:
        return None
    liq = []
    failures = 0
    def pair(f, base, name):
        nonlocal failures
        r = call(f, GETPAIR + PAD(t) + PAD(base))
        if r is None:
            failures += 1
            return
        p = addr(r)
        if p and int(p, 16) != 0:
            liq.append(name + ":" + p)
    def pool(fee, lbl):
        nonlocal failures
        r = call(UNIV3, GETPOOL + PAD(t) + PAD(WETH) + PAD(hex(fee)[2:]))
        if r is None:
            failures += 1
            return
        p = addr(r)
        if p and int(p, 16) != 0:
            liq.append(lbl + ":" + p)
    pair(UNIV2, WETH, "uni2weth")
    pair(UNIV2, USDC, "uni2usdc")
    pair(UNIV2, DAI, "uni2dai")
    pair(SUSHI, WETH, "sushi_weth")
    pair(SUSHI, USDC, "sushi_usdc")
    pool(3000, "uni3weth3k")
    pool(10000, "uni3weth10k")
    r = call(UNIV3, GETPOOL + PAD(t) + PAD(USDC) + PAD(hex(3000)[2:]))
    if r is None:
        failures += 1
    else:
        p = addr(r)
        if p and int(p, 16) != 0:
            liq.append("uni3usdc3k:" + p)
    return {"dao": row["dao"], "token": t, "eth": row["eth"], "minAQ": row["minAQ"],
            "pools": liq, "err": failures > 0}


def pool_detail(row):
    """Read pool depth + token supply; compute the fraction of the minAQ quorum
    that is actually buyable from the existing pool."""
    tok = row["token"]
    out = {"dao": row["dao"], "pools": row["pools"]}
    total = dec(call(tok, S("totalSupply()")))
    out["totalSupply"] = total
    minAQ = row["minAQ"] or 0
    # passing needs yea/votingPower > minAQ AND (if minAQ==0) yea*1e18/total > 0
    need = (minAQ * total) // 10**18 if total else None
    if total:
        floor_need = total // 10**18  # strict-inequality dust floor for minAQ==0
        need = max(need or 0, floor_need)
    out["need_tokens"] = need
    best_frac = 0.0
    best_res = None
    for p in row["pools"]:
        kind, _, pad = p.partition(":")
        if kind.startswith("uni2") or kind.startswith("sushi"):
            t0 = addr(call(pad, S("token0()")))
            r = call(pad, S("getReserves()"))
            if r and len(r) >= 2 + 128:
                r0 = int(r[2:66], 16)
                r1 = int(r[66:130], 16)
                token_res = r0 if t0 and t0.lower() == tok.lower() else r1
                if need and need > 0:
                    frac = token_res / need
                    if frac > best_frac:
                        best_frac, best_res = frac, token_res
                elif need == 0:
                    best_frac, best_res = 1.0, token_res
        else:  # univ3
            liq = dec(call(pad, S("liquidity()")))
            if liq and need and need > 0:
                # liquidity is not directly comparable to a token amount; record as proxy
                out.setdefault("v3_liquidity", []).append({"pool": pad, "liquidity": liq})
            elif need == 0:
                best_frac = max(best_frac, 1.0)
    out["token_reserve"] = best_res
    out["acquirable_frac"] = round(best_frac, 6)
    return out


def main():
    t0 = time.time()
    limit = int(os.environ.get("SCAN_LIMIT", "0"))
    join = JOIN[:limit] if limit else JOIN
    global RPCS
    RPCS = _healthy()
    print(f"RPC pool: {len(RPCS)} healthy endpoints", flush=True)
    print(f"funded DAOs: {len(join)} (of {len(JOIN)})", flush=True)

    with ThreadPoolExecutor(max_workers=28) as ex:
        pm = list(ex.map(scan_pm, join))
    # retry pass for rows that failed due to transient RPC errors
    for _ in range(3):
        failed = [r for r, x in zip(join, pm) if x.get("err")]
        if not failed:
            break
        print(f"[A] retrying {len(failed)} failed rows", flush=True)
        with ThreadPoolExecutor(max_workers=4) as ex:
            fixed = list(ex.map(scan_pm, failed))
        fx = {x["dao"]: x for x in fixed if not x.get("err")}
        pm = [fx.get(x["dao"], x) for x in pm]
    ok = [x for x in pm if not x.get("err")]
    mgr = [x for x in ok if x["isMgr"]]
    tot = sum(x["eth"] for x in mgr)
    print(f"[A] pm re-read ok={len(ok)} isMgr={len(mgr)} ({100*len(mgr)/max(len(ok),1):.1f}%) "
          f"ETH={tot/1e18:.4f}  ({time.time()-t0:.0f}s)", flush=True)
    json.dump(pm, open(os.path.join(OUT, "aragon_full_pm.json"), "w"))

    # liquidity scan over the manager-funded set
    targets = [{"dao": x["dao"], "token": x["token"], "eth": x["eth"], "minAQ": x["minAQ"]} for x in mgr]
    with ThreadPoolExecutor(max_workers=28) as ex:
        lq = [x for x in ex.map(scan_liq, targets) if x]
    for _ in range(3):
        failed = [t for t, x in zip(targets, lq) if x.get("err")]
        if not failed:
            break
        print(f"[B] retrying {len(failed)} token rows", flush=True)
        with ThreadPoolExecutor(max_workers=4) as ex:
            fixed = {x["dao"]: x for x in ex.map(scan_liq, failed) if x and not x.get("err")}
        lq = [fixed.get(x["dao"], x) for x in lq]
    n_err = sum(1 for x in lq if x.get("err"))
    withpool = [x for x in lq if x["pools"]]
    print(f"[B] token liquidity scan: {len(lq)} tokens, {len(withpool)} with any pool, {n_err} unresolved "
          f"({time.time()-t0:.0f}s)", flush=True)
    json.dump(lq, open(os.path.join(OUT, "aragon_full_liq.json"), "w"))

    # at-risk join
    lqmap = {x["dao"]: x for x in lq}
    rows = []
    for x in mgr:
        rows.append({**x, "pools": lqmap.get(x["dao"], {}).get("pools", [])})

    # phase C: for DAOs that DO have a pool, read pool depth + token supply to judge
    # whether the minAQ quorum is actually acquirable.
    withpool0 = [x for x in rows if x["pools"]]
    with ThreadPoolExecutor(max_workers=8) as ex:
        details = list(ex.map(pool_detail, withpool0))
    for _ in range(3):
        failed = [r for r, d in zip(withpool0, details) if d.get("totalSupply") is None]
        if not failed:
            break
        print(f"[C] retrying {len(failed)} pool-detail rows", flush=True)
        with ThreadPoolExecutor(max_workers=4) as ex:
            fixed = {d["dao"]: d for d in ex.map(pool_detail, failed) if d.get("totalSupply") is not None}
        details = [fixed.get(d["dao"], d) for d in details]
    det = {d["dao"]: d for d in details}
    for x in rows:
        if x["dao"] in det:
            x.update(det[x["dao"]])
    json.dump(details, open(os.path.join(OUT, "aragon_pool_detail.json"), "w"), indent=1)
    print(f"[C] pool detail read for {len(details)} DAOs ({time.time()-t0:.0f}s)", flush=True)

    creat = [x for x in rows if x["anyCanCreate"] == 1 or x["tmCanCreate"] == 1]
    with_pool = [x for x in rows if x["pools"]]
    reachable = [x for x in with_pool
                 if x.get("acquirable_frac") is not None and x["acquirable_frac"] >= 1.0
                 and (x["anyCanCreate"] == 1 or x["tmCanCreate"] == 1)]
    summary = {
        "funded_daos": len(join),
        "pm_ok": len(ok), "manager_funded": len(mgr),
        "manager_funded_eth": round(tot / 1e18, 4),
        "manager_funded_with_tokenmanager": sum(1 for x in mgr if x["has_token_manager"]),
        "manager_funded_any_open": sum(1 for x in mgr if x["anyCanCreate"] == 1),
        "manager_funded_creatable": len(creat),
        "manager_funded_with_any_pool": len(with_pool),
        "manager_and_creatable_and_pool": len([x for x in creat if x["pools"]]),
        "pool_minAQ_acquirable": len(reachable),
        "pool_minAQ_acquirable_detail": [
            {"dao": x["dao"], "eth": round(x["eth"] / 1e18, 4), "minAQ": x["minAQ"],
             "token_reserve": x.get("token_reserve"), "need_tokens": x.get("need_tokens"),
             "acquirable_frac": x.get("acquirable_frac"), "token": x["token"]}
            for x in sorted(reachable, key=lambda y: -y["eth"])
        ],
        "eth_creatable": round(sum(x["eth"] for x in creat) / 1e18, 4),
        "eth_with_pool": round(sum(x["eth"] for x in with_pool) / 1e18, 4),
    }
    json.dump({"summary": summary, "rows": rows}, open(os.path.join(OUT, "aragon_at_risk.json"), "w"), indent=1)
    print("[C] summary:", json.dumps(summary, indent=1), flush=True)
    print(f"done in {time.time()-t0:.0f}s", flush=True)


if __name__ == "__main__":
    main()
