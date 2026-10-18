"""CI re-check (lightweight) — RealT RMM v3 + RealTokenWrapper, Gnosis, read-only.

Runs inside GitHub Actions with GNOSIS_RPC_URL supplied by the workflow.
Writes ci-out/ci_check.json and prints a compact summary.

Checks:
  1. Core state: aRTW supply, RTW held by aRTW, oracle price, wrapper basket value.
  2. RU03 recipient gate: Processor.canTransfer(from=wrapper,to=dest) for sampled tokens
     with eth_call `from = token` (rule engine resolves via msg.sender), plus direct
     token.transfer from the wrapper. Destinations: 3 fresh EOAs vs 3 whitelisted parties.
  3. Yam: offer count, sampled bids + showOffer liveness; 30-day OfferAccepted fill ratios.
  4. Issuer Buyback Program switch on realt.co/sell-orders.
"""
import json
import os
import random
import re
import sys
import time

import requests
from eth_abi import encode as abi_encode

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, "analysis"))
import gnosis as g  # noqa: E402

WRAPPER = "0x10497611Ee6524D75FC45E3739F472F83e282AD5"
POOL = "0xFb9b496519fCa8473fba1af0850B6B8F476BFdB3"
ARTW = "0xF3220Cd8F66AEB86fC2A82502977EAb4BFd2f647"
RTW = "0xd3DFf217818b4F33eB38a243158FBeD2BBB029D3"
ORACLE = "0xb4AE809Ad7CEB7e5B579dEdD0De7c213aD5AB516"
PROCESSOR = "0x3221a28eD2b2e955DA64d1d299956f277562C95c"
YAM = "0xC759AA7f9dd9720A1502c104DaE4F9852bb17C14"
SAFE = "0x4F7765c9feBc51cD63F68f573920c0B7bF803151"
VICTIM = "0x529f288298fe949c9c5c3323554c782db5021ed0"
FRESH = ["0x1111111111111111111111111111111111111111",
         "0x000000000000000000000000000000000000bEEF"]
WHITE = [SAFE, VICTIM]
STABLE = {"0xe91d153e0b41518a2ce8dd3d7944fa863463a97d", "0xddafbb505ad214d7b80b1f830fccc89b60fb7a83"}
IMPAIR = 0.19
TOPIC_ACCEPTED = "0x" + g.keccak(text="OfferAccepted(uint256,address,address,address,address,uint256,uint256)").hex()


def main():
    out = {"chain": "gnosis", "chain_id": 100, "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    block = g.latest_block()
    out["block"] = block
    out["timestamp"] = g.block_ts(block)
    print("block", block, flush=True)

    # 1. core state
    core = {
        "artw_total_supply": str(g.dec(["uint256"], g.call(ARTW, "totalSupply()(uint256)", block=block))[0]),
        "rtw_at_artw": str(g.dec(["uint256"], g.call(RTW, "balanceOf(address)(uint256)", [ARTW], block=block))[0]),
        "rtw_at_wrapper": str(g.dec(["uint256"], g.call(RTW, "balanceOf(address)(uint256)", [WRAPPER], block=block))[0]),
        "oracle_rtw_price": g.dec(["uint256"], g.call(ORACLE, "getAssetPrice(address)(uint256)", [RTW], block=block))[0],
    }
    tl, amts = g.dec(["address[]", "uint256[]"],
                     g.call(WRAPPER, "getAllTokenBalancesOfWrapper()(address[],uint256[])", block=block))
    prices = g.multicall([(WRAPPER, g.sel("getRealTokenPrice(address)") + abi_encode(["address"], [t]).hex())
                          for t in tl], block=block)
    toks = []
    for t, a, (ok, ret) in zip(tl, amts, prices):
        p = int.from_bytes(ret[:32], "big") if ok else 0
        toks.append((t.lower(), a, p))
    toks.sort(key=lambda x: -(x[1] * x[2]))
    core["tokens"] = len(toks)
    core["basket_value_usd_marks"] = round(sum(a * p / 1e8 / 1e18 for _, a, p in toks), 2)
    out["core"] = core
    marks = {t: p / 1e8 for t, a, p in toks}
    print("core", core["tokens"], "tokens; basket $", core["basket_value_usd_marks"], flush=True)

    # 2. RU03 gate
    sample = [t for t, a, p in toks[:14]]
    rng = random.Random(4)
    sample += rng.sample([t for t, a, p in toks[120:]], 8)
    sample = list(dict.fromkeys(sample))
    gate = {"tokens": len(sample), "canTransfer": {}, "transfer": {}}
    ct = []
    for t in sample:
        calls = [(PROCESSOR, g.sel("canTransfer(address,address,uint256)") +
                  abi_encode(["address", "address", "uint256"], [WRAPPER.lower(), d.lower(), 10 ** 18]).hex())
                 for d in FRESH + WHITE]
        res = g.rpc_batch([("eth_call", [{"to": c[0], "from": t, "data": c[1]}, hex(block)]) for c in calls])
        for d, r in zip(FRESH + WHITE, res):
            if isinstance(r, str) and len(r) >= 194:
                v = g.abi_decode(["bool", "uint256", "uint256"], bytes.fromhex(r[2:]))
                ct.append({"token": t, "dest": d, "allowed": v[0], "rule_id": v[1], "reason": v[2]})
    for label, group in [("fresh", FRESH), ("whitelisted", WHITE)]:
        rows = [x for x in ct if x["dest"] in group]
        gate["canTransfer"][label] = {"probes": len(rows),
                                      "allowed": sum(1 for x in rows if x["allowed"]),
                                      "denied": sum(1 for x in rows if not x["allowed"]),
                                      "denied_rule_ids": sorted({x["rule_id"] for x in rows if not x["allowed"]})}
    tr = []
    for t in sample[:6]:
        for d in FRESH + WHITE:
            try:
                g.eth_call(t, g.sel("transfer(address,uint256)") +
                           abi_encode(["address", "uint256"], [d.lower(), 10 ** 18]).hex(),
                           block=block, frm=WRAPPER)
                tr.append({"token": t, "dest": d, "result": "OK"})
            except Exception as e:  # noqa: BLE001
                s = str(e)
                tr.append({"token": t, "dest": d, "result": "RU03" if "RU03" in s else "REVERT"})
    for label, group in [("fresh", FRESH), ("whitelisted", WHITE)]:
        rows = [x for x in tr if x["dest"] in group]
        gate["transfer"][label] = {"probes": len(rows),
                                   "OK": sum(1 for x in rows if x["result"] == "OK"),
                                   "RU03": sum(1 for x in rows if x["result"] == "RU03")}
    out["ru03_gate"] = gate
    print("gate", json.dumps(gate["canTransfer"]), json.dumps(gate["transfer"]), flush=True)

    # 3. Yam book sample + 30d fills
    count = g.dec(["uint256"], g.call(YAM, "getOfferCount()(uint256)", block=block))[0]
    ids = list(range(max(0, count - 1500), count)) + rng.sample(range(0, max(0, count - 1500)), 500)
    ids = sorted(set(ids))
    sig = "getInitialOffer(uint256)(address,address,address,address,uint256,uint256)"
    res = g.multicall([(YAM, g.sel(sig) + abi_encode(["uint256"], [i]).hex()) for i in ids], block=block)
    offers = {}
    for i, (ok, ret) in zip(ids, res):
        if ok and len(ret) >= 192:
            v = g.abi_decode(["address", "address", "address", "address", "uint256", "uint256"], ret)
            offers[i] = (v[0].lower(), v[1].lower(), v[4], v[5])
    bids = []
    for i, (ot, bt, price, amount) in offers.items():
        if amount == 0 or price == 0:
            continue
        if bt in marks and ot not in marks:
            face = 1e18 / price
            bids.append({"id": i, "token": bt, "ccy": ot, "ratio_face": face / marks[bt],
                         "cash": ot in STABLE})
    show_sig = "showOffer(uint256)(address,address,address,address,uint256,uint256)"
    res2 = g.multicall([(YAM, g.sel(show_sig) + abi_encode(["uint256"], [b["id"]]).hex()) for b in bids],
                       block=block)
    for b, (ok, ret) in zip(bids, res2):
        b["available"] = str(g.abi_decode(["address", "address", "address", "address", "uint256", "uint256"],
                                          ret)[5]) if (ok and len(ret) >= 192) else "0"
        b["live"] = int(b["available"]) > 0
    live_cash = sorted([b for b in bids if b["live"] and b["cash"]], key=lambda x: -x["ratio_face"])
    live_all = sorted([b for b in bids if b["live"]], key=lambda x: -x["ratio_face"])
    out["yam"] = {
        "offer_count": count,
        "sampled": len(ids),
        "bids_sampled": len(bids),
        "live_cash_bids": len(live_cash),
        "best_live_cash_bid": live_cash[0] if live_cash else None,
        "best_live_bid_any_currency": live_all[0] if live_all else None,
        "live_cash_bids_ge_0_4x": [b for b in live_cash if b["ratio_face"] >= 0.4][:10],
        "live_cash_bids_ge_0_909x": [b for b in live_cash if b["ratio_face"] >= 0.909][:10],
    }
    # fills last 30d
    frm = block - int(30 * 24 * 3600 / 5)
    logs = []
    b0 = frm
    while b0 <= block:
        e = min(b0 + 150_000, block)
        try:
            logs.extend(g.rpc("eth_getLogs", [{"address": YAM, "fromBlock": hex(b0), "toBlock": hex(e),
                                               "topics": [TOPIC_ACCEPTED]}]))
        except Exception:  # noqa: BLE001
            pass
        b0 = e + 1
    ratios = []
    for l in logs:
        try:
            ot, bt, price, amount = g.abi_decode(["address", "address", "uint256", "uint256"],
                                                 bytes.fromhex(l["data"][2:]))
        except Exception:  # noqa: BLE001
            continue
        ot, bt = ot.lower(), bt.lower()
        if ot in marks:
            cur = bt
            face = price / (10 ** 6 if cur in ("0xddafbb505ad214d7b80b1f830fccc89b60fb7a83",
                                               "0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1") else 10 ** 18)
            adj = face * (IMPAIR if cur not in STABLE else 1.0)
            ratios.append({"ratio_face": face / marks[ot], "ratio_cash": adj / marks[ot],
                           "cash": cur in STABLE})
        elif bt in marks:
            cur = ot
            face = 1e18 / price if price else 0
            adj = face * (IMPAIR if cur not in STABLE else 1.0)
            ratios.append({"ratio_face": face / marks[bt], "ratio_cash": adj / marks[bt],
                           "cash": cur in STABLE})
    cash = sorted(x["ratio_cash"] for x in ratios if x["cash"])
    face = sorted(x["ratio_face"] for x in ratios)
    def q(a, p):
        return round(a[max(0, min(len(a) - 1, int(p * (len(a) - 1))))], 4) if a else None
    out["yam"]["fills_30d"] = {
        "count": len(logs), "realtoken_fills": len(ratios), "cash_fills": len(cash),
        "cash_median": q(cash, .5), "cash_p90": q(cash, .9), "cash_max": cash[-1] if cash else None,
        "face_median": q(face, .5), "face_p90": q(face, .9), "face_max": face[-1] if face else None,
        "cash_ge_0909": sum(1 for x in cash if x >= 0.909),
        "face_ge_0909": sum(1 for x in face if x >= 0.909),
    }
    print("yam", json.dumps(out["yam"], indent=1)[:1200], flush=True)

    # 4. IBP
    ibp = {"source": "https://realt.co/sell-orders/",
           "fetched_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
    try:
        r = requests.get("https://realt.co/sell-orders/", headers={"user-agent": "Mozilla/5.0"}, timeout=40)
        html = r.text
        ibp["http_status"] = r.status_code
        m = re.search(r'"sell_tokens_settings":\{"allow_sell_orders":"([^"]*)"', html)
        ibp["allow_sell_orders"] = m.group(1) if m else None
        m2 = re.search(r'"disabled_notice":"([^"]*)"', html)
        ibp["disabled_notice"] = m2.group(1)[:300] if m2 else None
        ibp["paused_notice_present"] = "temporarily paused token buyback" in html.lower()
    except Exception as e:  # noqa: BLE001
        ibp["error"] = str(e)[:200]
    out["ibp"] = ibp
    print("ibp", json.dumps(ibp)[:400], flush=True)

    os.makedirs(os.path.join(ROOT, "ci-out"), exist_ok=True)
    p = os.path.join(ROOT, "ci-out", "ci_check.json")
    json.dump(out, open(p, "w"), indent=2)
    print("wrote", p, flush=True)


if __name__ == "__main__":
    main()
