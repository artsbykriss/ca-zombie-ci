#!/usr/bin/env python3
"""Compute Omnipair live TVL in USD (read-only).

TVL = sum over pairs of (cash_reserve0*P0 + cash_reserve1*P1)
      + sum of collateral vault balances priced.
Prices: DefiLlama keyless coins API (falls back to the pair's own EMA price).
"""
import json
import os
import time
import urllib.request

import omni as O

HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "live_state.json")))


def llama_prices(mints):
    out = {}
    keys = [f"solana:{m}" for m in mints]
    for i in range(0, len(keys), 40):
        chunk = keys[i:i + 40]
        url = "https://coins.llama.fi/prices/current/" + ",".join(chunk)
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "audit/1.0"})
            j = json.load(urllib.request.urlopen(req, timeout=45))
            for k, v in (j.get("coins") or {}).items():
                out[k.split(":", 1)[1]] = v.get("price")
        except Exception as e:  # noqa: BLE001
            print("llama err", e)
        time.sleep(0.5)
    return out


def main():
    pairs = D["pairs"]
    vm = D["vault_map"]
    vb = D["vault_balances"]
    mints = set()
    for p in pairs:
        mints.add(p["token0"]); mints.add(p["token1"])
    prices = llama_prices(sorted(mints))
    missing = [m for m in mints if not prices.get(m)]
    out = {"slot": D.get("slot"), "prices": prices, "missing_prices": missing}
    tot_cash = 0.0
    tot_onchain = 0.0
    tot_coll = 0.0
    per_pair = []
    for p in pairs:
        def px(m):
            return prices.get(m) or 0.0
        d0 = 10 ** p["token0_decimals"]
        d1 = 10 ** p["token1_decimals"]
        cash = p["cash_reserve0"] / d0 * px(p["token0"]) + p["cash_reserve1"] / d1 * px(p["token1"])
        b0 = vb.get(vm[f"{p['pubkey']}:reserve0"])
        b1 = vb.get(vm[f"{p['pubkey']}:reserve1"])
        a0 = int(b0["amount"]) if b0 else 0
        a1 = int(b1["amount"]) if b1 else 0
        onchain = a0 / d0 * px(p["token0"]) + a1 / d1 * px(p["token1"])
        c0 = vb.get(vm[f"{p['pubkey']}:collateral0"])
        c1 = vb.get(vm[f"{p['pubkey']}:collateral1"])
        e0 = int(c0["amount"]) if c0 else 0
        e1 = int(c1["amount"]) if c1 else 0
        coll = e0 / d0 * px(p["token0"]) + e1 / d1 * px(p["token1"])
        tot_cash += cash; tot_onchain += onchain; tot_coll += coll
        if cash + coll > 1.0:
            per_pair.append({"pair": p["pubkey"], "cash_usd": round(cash, 2),
                             "onchain_usd": round(onchain, 2), "collateral_usd": round(coll, 2)})
    per_pair.sort(key=lambda x: -(x["cash_usd"] + x["collateral_usd"]))
    out.update({
        "tvl_adapter_cash_plus_collateral_usd": round(tot_cash + tot_coll, 2),
        "tvl_onchain_reserve_plus_collateral_usd": round(tot_onchain + tot_coll, 2),
        "cash_reserve_usd": round(tot_cash, 2),
        "reserve_vault_onchain_usd": round(tot_onchain, 2),
        "collateral_vault_usd": round(tot_coll, 2),
        "top_pairs": per_pair[:12],
        "n_pairs_with_value": len(per_pair),
    })
    json.dump(out, open(os.path.join(HERE, "tvl.json"), "w"), indent=1)
    print(json.dumps({k: v for k, v in out.items() if k != "prices"}, indent=1))


if __name__ == "__main__":
    main()
