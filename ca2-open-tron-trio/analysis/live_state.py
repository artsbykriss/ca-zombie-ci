#!/usr/bin/env python3
"""Read-only live state for the Tron trio at a stated block.

All calls are wallet/triggerconstantcontract simulations (no broadcast).
Writes analysis/live_state.json.
"""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tronlib as T

OUT = os.path.dirname(os.path.abspath(__file__))
FRESH = T.fresh_address()
C = {
    "CherryPool": "TQxzSmRaCf1qrWdP6sfCihmrdXLNs8r4RR",
    "PokerGame": "TAcszQSbMybSkhfy4nQrAptmACRTDcYUgn",
    "FireFull": "TFxznGmEVdp5XxnQnyGp2FhFfBkMAprveW",
}
SLOTS = {"CherryPool": 0, "PokerGame": 1, "FireFull": 2}


def call(contract, sig, params=""):
    r = T.trigger(FRESH, contract, sig, params)
    res = {
        "sig": sig,
        "parameter": params,
        "result": r.get("result"),
        "constant_result": r.get("constant_result"),
        "energy_used": r.get("energy_used"),
        "energy_penalty": r.get("energy_penalty"),
        "txid": (r.get("transaction") or {}).get("txID"),
    }
    return res


def main():
    block = T.now_block()
    out = {"block": block, "probe_address": FRESH,
           "probe_address_hex": T.addr_to_hex(FRESH), "contracts": {}}
    for name, addr in C.items():
        print(f"== {name} {addr} @ {block}")
        acct = T.get_account(addr)
        entry = {
            "address": addr,
            "address_hex": T.addr_to_hex(addr),
            "balance_sun": acct.get("balance", 0),
            "balance_trx": acct.get("balance", 0) / 1e6,
            "account_keys": sorted(acct.keys()),
            "calls": [],
        }
        views = {
            "CherryPool": [
                ("SecondCherryAmount()", ""), ("CherryToken()", ""), ("PledgeToken()", ""),
                ("CherryTotalAmount()", ""), ("PledgeTokenTotalAmount()", ""),
                ("getPledgeTokenAmount()", ""), ("getRemainCherryAmount()", ""),
                ("CurDivPeriNo()", ""), ("getEndTime()", ""), ("isStarted()", ""),
                ("hasCherry()", ""), ("getUserTokenAmount(address)", T.enc_addr(FRESH)),
                ("userAmountTimeOf(address)", T.enc_addr(FRESH)),
                ("callWaitingCherry(address)", T.enc_addr(FRESH)),
                ("tokenUserAmountOf(address,address)", T.enc_addr(T.hex_to_addr("0" * 40)) + T.enc_addr(FRESH)),
                ("DivPeriOf(uint256)", T.enc_uint(0)),
            ],
            "PokerGame": [
                ("owner()", ""), ("coo()", ""), ("cfo()", ""), ("name()", ""),
                ("stopped()", ""), ("income()", ""), ("mineContract()", ""),
                ("balance_of(address)", T.enc_addr(FRESH)),
                ("room_of(address)", T.enc_addr(FRESH)),
                ("status_of(address)", T.enc_addr(FRESH)),
                ("levels(uint256)", T.enc_uint(0)),
                ("room_map(uint256)", T.enc_uint(0)),
                ("prize_of_game(uint256)", T.enc_uint(0)),
                ("getPaidPlayers(uint256)", T.enc_uint(0)),
                ("game_paid_players(uint256,uint256)", T.enc_uint(0) + T.enc_uint(0)),
            ],
            "FireFull": [
                ("creater()", ""), ("owners(address)", T.enc_addr(FRESH)),
                ("players(address)", T.enc_addr(FRESH)), ("playerCounter()", ""),
                ("superPlayerList(address)", T.enc_addr(FRESH)),
                ("nomalList(uint256)", T.enc_uint(0)),
                ("contractInfo()", ""), ("jackpot(uint256)", T.enc_uint(0)),
                ("jackpotInfo()", ""), ("periods()", ""), ("contractState()", ""),
                ("rewardScale(uint256)", T.enc_uint(0)), ("joinScale()", ""),
                ("minJoinAmount()", ""), ("retainAddress(uint256)", T.enc_uint(0)),
                ("firePowerContract()", ""), ("sedimentaryAsset()", ""),
                ("superPlayerProfit()", ""), ("totalJoin()", ""), ("periodsLimit()", ""),
                ("contractIndexInfo()", ""), ("nomalListIndex()", ""),
            ],
        }[name]
        for sig, params in views:
            try:
                r = call(addr, sig, params)
            except Exception as e:  # noqa: BLE001
                r = {"sig": sig, "error": str(e)[:200]}
            entry["calls"].append(r)
            print(f"  {sig:45s} {str(r.get('constant_result'))[:80]} e={r.get('energy_used')} "
                  f"res={r.get('result', {}).get('result') if isinstance(r.get('result'), dict) else r.get('result')}")
            time.sleep(0.9)
        out["contracts"][name] = entry
    json.dump(out, open(f"{OUT}/live_state.json", "w"), indent=1)
    print(json.dumps({k: {"balance_trx": v["balance_trx"]} for k, v in out["contracts"].items()}, indent=1))


if __name__ == "__main__":
    main()
