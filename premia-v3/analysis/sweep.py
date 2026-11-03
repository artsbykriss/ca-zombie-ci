#!/usr/bin/env python3
"""Premia V3 (Arbitrum) — independent pool/vault balance sweep.

Reads the pool set produced by fetch_pool_logs.py (every PoolDeployed log from
the factory), measures each pool's own base/quote token balances at a pinned
block via Multicall3, reads each pool's on-chain settings (maturity / isCall),
prices tokens with DefiLlama, and enumerates every vault from the on-chain
VaultRegistry.

Read-only. RPC URLs are taken from env vars and never printed. No secrets are
written to disk.

Usage:
  python3 analysis/sweep.py [--block N] [--out ci-out/sweep.json] [--limit N]
"""
import argparse
import gzip
import json
import os
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

FACTORY = "0xAE4fB6622F25f397587F11638dA8CE88C27b5645"
DIAMOND = "0x2Ea42642D1B951f18eA7FbCE495Bea9E517b198F"
VAULT_REGISTRY = "0xBB7456a7661f46ebA8C638cb8CC2Ac181f45F3b9"
MULTICALL3 = "0xcA11bde05977b3631167028862bE2a173976CA11"

# public fallbacks only; keyed endpoints are built from env vars at runtime
PUBLIC_RPCS = [
    "https://arb1.arbitrum.io/rpc",
    "https://arbitrum.drpc.org",
    "https://arbitrum-one.publicnode.com",
    "https://1rpc.io/arb",
]


def env_key(name):
    v = os.environ.get(name, "")
    if v:
        return v
    # local fallback for interactive runs; never written to output
    try:
        env = open("/home/heisenberg/CA/.env").read()
        import re

        m = re.search(rf"^{name}=(.*)$", env, re.M)
        if m:
            return m.group(1).strip().strip('"').strip("'")
    except OSError:
        pass
    return ""


def build_rpcs():
    out = []
    for k in ("ARB_RPC_URL",):
        v = os.environ.get(k, "")
        if v:
            out.append(v)
    ak = env_key("ALCHEMY_API_KEY")
    if ak:
        out.append(f"https://arb-mainnet.g.alchemy.com/v2/{ak}")
    ak2 = env_key("ALCHEMY_API_KEY_2")
    if ak2:
        out.append(f"https://arb-mainnet.g.alchemy.com/v2/{ak2}")
    ankr = env_key("ANKR_API_KEY")
    if ankr:
        out.append(f"https://rpc.ankr.com/arbitrum/{ankr}")
    out.extend(PUBLIC_RPCS)
    # de-dupe, keep order
    seen = set()
    return [u for u in out if not (u in seen or seen.add(u))]


RPCS = build_rpcs()
_rpc_i = 0
BLOCK = None  # pinned block for state reads


def rpc(method, params, tries=5):
    global _rpc_i
    last = None
    for t in range(tries):
        url = RPCS[(_rpc_i + t) % len(RPCS)]
        try:
            req = urllib.request.Request(
                url,
                data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"},
            )
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.loads(r.read())
            if "result" in d:
                _rpc_i = (_rpc_i + t) % len(RPCS)
                return d["result"]
            last = RuntimeError(str(d.get("error"))[:160])
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(0.6 * (t + 1))
    raise RuntimeError(str(last)[:200])


# ---------------- Multicall3 aggregate3 ----------------
def enc_aggregate3(calls):
    """calls: list of (target, calldata_hex)."""
    n = len(calls)
    head = "82ad56cb" + hex(32)[2:].rjust(64, "0") + hex(n)[2:].rjust(64, "0")
    offs = []
    body = ""
    cur = n * 32
    for target, cd in calls:
        offs.append(cur)
        cd = cd[2:] if cd.startswith("0x") else cd
        sub = (
            target[2:].lower().rjust(64, "0")
            + "1".rjust(64, "0")
            + hex(96)[2:].rjust(64, "0")
            + hex(len(cd) // 2)[2:].rjust(64, "0")
            + cd.ljust(((len(cd) + 63) // 64) * 64, "0")
        )
        body += sub
        cur += len(sub) // 2
    return "0x" + head + "".join(hex(o)[2:].rjust(64, "0") for o in offs) + body


def dec_aggregate3(res, n):
    b = res[2:]
    words = [b[i * 64 : (i + 1) * 64] for i in range(len(b) // 64)]
    out = [None] * n
    cnt = int(words[1], 16)
    for j in range(cnt):
        off = int(words[2 + j], 16) // 32
        ts = 2 + off
        ok = int(words[ts], 16)
        if ok != 1:
            continue
        boff = int(words[ts + 1], 16) // 32
        bs = ts + boff
        ln = int(words[bs], 16)
        if ln == 0:
            out[j] = "0x"
            continue
        out[j] = "0x" + "".join(words[bs + 1 : bs + 1 + ln // 32])
    return out


def multicall(calls, batch=100):
    """Returns list of raw return-data hex (or None on revert)."""
    tag = hex(BLOCK) if BLOCK else "latest"
    out = []
    for i in range(0, len(calls), batch):
        chunk = calls[i : i + batch]
        res = None
        for attempt in range(6):
            try:
                res = rpc("eth_call", [{"to": MULTICALL3, "data": enc_aggregate3(chunk)}, tag], tries=3)
                break
            except Exception as e:  # noqa: BLE001
                if attempt == 5:
                    raise
                time.sleep(2.0 * (attempt + 1))
        out.extend(dec_aggregate3(res, len(chunk)))
        time.sleep(0.05)
    return out


def balance_of_calldata(holder):
    return "0x70a08231" + holder[2:].lower().rjust(64, "0")


def uint_of(raw):
    if not raw or raw == "0x":
        return None
    return int(raw, 16)


def load_pools():
    p = os.path.join(HERE, "pools.json")
    if not os.path.exists(p):
        p = os.path.join(HERE, "pools.json.gz")
        with gzip.open(p, "rt") as f:
            return json.load(f)
    with open(p) as f:
        return json.load(f)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--block", type=int, default=0)
    ap.add_argument("--out", default=os.path.join(ROOT, "ci-out", "sweep.json"))
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    data = load_pools()
    pools = data["pools"]
    if args.limit:
        pools = dict(list(pools.items())[: args.limit])
    global BLOCK
    head = int(rpc("eth_blockNumber", []), 16)
    block = args.block or (head - 20)
    BLOCK = block
    blk = rpc("eth_getBlockByNumber", [hex(block), False])
    ts = int(blk["timestamp"], 16)
    print(f"pools={len(pools)} block={block} ts={ts}", flush=True)

    keys = list(pools.keys())
    # 1) balanceOf(base) and balanceOf(quote) for every pool
    calls = []
    meta = []
    for k in keys:
        p = pools[k]
        calls.append((p["base"], balance_of_calldata(p["pool"])))
        meta.append((k, "base"))
        calls.append((p["quote"], balance_of_calldata(p["pool"])))
        meta.append((k, "quote"))
    print(f"balance calls={len(calls)}", flush=True)
    res = multicall(calls)
    bal = {}
    for (k, side), raw in zip(meta, res):
        v = uint_of(raw)
        if v:
            bal.setdefault(k, {})[side] = v
    print(f"funded pools={len(bal)}", flush=True)

    # 2) getPoolSettings() for funded pools (maturity/strike/isCall/base/quote)
    fkeys = list(bal.keys())
    calls = [(pools[k]["pool"], "0xe4a0ce2f") for k in fkeys]
    res = multicall(calls)
    settings = {}
    for k, raw in zip(fkeys, res):
        if not raw or len(raw) < 2 + 6 * 64:
            continue
        b = raw[2:]
        w = [b[i * 64 : (i + 1) * 64] for i in range(6)]
        settings[k] = {
            "base": "0x" + w[0][-40:],
            "quote": "0x" + w[1][-40:],
            "oracle": "0x" + w[2][-40:],
            "strike": int(w[3], 16),
            "maturity": int(w[4], 16),
            "isCall": int(w[5], 16) != 0,
        }

    # 3) prices
    tokens = sorted({p["base"] for p in pools.values()} | {p["quote"] for p in pools.values()})
    prices = {}

    def price_tokens(tks):
        tks = [t for t in tks if t.lower() not in prices]
        for i in range(0, len(tks), 25):
            chunk = tks[i : i + 25]
            u = "https://coins.llama.fi/prices/current/" + ",".join("arbitrum:" + t.lower() for t in chunk)
            try:
                with urllib.request.urlopen(u, timeout=40) as r:
                    d = json.loads(r.read())
                for t in chunk:
                    c = d["coins"].get("arbitrum:" + t.lower())
                    if c:
                        prices[t.lower()] = {
                            "price": c["price"],
                            "symbol": c.get("symbol"),
                            "decimals": c.get("decimals"),
                        }
            except Exception as e:  # noqa: BLE001
                print(f"price err {i}: {str(e)[:80]}", flush=True)
            time.sleep(0.2)
        # decimals on-chain fallback for tokens without a price
        missing = [t for t in tks if t.lower() not in prices]
        if missing:
            calls = [(t, "0x313ce567") for t in missing]  # decimals()
            res = multicall(calls)
            for t, raw in zip(missing, res):
                v = uint_of(raw)
                if v is not None:
                    prices[t.lower()] = {"price": 0.0, "symbol": None, "decimals": v}

    price_tokens(tokens)

    def token_usd(t, raw):
        pr = prices.get(t.lower())
        if not pr:
            return 0.0
        dec = pr.get("decimals")
        if dec is None:
            dec = 18
        return raw / (10 ** dec) * pr["price"]

    rows = []
    totals = {"all": 0.0, "pool_token": 0.0}
    tok_tot = {}
    for k, b in bal.items():
        p = pools[k]
        s = settings.get(k, {})
        is_call = s.get("isCall", p["isCall"])
        maturity = s.get("maturity", p["maturity"])
        pool_token = (s.get("base", p["base"]) if is_call else s.get("quote", p["quote"]))
        usd_all = 0.0
        usd_pool = 0.0
        detail = {}
        for side, raw in b.items():
            t = p["base"] if side == "base" else p["quote"]
            u = token_usd(t, raw)
            usd_all += u
            detail[side] = {"token": t, "raw": raw, "usd": round(u, 6)}
            if t.lower() == pool_token.lower():
                usd_pool += u
            tok_tot[t.lower()] = tok_tot.get(t.lower(), 0.0) + u
        totals["all"] += usd_all
        totals["pool_token"] += usd_pool
        rows.append(
            {
                "pool": p["pool"],
                "base": s.get("base", p["base"]),
                "quote": s.get("quote", p["quote"]),
                "isCall": is_call,
                "strike": s.get("strike", p["strike"]),
                "maturity": maturity,
                "open": maturity > ts,
                "usd_all": round(usd_all, 6),
                "usd_pool_token": round(usd_pool, 6),
                "holdings": detail,
            }
        )
    rows.sort(key=lambda r: r["usd_pool_token"], reverse=True)
    open_rows = [r for r in rows if r["open"]]
    expired_rows = [r for r in rows if not r["open"]]

    # 4) vaults
    vraw = rpc("eth_call", [{"to": VAULT_REGISTRY, "data": "0x44d00f82"}, hex(block)])
    from eth_abi import decode

    vlist = decode(["(address,address,bytes32,uint8,uint8)[]"], bytes.fromhex(vraw[2:]))[0]
    price_tokens([v[1] for v in vlist])
    vcalls = [(asset, balance_of_calldata(a)) for a, asset, _, _, _ in vlist]
    vres = multicall(vcalls)
    vaults = []
    for (a, asset, vt, side, opt), raw in zip(vlist, vres):
        vbal = uint_of(raw) or 0
        vaults.append(
            {
                "vault": a,
                "asset": asset,
                "side": side,
                "optionType": opt,
                "balance_raw": vbal,
                "usd": round(token_usd(asset, vbal), 6),
            }
        )
    vault_usd = sum(v["usd"] for v in vaults)

    # 5) diamond's own balances (not reachable by pool accounting, for completeness)
    dcalls = [(t, balance_of_calldata(DIAMOND)) for t in tokens]
    dres = multicall(dcalls)
    diamond = {}
    for t, raw in zip(tokens, dres):
        v = uint_of(raw) or 0
        if v:
            diamond[t] = {"raw": v, "usd": round(token_usd(t, v), 6)}

    summary = {
        "block": block,
        "timestamp": ts,
        "pools_total": len(pools),
        "pools_funded": len(rows),
        "pools_open": len(open_rows),
        "pools_expired": len(expired_rows),
        "usd_all_tokens": round(totals["all"], 2),
        "usd_pool_token": round(totals["pool_token"], 2),
        "usd_open": round(sum(r["usd_pool_token"] for r in open_rows), 2),
        "usd_expired": round(sum(r["usd_pool_token"] for r in expired_rows), 2),
        "largest_pool": rows[0] if rows else None,
        "largest_open_pool": open_rows[0] if open_rows else None,
        "vault_count": len(vaults),
        "vault_usd": round(vault_usd, 2),
        "vaults": sorted(vaults, key=lambda v: v["usd"], reverse=True),
        "diamond_balances": diamond,
        "token_totals_usd": {k: round(v, 2) for k, v in sorted(tok_tot.items(), key=lambda x: -x[1])},
        "prices": {k: {"price": v["price"], "symbol": v["symbol"]} for k, v in prices.items()},
        "top20": rows[:20],
        "top20_open": open_rows[:20],
        "all_funded": rows,
    }
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w") as f:
        json.dump(summary, f, indent=1)
    # compact CSV for eyeballing
    csvp = os.path.splitext(args.out)[0] + ".csv"
    with open(csvp, "w") as f:
        f.write("pool,base,quote,isCall,strike,maturity,open,usd_pool_token\n")
        for r in rows:
            f.write(
                f"{r['pool']},{r['base']},{r['quote']},{int(r['isCall'])},{r['strike']},{r['maturity']},{int(r['open'])},{r['usd_pool_token']}\n"
            )
    print(
        json.dumps(
            {
                "pools_total": summary["pools_total"],
                "pools_funded": summary["pools_funded"],
                "pools_open": summary["pools_open"],
                "usd_pool_token": summary["usd_pool_token"],
                "usd_open": summary["usd_open"],
                "usd_expired": summary["usd_expired"],
                "largest": summary["largest_pool"],
                "largest_open": summary["largest_open_pool"],
                "vault_usd": summary["vault_usd"],
            },
            indent=1,
        ),
        flush=True,
    )


if __name__ == "__main__":
    main()
