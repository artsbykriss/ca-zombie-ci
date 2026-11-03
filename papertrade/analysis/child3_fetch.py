#!/usr/bin/env python3
"""Child 3: fetch live HL L2 books + candles. Read-only. Writes only into analysis/."""
import json, time, urllib.request, datetime, sys

BASE = "https://api.hyperliquid.xyz/info"
UA = "Mozilla/5.0 (X11; Linux x86_64) papertrade-research/1.0"

def post(payload, timeout=30):
    req = urllib.request.Request(
        BASE,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "User-Agent": UA},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def main():
    out = {}
    for coin in ("BTC", "ETH"):
        t0 = time.time()
        book = post({"type": "l2Book", "coin": coin})
        t1 = time.time()
        ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")
        rec = {
            "coin": coin,
            "fetched_at_utc": ts,
            "fetch_latency_s": round(t1 - t0, 3),
            "api_time_ms": book.get("time"),
            "response": book,
        }
        with open(f"/home/heisenberg/CA/papertrade/analysis/child3-books-{coin}.json", "w") as f:
            json.dump(rec, f, indent=1)
        bid = float(book["levels"][0][0]["px"])
        ask = float(book["levels"][1][0]["px"])
        print(coin, ts, "bid", bid, "ask", ask, "mid", (bid+ask)/2,
              "levels", len(book["levels"][0]), len(book["levels"][1]))
        out[coin] = rec

    # candles: last 24h of 1m
    now_ms = int(time.time() * 1000)
    day_ago = now_ms - 24 * 3600 * 1000
    candles = {}
    for coin in ("BTC", "ETH"):
        try:
            c = post({"type": "candleSnapshot", "req": {
                "coin": coin, "interval": "1m",
                "startTime": day_ago, "endTime": now_ms}})
            candles[coin] = {"request": {"coin": coin, "interval": "1m",
                                         "startTime": day_ago, "endTime": now_ms},
                             "fetched_at_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                             "n": len(c), "candles": c}
            print(coin, "candles", len(c))
        except Exception as e:
            print(coin, "candle error", e)
            candles[coin] = {"error": str(e)}
    with open("/home/heisenberg/CA/papertrade/analysis/child3-candles.json", "w") as f:
        json.dump(candles, f)

    # meta / funding for context + fee tier info not available unauthenticated
    try:
        meta = post({"type": "metaAndAssetCtxs"})
        with open("/home/heisenberg/CA/papertrade/analysis/child3-meta.json", "w") as f:
            json.dump({"fetched_at_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), "data": meta}, f)
        print("meta fetched")
    except Exception as e:
        print("meta error", e)

if __name__ == "__main__":
    main()
