"""Exhaustive re-analysis of the full Yam book using the 2026-10-17 full enumeration
(/tmp/opencode/realt/v4b_offers.pkl, all 250,283 offers) + FRESH liveness checks
(showOffer) at today's block.

The book is provably unchanged since that enumeration: getOfferCount() is still
250,283 and OfferCreated/OfferDeleted/OfferAccepted since block 48,794,906 = 0/0/0
(one price update only). This script therefore gives an exhaustive, not sampled,
live-bid census.

Writes analysis/book_full.json.
"""
import json
import os
import pickle
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gnosis as g  # noqa: E402

YAM = "0xC759AA7f9dd9720A1502c104DaE4F9852bb17C14"
PKL = "/tmp/opencode/realt/v4b_offers.pkl"
A_WXDAI = "0x0ca4f5554dd9da6217d62d8df2816c82bba4157b"
A_USDC = "0xed56f76e9cbc6a64b821e9c016eafbd3db5436d1"
STABLE = {
    "0xe91d153e0b41518a2ce8dd3d7944fa863463a97d": 1.0,   # WXDAI
    "0xddafbb505ad214d7b80b1f830fccc89b60fb7a83": 1.0,   # USDC
    "0x44fa8e6f47987339850636f88629646662444217": 1.0,   # DAI
    "0x4ecaba5870353805a9f068101a40e0f32ed605c6": 1.0,   # USDT
}
IMPAIR = 0.19


def main():
    block = g.latest_block()
    ts = g.block_ts(block)
    wt = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "wrapper_tokens.json")))
    marks = {t["address"]: t["price_1e8"] / 1e8 for t in wt["tokens"]}
    rt_set = set(marks)

    book = pickle.load(open(PKL, "rb"))
    print("offers in enumeration", len(book), "block now", block)

    bids, asks = [], []
    for oid, offer_token, buyer_token, seller, buyer, price, amount in book:
        offer_token, buyer_token = offer_token.lower(), buyer_token.lower()
        if amount == 0 or price == 0:
            continue
        if buyer_token in rt_set and offer_token not in rt_set:
            mark = marks[buyer_token]
            if mark <= 0:
                continue
            # price = RealToken base units per 1 whole currency token
            face = 1e18 / price if price else 0
            cash = offer_token in STABLE and STABLE[offer_token] == 1.0
            bids.append({
                "offer_id": oid, "realtoken": buyer_token, "currency": offer_token,
                "seller": seller.lower(), "buyer": buyer.lower(), "price": str(price),
                "amount": str(amount), "cash_currency": cash,
                "ratio_face": face / mark,
                "ratio_cash": (face / mark) if cash else None,
                "ratio_impaired_sens": (face * IMPAIR / mark) if not cash and offer_token in (A_WXDAI, A_USDC) else None,
            })
        elif offer_token in rt_set and buyer_token not in rt_set:
            mark = marks[offer_token]
            if mark <= 0:
                continue
            # price = buyerToken base units per 1 whole RealToken; decimals needed
            dec = 18 if buyer_token not in ("0xddafbb505ad214d7b80b1f830fccc89b60fb7a83",) else 6
            face = price / 10 ** dec
            cash = buyer_token in STABLE
            asks.append({
                "offer_id": oid, "realtoken": offer_token, "currency": buyer_token,
                "seller": seller.lower(), "price": str(price), "amount": str(amount),
                "cash_currency": cash, "ratio_face": face / mark,
                "ratio_cash": (face / mark) if cash else None,
            })

    print("bids", len(bids), "asks", len(asks))

    # liveness candidates: every cash bid (any price) above 1% of mark, and every bid
    # that nominally looks >=0.4x (regardless of currency)
    cand = [b for b in bids if (b["cash_currency"] and b["ratio_face"] >= 0.01)
            or b["ratio_face"] >= 0.4]
    print("liveness candidates", len(cand))
    sig = "showOffer(uint256)(address,address,address,address,uint256,uint256)"
    res = g.multicall([(YAM, g.sel(sig) + g.abi_encode(["uint256"], [b["offer_id"]]).hex()) for b in cand],
                      block=block)
    for b, (ok, ret) in zip(cand, res):
        if ok and len(ret) >= 192:
            v = g.abi_decode(["address", "address", "address", "address", "uint256", "uint256"], ret)
            b["available"] = str(v[5])
        else:
            b["available"] = "0"
        b["live"] = int(b["available"]) > 0

    live = [b for b in cand if b["live"]]
    live_cash = [b for b in live if b["cash_currency"]]
    live_cash.sort(key=lambda x: -x["ratio_face"])
    live_any = sorted(live, key=lambda x: -x["ratio_face"])

    def meaningful(b):
        # size in USD at face, for cash bids: amount is currency units
        try:
            dec = 6 if b["currency"] == "0xddafbb505ad214d7b80b1f830fccc89b60fb7a83" else 18
            return int(b["available"]) / 10 ** dec
        except Exception:  # noqa: BLE001
            return 0.0

    ge04 = [b for b in live_cash if b["ratio_face"] >= 0.4]
    ge0909 = [b for b in live_cash if b["ratio_face"] >= 0.909]
    ge0909_100 = [b for b in ge0909 if meaningful(b) >= 100]

    out = {
        "chain": "gnosis", "block": block, "timestamp": ts,
        "source": "full enumeration 250,283 offers (2026-10-17) + fresh showOffer liveness",
        "offer_count": len(book),
        "book_unchanged_since": 48794906,
        "bids_total": len(bids),
        "asks_total": len(asks),
        "liveness_candidates": len(cand),
        "live_bids": len(live),
        "live_cash_bids": len(live_cash),
        "best_live_cash_bid": live_cash[0] if live_cash else None,
        "best_live_any_bid": live_any[0] if live_any else None,
        "live_cash_bids_ge_0_4x": ge04[:50],
        "live_cash_bids_ge_0_909x": ge0909[:50],
        "live_cash_bids_ge_0_909x_size100": ge0909_100[:50],
        "live_bids_ge_0_909x_any_currency": [b for b in live_any if b["ratio_face"] >= 0.909][:50],
        "top_live_cash_bids": live_cash[:40],
        "top_live_any_bids": live_any[:40],
    }
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "book_full.json")
    with open(p, "w") as f:
        json.dump(out, f, indent=2)
    print("wrote", p)
    print("live candidates", len(live), "live cash", len(live_cash),
          "cash >=0.4x", len(ge04), "cash >=0.909x", len(ge0909), "(>= $100 size:", len(ge0909_100), ")")
    if live_cash:
        b = live_cash[0]
        print("best live cash bid", b["offer_id"], "ratio", round(b["ratio_face"], 4),
              "size $", round(meaningful(b), 2), "token", b["realtoken"], "ccy", b["currency"])
    if live_any:
        b = live_any[0]
        print("best live any bid", b["offer_id"], "ratio_face", round(b["ratio_face"], 4),
              "available", b["available"], "ccy", b["currency"])


if __name__ == "__main__":
    main()
