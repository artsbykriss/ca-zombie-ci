#!/usr/bin/env python3
"""Create shard states for the explorer tx crawler (per market, disjoint ranges).

Reads existing era-positions-txstate-<label>.json, writes
era-positions-txstate-<label>-<tag>.json with seeded done windows and a fresh
250k-window queue for the shard range.
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
LATEST = 72_477_000
WIN = 250_000

SHARDS = {
    "rfUSDCe": [("a", 1_900_000, 25_000_000), ("b", 25_000_001, 50_000_000), ("c", 50_000_001, LATEST)],
    "rfWBTC":  [("a", 1_900_000, 40_000_000), ("b", 40_000_001, LATEST)],
    "rfETH":   [("a", 1_900_000, 40_000_000), ("b", 40_000_001, LATEST)],
    "rfUSDT":  [("a", 1_900_000, LATEST)],
    "rfZK":    [("a", 1_900_000, LATEST)],
    "rfUSDC":  [("a", 1_900_000, LATEST)],
}


def windows(lo, hi, win=WIN):
    out = []
    x = lo
    while x <= hi:
        out.append([x, min(x + win - 1, hi)])
        x += win
    return out


def main():
    for label, shards in SHARDS.items():
        main_state = os.path.join(HERE, f"era-positions-txstate-{label}.json")
        done_main = []
        if os.path.exists(main_state):
            st = json.load(open(main_state))
            done_main = [(lo, hi) for lo, hi, n in st.get("done", [])]
        for tag, lo, hi in shards:
            sp = os.path.join(HERE, f"era-positions-txstate-{label}-{tag}.json")
            if os.path.exists(sp):
                continue
            done = [(max(lo, a), min(hi, b)) for a, b in done_main if b >= lo and a <= hi]
            done.sort()
            # merge
            merged = []
            for a, b in done:
                if merged and a <= merged[-1][1] + 1:
                    merged[-1][1] = max(merged[-1][1], b)
                else:
                    merged.append([a, b])
            queue = []
            cur = lo
            for a, b in merged:
                if a > cur:
                    queue += windows(cur, a - 1)
                cur = max(cur, b + 1)
            if cur <= hi:
                queue += windows(cur, hi)
            json.dump({"queue": queue, "done": [[a, b, -1] for a, b in merged], "failed": [],
                       "n_txs": 0, "partial_windows": []}, open(sp, "w"), indent=1)
            print(f"{label}-{tag}: range {lo}-{hi}, seeded done {len(merged)}, queue {len(queue)}")


if __name__ == "__main__":
    main()
