"""Live-state snapshot for RealT RMM v3 + RealTokenWrapper (Gnosis). Read-only.

Writes analysis/live_state.json:
  - core supply / oracle / reserve configuration
  - wrapper token basket and marks (623 tokens)
  - wrapper-level RealToken transfer probe (10 tokens x 5 recipients)
  - aRTW transferability + withdraw recipient probe

NOTE: the authoritative RU03 census (40 tokens x 8 destinations, Processor.canTransfer
with msg.sender == token) lives in gate_probe.py; the incumbent/liquidation census lives
in incumbent.py. This script intentionally keeps only the core snapshot.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gnosis as g  # noqa: E402

WRAPPER = "0x10497611Ee6524D75FC45E3739F472F83e282AD5"
POOL = "0xFb9b496519fCa8473fba1af0850B6B8F476BFdB3"
ARTW = "0xF3220Cd8F66AEB86fC2A82502977EAb4BFd2f647"
RTW = "0xd3DFF217818b4F33eB38a243158FBeD2BBB029D3"
ORACLE = "0xb4AE809Ad7CEB7e5B579dEdD0De7c213aD5AB516"
SAFE = "0x4F7765c9feBc51cD63F68f573920c0B7bF803151"
VICTIM = "0x529f288298fe949c9c5c3323554c782db5021ed0"
DC0604 = "0xDc0604B378adCa99a9e2096707aD4830673CE5B8"
WXDAI = "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d"
USDC = "0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83"

FRESH = ["0x1111111111111111111111111111111111111111",
         "0x000000000000000000000000000000000000bEEF"]
DESTS = {"fresh_1111": FRESH[0], "fresh_beef": FRESH[1], "incumbent_safe": SAFE,
         "victim_529f": VICTIM, "buyer_dc0604": DC0604}


def main():
    block = g.latest_block()
    ts = g.block_ts(block)
    print("block", block, "ts", ts, flush=True)
    out = {"chain": "gnosis", "chain_id": 100, "block": block, "timestamp": ts,
           "rpc": "keyless/public (redacted)"}

    out["wrapper_artw"] = g.dec(["address"], g.call(WRAPPER, "getArtw()(address)", block=block))[0]
    out["wrapper_rtw"] = g.dec(["address"], g.call(WRAPPER, "getRtw()(address)", block=block))[0]
    out["wrapper_pool"] = g.dec(["address"], g.call(WRAPPER, "getPool()(address)", block=block))[0]
    out["artw_total_supply"] = str(g.dec(["uint256"], g.call(ARTW, "totalSupply()(uint256)", block=block))[0])
    out["rtw_at_artw"] = str(g.dec(["uint256"], g.call(RTW, "balanceOf(address)(uint256)", [ARTW], block=block))[0])
    out["rtw_at_wrapper"] = str(g.dec(["uint256"], g.call(RTW, "balanceOf(address)(uint256)", [WRAPPER], block=block))[0])
    out["rtw_total_supply"] = str(g.dec(["uint256"], g.call(RTW, "totalSupply()(uint256)", block=block))[0])
    out["oracle_rtw_price"] = g.dec(["uint256"], g.call(ORACLE, "getAssetPrice(address)(uint256)", [RTW], block=block))[0]

    reserves = g.dec(["address[]"], g.call(POOL, "getReservesList()(address[])", block=block))[0]
    out["reserves"] = {}
    struct_sig = ("getReserveData(address)(uint256,uint128,uint128,uint128,uint128,uint128,"
                  "uint40,uint16,address,address,address,address,uint128,uint128,uint128)")
    for r in reserves:
        d = g.dec(["uint256", "uint128", "uint128", "uint128", "uint128", "uint128", "uint40",
                   "uint16", "address", "address", "address", "address", "uint128", "uint128", "uint128"],
                  g.call(POOL, struct_sig, [r], block=block))
        cfg = d[0]
        rec = {
            "configuration": str(cfg),
            "liquidity_index": str(d[1]),
            "variable_borrow_index": str(d[3]),
            "last_update_timestamp": d[6],
            "a_token": d[8],
            "variable_debt_token": d[10],
            "ltv_bps": cfg & 0xFFFF,
            "liquidation_threshold_bps": (cfg >> 16) & 0xFFFF,
            "liquidation_bonus_bps": (cfg >> 32) & 0xFFFF,
            "decimals": (cfg >> 48) & 0xFF,
            "active": bool((cfg >> 56) & 1),
            "frozen": bool((cfg >> 57) & 1),
            "borrowing_enabled": bool((cfg >> 58) & 1),
            "paused": bool((cfg >> 60) & 1),
        }
        if d[8] != "0x0000000000000000000000000000000000000000":
            rec["a_token_supply"] = str(g.dec(["uint256"], g.call(d[8], "totalSupply()(uint256)", block=block))[0])
        if d[10] != "0x0000000000000000000000000000000000000000":
            rec["variable_debt_supply"] = str(g.dec(["uint256"], g.call(d[10], "totalSupply()(uint256)", block=block))[0])
        out["reserves"][r.lower()] = rec

    tl, amts = g.dec(["address[]", "uint256[]"],
                     g.call(WRAPPER, "getAllTokenBalancesOfWrapper()(address[],uint256[])", block=block))
    prices = g.multicall([(WRAPPER, g.sel("getRealTokenPrice(address)") + g.abi_encode(["address"], [t]).hex())
                          for t in tl], block=block)
    toks = []
    for t, a, (ok, ret) in zip(tl, amts, prices):
        p = int.from_bytes(ret[:32], "big") if ok else 0
        toks.append({"address": t.lower(), "amount": str(a), "price_1e8": p,
                     "value_usd": a * p / 1e8 / 1e18})
    toks.sort(key=lambda x: -x["value_usd"])
    out["wrapper_tokens_count"] = len(toks)
    out["wrapper_value_usd_at_marks"] = round(sum(x["value_usd"] for x in toks), 2)
    out["top_tokens"] = toks[:30]

    # wrapper-level transfer probes (the actual transfer executed by liquidationCall/withdraw)
    probe = []
    for t in [x["address"] for x in toks[:10]]:
        for label, d in DESTS.items():
            try:
                g.eth_call(t, g.sel("transfer(address,uint256)") +
                           g.abi_encode(["address", "uint256"], [d.lower(), 10 ** 18]).hex(),
                           block=block, frm=WRAPPER)
                probe.append({"token": t, "dest_label": label, "result": "OK"})
            except Exception as e:  # noqa: BLE001
                s = str(e)
                probe.append({"token": t, "dest_label": label,
                              "result": "RU03" if "RU03" in s else "REVERT"})
    out["wrapper_transfer_probe"] = probe
    out["wrapper_transfer_summary"] = {}
    for label in DESTS:
        rows = [p for p in probe if p["dest_label"] == label]
        out["wrapper_transfer_summary"][label] = {
            "probes": len(rows), "OK": sum(1 for p in rows if p["result"] == "OK"),
            "RU03": sum(1 for p in rows if p["result"] == "RU03"),
            "other_revert": sum(1 for p in rows if p["result"] == "REVERT")}

    artw = {}
    for label, frm in [("victim_529f", VICTIM), ("incumbent_safe", SAFE)]:
        try:
            g.eth_call(ARTW, g.sel("transfer(address,uint256)") +
                       g.abi_encode(["address", "uint256"], [FRESH[0].lower(), 1]).hex(),
                       block=block, frm=frm)
            artw[label] = {"transfer_to_fresh": "OK"}
        except Exception as e:  # noqa: BLE001
            artw[label] = {"transfer_to_fresh": "REVERT: " + str(e)[:300]}
        tok = toks[0]["address"]
        for to_label, to in [("to_fresh", FRESH[0]), ("to_safe", SAFE)]:
            try:
                g.eth_call(WRAPPER, g.sel("withdraw(address,uint256,address)") +
                           g.abi_encode(["address", "uint256", "address"], [tok, 10 ** 15, to.lower()]).hex(),
                           block=block, frm=frm)
                artw[label]["withdraw_" + to_label] = "OK"
            except Exception as e:  # noqa: BLE001
                s = str(e)
                artw[label]["withdraw_" + to_label] = ("RU03" if "RU03" in s else "REVERT") + " :: " + s[:200]
    out["artw_and_withdraw_probe"] = artw

    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "live_state.json")
    json.dump(out, open(p, "w"), indent=2)
    print("wrote", p)
    print("tokens", out["wrapper_tokens_count"], "basket $", out["wrapper_value_usd_at_marks"])
    print("transfer summary", json.dumps(out["wrapper_transfer_summary"]))
    print("artw/withdraw", json.dumps(artw, indent=1)[:800])
    print("reserves", json.dumps({k: {kk: vv for kk, vv in v.items() if kk in
                                      ("active", "frozen", "borrowing_enabled", "paused",
                                       "ltv_bps", "liquidation_threshold_bps", "liquidation_bonus_bps")}
                                  for k, v in out["reserves"].items()}, indent=1))


if __name__ == "__main__":
    main()
