#!/usr/bin/env python3
"""Read state for candidate accounts at one fixed block. Writes era-positions-raw.json.

Usage:
  python3 era-positions-read.py [--only-borrowers] [--limit N]

Reads per account: 6x getAccountSnapshot, getAccountLiquidity, getAssetsIn.
Market config: oracle prices, collateral factors, closeFactor, liquidationIncentive,
totalSupply/totalBorrows/getCash/exchangeRate/decimals/symbol.
"""
import json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
import os as _os
RPC_URLS = []
if _os.environ.get("ALCHEMY_API_KEY_2"):
    RPC_URLS.append("https://zksync-mainnet.g.alchemy.com/v2/" + _os.environ["ALCHEMY_API_KEY_2"])
if _os.environ.get("INFURA_API_KEY"):
    RPC_URLS.append("https://zksync-mainnet.infura.io/v3/" + _os.environ["INFURA_API_KEY"])
RPC_URLS.append("https://mainnet.era.zksync.io/")


def sel(sig):
    import sha3
    k = sha3.keccak_256(); k.update(sig.encode()); return "0x" + k.digest().hex()[:8]


SEL = {
    "getUnderlyingPrice(address)": "0xfc57d4df",
    "collateralFactorMantissa(address)": "0xe7c02777",
    "markets(address)": "0x8e8f294b",
    "decimals()": "0x313ce567",
    "totalSupply()": "0x18160ddd",
    "totalBorrows()": "0x47bd3718",
    "getCash()": "0x3b1d21a2",
    "exchangeRateStored()": "0x182df0f5",
    "symbol()": "0x95d89b41",
    "oracle()": "0x7dc0d1d0",
    "closeFactorMantissa()": "0x6c540baf",
    "liquidationIncentiveMantissa()": "0x4ada90af",
    "getAccountSnapshot(address)": "0xc37f68e2",
    "getAccountLiquidity(address)": "0x5ec88c79",
    "getAssetsIn(address)": "0xabfceffc",
    "balanceOf(address)": "0x70a08231",
    "borrowBalanceStored(address)": "0x95dd9193",
}


def pad(addr):
    return addr.lower().replace("0x", "").rjust(64, "0")


def pad32(n):
    return format(n, "x").rjust(64, "0")


def post(url, payload, timeout=22):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def batch_calls(items, block_hex, max_batch=100, tries=5):
    """items: list of (to, data). Returns list of raw results (hex or None) + errors."""
    out = [None] * len(items)
    errs = [None] * len(items)
    pending = list(range(len(items)))
    size = max_batch
    attempt = 0
    while pending and attempt < tries:
        attempt += 1
        groups = [pending[i:i + size] for i in range(0, len(pending), size)]
        still = []
        for g in groups:
            payload = [{"jsonrpc": "2.0", "id": i, "method": "eth_call",
                        "params": [{"to": items[i][0], "data": items[i][1]}, block_hex]} for i in g]
            done = False
            for url in RPC_URLS:
                try:
                    resp = post(url, payload)
                    if not isinstance(resp, list):
                        continue
                    byid = {r.get("id"): r for r in resp}
                    for i in g:
                        r = byid.get(i, {})
                        if "result" in r:
                            out[i] = r["result"]
                        else:
                            errs[i] = str(r.get("error", "no result"))[:160]
                    done = True
                    break
                except Exception as e:
                    errs[g[0]] = f"transport {str(e)[:100]}"
            if not done:
                still.extend(g)
        pending = still
        if pending:
            size = max(3, size // 3)
            time.sleep(0.8 * attempt)
    return out, errs


def dec_uint(raw):
    return int(raw, 16) if raw and raw != "0x" else None


def dec_addrs(raw):
    if not raw or raw == "0x":
        return []
    b = raw[2:]
    n = int(b[64:128], 16)
    addrs = []
    for i in range(n):
        w = b[128 + i * 64: 192 + i * 64]
        addrs.append("0x" + w[-40:])
    return addrs


def main():
    only_borrowers = "--only-borrowers" in sys.argv
    limit = None
    if "--limit" in sys.argv:
        limit = int(sys.argv[sys.argv.index("--limit") + 1])

    cand = json.load(open(os.path.join(HERE, "era-positions-candidates.json")))
    addresses = cand["candidates"]
    if only_borrowers:
        txb = json.load(open(os.path.join(HERE, "era-positions-txaccounts.json")))
        addresses = sorted(set(txb["borrowers"]) | set(txb["liquidators"]) | set(txb["borrower_params"]))
    if limit:
        addresses = addresses[:limit]
    print(f"reading {len(addresses)} accounts", flush=True)

    # fixed block
    block = None
    for url in RPC_URLS:
        try:
            j = post(url, {"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}, timeout=40)
            block = int(j["result"], 16)
            break
        except Exception:
            continue
    if block is None:
        sys.exit("no block")
    bh = hex(block)
    print(f"block {block} ({bh})", flush=True)

    # market config
    cfg_items = [(C, SEL["oracle()"]), (C, SEL["closeFactorMantissa()"]), (C, SEL["liquidationIncentiveMantissa()"])]
    cfg_keys = ["oracle", "closeFactor", "liqIncentive"]
    for m, a in MARKETS.items():
        cfg_items += [
            (C, SEL["markets(address)"] + pad(a)),
            (C, SEL["collateralFactorMantissa(address)"] + pad(a)),
            (a, SEL["decimals()"]), (a, SEL["totalSupply()"]), (a, SEL["totalBorrows()"]),
            (a, SEL["getCash()"]), (a, SEL["exchangeRateStored()"]), (a, SEL["symbol()"]),
        ]
        cfg_keys += [f"{m}|markets", f"{m}|cf", f"{m}|decimals", f"{m}|totalSupply",
                     f"{m}|totalBorrows", f"{m}|cash", f"{m}|xrate", f"{m}|symbol"]
    raws, errs = batch_calls(cfg_items, bh, max_batch=100)
    cfg = {}
    for k, raw, e in zip(cfg_keys, raws, errs):
        cfg[k] = {"raw": raw, "err": e}
    oracle = "0x" + cfg["oracle"]["raw"][-40:] if cfg["oracle"]["raw"] else None
    print("oracle:", oracle, flush=True)
    if oracle:
        pr_items = [(oracle, SEL["getUnderlyingPrice(address)"] + pad(a)) for a in MARKETS.values()]
        pr_raws, pr_errs = batch_calls(pr_items, bh, max_batch=6)
        for m, raw, e in zip(MARKETS, pr_raws, pr_errs):
            cfg[f"{m}|price"] = {"raw": raw, "err": e}

    # per-account reads
    prog_path = os.path.join(HERE, "era-positions-read-progress.json")
    prog = json.load(open(prog_path)) if os.path.exists(prog_path) else {}
    prog.setdefault("block", block)
    prog.setdefault("accounts", {})
    todo = [a for a in addresses if a not in prog["accounts"]]
    print(f"todo {len(todo)} (done {len(prog['accounts'])})", flush=True)
    t0 = time.time()
    CH = 40
    for i in range(0, len(todo), CH):
        chunk = todo[i:i + CH]
        items = []
        for a in chunk:
            for m, addr in MARKETS.items():
                items.append((addr, SEL["getAccountSnapshot(address)"] + pad(a)))
            items.append((C, SEL["getAccountLiquidity(address)"] + pad(a)))
            items.append((C, SEL["getAssetsIn(address)"] + pad(a)))
        raws, errs = batch_calls(items, bh, max_batch=100)
        k = 0
        for a in chunk:
            snaps = {}
            for m in MARKETS:
                raw, e = raws[k], errs[k]; k += 1
                if raw and raw != "0x":
                    b = raw[2:]
                    try:
                        snaps[m] = [int(b[0:64], 16), int(b[64:128], 16), int(b[128:192], 16), int(b[192:256], 16)]
                    except Exception:
                        snaps[m] = {"err": f"decode {str(raw)[:40]}"}
                else:
                    snaps[m] = {"err": e or "empty"}
            raw, e = raws[k], errs[k]; k += 1
            liq = None
            if raw and raw != "0x":
                b = raw[2:]
                liq = {"err": int(b[0:64], 16), "liquidity": int(b[64:128], 16), "shortfall": int(b[128:192], 16)}
            else:
                liq = {"err_str": e or "empty"}
            raw, e = raws[k], errs[k]; k += 1
            assets = dec_addrs(raw) if raw else []
            prog["accounts"][a] = {"snapshots": snaps, "liquidity": liq, "assetsIn": assets}
        json.dump(prog, open(prog_path, "w"))
        el = time.time() - t0
        rate = (i + len(chunk)) / el if el else 0
        print(f"progress {len(prog['accounts'])}/{len(addresses)} ({rate:.1f} acct/s)", flush=True)

    # assemble raw json
    out = {"block": block, "block_hex": bh, "comptroller": C, "oracle": oracle,
           "market_config_raw": cfg, "n_accounts": len(prog["accounts"]),
           "accounts": prog["accounts"], "rpc": "public zksync era (keyless)", "ts": int(time.time())}
    json.dump(out, open(os.path.join(HERE, "era-positions-raw.json"), "w"))
    print("wrote era-positions-raw.json", flush=True)


if __name__ == "__main__":
    main()
