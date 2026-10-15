#!/usr/bin/env python3
"""Build final deliverable data files: state.json, borrowers.csv."""
import json, csv, sys

BASE = "."
state = json.load(open(f"{BASE}/state_v2.json"))
bor = json.load(open(f"{BASE}/borrowers.json"))
holders = {}
for m in ["hKAVA", "hATOM", "hUSDT"]:
    try:
        holders[m] = json.load(open(f"{BASE}/holders_{m}.json"))
    except Exception:
        pass

PRICES = bor["prices"]
CF = bor["cf"]
DEC = {"hKAVA": 18, "hATOM": 6, "hUSDT": 6}
USDC = {  # per-market USD values at pinned block
}
mk = state["markets"]
COMP = state["comptroller"]

def usd(units, m): return round(units * PRICES[m], 2)

market_usd = {}
for m, M in mk.items():
    cash = M["native_balance_wei"] if m == "hKAVA" else (M["balanceOf_uATOM"] if m == "hATOM" else M["balanceOf_uUSDT"])
    er = M["exchangeRateStored()"]
    ts = M["totalSupply()"]
    tb = M["totalBorrows()"]
    tr = M["totalReserves()"]
    total_value_units = ts * er / 1e18 / (10 ** DEC[m])
    market_usd[m] = {
        "cash_units": cash / 10 ** DEC[m],
        "cash_usd": usd(cash / 10 ** DEC[m], m),
        "totalBorrows_units": tb / 10 ** DEC[m],
        "totalBorrows_usd": usd(tb / 10 ** DEC[m], m),
        "totalReserves_units": tr / 10 ** DEC[m],
        "totalReserves_usd": usd(tr / 10 ** DEC[m], m),
        "token_claims_units": total_value_units,
        "token_claims_usd": usd(total_value_units, m),
        "exchangeRateStored": er,
        "totalSupply_ctokens": ts / 1e8,
        "collateralFactor": CF[m],
        "mintGuardianPaused": int(COMP.get(f"mintGuardianPaused(address)[{m}]", 0)),
        "borrowGuardianPaused": int(COMP.get(f"borrowGuardianPaused(address)[{m}]", 0)),
        "borrowCap": int(COMP.get(f"borrowCaps(address)[{m}]", 0)),
    }

out = {
    "chain": "kava", "chain_id": 2222,
    "block": state["block"], "block_timestamp": state["block_timestamp"],
    "prices_usd": {"KAVA": PRICES["hKAVA"], "ATOM": PRICES["hATOM"], "USDT": PRICES["hUSDT"],
                   "source": "DefiLlama coins.llama.fi/prices/current (coingecko:kava, kava:0x1593..(ATOM), kava:0x919C..(USDT))", "ts": 1792060918},
    "contracts": {
        "comptroller_unitroller": "0x3A4Ec955a18eF6eB33025599505E7d404a4d59eC",
        "comptroller_impl": "0xb618fb7c9921fb35a75fddf5ee1bbdf19080020c",
        "oracle_pyth_asset_config": "0xE8Ae943de7f036Cfa505127641Eee7c5b6606878",
        "pyth_proxy": "0xa2aa501b19aff244d90cc15a4cf739d2725b5729",
        "pyth_impl": "0x36825bf3fbdf5a29e2d5148bfe7dcf7b5639e320",
        "admin_safe": "0xcecC934494adED6c0c82C52656a845862176ceeE",
        "admin_safe_threshold": "2-of-8 (Gnosis Safe v1.3.0)",
        "liquidator_allowlist": "0x49AE3cc17eD67c9Bc9cd11E4d799c329bC90203F",
        "liquidator_allowlist_owner": "0xcecC934494adED6c0c82C52656a845862176ceeE",
        "whitelisted_liquidators": ["0x9b9FB7e3291C43F3146A9F590a421aC3C0377709", "0x608cB0F61c1e574025D3e8168078d13e2320781D"],
        "liquidator_bot_owner_and_profitWallet": "0xbA6f82F77fCf03d33150fceC7384644AC12F4DD5",
        "hKAVA_CNativeDelegator": "0xb51eFaF2f7aFb8a2F5Be0b730281E414FB487636",
        "hKAVA_impl_CNativeDelegate": "0x39c18a98d1d5e432a9f7469009f65f1da0c706b4",
        "hATOM_CErc20Delegator": "0x1Bf92bE674483D54A8E3A589e456c39eAC4339bd",
        "hUSDT_CErc20Delegator": "0xcE86EBc669BBf07A64A0a55BB105Cc2B5B5d1961",
        "CErc20Delegate_impl": "0x5c59874128dc86e386973dd0b877f796d152b9ea",
        "uATOM": "0x15932E26f5BD4923d46a2b205191C4b5d5f43FE3",
        "uUSDT": "0x919C1c267BC06a7039e03fcc2eF738525769109c",
        "HOV": "0xCe82db637A2D750380ef27063518eAa263fbe10E",
        "esHOV": "0xD3452d932A81C1221C1Ba331852554cBBEF8c652",
        "xHOV": "0xD6aDF6284b657c3c5b0d0Fa69BDB03afb8a98c76",
    },
    "comptroller": {
        "closeFactorMantissa": int(COMP["closeFactorMantissa()"]),
        "liquidationIncentiveMantissa": int(COMP["liquidationIncentiveMantissa()"]),
        "pauseGuardian": "0x0",
        "transferGuardianPaused": int(COMP["transferGuardianPaused()"]),
        "seizeGuardianPaused": int(COMP["seizeGuardianPaused()"]),
        "maxAssets": int(COMP["maxAssets()"]),
        "allMarkets": ["0xb51eFaF2f7aFb8a2F5Be0b730281E414FB487636", "0x1Bf92bE674483D54A8E3A589e456c39eAC4339bd", "0xcE86EBc669BBf07A64A0a55BB105Cc2B5B5d1961"],
        "rewardTokens": ["0xD3452d932A81C1221C1Ba331852554cBBEF8c652(esHOV)", "0x0(native index)", "0xCe82db637A2D750380ef27063518eAa263fbe10E(HOV)"],
        "rewardNativeToken": 1,
        "protocolTokenAddress": "0xD3452d932A81C1221C1Ba331852554cBBEF8c652",
        "visibility_of_comptroller_balances": {
            "native_KAVA_wei": 673992665928889519148,
            "HOV_wei": 15967132657649620446,
            "esHOV_wei": 9714740901053116555,
            "note": "unclaimed reward pot; claimReward pays the holder, not the caller"
        },
    },
    "markets": market_usd,
    "total_cash_usd": round(sum(v["cash_usd"] for v in market_usd.values()), 2),
    "gates": {
        "mint_all_markets_paused_(MP)": True,
        "borrow_all_markets_paused_(BP)": True,
        "oracle_live": False,
        "oracle_revert_reason": "StalePrice (Pyth getPriceNoOlderThan; custom error 0x19abf40e for erc20 path, string 'StalePrice' for native path)",
        "liquidations_open_to_outside": False,
        "liquidator_allowlist_size": 2,
        "redeem_open_to_non_members": True,
        "redeem_oracle_gated_for_members": True,
        "pyth_update_fee_wei": 0,
        "pyth_version": "1.3.0",
    },
    "borrower_summary": {
        "unique_borrowers_all_time": len(bor["borrowers"]),
        "borrowers_with_debt_now": len([b for b in bor["borrowers"] if b["debt_usd"] > 0.01]),
        "underwater_borrowers": [b["address"] for b in bor["borrowers"] if b["shortfall_usd"] > 1],
        "total_shortfall_usd": round(sum(b["shortfall_usd"] for b in bor["borrowers"]), 2),
        "total_collateral_of_underwater_usd": round(sum(b["collateral_usd"] for b in bor["borrowers"] if b["shortfall_usd"] > 1), 2),
        "max_liquidation_bonus_usd_gross": round(sum(min(0.5*b["debt_usd"], b["collateral_usd"]/1.05)*0.05 for b in bor["borrowers"] if b["shortfall_usd"] > 1), 2),
    },
}
json.dump(out, open("state.json", "w"), indent=1)
print("wrote state.json")
print(json.dumps(out["borrower_summary"], indent=1))
print("total cash usd:", out["total_cash_usd"])

# borrowers.csv
with open("borrowers.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["address", "hkava_ctokens", "hkava_collateral_kava", "hkava_debt_kava",
                "hatom_ctokens", "hatom_collateral_atom", "hatom_debt_atom",
                "husdt_ctokens", "husdt_collateral_usdt", "husdt_debt_usdt",
                "collateral_usd", "debt_usd", "liquidity_usd_cf", "shortfall_usd", "net_usd",
                "max_repay_usd", "gross_liquidation_bonus_usd"])
    for b in sorted(bor["borrowers"], key=lambda x: -x["debt_usd"]):
        pos = b["positions"]
        def g(m, k):
            p = pos.get(m)
            return round(p[k], 6) if isinstance(p, dict) else ""
        max_repay = 0.0
        bonus = 0.0
        if b["shortfall_usd"] > 0:
            avail = b["collateral_usd"] / 1.05
            for m in ["hKAVA", "hATOM", "hUSDT"]:
                d = pos.get(m, {})
                if isinstance(d, dict) and d["debt_units"] > 0:
                    repay = min(0.5 * d["debt_units"] * PRICES[m], avail)
                    max_repay += repay
                    bonus += 0.05 * repay
        w.writerow([b["address"],
                    round(g("hKAVA", "cTokens")/1e8, 4) if g("hKAVA", "cTokens") != "" else "",
                    g("hKAVA", "collateral_units"), g("hKAVA", "debt_units"),
                    round(g("hATOM", "cTokens")/1e8, 4) if g("hATOM", "cTokens") != "" else "",
                    g("hATOM", "collateral_units"), g("hATOM", "debt_units"),
                    round(g("hUSDT", "cTokens")/1e8, 4) if g("hUSDT", "cTokens") != "" else "",
                    g("hUSDT", "collateral_units"), g("hUSDT", "debt_units"),
                    b["collateral_usd"], b["debt_usd"], b["liquidity_usd"], b["shortfall_usd"], b["net_usd"],
                    round(max_repay, 2), round(bonus, 2)])
print("wrote borrowers.csv rows:", len(bor["borrowers"]))
