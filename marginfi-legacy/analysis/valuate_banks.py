#!/usr/bin/env python3
"""Value the marginfi banks: fetch prices for all mints (DefiLlama + Jupiter fallback) and
aggregate liquidity/insurance/fee vault USD. Outputs valuation.json + banks_valued.json.
No secrets."""
import json, time, urllib.request, sys

def http_json(url, tries=4, timeout=45):
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research"})
            with urllib.request.urlopen(req, timeout=timeout) as f:
                return json.load(f)
        except Exception as e:
            err = e
            time.sleep(1.5 * (i + 1))
    print("fail", url, err, file=sys.stderr)
    return None

def llama_prices(mints):
    out = {}
    B = 50
    for i in range(0, len(mints), B):
        chunk = mints[i:i+B]
        url = "https://coins.llama.fi/prices/current/" + ",".join(f"solana:{m}" for m in chunk)
        r = http_json(url)
        if r and "coins" in r:
            for k, v in r["coins"].items():
                out[k.split(":", 1)[1]] = v["price"]
        time.sleep(0.3)
    return out

def jup_prices(mints):
    out = {}
    B = 50
    for i in range(0, len(mints), B):
        chunk = mints[i:i+B]
        url = "https://lite-api.jup.ag/price/v3?ids=" + ",".join(chunk)
        r = http_json(url)
        if isinstance(r, dict):
            for k, v in r.items():
                if isinstance(v, dict) and v.get("usdPrice") is not None:
                    out[k] = float(v["usdPrice"])
        time.sleep(0.3)
    return out

def main():
    banks = json.load(open("banks.json"))
    vaults = json.load(open("vaults.json"))
    mints = sorted({b["mint"] for b in banks.values()})
    prices = llama_prices(mints)
    missing = [m for m in mints if m not in prices]
    print(f"llama prices: {len(prices)}/{len(mints)}, missing {len(missing)}", file=sys.stderr)
    if missing:
        jp = jup_prices(missing)
        print(f"jupiter filled: {len(jp)}", file=sys.stderr)
        prices.update(jp)
    still = [m for m in mints if m not in prices]
    json.dump({"prices": prices, "missing": still}, open("prices.json", "w"), indent=1)

    tot = {"liquidity": 0.0, "insurance": 0.0, "fee": 0.0}
    per_bank = []
    for pk, b in banks.items():
        row = {"bank": pk, "mint": b["mint"], "decimals": b["mint_decimals"], "group": b["group"],
               "oracle": b["config"]["oracle_setup"], "op_state": b["config"]["operational_state"],
               "risk_tier": b["config"]["risk_tier"], "asset_tag": b["config"]["asset_tag"],
               "flags": b["flags"], "size": b["_account_bytes"],
               "asset_weight_init": b["config"]["asset_weight_init"],
               "asset_weight_maint": b["config"]["asset_weight_maint"],
               "liability_weight_init": b["config"]["liability_weight_init"],
               "liability_weight_maint": b["config"]["liability_weight_maint"],
               "oracle_max_age": b["config"]["oracle_max_age"],
               "oracle_max_confidence": b["config"]["oracle_max_confidence"],
               "total_asset_value_init_limit": b["config"]["total_asset_value_init_limit"],
               "deposit_limit": b["config"]["deposit_limit"], "borrow_limit": b["config"]["borrow_limit"],
               "lending_position_count": b["lending_position_count"],
               "borrowing_position_count": b["borrowing_position_count"],
               "last_oracle_price": b["cache"]["last_oracle_price"],
               "last_oracle_price_ts": b["cache"]["last_oracle_price_timestamp"],
               "price_multiplier": b["cache"]["price_multiplier"],
               "asset_share_value": b["asset_share_value"], "liability_share_value": b["liability_share_value"],
               "total_asset_shares": b["total_asset_shares"], "total_liability_shares": b["total_liability_shares"],
               "collected_insurance_fees": b["collected_insurance_fees_outstanding"],
               "collected_group_fees": b["collected_group_fees_outstanding"],
               "collected_program_fees": b["collected_program_fees_outstanding"],
               "cb_tier": b["cb_tier"]}
        price = prices.get(b["mint"])
        row["price_usd"] = price
        for kind, key in (("liquidity", "liquidity_vault"), ("insurance", "insurance_vault"), ("fee", "fee_vault")):
            v = vaults.get(b[key], {})
            amt = float(v.get("ui") or 0) if v.get("exists") else 0.0
            usd = amt * price if price else None
            row[key + "_amount"] = amt
            row[key + "_usd"] = usd
            if usd:
                tot[kind] += usd
        per_bank.append(row)
    per_bank.sort(key=lambda r: -(r["liquidity_vault_usd"] or 0))
    json.dump({"totals_usd": tot, "per_bank": per_bank}, open("banks_valued.json", "w"), indent=1)
    print(json.dumps(tot, indent=1), file=sys.stderr)

if __name__ == "__main__":
    main()
