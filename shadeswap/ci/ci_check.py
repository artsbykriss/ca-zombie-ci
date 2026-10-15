#!/usr/bin/env python3
"""Self-contained live re-verification of the ShadeSwap finding on Secret Network.

Runs in CI (GitHub Actions). Read-only: only public RPC queries (ABCI + Tendermint RPC).
Writes results to ci-out/.
"""
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, "analysis"))

from secret_abci import abci_query, contract_info, ld, parse_proto  # noqa
from secret_enc_query import smart_query  # noqa

RPCS = [
    "https://rpc.secret.mainnet.secret3.dev",
    "https://rpc-secret.keplr.app",
]

FACTORY = "secret1ja0hcwvy76grqkpgwznxukgd7t8a8anmmx05pp"
PAIRS = {
    "SHD/stkd-SCRT": "secret1qyt4l47yq3x43ezle4nwlh5q0sn6f9sesat7ap",
    "SILK/stkd-SCRT": "secret1a6efnz9y702pctmnzejzkjdyq0m62jypwsfk92",
    "SILK/SHD": "secret1l34fyc9g23fnlk896693nw57phevnyha7pt6gj",
    "SHD/saWBTC": "secret1hnev28m6s2hkzkkdfn7m79kdxg57haacqzwu7g",
    "SILK/saWBTC": "secret1ygwaq7rxlyfnungn0d268z36mm3c8un76f8atc",
    "SILK/saUSDC": "secret1qz57pea4k3ndmjpy6tdjcuq4tzrvjn0aphca0k",
    "SILK/saUSDT": "secret10szrjlyza5u7yqcqvqenf28nmhwph4pad9csyw",
}
TOKENS = {
    "SHD": "secret153wu605vvp934xhd4k9dtd640zsep5jkesstdm",
    "SILK": "secret1fl449muk5yq8dlad7a22nje4p5d2pnsgymhjfd",
    "stkd-SCRT": "secret1k6u0cy4feepm6pehnz804zmwakuwdapm69tuc4",
}

res = {"run_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "rpc": {}}

# 1) liveness
for rpc in RPCS:
    try:
        import urllib.request
        req = urllib.request.Request(rpc + "/status", headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=20) as r:
            st = json.load(r)["result"]["sync_info"]
        res["rpc"][rpc] = {"height": st["latest_block_height"], "time": st["latest_block_time"],
                           "catching_up": st["catching_up"]}
        print(f"LIVE {rpc} height={st['latest_block_height']} {st['latest_block_time']}")
    except Exception as e:
        res["rpc"][rpc] = {"error": str(e)[:120]}
        print(f"RPC FAIL {rpc}: {e}")
    time.sleep(0.3)

# 2) factory contract info + config
try:
    info, h = contract_info(FACTORY)
    res["factory_info"] = info
    print(f"factory: code={info.get('code_id')} label={info.get('label')!r} admin={info.get('admin')}")
except Exception as e:
    res["factory_info"] = {"error": str(e)[:150]}

# 3) pair states
res["pairs"] = {}
for name, addr in PAIRS.items():
    try:
        r, _ = smart_query(addr, {"get_pair_info": {}})
        pi = r["get_pair_info"]
        res["pairs"][name] = {"address": addr, "t0": pi["pair"][0]["custom_token"]["contract_addr"],
                              "t1": pi["pair"][1]["custom_token"]["contract_addr"],
                              "amount_0": pi["amount_0"], "amount_1": pi["amount_1"],
                              "total_liquidity": pi["total_liquidity"], "stable": pi["pair"][2]}
        print(f"pair {name}: {pi['amount_0']} / {pi['amount_1']}")
    except Exception as e:
        res["pairs"][name] = {"address": addr, "error": str(e)[:150]}
        print(f"pair {name} FAIL {str(e)[:120]}")
    time.sleep(0.4)

# 4) token info
res["tokens"] = {}
for name, addr in TOKENS.items():
    try:
        r, _ = smart_query(addr, {"token_info": {}})
        res["tokens"][name] = r["token_info"]
        print(f"token {name}: supply={r['token_info']['total_supply']} dec={r['token_info']['decimals']}")
    except Exception as e:
        res["tokens"][name] = {"error": str(e)[:150]}
    time.sleep(0.4)

# 5) stkd-SCRT exchange rate
try:
    r, _ = smart_query(TOKENS["stkd-SCRT"], {"staking_info": {"time": int(time.time())}})
    res["stkd_scrt_staking"] = r["staking_info"]
    print(f"stkd-SCRT price={r['staking_info']['price']} (6dp SCRT/stkd-SCRT) status=normal")
except Exception as e:
    res["stkd_scrt_staking"] = {"error": str(e)[:150]}

# 6) swap simulations (key extraction paths + one blocked path)
def sim(pair, offer_sym, amount_raw, label):
    p = res["pairs"].get(pair)
    if not p or "t0" not in p:
        return {"error": "pair state missing"}
    ct = None
    for side in ("t0", "t1"):
        pass
    # rebuild code-hash-bearing token refs
    try:
        r2, _ = smart_query(PAIRS[pair], {"get_pair_info": {}})
        pi = r2["get_pair_info"]
        for s in pi["pair"][:2]:
            if s["custom_token"]["contract_addr"] == TOKENS[offer_sym]:
                ct = s["custom_token"]
        q = {"swap_simulation": {"offer": {"token": {"custom_token": ct}, "amount": str(amount_raw)},
                                 "exclude_fee": False}}
        rr, _ = smart_query(PAIRS[pair], q)
        print(f"SIM {label}: {json.dumps(rr)[:200]}")
        return rr
    except Exception as e:
        print(f"SIM {label} FAIL: {str(e)[:160]}")
        return {"error": str(e)[:200]}

res["sims"] = {
    "stkd_to_SILK_1000": sim("SILK/stkd-SCRT", "stkd-SCRT", 1000_000000, "1000 stkd-SCRT -> SILK"),
    "stkd_to_SHD_1000": sim("SHD/stkd-SCRT", "stkd-SCRT", 1000_000000, "1000 stkd-SCRT -> SHD"),
    "SHD_to_saWBTC_500": sim("SHD/saWBTC", "SHD", 500_00000000, "500 SHD -> saWBTC"),
    "SILK_to_saUSDC_1000": sim("SILK/saUSDC", "SILK", 1000_000000, "1000 SILK -> saUSDC"),
    "SILK_to_saUSDT_1000": sim("SILK/saUSDT", "SILK", 1000_000000, "1000 SILK -> saUSDT"),
}

# 7) valuation of the 7 monitored pairs at fixed external prices (2026-10-15)
PRICES = {"SHD": 0.064581, "SILK": 0.100548, "stkd-SCRT": 0.018445, "saWBTC": 81213.0,
          "saUSDC": 1.0, "saUSDT": 1.0}
DEC = {"SHD": 8, "SILK": 6, "stkd-SCRT": 6, "saWBTC": 8, "saUSDC": 6, "saUSDT": 6}
SYM = {TOKENS["SHD"]: "SHD", TOKENS["SILK"]: "SILK", TOKENS["stkd-SCRT"]: "stkd-SCRT",
       "secret1guyayjwg5f84daaxl7w84skd8naxvq8vz9upqx": "saWBTC",
       "secret1vkq022x4q8t8kx9de3r84u669l65xnwf2lg3e6": "saUSDC",
       "secret1wk5j2cntwg2fgklf0uta3tlkvt87alfj7kepuw": "saUSDT"}
tvl = 0.0
for name, p in res["pairs"].items():
    if "t0" not in p:
        continue
    for t, amt in ((p["t0"], int(p["amount_0"])), (p["t1"], int(p["amount_1"]))):
        s = SYM.get(t)
        if s and s in PRICES:
            tvl += amt / 10 ** DEC[s] * PRICES[s]
res["monitored_pairs_tvl_usd"] = round(tvl, 2)
print(f"monitored pairs TVL (external prices): ${tvl:,.2f}")

json.dump(res, open(os.path.join(ROOT, "ci-out", "ci-results.json"), "w"), indent=1)
print("wrote ci-out/ci-results.json")
