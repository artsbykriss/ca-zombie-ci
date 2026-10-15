#!/usr/bin/env python3
"""Final live-state snapshot for the STON.fi v1 report (read-only, keyless endpoints)."""
import json
import sys
import urllib.request

sys.path.insert(0, "/home/heisenberg/CA/stonfi-v1/analysis")
from ton_client import run_get_method, account_states, masterchain_head, _get, account  # noqa
from pytoniq_core import Cell, Address, Builder  # noqa

ROUTER = "EQB3ncyBUTjZUA5EnFKR5_EnOMI9V1tTEAAPaiU71gc4TiUt"
USDT_WALLET = "0:4eec921b9d4d56a0d94676016d49c26b39b1d7901a7e153e66033f146a0886f4"
PTON_WALLET = "0:1150b518b2626ad51899f98887f8824b70065456455f7fe2813f012699a4061f"
POOL = "EQD8TJ8xEWB1SpnRE4d89YO3jl0W0EiBnNS4IBaHaUmdfizE"
HOLE = "0:0000000000000000000000000000000000000000000000000000000000000000"


def price():
    try:
        req = urllib.request.Request("https://coins.llama.fi/prices/current/coingecko:the-open-network",
                                     headers={"User-Agent": "zombie-hunt-research/1.0"})
        return json.loads(urllib.request.urlopen(req, timeout=30).read())["coins"]["coingecko:the-open-network"]["price"]
    except Exception:
        return None


def main():
    head = masterchain_head()
    out = {"masterchain_seqno": head["seqno"], "gen_utime": head["gen_utime"], "ton_price_usd": price()}

    ec, dec, _ = run_get_method(ROUTER, "get_router_data")
    rst = account_states(ROUTER)
    out["router"] = {
        "address": ROUTER, "is_locked": dec["is_locked"], "admin": dec["admin_address"],
        "temp_upgrade_end_code": Cell.from_boc(bytes.fromhex(dec["temp_upgrade"]))[0].begin_parse().load_uint(64),
        "ton_balance_nanoton": rst["balance"], "code_hash_b64": rst["code_hash"],
    }

    for name, addr in [("usdt", USDT_WALLET), ("pton", PTON_WALLET)]:
        friendly = Address(addr).to_str(True, True)
        st = account_states(friendly)
        # authoritative: get_wallet_data getter
        ec, wd, _stk = run_get_method(friendly, "get_wallet_data")
        bal = wd["balance"] if wd else None
        out[f"router_{name}_wallet"] = {"address": friendly, "jetton_balance_raw": bal,
                                        "ton_balance_nanoton": st["balance"]}

    ec, dec, _ = run_get_method(POOL, "get_pool_data")
    pst = account_states(POOL)
    out["usdt_pton_pool"] = {
        "address": POOL, "reserve0_usdt_raw": dec["reserve0"], "reserve1_pton_raw": dec["reserve1"],
        "token0": dec["token0_address"], "token1": dec["token1_address"],
        "lp_total_supply": (lambda d: d)(json.loads(json.dumps(dec)).get("lp_total_supply")) if "lp_total_supply" in dec else None,
        "collected_token0_protocol_fee": dec["collected_token0_protocol_fee"],
        "collected_token1_protocol_fee": dec["collected_token1_protocol_fee"],
        "protocol_fee_address": dec["protocol_fee_address"],
        "protocol_fee_address_is_hole": dec["protocol_fee_address"] == HOLE,
        "ton_balance_nanoton": pst["balance"], "code_hash_b64": pst["code_hash"],
    }

    # aggregate pool figures from the public STON.fi API (v1 pools)
    api = _get("https://api.ston.fi/v1/pools?dex_v2=false")
    ps = api["pool_list"]
    USDT = "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs"
    APT = "EQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM9c"
    agg = {"pools": len(ps), "usdt_reserves_raw": 0, "pton_side_reserves_raw": 0,
           "usdt_collected_fees_raw": 0, "pton_side_collected_fees_raw": 0, "lp_usd": 0.0}
    for p in ps:
        for side in ("0", "1"):
            tok = p[f"token{side}_address"]
            if tok == USDT:
                agg["usdt_reserves_raw"] += int(p[f"reserve{side}"])
                agg["usdt_collected_fees_raw"] += int(p[f"collected_token{side}_protocol_fee"] or 0)
            if tok == APT:
                agg["pton_side_reserves_raw"] += int(p[f"reserve{side}"])
                agg["pton_side_collected_fees_raw"] += int(p[f"collected_token{side}_protocol_fee"] or 0)
        agg["lp_usd"] += float(p.get("lp_total_supply_usd") or 0)
    out["v1_pools_aggregate_api"] = agg

    # addr_none locked initial LP of the big pool
    ec, rdec, _ = run_get_method(ROUTER, "get_router_data")
    lp_code = Cell.from_boc(bytes.fromhex(rdec["jetton_lp_wallet_code"]))[0]
    none_bits = Builder().store_bit(0).store_bit(0).end_cell()
    inner = Builder().store_coins(0).store_slice(none_bits.begin_parse()).store_address(Address(POOL)).store_ref(lp_code).end_cell()
    si = Builder().store_bit(0).store_bit(0).store_dict(lp_code).store_dict(inner).store_bit(0).end_cell()
    locked_wallet = Address("0:" + si.hash.hex()).to_str(True, True)
    ec, ldec, _ = run_get_method(locked_wallet, "get_wallet_data")
    out["big_pool_locked_initial_lp"] = {"wallet": locked_wallet, "balance_raw": ldec["balance"] if ldec else None}

    print(json.dumps(out, indent=2, default=str))
    json.dump(out, open("/home/heisenberg/CA/stonfi-v1/analysis/final_snapshot.json", "w"), indent=2, default=str)


if __name__ == "__main__":
    main()
