#!/usr/bin/env python3
"""Fountain Protocol — CI enumeration (read-only).

1. Nexus: enumerate tx history per cToken market -> borrower/supplier candidate sets.
2. Emerald RPC (batched): read live positions for all candidates (debt, cTokens, account
   liquidity, compAccrued) + market totals at a pinned block.
3. Emit JSON summary (E-U / H-O / S supporting data).

Public endpoints only; no secrets.
"""
import json, base64, os, sys, time, urllib.request, argparse, collections
from concurrent.futures import ThreadPoolExecutor

NEXUS = "https://nexus.oasis.io/v1/emerald"
RPCS = [os.environ.get("OASIS_RPC", ""), "https://emerald.oasis.dev", "https://1rpc.io/oasis/emerald"]
RPCS = [u for u in RPCS if u]
UA = {"Content-Type": "application/json", "User-Agent": "fountain-enum/1.0"}

COMPTROLLERS = {
    "classic": "0xA7684aE7e07Dac91113900342b3ef25B9Fd1D841",
    "usd":     "0x1C0C30795802Bf2B3232a824f41629BbBCF63127",
    "lpt":     "0x7c4d0c834701C6E7F57b8C1424d30aDC46eA0840",
}
MARKETS = {
    "classic": {
        "0xd7d588babfb99e82cd6dd0ca7677a5599aa678b5": "fROSE",
        "0x275b88547185d955f66e5dd1066e040af468fc66": "fETH",
        "0x352cc3320debffa3046cf66a4e0a80d528f00285": "fUSDT",
        "0x61d90f6ab2b2b1baffa39bebb5d8ad57028da258": "fUSDC",
    },
    "usd": {
        "0x2552707d66c102c12b0f8284824f80e1299cb6b7": "fUSDT_wormhole",
        "0xbe5a2c8da347311c46b1f0868aa52b8eb59938b3": "fUSDC_wormhole",
        "0x54cc15a99e40cc4a6d8a2ddc1b8ee65a2d7414e1": "fUSDC_celer",
        "0x27d51cd65070d28463a42ee644a22353c2bbddf3": "fUSDC_anyswap",
    },
    "lpt": {
        "0x63f1fe2e1da490611fc16e4a5d92b7ec7d0911a9": "fROSE_lpt",
        "0xf377b8bcdd8e154ab8c846eebdf758f37be93381": "fWETH_wormhole_WROSE",
        "0xb317c67b105f7e216f483618a91eaea3814b9b3c": "fWROSE_WETH_wormhole",
        "0x3acaddeb99c714103683a1a061b793d53563f17c": "fUSDC_celer_WROSE",
        "0xb473e13cbb875c8f9598513cd4eb2c52b1b88173": "fWROSE_WETH_wormhole2",
        "0x6e298782e7bbc097442ed579d620d1b5a8e7dfd3": "fWROSE_USDT_wormhole",
        "0x4be7e0ec31797d4d61fc07dbf0f843ae04a58f05": "fWROSE_USDC_anyswap",
    },
}
FTP = "0xd1dF9CE4b6159441D18BD6887DBD7320A8D52A05"
SEL = {
    "0xc5ebeaec": "borrow", "0xa0712d68": "mint", "0x1249c58b": "mint_eth",
    "0xdb006a75": "redeem", "0x852a12e3": "redeemUnderlying", "0x0e752702": "repayBorrow",
    "0xf5e3c462": "liquidateBorrow", "0xaae40a2a": "liquidateBorrow_eth",
    "0x2608f818": "repayBorrowBehalf",
}

def rpc_batch(items, timeout=60):
    """items: list of (method, params). Returns list of results (None on failure)."""
    body = json.dumps([{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(items)]).encode()
    last = None
    for attempt in range(6):
        url = RPCS[attempt % len(RPCS)]
        try:
            req = urllib.request.Request(url, data=body, headers=UA)
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read())
            if isinstance(out, dict):
                raise RuntimeError(str(out)[:200])
            res = {o["id"]: o.get("result") for o in out if isinstance(o, dict) and "id" in o}
            return [res.get(i) for i in range(len(items))]
        except Exception as e:
            last = str(e)
            time.sleep(1.0 + attempt)
    print(f"  [rpc_batch failed: {last}]", flush=True)
    return [None] * len(items)

def rpc(method, params, timeout=60):
    return rpc_batch([(method, params)], timeout)[0]

def batch_calls(calls, block_tag="latest", chunk=20, workers=3):
    """calls: list of (to, data). Returns list of raw eth_call results at block_tag."""
    out = [None] * len(calls)
    chunks = [(i, calls[i:i + chunk]) for i in range(0, len(calls), chunk)]
    def run(ci_chunk):
        ci, ch = ci_chunk
        items = [("eth_call", [{"to": to, "data": data}, block_tag]) for to, data in ch]
        res = rpc_batch(items)
        return ci, res
    with ThreadPoolExecutor(max_workers=workers) as ex:
        for ci, res in ex.map(run, chunks):
            for j, r in enumerate(res):
                out[ci + j] = r
    return out

def call(to, sel, arg=None):
    data = "0x" + sel + ((arg[2:].lower().rjust(64, "0")) if arg else "")
    return rpc("eth_call", [{"to": to, "data": data}, "latest"])

def u(h):
    return None if not isinstance(h, str) or h == "0x" else int(h, 16)

def nexus_txs(addr, max_pages=60, cache_dir=None):
    out = []
    for page in range(max_pages):
        d = None
        name = os.path.join(cache_dir, f"{addr.lower()}-{page}.json") if cache_dir else None
        if name and os.path.exists(name):
            d = json.load(open(name))
        else:
            url = f"{NEXUS}/transactions?rel={addr}&limit=100&offset={page*100}"
            for a in range(3):
                try:
                    req = urllib.request.Request(url, headers={"User-Agent": UA["User-Agent"]})
                    with urllib.request.urlopen(req, timeout=60) as r:
                        d = json.loads(r.read())
                    break
                except Exception:
                    time.sleep(2)
            if name and d is not None:
                json.dump(d, open(name, "w"))
        txs = (d or {}).get("transactions", [])
        if not txs:
            break
        out.extend(txs)
        if len(txs) < 100:
            break
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="ci-out/enumeration.json")
    ap.add_argument("--max-pages", type=int, default=40)
    ap.add_argument("--time-budget", type=int, default=1200, help="seconds for Nexus phase")
    a = ap.parse_args()
    os.makedirs(os.path.dirname(a.out) or ".", exist_ok=True)
    cache_dir = os.path.join(os.path.dirname(a.out) or ".", "nexus-cache")
    os.makedirs(cache_dir, exist_ok=True)

    latest = int(rpc("eth_blockNumber", []), 16)
    block = latest - 2
    res = {"rpcs": RPCS, "latest": latest, "block": block, "markets": {}, "candidates": {}, "summary": {}}
    print(f"block={block}", flush=True)

    # ---- market state (batched) ----
    mkt_calls = []  # (key, to, data)
    meta = []       # (label, market_or_none, field)
    for label, ms in MARKETS.items():
        comp = COMPTROLLERS[label]
        res["markets"][label] = {"comptroller": comp, "markets": {}}
        for m, name in ms.items():
            res["markets"][label]["markets"][m] = {"name": name}
            for key, sel in [("cash", "0x3b1d21a2"), ("borrows", "0x47bd3718"), ("reserves", "0x8f840ddd"),
                             ("totalSupply", "0x18160ddd"), ("exchangeRate", "0x182df0f5"), ("decimals", "0x313ce567"),
                             ("accrualBlockTimestamp", "0xcfa99201")]:
                mkt_calls.append((m, sel)); meta.append((label, m, key))
            for key, sel in [("mintPaused", "0x731f0c2b"), ("borrowPaused", "0x6d154ea5")]:
                mkt_calls.append((comp, sel + m[2:].lower().rjust(64, "0"))); meta.append((label, m, key))
        for key, sel in [("seizeGuardianPaused", "0xac0b0bb7"), ("transferGuardianPaused", "0x87f76303"),
                         ("closeFactor", "0xe8755446"), ("liqIncentive", "0x4ada90af")]:
            mkt_calls.append((comp, sel)); meta.append((label, None, key))
        for key, sel in [("admin", "0xf851a440"), ("pauseGuardian", "0x24a3d622"), ("oracle", "0x7dc0d1d0")]:
            mkt_calls.append((comp, sel)); meta.append((label, None, key))
        mkt_calls.append((FTP, "0x70a08231" + comp[2:].lower().rjust(64, "0"))); meta.append((label, None, "ftpBalance"))
    results = batch_calls(mkt_calls, hex(block))
    for (label, m, key), r in zip(meta, results):
        val = u(r) if isinstance(r, str) else None
        if key in ("admin", "pauseGuardian", "oracle") and isinstance(r, str):
            val = "0x" + r[-40:]
        if m is None:
            res["markets"][label][key] = val
        else:
            res["markets"][label]["markets"][m][key] = val
    print("market state done", flush=True)

    # ---- market ERC20 balances (sweepToken surface: non-underlying tokens held by markets) ----
    ALL_TOKENS = {
        "WETH": "0x3223f17957ba502cbe71401d55a0db26e5f7c68f",
        "USDT": "0xdc19a122e268128b5ee20366299fc7b5b199c8e3",
        "USDC": "0xe8a638b3b7565ee7c5eb9755e58552afc87b94dd",
        "USDC_celer": "0x81ecac0d6be0550a00ff064a4f9dd2400585fe9c",
        "USDC_anyswap": "0x80a16016cc4a2e6a2caca8a4a498b1699ff0f844",
        "t0xfb9b": "0xfb9bd52abe613a5c4a20e9fc09462a2ec5f2d1b2",
        "t0x28c9": "0x28c9d3e689b5d3629afc2d69ef6a2799578574e0",
        "t0x60bf": "0x60bf7989a447c45aaa0aeb86873b50b5a3709b10",
        "t0xc1ab": "0xc1ab2878d289d5c402837600c6abc03a8a92d890",
        "t0xd9f3": "0xd9f3be6497b26efbed163a95912fb5e2f235fd53",
        "t0x89f5": "0x89f5e345b7837e950136811b94af6ccba199efa8",
        "FTP": FTP,
    }
    bal_calls = []
    bal_meta = []
    for label, ms in MARKETS.items():
        for m in ms:
            for tname, taddr in ALL_TOKENS.items():
                bal_calls.append((taddr, "0x70a08231" + m[2:].lower().rjust(64, "0")))
                bal_meta.append((label, m, tname, taddr))
    bals = batch_calls(bal_calls, hex(block))
    res["market_token_balances"] = {}
    for (label, m, tname, taddr), r in zip(bal_meta, bals):
        v = u(r) if isinstance(r, str) else None
        if v:
            res["market_token_balances"].setdefault(m, {})[tname] = v
    print(f"markets holding non-zero ERC20 balances: {list(res['market_token_balances'].keys())}", flush=True)

    # ---- enumerate candidate accounts from Nexus tx history (parallel per market) ----
    candidates = set()
    liq_events = []
    market_list = [(label, m, ms[m]) for label, ms in MARKETS.items() for m in ms]
    deadline = time.time() + a.time_budget
    def fetch_market(item):
        label, m, name = item
        if time.time() > deadline:
            return label, m, name, []
        txs = nexus_txs(m, a.max_pages, cache_dir)
        return label, m, name, txs
    with ThreadPoolExecutor(max_workers=6) as ex:
        for label, m, name, txs in ex.map(fetch_market, market_list):
            print(f"  nexus {name} ({m[:10]}): {len(txs)} txs", flush=True)
            for t in txs:
                data = (t.get("body") or {}).get("data")
                if not data:
                    continue
                try:
                    b = base64.b64decode(data)
                except Exception:
                    continue
                sel = "0x" + b[:4].hex()
                nm = SEL.get(sel)
                if not nm or not t.get("success"):
                    continue
                snd = t.get("sender_0_eth")
                if nm in ("borrow", "mint", "mint_eth", "repayBorrow", "repayBorrowBehalf", "liquidateBorrow", "liquidateBorrow_eth") and snd:
                    candidates.add((label, snd.lower()))
                if nm in ("liquidateBorrow", "liquidateBorrow_eth") and len(b) >= 100:
                    liq_events.append({"market": m, "ts": t.get("timestamp"), "sender": snd,
                                       "borrower": "0x" + b[16:36].hex()})
    # ---- also scan each comptroller's history (captures internal-call borrows/mints) ----
    comp_list = [(label, COMPTROLLERS[label]) for label in MARKETS]
    def fetch_comp(item):
        label, c = item
        txs = nexus_txs(c, a.max_pages, cache_dir)
        return label, c, txs
    with ThreadPoolExecutor(max_workers=3) as ex:
        for label, c, txs in ex.map(fetch_comp, comp_list):
            print(f"  nexus comptroller {label} ({c[:10]}): {len(txs)} txs", flush=True)
            for t in txs:
                data = (t.get("body") or {}).get("data")
                if not data:
                    continue
                try:
                    b = base64.b64decode(data)
                except Exception:
                    continue
                sel = "0x" + b[:4].hex()
                nm = SEL.get(sel)
                if not nm or not t.get("success"):
                    continue
                snd = t.get("sender_0_eth")
                if snd:
                    candidates.add((label, snd.lower()))

    res["liquidateBorrow_txs"] = liq_events
    print(f"candidates: {len(candidates)}", flush=True)

    # ---- read live positions (batched) ----
    cand_calls = []
    cand_meta = []
    for label, acct in sorted(candidates):
        cand_calls.append((COMPTROLLERS[label], "0x5ec88c79" + acct[2:].rjust(64, "0"))); cand_meta.append((label, acct, "liquidity"))
        cand_calls.append((COMPTROLLERS[label], "0xcc7ebdc4" + acct[2:].rjust(64, "0"))); cand_meta.append((label, acct, "compAccrued"))
        for m in MARKETS[label]:
            cand_calls.append((m, "0xc37f68e2" + acct[2:].rjust(64, "0"))); cand_meta.append((label, acct, m))
    results = batch_calls(cand_calls, hex(block), chunk=25, workers=4)
    for (label, acct, field), r in zip(cand_meta, results):
        key = f"{label}:{acct}"
        row = res["candidates"].setdefault(key, {"comptroller": {}, "positions": {}, "compAccrued": None})
        if field == "liquidity":
            if isinstance(r, str) and len(r) >= 194:
                row["comptroller"] = {"err": u("0x" + r[2:66]), "liquidity": u("0x" + r[66:130]), "shortfall": u("0x" + r[130:194])}
        elif field == "compAccrued":
            row["compAccrued"] = u(r) if isinstance(r, str) else None
        else:
            if isinstance(r, str) and len(r) >= 258:
                ctok = u("0x" + r[66:130]); debt = u("0x" + r[130:194])
                if ctok or debt:
                    row["positions"][field] = {"cTokens": ctok, "borrowBalance": debt}
    print(f"positions read: {len(res['candidates'])}", flush=True)

    # ---- summaries ----
    cash_total = {}
    borrow_total = {}
    for label, ms in res["markets"].items():
        cash_total[label] = sum((d.get("cash") or 0) for d in ms["markets"].values())
        borrow_total[label] = sum((d.get("borrows") or 0) for d in ms["markets"].values())
    shortfalls = {k: v for k, v in res["candidates"].items() if (v.get("comptroller") or {}).get("shortfall")}
    with_debt = {k: v for k, v in res["candidates"].items() if any(p.get("borrowBalance") for p in v["positions"].values())}
    res["summary"] = {
        "cash_by_comptroller": cash_total,
        "borrows_by_comptroller": borrow_total,
        "candidates": len(candidates),
        "accounts_with_remaining_debt": len(with_debt),
        "accounts_with_shortfall": len(shortfalls),
        "shortfall_keys": sorted(shortfalls.keys()),
    }
    json.dump(res, open(a.out, "w"), indent=1)
    print("summary:", json.dumps(res["summary"], indent=1), flush=True)
    print("wrote", a.out, flush=True)

if __name__ == "__main__":
    main()
