"""Fetch Compound-style events for all Orbit markets via Etherscan V2 (chainid 81457).

Read-only; API key read from env, never written to disk. Saves analysis/logs/*.json.
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
if not KEY:
    print("ETHERSCANV2_API_KEY missing", file=sys.stderr)
    sys.exit(1)

MARKETS = [
    # c1
    "0xf92996ddc677a8dcb032ac5fe62bbf00f92ae2ec", "0xd847b486fe612c51900f1da1a045741820dd5fa0",
    "0x9aecedcd6a82d26f2f86d331b17a1c1676442a87", "0xf9b3b455f5d900f62bc1792a6ca6e1d47b989389",
    "0x0872b71efc37cb8dde22b2118de3d800427fdba0", "0x8c415331761063e5d6b1c8e700f996b13603fc2e",
    # c2
    "0x795dcd51eac6eb3123b7a4a1f906992eaa54cb0e", "0x4991b902f397dc16b0bbd21b0057a20b4b357ae2",
    "0xb51b76c73fb24f472e0dd63bb8195bd2170bc65d",
    # c3
    "0xafabd582e82042f4a8574f75c36409abea916ac5", "0x9bbba6322fe5f3968c1f27c8b860727d683194c8",
    "0xd55634a79e571dc4c7cdd2f2c0a5857bf7a8a782", "0xfb661cdcfcb62b4ed7bbef6f70068863e213cb6b",
    "0xa3135b76c28b3971b703a5e6cd451531b187eb5a", "0x4adf85e2e760c9211894482df74ba535bcae50a4",
    "0x3a61f4bf054cdfac3a3436a21c4463c6d85c2408", "0x7732e29e35e8a8b26e7f026c0865c7c2d88cf853",
    "0x586abb06179535de9eb6c6d968a355128dd74511",
    # c4
    "0x530a8d3fdf61112f8a879d753fe02e9e37ec36aa", "0xe9391d8e1d5c970f7648852ffeda1a9f42833857",
    "0x7878c119f08052789f84cf4fdd3c3642fa291257",
]

PAGE_CAP = {"Borrow": 12, "RepayBorrow": 12, "LiquidateBorrow": 3, "Mint": 3, "Redeem": 3}

EVENTS = {
    "Borrow": "0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80",
    "RepayBorrow": "0x1a2a22cb034d26d1854bdc6666a5b91fe25efbbb5dcad3b0355478d6f5c362a1",
    "LiquidateBorrow": "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52",
    "Mint": "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f",
    "Redeem": "0xe5b754fb1abb7f01b499791d0b820ae3b6af3424ac1c59768edb53f4ec31a929",
}


def fetch_logs(addr, topic, page=1, offset=1000, from_block=0, to_block=99999999):
    q = urllib.parse.urlencode({
        "chainid": 81457, "module": "logs", "action": "getLogs", "address": addr,
        "topic0": topic, "fromBlock": from_block, "toBlock": to_block,
        "page": page, "offset": offset, "apikey": KEY})
    url = f"https://api.etherscan.io/v2/api?{q}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    for _ in range(4):
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                return json.loads(r.read())
        except Exception as e:  # noqa: BLE001
            print("  retry", e, flush=True)
            time.sleep(2)
    return {"status": "0", "message": "failed", "result": []}


def main():
    os.makedirs(LOGDIR, exist_ok=True)
    summary = {}
    for m in MARKETS:
        summary[m] = {}
        for ev, topic in EVENTS.items():
            page = 1
            all_logs = []
            while True:
                j = fetch_logs(m, topic, page=page)
                res = j.get("result") or []
                if not isinstance(res, list) or not res:
                    break
                all_logs.extend(res)
                if len(res) < 1000:
                    break
                page += 1
                time.sleep(0.3)
                if page > PAGE_CAP.get(ev, 5):
                    print(f"  {m} {ev}: truncated at page cap", flush=True)
                    break
            summary[m][ev] = len(all_logs)
            with open(os.path.join(LOGDIR, f"{m}_{ev}.json"), "w") as f:
                json.dump(all_logs, f)
            print(f"{m} {ev}: {len(all_logs)}", flush=True)
            time.sleep(0.25)
    with open(os.path.join(LOGDIR, "summary.json"), "w") as f:
        json.dump(summary, f, indent=1)


if __name__ == "__main__":
    main()
