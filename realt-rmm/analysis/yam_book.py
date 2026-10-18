"""Yam (RealTokenYamUpgradeableV3) book + fills re-verification. Read-only.

Components:
  A. Book sample: getInitialOffer over the newest 3,000 ids + 3,000 seeded-random ids.
     Classify bids (buyerToken = RealToken) and asks (offerToken = RealToken).
     Live-check every sampled bid with showOffer (min(amount, seller balance, allowance)).
  B. Delta scan since the v4b exhaustive enumeration block (48,794,906): OfferCreated /
     OfferUpdated / OfferDeleted / OfferAccepted events.
  C. Fill census for the last 30 days: OfferAccepted, ratio vs frozen wrapper marks.

Writes analysis/yam_book.json.
"""
import json
import os
import random
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gnosis as g  # noqa: E402

YAM = "0xC759AA7f9dd9720A1502c104DaE4F9852bb17C14"
V4B_BLOCK = 48_794_906
TOPIC_CREATED = "0x" + g.keccak(text="OfferCreated(address,address,address,address,uint256,uint256,uint256)").hex()
TOPIC_UPDATED = "0x" + g.keccak(text="OfferUpdated(uint256,uint256,uint256,uint256,uint256)").hex()
TOPIC_DELETED = "0x" + g.keccak(text="OfferDeleted(uint256)").hex()
TOPIC_ACCEPTED = "0x" + g.keccak(text="OfferAccepted(uint256,address,address,address,address,uint256,uint256)").hex()

STABLE_USD = {
    "0xe91d153e0b41518a2ce8dd3d7944fa863463a97d": 1.0,   # WXDAI
    "0xddafbb505ad214d7b80b1f830fccc89b60fb7a83": 1.0,   # USDC
    "0x44fa8e6f47987339850636f88629646662444217": 1.0,   # DAI (if used)
    "0x4ecaba5870353805a9f068101a40e0f32ed605c6": 1.0,   # USDT
    "0x3f56e0c36d275367b8c502090edf38289b3dea0d": 1.0,   # MAI
}
IMPAIRED = {
    "0xc61b352fcc3d8e2f1d4c02f6b495e0f4c8d3b7e5": 0.19,  # placeholder, replaced below
}


def get_logs(topic, frm, to, chunk=100_000):
    out = []
    b = frm
    while b <= to:
        e = min(b + chunk - 1, to)
        try:
            logs = g.rpc("eth_getLogs", [{"address": YAM, "fromBlock": hex(b), "toBlock": hex(e),
                                          "topics": [topic]}])
        except Exception as ex:  # noqa: BLE001
            print("getLogs retry", b, e, str(ex)[:80])
            time.sleep(1)
            logs = g.rpc("eth_getLogs", [{"address": YAM, "fromBlock": hex(b), "toBlock": hex(e),
                                          "topics": [topic]}])
        out.extend(logs)
        b = e + 1
        time.sleep(0.05)
    return out


def main():
    block = g.latest_block()
    ts = g.block_ts(block)
    print("block", block, "ts", ts)

    wt = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "wrapper_tokens.json")))
    marks = {t["address"]: t["price_1e8"] / 1e8 for t in wt["tokens"]}
    rt_set = set(marks)
    # stable-ish / impaired currencies actually seen in the book
    # Pool aTokens are NOT cash: the pool is ~100% utilised (supply < debt on both
    # stable reserves) so they cannot be redeemed; last observable market price for
    # aWXDAI was $0.188-0.195 (v4b §5). Treat them as impaired, with a sensitivity
    # value of 0.19 for reporting.
    A_WXDAI = "0x0ca4f5554dd9da6217d62d8df2816c82bba4157b"
    A_USDC = "0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1"
    currency_usd = dict(STABLE_USD)
    currency_usd[A_WXDAI] = None   # not realisable cash
    currency_usd[A_USDC] = None
    IMPAIR_SENS = 0.19

    # ---------- A. book sample ----------
    count = g.dec(["uint256"], g.call(YAM, "getOfferCount()(uint256)", block=block))[0]
    ids = list(range(max(0, count - 3000), count))
    rng = random.Random(20261018)
    ids += rng.sample(range(0, max(0, count - 3000)), 3000)
    ids = sorted(set(ids))
    print("offerCount", count, "sampled ids", len(ids))

    sig = "getInitialOffer(uint256)(address,address,address,address,uint256,uint256)"
    res = g.multicall([(YAM, g.sel(sig) + g.abi_encode(["uint256"], [i]).hex()) for i in ids], block=block)
    offers = {}
    for i, (ok, ret) in zip(ids, res):
        if not ok or len(ret) < 192:
            continue
        v = g.abi_decode(["address", "address", "address", "address", "uint256", "uint256"], ret)
        offers[i] = {"offer_id": i, "offer_token": v[0].lower(), "buyer_token": v[1].lower(),
                     "seller": v[2].lower(), "buyer": v[3].lower(), "price": str(v[4]),
                     "amount": str(v[5])}

    # decimals cache for non-RealToken tokens
    currencies = {o["offer_token"] for o in offers.values() if o["offer_token"] not in rt_set}
    currencies |= {o["buyer_token"] for o in offers.values() if o["buyer_token"] not in rt_set}
    dec = {}
    for c in currencies:
        try:
            dec[c] = g.dec(["uint8"], g.call(c, "decimals()(uint8)", block=block))[0]
        except Exception:  # noqa: BLE001
            dec[c] = 18
    print("currencies", len(currencies))

    bids, asks = [], []
    for o in offers.values():
        if int(o["amount"]) == 0:
            continue
        pt = o["offer_token"]
        bt = o["buyer_token"]
        pr = int(o["price"])
        if bt in rt_set and pt not in rt_set and pr > 0:
            # seller offers currency, wants RealToken: price = token base units per 1 whole currency
            usd_per_cur = currency_usd.get(pt, 1.0)
            d_tok = 18
            usd_per_tok = usd_per_cur * (10 ** d_tok) / pr if usd_per_cur is not None else None
            usd_per_tok_face = (10 ** d_tok) / pr
            mark = marks[bt]
            if mark > 0:
                o2 = dict(o, side="bid", realtoken=bt, currency=pt,
                          cash_currency=usd_per_cur is not None,
                          ratio_vs_mark_face=(usd_per_tok_face / mark),
                          ratio_vs_mark=(usd_per_tok / mark) if usd_per_tok is not None else None,
                          ratio_vs_mark_impaired_sens=(usd_per_tok_face * IMPAIR_SENS / mark)
                          if usd_per_cur is None else None)
                bids.append(o2)
        elif pt in rt_set and bt not in rt_set and pr > 0:
            usd_per_cur = currency_usd.get(bt, 1.0)
            face_per_tok = pr / 10 ** dec.get(bt, 18)
            usd_per_tok = face_per_tok * usd_per_cur if usd_per_cur is not None else None
            mark = marks[pt]
            if mark > 0:
                o2 = dict(o, side="ask", realtoken=pt, currency=bt,
                          cash_currency=usd_per_cur is not None,
                          ratio_vs_mark_face=face_per_tok / mark,
                          ratio_vs_mark=(usd_per_tok / mark) if usd_per_tok is not None else None,
                          ratio_vs_mark_impaired_sens=(face_per_tok * IMPAIR_SENS / mark)
                          if usd_per_cur is None else None)
                asks.append(o2)

    bids.sort(key=lambda x: -(x["ratio_vs_mark"] or 0))
    asks.sort(key=lambda x: (x["ratio_vs_mark"] if x["ratio_vs_mark"] is not None else 1e9))

    # live availability for all sampled bids (and the cheapest 100 asks)
    live_ids = [b["offer_id"] for b in bids] + [a["offer_id"] for a in asks[:100]]
    show_sig = "showOffer(uint256)(address,address,address,address,uint256,uint256)"
    res2 = g.multicall([(YAM, g.sel(show_sig) + g.abi_encode(["uint256"], [i]).hex()) for i in live_ids],
                       block=block)
    live = {}
    for i, (ok, ret) in zip(live_ids, res2):
        if ok and len(ret) >= 192:
            v = g.abi_decode(["address", "address", "address", "address", "uint256", "uint256"], ret)
            live[i] = {"available": str(v[5]), "price": str(v[4])}
    for b in bids:
        b["available"] = live.get(b["offer_id"], {}).get("available", "0")
        b["live"] = int(b["available"]) > 0
    for a in asks:
        a["available"] = live.get(a["offer_id"], {}).get("available", "0")
        a["live"] = int(a["available"]) > 0

    live_bids = [b for b in bids if b["live"]]
    live_bids.sort(key=lambda x: -(x["ratio_vs_mark"] if x["ratio_vs_mark"] is not None else -1))
    cash_bids = [b for b in live_bids if b["cash_currency"]]
    cash_bids.sort(key=lambda x: -(x["ratio_vs_mark"] or 0))
    best = cash_bids[0] if cash_bids else None
    best_face = live_bids[0] if live_bids else None
    ge04 = [b for b in cash_bids if (b["ratio_vs_mark"] or 0) >= 0.4]
    ge0909 = [b for b in cash_bids if (b["ratio_vs_mark"] or 0) >= 0.909]

    # ---------- B. delta since v4b ----------
    delta = {}
    for name, topic in [("created", TOPIC_CREATED), ("updated", TOPIC_UPDATED),
                        ("deleted", TOPIC_DELETED), ("accepted", TOPIC_ACCEPTED)]:
        logs = get_logs(topic, V4B_BLOCK, block)
        delta[name] = len(logs)
        print("delta", name, len(logs))
    # any OfferCreated since v4b? (offerCount equality already implies 0)
    updated_ids = sorted({int(l["topics"][1], 16) for l in get_logs(TOPIC_UPDATED, V4B_BLOCK, block)})
    touched = {}
    if updated_ids:
        sig_i = "getInitialOffer(uint256)(address,address,address,address,uint256,uint256)"
        r3 = g.multicall([(YAM, g.sel(sig_i) + g.abi_encode(["uint256"], [i]).hex()) for i in updated_ids],
                         block=block)
        for i, (ok, ret) in zip(updated_ids, r3):
            if ok and len(ret) >= 192:
                v = g.abi_decode(["address", "address", "address", "address", "uint256", "uint256"], ret)
                touched[str(i)] = {"offer_token": v[0].lower(), "buyer_token": v[1].lower(),
                                   "price": str(v[4]), "amount": str(v[5])}
    delta["updated_offers_after_v4b"] = touched
    delta["updated_realtoken_side"] = [
        {"offer_id": int(k), **v} for k, v in touched.items()
        if v["offer_token"].lower() in rt_set or v["buyer_token"].lower() in rt_set]

    # ---------- C. 30-day fill census ----------
    ts30 = block - int(30 * 24 * 3600 / 5)  # ~5 s blocks
    logs = get_logs(TOPIC_ACCEPTED, ts30, block, chunk=150_000)
    print("fills 30d", len(logs))
    fills = []
    for l in logs:
        try:
            offer_token, buyer_token, price, amount = g.abi_decode(
                ["address", "address", "uint256", "uint256"], bytes.fromhex(l["data"][2:]))
        except Exception:  # noqa: BLE001
            continue
        offer_token, buyer_token = offer_token.lower(), buyer_token.lower()
        blockn = int(l["blockNumber"], 16)
        rec = {"block": blockn, "tx": l["transactionHash"], "offer_token": offer_token,
               "buyer_token": buyer_token, "price": str(price), "amount": str(amount)}
        if offer_token in rt_set:
            mark = marks[offer_token]
            cur = currency_usd.get(buyer_token, 1.0)
            face = price / 10 ** dec.get(buyer_token, 18)
            usd = face * cur if cur is not None else None
            rec.update({"realtoken": offer_token, "direction": "ask_fill",
                        "face_usd_per_token": face,
                        "usd_per_token": usd, "ratio_vs_mark": usd / mark if (usd is not None and mark) else None,
                        "ratio_vs_mark_face": face / mark if mark else None,
                        "usd_notional": (amount / 1e18) * (usd if usd is not None else face * IMPAIR_SENS)})
        elif buyer_token in rt_set:
            mark = marks[buyer_token]
            cur = currency_usd.get(offer_token, 1.0)
            face = 1e18 / price if price else 0
            # price is RealToken base units per 1 whole currency token -> 1e18/price USD/token
            usd_per_token = cur * 1e18 / price if (price and cur is not None) else None
            rec.update({"realtoken": buyer_token, "direction": "bid_fill",
                        "face_usd_per_token": face,
                        "usd_per_token": usd_per_token,
                        "ratio_vs_mark": usd_per_token / mark if (usd_per_token is not None and mark) else None,
                        "ratio_vs_mark_face": face / mark if mark else None,
                        "usd_notional": (amount / 10 ** dec.get(offer_token, 18))
                        * (cur if cur is not None else IMPAIR_SENS)})
        else:
            continue
        fills.append(rec)

    # tag fills whose currency is an impaired aToken (parsed from the fill token ids)
    A_TOKENS = {A_WXDAI, A_USDC}
    for f in fills:
        imp = f["offer_token"] in A_TOKENS or f["buyer_token"] in A_TOKENS
        f["impaired_currency"] = imp
        face = f["ratio_vs_mark"]
        f["ratio_vs_mark_impaired_sens"] = (face * IMPAIR_SENS) if imp and face is not None else face
    ratios = sorted(r["ratio_vs_mark"] for r in fills if r["ratio_vs_mark"])
    def pct(p):
        if not ratios:
            return None
        k = max(0, min(len(ratios) - 1, int(p * (len(ratios) - 1))))
        return round(ratios[k], 5)
    def stats(key):
        rr = sorted(r[key] for r in fills if r.get(key))
        if not rr:
            return {}
        def q(p):
            return round(rr[max(0, min(len(rr) - 1, int(p * (len(rr) - 1))))], 5)
        return {"count": len(rr), "min": round(rr[0], 5), "p25": q(.25), "median": q(.5),
                "p75": q(.75), "p90": q(.90), "p99": q(.99), "max": round(rr[-1], 5)}
    fill_stats = {
        "count": len(fills),
        "impaired_currency_fills": sum(1 for r in fills if r["impaired_currency"]),
        "usd_notional_total_portfolio_value": round(sum(r["usd_notional"] for r in fills), 2),
        "realisable_cash_ratio_stats": stats("ratio_vs_mark"),
        "face_ratio_stats_all": stats("ratio_vs_mark_face"),
        "impaired_adj_ratio_stats": stats("ratio_vs_mark_impaired_sens"),
        "ge_0909_count_cash": sum(1 for r in fills if r.get("ratio_vs_mark") and r["ratio_vs_mark"] >= 0.909),
        "ge_0909_notional_cash": round(sum(r["usd_notional"] for r in fills
                                           if r.get("ratio_vs_mark") and r["ratio_vs_mark"] >= 0.909), 2),
        "ge_0909_count_face": sum(1 for r in fills if r.get("ratio_vs_mark_face") and r["ratio_vs_mark_face"] >= 0.909),
    }
    top_fills = sorted([r for r in fills if r.get("ratio_vs_mark")], key=lambda x: -x["ratio_vs_mark"])[:25]

    out = {
        "chain": "gnosis", "chain_id": 100, "block": block, "timestamp": ts,
        "yam": YAM, "offer_count": count, "offer_count_at_v4b": 250283,
        "sample": {"ids": len(ids), "bids": len(bids), "asks": len(asks),
                   "live_bids": len(live_bids), "live_asks": len(asks)},
        "live_bids_ge_0_4x": ge04[:20],
        "live_bids_ge_0_909x": ge0909[:20],
        "best_live_bid": best,
        "top_sampled_bids": bids[:30],
        "cheapest_sampled_asks": asks[:10],
        "delta_since_v4b": delta,
        "fills_30d": fill_stats,
        "fills_30d_top_ratio": top_fills,
        "fills_30d_all": fills[-2000:],
    }
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "yam_book.json")
    with open(p, "w") as f:
        json.dump(out, f, indent=2)
    print("wrote", p)
    print("sample bids", len(bids), "live bids", len(live_bids),
          "best cash live bid ratio", round(best["ratio_vs_mark"], 4) if best else None,
          "best face live bid ratio", round(best_face["ratio_vs_mark_face"], 4) if best_face else None)
    print("live bids >=0.4x", len(ge04), ">=0.909x", len(ge0909))
    print("30d fills", json.dumps(fill_stats, indent=1))
    print("delta", {k: v for k, v in delta.items() if not isinstance(v, (dict, list))})


if __name__ == "__main__":
    main()
