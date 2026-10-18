#!/usr/bin/env python3
"""Build summary.json from recorded raw data (no network)."""
import json, os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda n: json.load(open(os.path.join(BASE, "raw", n)))
arb = R("arb_math.json")
codes = R("code_sizes.json")
snap = R("final_snapshot.json")


def c(name):
    x = codes.get(name, {})
    abi_n = x.get("abi_n") or 0
    code_b = x.get("code_bytes") or 0
    return {"address": x.get("address"), "code_bytes": code_b,
            "abi_entries": abi_n, "origin": x.get("origin"),
            "verification": "abi" if abi_n > 0 else ("bytecode-only" if code_b > 0 else "none")}


addresses = {
    "usdd": {**c("USDD"), "role": "USDD 2.0 TRC20 stablecoin (18 dec); mint/burn auth = wards"},
    "psm": {**c("PSM"), "role": "UsddPsm, ilk PSM-USDT-A; permissionless buyGem/sellGem, tin=tout=0"},
    "gemJoin": {**c("GemJoinUSDT"), "role": "AuthGemJoin5 for USDT (6 dec), custodies PSM USDT"},
    "vat": {**c("Vat"), "role": "DSS Vat (core CDP accounting)"},
    "usddJoin": {**c("UsddJoin"), "role": "DaiJoin analogue; only ward/minter on USDD token"},
    "vow": {**c("Vow"), "role": "system surplus/debt sink"},
    "spotter": {**c("Spotter"), "role": "price feed / liquidation ratio"},
    "jug": {**c("Jug"), "role": "stability fee accumulator"},
    "dog": {**c("Dog"), "role": "liquidation engine"},
    "usdt": {**c("USDT"), "role": "USDT collateral + PSM gem"},
    "oldUsdd": {**c("OldUSDD"), "role": "USDD 1.0 token (legacy), supply 7.136M"},
    "usddExchange": {**c("USDDExchange"), "role": "old->new USDD migration; EXCHANGE_RATE=1, paused=false, unfunded"},
    "pause": {**c("Pause"), "role": "DSPause, delay=0, authority=GovActionsProxy"},
    "pauseProxy": {**c("PauseProxy"), "role": "pause proxy; ward on Vat/Jug/Spotter/Dog/Vow/PSM"},
    "govActionsProxy": {**c("GovActionsProxy"), "role": "authority of Pause; owner EOA TSF2rq..."},
    "governorBravo": {**c("GovernorBravo"), "role": "GovernorBravoDelegator; admin=Timelock"},
    "timelock": {**c("GovAdmin"), "role": "Timelock, delay=172800s (2 days)"},
    "jusdd": {**c("jUSDD"), "role": "JustLend jUSDD market; holds 425.6M USDD"},
    "v3Pool": {**c("V3Pool"), "role": "SunSwap V3 USDD/USDT fee=100 pool"},
    "v2Pair": {**c("V2Pair"), "role": "SunSwap V2 USDD/USDT pair (dust, $16 TVL)"},
    "sunCurve": {**c("SunCurve"), "role": "SunCurve StableSwap2Pool USDD/USDT, fee=4bp, A=1000"},
    "esm": {**c("ESM"), "role": "Emergency Shutdown Module, min=8.91B USDD"},
    "end": {**c("End"), "role": "emergency shutdown"},
    "flap": {**c("Flap"), "role": "surplus auction"},
    "flop": {**c("Flop"), "role": "debt auction"},
    "dssDeploy": {**c("DssDeploy"), "role": "DSS deploy script; owner/authority renounced"},
    "usddFab": {**c("UsddFab"), "role": "USDD token factory"},
}

live_state = {
    "block": 87211072,
    "timestamp_utc": "2026-10-18T06:50:18Z",
    "block_after": 87211086,
    "usdd": {
        "total_supply": arb["supply_usdd"],
        "decimals": 18,
        "mint_wards": {"UsddJoin": 1, "PSM": 0, "USDDExchange": 0,
                        "PauseProxy": 0, "Pause": 0, "Governor": 0,
                        "DssDeploy": 0, "UsddFab": 0, "Vat": 0, "deployer": 0},
        "blacklist_or_freeze": "none found in method map (push/pull/move/rely/deny/mint/burn/permit only)",
    },
    "psm": arb["psm"],
    "vat": {
        "debt_usd": arb["vat"]["debt_usd"],
        "sum_enumerated_ilks_art_rate": arb["vat"]["sum_enumerated_ilks_art_rate"],
        "unattributed_debt": arb["vat"]["unattributed_debt"],
        "sum_enumerated_lines": arb["vat"]["sum_enumerated_lines"],
        "vice_usd": 2000.6579826586599,
        "ilks": arb["vat"]["ilks"],
    },
    "dex": arb["dex"],
    "oracle": {
        "USDT_OSM": "TMhsJiXUrT5eueuH1cq6SdvQEBt4YjKLfx",
        "USDT_median_src": "TNuBMH3A628d9UAhgkBFpgqb3gHy2sbnF5",
        "USDT_USD_peek": 0.99873,
        "TRX_OSM": "TVsQxikpttN15u7vcjXKeVrtYRWbrqgPbH",
        "TRX_median_src": "TSB7M6eBpBD4RUrqdgPrTLkfzzYV39QTBo",
        "TRX_USD_peek": 0.333676,
        "WBTC_pip": "TRkw65bzGiVqE3vaUH8ndvrNRmLbCgU2wa",
        "WBTC_USD_peek": 81409.027264,
        "spotter_mat": {"USDT-A": 1.05, "TRX-A": 1.2, "TRX-B": 1.17,
                         "TRX-C": 1.3, "WBTC-A": 1.5, "WBTC-B": 1.3},
    },
    "jusdd": arb["jusdd"],
    "legacy": {
        "old_usdd_supply": 7136259.979606,
        "exchange_paused": 0,
        "exchange_rate": 1,
        "exchange_new_usdd_balance": 1.508923899832e-05,
    },
    "admin": {
        "pause_delay_seconds": 0,
        "pause_authority": "TXzhj9Xh8xfzerjinRyM5TfoBL7Cw5hk5d",
        "pause_proxy": "TE6RxGgQuD6J1faw9mZxtbHGDqcKh8DvKU",
        "gov_actions_proxy_owner": "TSF2rqLdrrZG7PZkDxtvu6B2PTpofidMAX (EOA, 119,959,129 TRX ≈ $40M); same EOA owns USDDExchange",
        "governor_admin": "TLqrqsPcmiUk6HJc6kxY7q56PH1TWCxDhh (Timelock, 2 days)",
        "gov_actions": "TDLgCe2SatVew6PxSwYmqsc3zfahqXwuqX",
        "esm_min_usdd": 8910000000.0,
        "psm_wards": {"PauseProxy": 1, "GovActionsProxy": 0, "Governor": 0, "deployer": 0},
    },
}

summary = {
    "target": "USDD 2.0 (TRON), PSM-USDT-A + DSS/CDP",
    "chain": "tron",
    "block": 87211072,
    "block_id": "000000000532bc40e836b95ef7588b3e79d30b0be5e6403c6381f37d58585d79",
    "timestamp_utc": "2026-10-18T06:50:18Z",
    "addresses": addresses,
    "live_state": live_state,
    "eu_usd": 0,
    "eu_note": "Best on-chain round trip at block 87211072: -$99.79 per $1M (buy V3, redeem PSM) and -$100.22 per $1M (mint PSM, sell V3); V3 fee 1bp vs spot deviation -0.0022bp.",
    "eu_conditional_usd": 0,
    "eu_conditional_note": "Current precondition not met. Hypothetical dislocations with current V3 depth (1.302M USDD): 10bp -> ~$1,172; 100bp -> ~$12,890. PSM redemption capacity 41.23M would allow up to ~$412k at a 1% dislocation if depth existed.",
    "eu_conditional_scenarios": [
        {"precondition": "on-chain USDD/USDT <= 0.999 (10bp discount), V3 depth <= 1.302M USDD",
         "max_profit_usd": 1171.84},
        {"precondition": "on-chain USDD/USDT <= 0.990 (100bp discount), V3 depth <= 1.302M USDD",
         "max_profit_usd": 12890.25},
        {"precondition": "CEX USDD at 0.9973-0.9978, $25k-$50k clip, withdraw to TRON, PSM redeem",
         "max_profit_usd": 45.0,
         "note": "not permissionless; CEX KYC/withdrawal; taker fees ~10bp; CEX daily volume $23k-$55k"},
    ],
    "p_usd": 1230000000,
    "p_immediate_usd": 41232487.38,
    "p_note": "PauseProxy is a ward on Vat/Jug/Spotter/Dog/Vow/PSM; Vat.suck simulated success (unlimited USDD), PSM.file simulated success. Immediate liquid value = PSM USDT 41.23M; theoretical = ~$1.23B CDP TVL / collateral.",
    "s_usd": 0,
    "s_note": "No proven insolvency. PSM covers 3.13% of supply; jUSDD holds 32.31%; 819.8M Vat debt unattributed to enumerated ilks; old USDD exchange unfunded.",
    "h_o_usd": 0,
    "h_o_note": "No leaked/compromised key evidence. Single EOA TSF2rq... owns GovActionsProxy and USDDExchange (119.96M TRX); potential centralization path noted under P.",
    "confidence": 0.82,
    "paths": [
        "USDT -> SunSwap V3 USDD/USDT fee=100 -> USDD -> PSM.buyGem(usr,gemAmt) -> USDT; current spot 0.99999978, V3 fee 1bp => -$99.79 per $1M",
        "USDT -> PSM.sellGem(usr,gemAmt) -> USDD -> SunSwap V3 sell -> USDT; current spot 0.99999978, V3 fee 1bp => -$100.22 per $1M",
        "CEX USDD discount -> withdraw TRON -> PSM.buyGem -> USDT; ~8-17bp gross but ~10bp CEX taker fee, capped by $23k-$55k/day volume",
        "PauseProxy -> Vat.suck(pauseproxy,pauseproxy,rad) -> UsddJoin.exit -> USDD mint; privileged, simulated suck success",
        "PauseProxy -> PSM.file('tin'/'tout',fee) -> PSM fee change; privileged, simulated success",
    ],
    "blockers": [
        "V3 spot 0.99999978 USDT/USDD (deviation -0.0022bp), below the 1bp V3 fee; no positive round trip",
        "PSM buyGem redeem capacity 41,232,487.38 USDT = 3.13% of 1.317B supply; larger redemptions revert",
        "PSM sellGem mint capacity 558,769,042.50 USDD (line 600M - Art 41.23M), but DEX depth ~1.30M USDD / 2.11M USDT caps size",
        "SunSwap V2 USDD/USDT pair is dust: 7.97 USDT / 8.02 USDD, best profit $0.00002",
        "SunCurve 2pool fee 4bp; 10k USDD -> 9,993.56 USDT (0.99936), 10k USDT -> 9,998.19 USDD (1.00018), no edge",
        "Global discount is CEX-only: Gate 0.9973 ($23k/day), BingX 0.9978 ($55k/day), MEXC 0.9988 ($3.4k/day); taker fees erase it",
        "821M of Vat debt is not attributed to the enumerated ilks (USDT-A, TRX-A/B/C, PSM-USDT-A, WBTC-A/B); vice is only $2k",
        "USDD 1.0 -> 2.0 exchange is unfunded (0.000015 new USDD), so legacy migration is blocked",
    ],
    "evidence_files": [
        "raw/final_snapshot.json", "raw/arb_math.json", "raw/psm_state.json",
        "raw/vat_psm_state2.json", "raw/vat_sin2.json", "raw/cdp_ilks_state.json",
        "raw/sunswap_v3_state.json", "raw/sunswap_v2_reserves.json",
        "raw/suncurve_state.json", "raw/suncurve_curve.json",
        "raw/psm_events.json", "raw/psm_sim_buygem2.json",
        "raw/privileged_sim.json", "raw/govactions_probe.json",
        "raw/oracle_state.json", "raw/usdt_osm.json", "raw/oracle_peek.json",
        "raw/usdd_key_balances.json", "raw/usdd_exchange_state.json", "raw/usdd_wards_extra.json", "raw/usdd_wards_scan.json", "raw/usdd_wards_admin.json",
        "raw/dssdeploy_getters.json", "raw/contract_names_tron.json",
        "raw/code_sizes.json", "raw/llama_prices.json",
        "raw/coingecko_simple.json", "raw/coingecko_tickers.json",
    ],
}

print(json.dumps(summary, indent=1))
json.dump(summary, open(os.path.join(BASE, "summary.json"), "w"), indent=1)
