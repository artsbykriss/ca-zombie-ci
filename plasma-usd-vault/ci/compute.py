#!/usr/bin/env python3
"""Compute Plasma global/local NAV from env values captured by ci/run.sh."""
import json, os

def i(k):
    v = os.environ.get(k, "0").strip().split()[0]
    try:
        return int(v)
    except Exception:
        return 0

pb, eb = i("PB"), i("EB")
rate, psup = i("RATE"), i("PSUP")
atb, idle = i("ATB"), i("IDLE")
esup, eusdt, eusdc, eusds, edai = i("ESUP"), i("EUSDT"), i("EUSDC"), i("EUSDS"), i("EDAI")
assets_p = atb + idle
assets_e = eusdt + eusdc + eusds // 10**12 + edai // 10**12
gsup, gassets = psup + esup, assets_p + assets_e
out = {
    "plasma_block": pb,
    "ethereum_block": eb,
    "accountant_rate_1e6": rate,
    "rate_in_quote_usdt0_1e6": i("RATEQ"),
    "plasma_supply_1e6": psup,
    "plasma_atoken_1e6": atb,
    "plasma_idle_usdt0_1e6": idle,
    "plasma_assets_1e6": assets_p,
    "plasma_local_nav_1e6": (assets_p * 10**6 // psup) if psup else 0,
    "eth_supply_1e6": esup,
    "eth_usdt_1e6": eusdt,
    "eth_usdc_1e6": eusdc,
    "eth_usds_wei": eusds,
    "eth_dai_wei": edai,
    "eth_assets_1e6": assets_e,
    "eth_local_nav_1e6": (assets_e * 10**6 // esup) if esup else 0,
    "global_supply_1e6": gsup,
    "global_assets_1e6": gassets,
    "global_nav_1e6": (gassets * 10**6 // gsup) if gsup else 0,
    "global_nav_vs_rate_bps": ((gassets * 10**6 // gsup) - rate) * 10000 // rate if rate else 0,
    "canCall_attacker_bulkWithdraw": os.environ.get("CAN_BW", ""),
    "bulkWithdraw_attacker_result": os.environ.get("BW_RES", ""),
    "deposit_attacker_result": os.environ.get("DEP_RES", ""),
    "idToChains_30101": os.environ.get("LZ", ""),
    "lz_peer_enabled_both_ways": "true, true" in os.environ.get("LZ", ""),
}
print(json.dumps(out, indent=1))
