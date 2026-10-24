#!/usr/bin/env python3
"""Read-only Rujira FIN / THORChain app-layer snapshot.
Writes analysis/state-live.json. No secrets, no transactions.
"""
import base64, json, time, urllib.request
from concurrent.futures import ThreadPoolExecutor
from decimal import Decimal

BASE = "https://gateway.liquify.com/chain/thorchain_api"
HERE = "analysis/"

def get(path, tries=3):
    last = None
    for _ in range(tries):
        try:
            return json.load(urllib.request.urlopen(BASE + path, timeout=35))
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(1.5)
    raise last

def smart(addr, msg, tries=3):
    b = base64.b64encode(json.dumps(msg).encode()).decode()
    return get(f"/cosmwasm/wasm/v1/contract/{addr}/smart/{b}", tries)

def pool_prices():
    pools = get("/thorchain/pools")
    p = {x["asset"].upper(): int(x["asset_tor_price"]) / 1e8 for x in pools}
    # native/denom aliases; updated at runtime from DefiLlama
    try:
        d = json.load(urllib.request.urlopen(
            "https://coins.llama.fi/prices/current/coingecko:thorchain,coingecko:rujira", timeout=20))
        c = d["coins"]
        p["THOR.RUNE"] = c["coingecko:thorchain"]["price"]
        p["RUNE"] = p["THOR.RUNE"]
        p["THOR.RUJI"] = c["coingecko:rujira"]["price"]
    except Exception:  # noqa: BLE001
        p.setdefault("RUNE", 0.0); p.setdefault("THOR.RUNE", 0.0)
    p.setdefault("THOR.RUJI", p.get("THOR.RUJI", 0.0))
    return p

ALIAS = {"RUNE": "THOR.RUNE", "X/RUJI": "THOR.RUJI", "TCY": "THOR.TCY"}

def poolkey(den, price):
    u = den.upper()
    if u in ALIAS: return ALIAS[u]
    if u in price: return u
    if "-" in u:
        a, b = u.split("-", 1)
        k = a + "." + b
        if k in price: return k
    return None

def bank_value(addr, price):
    d = get(f"/cosmos/bank/v1beta1/balances/{addr}")
    val = 0.0; unp = {}
    for b in d.get("balances", []):
        amt = int(b["amount"]) / 1e8
        k = poolkey(b["denom"], price)
        if k: val += amt * price[k]
        else: unp[b["denom"]] = unp.get(b["denom"], 0.0) + amt
    return val, unp

def main():
    mimir = get("/thorchain/mimir")
    version = get("/thorchain/version")
    lastblock = get("/thorchain/lastblock")
    upgrade = get("/thorchain/upgrade_proposals") or []
    contracts = get("/thorchain/contracts")
    block = json.load(urllib.request.urlopen(BASE + "/thorchain/block", timeout=30))
    height = block["header"]["height"]
    btime = block["header"]["time"]

    thor = next((x for x in lastblock if x.get("chain") == "THOR"), {})
    infos = contracts.get("infos", [])
    fin = [x["address"] for x in infos if x.get("contract") == "rujira-fin"]
    acct = [x["address"] for x in infos if x.get("contract") == "rujira-account"]
    price = pool_prices()

    # FIN code ids
    from collections import Counter
    codes = Counter()
    for a in fin:
        ci = get(f"/cosmwasm/wasm/v1/contract/{a}")["contract_info"]
        codes[ci["code_id"]] += 1

    # FIN bank values
    fin_total = 0.0; fin_rows = []; unp_all = {}
    with ThreadPoolExecutor(max_workers=6) as ex:
        vals = list(ex.map(lambda a: bank_value(a, price), fin))
    for a, (v, unp) in zip(fin, vals):
        fin_total += v; fin_rows.append({"address": a, "usd": round(v, 2)})
        for k, n in unp.items(): unp_all[k] = unp_all.get(k, 0.0) + n

    # CCL ranges
    ccl_total = 0.0; ccl_count = 0; ccl_rows = []
    for a in fin:
        try:
            cfg = smart(a, {"config": {}})["data"]; den = cfg["denoms"]
        except Exception:  # noqa: BLE001
            continue
        ranges = []; cursor = None
        for _ in range(20):
            msg = {"ranges": {"limit": 100}}
            if cursor: msg["ranges"]["cursor"] = cursor
            try: d = smart(a, msg)["data"]
            except Exception: break
            ranges += d.get("ranges", []); cursor = d.get("cursor")
            if not cursor: break
        vb = vq = 0.0
        for r in ranges:
            b = float(Decimal(r["base"]) / Decimal(1e8))
            q = float(Decimal(r["quote"]) / Decimal(1e8))
            kb, kq = poolkey(den[0], price), poolkey(den[1], price)
            if kb: vb += b * price[kb]
            if kq: vq += q * price[kq]
        v = vb + vq
        ccl_total += v; ccl_count += len(ranges)
        ccl_rows.append({"address": a, "ranges": len(ranges), "usd": round(v, 2)})

    # Credit accounts
    acct_total = 0.0; acct_funded = 0
    with ThreadPoolExecutor(max_workers=8) as ex:
        avals = list(ex.map(lambda a: bank_value(a, price)[0], acct))
    for v in avals:
        acct_total += v
        if v > 1: acct_funded += 1

    up = next((x for x in upgrade if str(x.get("name", "")).startswith("3.21")), {})
    state = {
        "chain": "thorchain-1",
        "height": int(height),
        "block_time_utc": btime,
        "thorchain_last_observed": thor.get("last_observed_in"),
        "last_signed_out_height": thor.get("last_signed_out"),
        "version": version,
        "upgrade_proposal": up,
        "halt": {
            "HALTWASMGLOBAL": mimir.get("HALTWASMGLOBAL"),
            "HALTWASMCONTRACT-JY3TQX": mimir.get("HALTWASMCONTRACT-JY3TQX"),
            "HALTTHORCHAIN": mimir.get("HALTTHORCHAIN"),
            "HALTTRADING": mimir.get("HALTTRADING"),
            "HALTSECUREDGLOBAL": mimir.get("HALTSECUREDGLOBAL"),
            "meaning": "HALTWASMGLOBAL=1 disables all CosmWasm executions; base layer remains live.",
        },
        "fin": {
            "pairs": len(fin),
            "tvl_usd": round(fin_total, 2),
            "ccl_ranges_usd": round(ccl_total, 2),
            "ccl_range_count": ccl_count,
            "code_ids": dict(codes),
            "top_pairs": sorted(fin_rows, key=lambda x: -x["usd"])[:8],
            "unpriced_legacy": {k: round(v, 4) for k, v in sorted(unp_all.items(), key=lambda x: -x[1])[:8]},
            "ccl_top_pairs": sorted(ccl_rows, key=lambda x: -x["usd"])[:8],
        },
        "credit_accounts": {
            "contracts": len(acct),
            "funded_gt_1usd": acct_funded,
            "tvl_usd": round(acct_total, 2),
        },
        "prices": {"source": "THORChain pools + DefiLlama", "RUNE": price.get("THOR.RUNE"), "RUJI": price.get("THOR.RUJI"), "BTC": price.get("BTC.BTC"), "ETH_USDC": price.get("ETH.USDC-0XA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48")},
        "incident": {
            "date": "2026-09-26",
            "contract": "FIN CCL range / position transfer function",
            "affected": "one team-owned CCL position; no user funds lost (Rujira)",
            "fix": "base layer, v3.21.0 at height 28,366,100",
            "public_technical_postmortem": False,
        },
    }
    json.dump(state, open(HERE + "state-live.json", "w"), indent=1)
    json.dump(mimir, open(HERE + "mimir.json", "w"), indent=1)
    json.dump(version, open(HERE + "version.json", "w"), indent=1)
    json.dump(lastblock, open(HERE + "lastblock.json", "w"), indent=1)
    json.dump(upgrade, open(HERE + "upgrade_proposals.json", "w"), indent=1)
    json.dump(contracts, open(HERE + "contracts.json", "w"), indent=1)

    print("height", height, btime)
    print("version", version.get("current"), "next", version.get("next"))
    print("upgrade", up.get("name"), up.get("height"), "approved", up.get("approved"))
    print("HALTWASMGLOBAL", mimir.get("HALTWASMGLOBAL"), "HALTTHORCHAIN", mimir.get("HALTTHORCHAIN"))
    print("FIN pairs", len(fin), "code_ids", dict(codes))
    print("FIN TVL $%.2f" % fin_total, "CCL $%.2f" % ccl_total, "ranges", ccl_count)
    print("Credit accounts", len(acct), "funded", acct_funded, "TVL $%.2f" % acct_total)

if __name__ == "__main__":
    main()
