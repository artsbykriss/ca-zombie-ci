#!/usr/bin/env python3
"""Read FDFPairV4 live state at a fixed Base block using Multicall3.

Outputs analysis/live_state.json with per-pair reserves, USDC balance,
pool-held shares, player-contract-held shares and per-share prices.
"""
import json, sys
from multicall import multicall, sel, dec_u, dec_u_array, enc_u, enc_a

USDC = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
BLOCK = hex(int(sys.argv[1])) if len(sys.argv) > 1 else "latest"
PAIRS = {
    "football": {"pair": "0x9da1bB4e725ACc0d96010b7cE2A7244Cda446617",
                 "player": "0x71c8b0c5148edb0399d1edf9bf0c8c81dea16918"},
    "nfl": {"pair": "0x4Fdce033b9F30019337dDC5cC028DC023580585e",
            "player": "0x2eef466e802ab2835ab81be63eebc55167d35b56"},
}

out = {"block": BLOCK, "usdc": USDC, "pairs": {}}
for name, p in PAIRS.items():
    pair, player = p["pair"], p["player"]
    ids = dec_u_array(multicall([(pair, sel("getAllPlayerIds()"))], BLOCK)[0][1])
    # reserves (one call, whole array)
    data = sel("getCurrencyReserves(uint256[])") + enc_u(32) + enc_u(len(ids)) + "".join(enc_u(x) for x in ids)
    reserves = dec_u_array(multicall([(pair, data)], BLOCK)[0][1])
    # prices for all ids
    data = sel("getPrices(uint256[])") + enc_u(32) + enc_u(len(ids)) + "".join(enc_u(x) for x in ids)
    prices = dec_u_array(multicall([(pair, data)], BLOCK)[0][1])
    # balances (pool + player contract) for every id
    calls = []
    for x in ids:
        calls.append((player, sel("balanceOf(address,uint256)") + enc_a(pair) + enc_u(x)))
    for x in ids:
        calls.append((player, sel("balanceOf(address,uint256)") + enc_a(player) + enc_u(x)))
    res = multicall(calls, BLOCK)
    pool_shares = [dec_u(r[1]) for r in res[:len(ids)]]
    own_shares = [dec_u(r[1]) for r in res[len(ids):]]
    # usdc balance, and pair-level config
    cfg = multicall([
        (USDC, sel("balanceOf(address)") + enc_a(pair)),
        (pair, sel("treasury()")),
        (pair, sel("upgradeVersion()")),
        (pair, sel("minCurrencyAmountForNewPools()")),
    ], BLOCK)
    usdc_bal = dec_u(cfg[0][1])
    out["pairs"][name] = {
        "pair": pair, "player": player,
        "n_pools": len(ids),
        "sum_currency_reserves_usdc": sum(reserves) / 1e6,
        "usdc_balance": usdc_bal / 1e6,
        "delta_usdc": (usdc_bal - sum(reserves)) / 1e6,
        "sum_pool_shares_wei": str(sum(pool_shares)),
        "sum_player_contract_shares_wei": str(sum(own_shares)),
        "treasury": "0x" + cfg[1][1][-40:],
        "upgradeVersion": dec_u(cfg[2][1]),
        "minCurrencyAmountForNewPools": dec_u(cfg[3][1]) / 1e6,
        "ids": ids,
        "reserves_usdc": [r / 1e6 for r in reserves],
        "pool_shares": [str(x) for x in pool_shares],
        "player_contract_shares": [str(x) for x in own_shares],
        "price_usdc_per_share": [p / 1e6 for p in prices],
    }
    v = out["pairs"][name]
    print(name, "pools", v["n_pools"], "sumReserves $%.2f" % v["sum_currency_reserves_usdc"],
          "USDCbal $%.2f" % v["usdc_balance"], "delta $%.2f" % v["delta_usdc"])
    top = sorted(zip(v["ids"], v["reserves_usdc"], v["price_usdc_per_share"], v["pool_shares"]), key=lambda x: -x[1])[:5]
    print("   top pools:", top)

json.dump(out, open("/home/heisenberg/CA/sport-fun/analysis/live_state.json", "w"), indent=1)
