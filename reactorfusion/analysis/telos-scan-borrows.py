#!/usr/bin/env python3
"""Scan comptroller Borrow/RepayBorrow/LiquidateBorrow logs on Telos (adaptive chunking).
Writes telos-logs-comptroller-*.json and telos-borrowers.json. HTTP only, no secrets."""
import json, os, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import _keccak

OUT = os.path.dirname(os.path.abspath(__file__))
API = "https://api.teloscan.io/api"
C = "0x19646a04bfdcf3553adc8faaf8b16d76ec41e494"

def topic(sig):
    return "0x" + _keccak(sig.encode()).hex()

TOPICS = {
    "Borrow": topic("Borrow(address,address,uint256,uint256,uint256,uint256)"),
    "RepayBorrow": topic("RepayBorrow(address,address,address,uint256,uint256,uint256,uint256)"),
    "LiquidateBorrow": topic("LiquidateBorrow(address,address,address,uint256,address,uint256)"),
}

def api_get(url, tries=8):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research"})
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read())
        except Exception as e:
            last = e
            time.sleep(1.5 * (i + 1))
    raise last

def get_logs(address, t0, start, end):
    url = f"{API}?module=logs&action=getLogs&address={address}&fromBlock={start}&toBlock={end}&topic0={t0}"
    j = api_get(url)
    if j.get("status") == "0":
        return []
    return j.get("result") or []

def fetch_range(address, t0, start, end, acc, depth=0):
    logs = get_logs(address, t0, start, end)
    if len(logs) >= 1000 and end > start and depth < 24:
        mid = (start + end) // 2
        fetch_range(address, t0, start, mid, acc, depth + 1)
        fetch_range(address, t0, mid + 1, end, acc, depth + 1)
    else:
        acc.extend(logs)

def decode_addr(word):
    return "0x" + word[-40:]

def main():
    rpc_req = urllib.request.Request("https://rpc.telos.net", data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 research"})
    with urllib.request.urlopen(rpc_req, timeout=30) as r:
        head = int(json.loads(r.read())["result"], 16)
    start = 300_000_000
    print("head", head, flush=True)

    result = {"head": head, "topics": TOPICS, "counts": {}, "borrowers": [], "liquidations": []}
    all_borrowers = set()
    only = sys.argv[1:] if len(sys.argv) > 1 else None
    for label, t0 in TOPICS.items():
        if only and label not in only:
            # load existing file to keep borrower extraction working
            p = os.path.join(OUT, f"telos-logs-comptroller-{label}.json")
            if os.path.exists(p):
                logs = json.load(open(p))
                result["counts"][label] = len(logs)
                print(f"{label}: loaded {len(logs)} existing logs", flush=True)
                for l in logs:
                    d = l["data"][2:]
                    if label == "Borrow":
                        all_borrowers.add(decode_addr(d[64:128]))
                    elif label == "LiquidateBorrow":
                        all_borrowers.add(decode_addr(d[128:192]))
                    else:
                        all_borrowers.add(decode_addr(d[64:128]))
            continue
        t0s = time.time()
        acc = []
        fetch_range(C, t0, start, head, acc)
        seen = {}
        for l in acc:
            seen[(l["transactionHash"], l.get("logIndex"))] = l
        logs = sorted(seen.values(), key=lambda l: (int(l["blockNumber"], 16), int(l.get("logIndex", "0x0"), 16)))
        with open(os.path.join(OUT, f"telos-logs-comptroller-{label}.json"), "w") as f:
            json.dump(logs, f)
        result["counts"][label] = len(logs)
        print(f"{label}: {len(logs)} logs in {time.time()-t0s:.0f}s", flush=True)
        for l in logs:
            d = l["data"][2:]
            if label == "Borrow":
                # (cToken, borrower, ...)
                ctoken = decode_addr(d[0:64]); borrower = decode_addr(d[64:128])
                amt = int(d[128:192], 16); account_borrows = int(d[192:256], 16); total = int(d[256:320], 16)
                all_borrowers.add(borrower)
                result.setdefault("borrow_events", []).append({"block": int(l["blockNumber"], 16), "ctoken": ctoken, "borrower": borrower, "amount": amt, "accountBorrows": account_borrows, "totalBorrows": total, "tx": l["transactionHash"]})
            elif label == "LiquidateBorrow":
                # (cToken, liquidator, borrower, repayAmount, cTokenCollateral, seizeTokens)
                ctoken = decode_addr(d[0:64]); liquidator = decode_addr(d[64:128]); borrower = decode_addr(d[128:192])
                repay = int(d[192:256], 16); coll = decode_addr(d[256:320]); seize = int(d[320:384], 16)
                all_borrowers.add(borrower)
                result["liquidations"].append({"block": int(l["blockNumber"], 16), "ctoken": ctoken, "liquidator": liquidator, "borrower": borrower, "repayAmount": repay, "ctokenCollateral": coll, "seizeTokens": seize, "tx": l["transactionHash"]})
            else:  # RepayBorrow (cToken indexed in topics[1])
                ctoken = decode_addr(l["topics"][1]); payer = decode_addr(d[0:64]); borrower = decode_addr(d[64:128])
                repay = int(d[128:192], 16)
                result.setdefault("repay_events", []).append({"block": int(l["blockNumber"], 16), "ctoken": ctoken, "payer": payer, "borrower": borrower, "repayAmount": repay, "tx": l["transactionHash"]})
                all_borrowers.add(borrower)
    result["borrowers"] = sorted(all_borrowers)
    print("unique borrowers:", len(all_borrowers))
    with open(os.path.join(OUT, "telos-borrowers.json"), "w") as f:
        json.dump(result, f, indent=1)

if __name__ == "__main__":
    main()
