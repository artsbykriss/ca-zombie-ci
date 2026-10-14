"""Fetch Borrow events for the liquidation-relevant markets only (Etherscan V2).

Target markets (debt market oracle refreshable AND borrow not paused):
  c1 oETH#2   0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389
  c2 oETHV2   0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e
  c4 oETHV2   0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa
  c3 DETH     0xa3135b76c28b3971b703a5e6cd451531b187eb5a
  c1 USDB     0x9aecedcd6a82d26f2f86d331b17a1c1676442a87 (context: dead oracle)
Writes to LOG_DIR/<market>_Borrow.json (existing files are reused).
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
LOGDIR = os.environ.get("LOG_DIR", os.path.join(HERE, "logs"))
KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
BT = "0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80"

MARKETS = [
    "0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389",
    "0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e",
    "0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa",
    "0xa3135b76c28b3971b703a5e6cd451531b187eb5a",
    "0x9aecedcd6a82d26f2f86d331b17a1c1676442a87",
]


def fetch_page(m, page, offset=1000, tries=4):
    q = urllib.parse.urlencode({"chainid": 81457, "module": "logs", "action": "getLogs",
                                "address": m, "topic0": BT, "fromBlock": 0, "toBlock": "latest",
                                "page": page, "offset": offset, "apikey": KEY})
    for _ in range(tries):
        try:
            req = urllib.request.Request(f"https://api.etherscan.io/v2/api?{q}",
                                         headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                j = json.loads(r.read())
            res = j.get("result") or []
            return res if isinstance(res, list) else []
        except Exception:  # noqa: BLE001
            time.sleep(2)
    return []


def main():
    os.makedirs(LOGDIR, exist_ok=True)
    for m in MARKETS:
        f = os.path.join(LOGDIR, f"{m}_Borrow.json")
        if os.path.exists(f):
            try:
                n = len(json.load(open(f)))
                print(f"{m} cached {n}", flush=True)
                continue
            except Exception:  # noqa: BLE001
                pass
        all_logs = []
        page = 1
        while page <= 15:
            res = fetch_page(m, page)
            if not res:
                break
            all_logs.extend(res)
            print(f"  {m} page {page}: {len(res)}", flush=True)
            if len(res) < 1000:
                break
            page += 1
            time.sleep(0.4)
        json.dump(all_logs, open(f, "w"))
        print(f"{m} borrow_events={len(all_logs)}", flush=True)
    print("DONE", flush=True)


if __name__ == "__main__":
    main()
