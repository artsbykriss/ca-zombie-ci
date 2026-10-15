#!/usr/bin/env python3
"""Serum Swap (SPL token-swap program SwaPpA9...) — independent CI verification.

Read-only. Public Solana RPC + DefiLlama prices only. No secrets.
Verifies:
  1. program upgrade authority / last deploy slot
  2. account census: 324-byte pool accounts, is_initialized, curve_type histogram (offset 291)
  3. fee config scan (trade/owner/host fractions)
  4. per-pool reserves, decimals, USD value (DL prices)
  5. ConstantPrice pools: fixed-rate mispricing extraction (both directions, fees applied)
  6. ConstantProduct pools: optimal-arbitrage upper bound (fee-aware numeric maximisation)
Writes ci-out/serum-verify.json and prints a summary.
"""
import json, math, os, struct, sys, time, urllib.request, urllib.error

PROGRAM = "SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8"
PROGRAMDATA = "FV9WWFWYzWHDpAc8oxiFKV1LmFUyWw7HGdo4GK19MiZW"
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ci-out")
os.makedirs(OUT_DIR, exist_ok=True)

RPCS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
]

ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58(x: bytes) -> str:
    n = int.from_bytes(x, "big")
    s = ""
    while n > 0:
        n, r = divmod(n, 58)
        s = ALPH[r] + s
    return "1" * (len(x) - len(x.lstrip(b"\x00"))) + s


def rpc(method, params, tries=6):
    last = None
    for attempt in range(tries):
        url = RPCS[attempt % len(RPCS)]
        body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "User-Agent": "zombie-ci/1.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                d = json.load(r)
            if "error" in d:
                last = d["error"]
                # retry on rate-limit style errors
                if isinstance(last, dict) and last.get("code") == -32005:
                    time.sleep(6)
                    continue
                raise RuntimeError(f"RPC error {last}")
            return d["result"]
        except Exception as e:  # noqa
            last = e
            time.sleep(4 + 3 * attempt)
    raise RuntimeError(f"RPC failed after retries: {last}")


def gpa(filters, data_slice):
    params = [PROGRAM, {"encoding": "base64", "filters": filters, "dataSlice": data_slice}]
    return rpc("getProgramAccounts", params)


def b64d(s):
    import base64
    return base64.b64decode(s)


def chunked(lst, n):
    for i in range(0, len(lst), n):
        yield lst[i:i + n]


def fetch_prices(mints):
    prices = {}
    mints = [m for m in mints if m]
    for ch in chunked(mints, 25):
        url = "https://coins.llama.fi/prices/current/" + ",".join("solana:" + m for m in ch)
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "zombie-ci/1.0"}), timeout=60) as r:
                d = json.load(r)
            for k, v in d.get("coins", {}).items():
                prices[k.split(":", 1)[1]] = v
        except Exception as e:
            print(f"price fetch failed for chunk: {e}")
        time.sleep(1)
    return prices


def main():
    out = {"program": PROGRAM, "rpc_endpoints": RPCS, "slot": None}

    # 1. program data account
    pd = rpc("getAccountInfo", [PROGRAMDATA, {"encoding": "base64", "dataSlice": {"offset": 0, "length": 45}}])
    b = b64d(pd["value"]["data"][0])
    # ProgramData header: tag u32 | slot u64 | Option<Pubkey> (option tag byte at 12, key at 13..45)
    out["programdata"] = {
        "last_deploy_slot": struct.unpack("<Q", b[4:12])[0],
        "option_tag": b[12],
        "upgrade_authority": b58(b[13:45]) if b[12] == 1 else None,
        "lamports": pd["value"]["lamports"],
    }
    print("programdata:", out["programdata"])

    # 2. census
    accs = gpa([{"dataSize": 324}], {"offset": 0, "length": 4})
    out["slot"] = None
    init_hist = {}
    pubkeys = []
    for a in accs:
        bb = b64d(a["account"]["data"][0])
        init_hist[bb[1]] = init_hist.get(bb[1], 0) + 1
        pubkeys.append(a["pubkey"])
    out["accounts_324"] = len(accs)
    out["init_hist"] = init_hist
    print("324-byte accounts:", len(accs), "init histogram:", init_hist)

    cur = gpa([{"dataSize": 324}], {"offset": 291, "length": 33})
    curve_hist = {}
    curve_params = {}
    for a in cur:
        bb = b64d(a["account"]["data"][0])
        ct = bb[0]
        curve_hist[ct] = curve_hist.get(ct, 0) + 1
        curve_params[a["pubkey"]] = (ct, bb[1:33].hex())
    out["curve_hist"] = curve_hist
    print("curve_type histogram:", curve_hist)

    # 3. full data for initialized pools
    initialized = [a["pubkey"] for a in accs if b64d(a["account"]["data"][0])[1] == 1]
    print("initialized pools:", len(initialized))
    pools = []
    for ch in chunked(initialized, 90):
        r = rpc("getMultipleAccounts", [ch, {"encoding": "base64"}])
        for pk, v in zip(ch, r["value"]):
            bb = b64d(v["data"][0])
            ct = bb[291]
            pools.append({
                "pool": pk,
                "curve_type": ct,
                "vaultA": b58(bb[35:67]),
                "vaultB": b58(bb[67:99]),
                "pool_mint": b58(bb[99:131]),
                "mintA": b58(bb[131:163]),
                "mintB": b58(bb[163:195]),
                "fee_account": b58(bb[195:227]),
                "fees": list(struct.unpack("<8Q", bb[227:291])),
                "curve_param": struct.unpack("<Q", bb[292:300])[0],
            })
        time.sleep(1)

    # fee scan
    fee_hist = {}
    for p in pools:
        k = tuple(p["fees"])
        fee_hist[str(k)] = fee_hist.get(str(k), 0) + 1
    out["fee_configs"] = fee_hist
    print("fee configs:", fee_hist)

    # 4. vault balances
    vaults = []
    for p in pools:
        vaults += [p["vaultA"], p["vaultB"]]
    bal = {}
    for ch in chunked(vaults, 100):
        r = rpc("getMultipleAccounts", [ch, {"encoding": "base64"}])
        for pk, v in zip(ch, r["value"]):
            if v is None:
                bal[pk] = None
            else:
                bb = b64d(v["data"][0])
                bal[pk] = struct.unpack("<Q", bb[64:72])[0]
        time.sleep(1)

    # 5. mint decimals
    mints = sorted({p["mintA"] for p in pools} | {p["mintB"] for p in pools})
    dec = {}
    for ch in chunked(mints, 90):
        r = rpc("getMultipleAccounts", [ch, {"encoding": "base64"}])
        for pk, v in zip(ch, r["value"]):
            dec[pk] = None if v is None else b64d(v["data"][0])[44]
        time.sleep(1)
    out["mints"] = {m: dec.get(m) for m in mints}

    # 6. prices
    prices = fetch_prices(mints)
    out["prices"] = {m: {"symbol": prices[m].get("symbol"), "price": prices[m].get("price"), "confidence": prices[m].get("confidence")} for m in prices}
    print("priced mints:", len(prices), "of", len(mints))

    # 7. per-pool valuation + extraction math
    def usd(mint, units):
        pr = prices.get(mint, {}).get("price")
        d = dec.get(mint)
        if pr is None or d is None or units is None:
            return None
        return units / (10 ** d) * pr

    cp_pools = [p for p in pools if p["curve_type"] == 0]
    cprice_pools = [p for p in pools if p["curve_type"] == 1]

    total_usd = 0.0
    unpriced_value_pools = []
    for p in pools:
        va = usd(p["mintA"], bal.get(p["vaultA"]))
        vb = usd(p["mintB"], bal.get(p["vaultB"]))
        p["usdA"] = va
        p["usdB"] = vb
        if va is not None:
            total_usd += va
        if vb is not None:
            total_usd += vb
        if va is None or vb is None:
            unpriced_value_pools.append(p["pool"])
    out["total_vault_usd_priced"] = round(total_usd, 2)
    out["pools_with_unpriced_side"] = len(unpriced_value_pools)
    print(f"total priced vault USD: {total_usd:.2f}; pools with unpriced side: {len(unpriced_value_pools)}")

    # ConstantPrice extraction
    cprice_results = []
    cprice_total = 0.0
    for p in cprice_pools:
        resA = bal.get(p["vaultA"]) or 0
        resB = bal.get(p["vaultB"]) or 0
        dA, dB = dec.get(p["mintA"]), dec.get(p["mintB"])
        pA = prices.get(p["mintA"], {}).get("price")
        pB = prices.get(p["mintB"], {}).get("price")
        price = p["curve_param"]  # token_b_price
        tn, td = p["fees"][0], p["fees"][1]
        f = tn / td if td else 0.0
        r = {"pool": p["pool"], "price": price, "resA": resA, "resB": resB, "decA": dA, "decB": dB,
             "pA": pA, "pB": pB, "trade_fee": f}
        # BtoA: pay B, receive A at rate P base-units A per base-unit B (before fee)
        # with fee f on input: to receive X base-units of A, pay X/P base-units of B, fee adds f/ (1-f)
        if pA is not None and pB is not None and price and dA is not None and dB is not None:
            # value per whole A received when paying with whole B: (P * 10^(dB-dA)) * pA - pB, input fee applied
            val_received_per_B = price * 10 ** (dB - dA) * pA
            cost_per_B = pB / (1 - f) if f < 1 else float("inf")
            profit_dir_BtoA = max(0.0, (val_received_per_B - cost_per_B)) * (resA / 10 ** dA) if resA else 0.0
            # AtoB: receive B, pay A: per whole A spent receive 10^dA/(P*10^dB) whole B
            val_received_per_A = (10 ** dA / (price * 10 ** dB)) * pB
            cost_per_A = pA / (1 - f) if f < 1 else float("inf")
            profit_dir_AtoB = max(0.0, (val_received_per_A - cost_per_A)) * (resB / 10 ** dB) if resB else 0.0
            r["profit_BtoA_usd"] = round(profit_dir_BtoA, 6)
            r["profit_AtoB_usd"] = round(profit_dir_AtoB, 6)
            cprice_total += max(profit_dir_BtoA, profit_dir_AtoB)
        else:
            r["profit_BtoA_usd"] = None
            r["profit_AtoB_usd"] = None
        cprice_results.append(r)
    out["constant_price_pools"] = cprice_results
    out["constant_price_extractable_usd"] = round(cprice_total, 4)
    print(f"ConstantPrice pools: {len(cprice_pools)}, extractable (priced only): ${cprice_total:.4f}")

    # ConstantProduct optimal arb (fee-aware numeric)
    def cp_out(d, x, y, f):
        # d: input base units; fee = ceil(d*f); d' = d - fee; out = y*d'/(x+d')
        fee = math.ceil(d * f)
        dp = d - fee
        if dp <= 0:
            return 0.0
        return y * dp / (x + dp)

    arb_results = []
    arb_total = 0.0
    for p in cp_pools:
        x = bal.get(p["vaultA"]) or 0
        y = bal.get(p["vaultB"]) or 0
        pA = prices.get(p["mintA"], {}).get("price")
        pB = prices.get(p["mintB"], {}).get("price")
        dA, dB = dec.get(p["mintA"]), dec.get(p["mintB"])
        tn, td = p["fees"][0], p["fees"][1]
        f = tn / td if td else 0.0
        if not (x and y and pA and pB and dA is not None and dB is not None):
            continue
        uA = pA / 10 ** dA  # USD per base unit
        uB = pB / 10 ** dB
        best = 0.0
        for direction in ("AtoB", "BtoA"):
            if direction == "AtoB":
                src, dst, u_src, u_dst = x, y, uA, uB
            else:
                src, dst, u_src, u_dst = y, x, uB, uA
            if src == 0 or dst == 0:
                continue
            lo, hi = 1.0, src * 10.0
            # golden-section search on profit
            gr = (math.sqrt(5) - 1) / 2
            a, b = lo, hi
            c, d = b - gr * (b - a), a + gr * (b - a)
            def prof(v):
                out_amt = cp_out(v, src, dst, f)
                return u_dst * out_amt - u_src * v
            for _ in range(200):
                if prof(c) > prof(d):
                    b, d = d, c
                    c = b - gr * (b - a)
                else:
                    a, c = c, d
                    d = a + gr * (b - a)
            cand = max(prof(a), prof(b), prof(c), prof(d), 0.0)
            best = max(best, cand)
        if best > 0:
            arb_results.append({"pool": p["pool"], "profit_usd": round(best, 6),
                                "resA_usd": round(x * uA, 2), "resB_usd": round(y * uB, 2)})
            arb_total += best
    arb_results.sort(key=lambda r: -r["profit_usd"])
    out["cp_arb_pools"] = arb_results[:50]
    out["cp_arb_extractable_usd"] = round(arb_total, 4)
    print(f"CP pools arb extractable (priced only): ${arb_total:.4f} across {len(arb_results)} pools")
    for r in arb_results[:10]:
        print("   ", r["pool"], f"${r['profit_usd']:.4f}", f"(res {r['resA_usd']}/{r['resB_usd']})")

    out["e_u_upper_bound_usd"] = round(arb_total + cprice_total, 4)
    with open(os.path.join(OUT_DIR, "serum-verify.json"), "w") as fh:
        json.dump(out, fh, indent=1)
    print("wrote", os.path.join(OUT_DIR, "serum-verify.json"))


if __name__ == "__main__":
    main()
