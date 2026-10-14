#!/usr/bin/env python3
"""Scan Teloscan logs for ReactorFusion Telos markets: all holders (Transfer) and
borrowers (comptroller Borrow/LiquidateBorrow). Read-only, HTTP only, no secrets.
Adaptive block-range splitting to defeat the 1000-log cap.
Writes telos-logs-*.json and telos-addresses.json."""
import json, os, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpclib import _keccak

OUT = os.path.dirname(os.path.abspath(__file__))
API = "https://api.teloscan.io/api"

COMPTROLLER = "0x19646a04bfdcf3553adc8faaf8b16d76ec41e494"
MARKETS = {
    "rfUSDC": "0xa6a5fe78a12ae40bed9300da6de624c089f77ac2",
    "rfUSDT": "0x3d187a993d946f196429c83f9a1831513ac2d2be",
    "rfETH": "0xce08cff82fb1b6902a7dca2ccd2d164bc2b5b1cd",
    "rfTLOS": "0x7d94d2f6f91ed5ed0104d89b3d263026d990ac5f",
}

def topic(sig):
    return "0x" + _keccak(sig.encode()).hex()

TOPICS = {
    "Transfer": topic("Transfer(address,address,uint256)"),
    "Borrow": topic("Borrow(address,address,uint256,uint256,uint256,uint256)"),
    "RepayBorrow": topic("RepayBorrow(address,address,address,uint256,uint256,uint256,uint256)"),
    "LiquidateBorrow": topic("LiquidateBorrow(address,address,address,uint256,address,uint256)"),
}

def api_get(url, tries=5):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research"})
            with urllib.request.urlopen(req, timeout=45) as r:
                return json.loads(r.read())
        except Exception as e:
            last = e
            time.sleep(1.0 * (i + 1))
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

def main():
    # head via JSON-RPC (explorer proxy endpoint 400s)
    rpc_req = urllib.request.Request("https://rpc.telos.net", data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 research"})
    with urllib.request.urlopen(rpc_req, timeout=30) as r:
        head = int(json.loads(r.read())["result"], 16)
    start = 300_000_000
    print("head", head)
    summary = {"head": head, "scan_start": start, "topics": TOPICS, "counts": {}}
    addresses = {"borrowers": set(), "holders": set()}

    jobs = []
    for name, addr in MARKETS.items():
        jobs.append((f"{name}.Transfer", addr, TOPICS["Transfer"]))
    jobs.append(("comptroller.Borrow", COMPTROLLER, TOPICS["Borrow"]))
    jobs.append(("comptroller.RepayBorrow", COMPTROLLER, TOPICS["RepayBorrow"]))
    jobs.append(("comptroller.LiquidateBorrow", COMPTROLLER, TOPICS["LiquidateBorrow"]))

    for label, addr, t0 in jobs:
        t0s = time.time()
        acc = []
        try:
            fetch_range(addr, t0, start, head, acc)
        except Exception as e:
            summary["counts"][label] = f"ERROR {e}"
            print(label, "ERROR", e)
            continue
        # dedupe by (txhash, logIndex)
        seen = {}
        for l in acc:
            seen[(l["transactionHash"], l.get("logIndex"))] = l
        logs = sorted(seen.values(), key=lambda l: (int(l["blockNumber"], 16), int(l.get("logIndex", "0x0"), 16)))
        with open(os.path.join(OUT, f"telos-logs-{label}.json"), "w") as f:
            json.dump(logs, f)
        summary["counts"][label] = len(logs)
        print(f"{label}: {len(logs)} logs in {time.time()-t0s:.0f}s")

        if label.endswith(".Transfer"):
            for l in logs:
                for t in l["topics"][1:3]:
                    a = "0x" + t[-40:]
                    if a != "0x0000000000000000000000000000000000000000":
                        addresses["holders"].add(a)
        elif label in ("comptroller.Borrow", "comptroller.LiquidateBorrow"):
            for l in logs:
                d = l["data"][2:]
                # Borrow: cToken, borrower, ... ; LiquidateBorrow: cToken, liquidator, borrower, ...
                borrower = "0x" + d[64:128][24:] if label == "comptroller.Borrow" else "0x" + d[128:192][24:]
                if borrower != "0x0000000000000000000000000000000000000000":
                    addresses["borrowers"].add(borrower)

    summary["n_borrowers"] = len(addresses["borrowers"])
    summary["n_holders"] = len(addresses["holders"])
    summary["addresses"] = {k: sorted(v) for k, v in addresses.items()}
    with open(os.path.join(OUT, "telos-addresses.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print("borrowers:", len(addresses["borrowers"]), "holders:", len(addresses["holders"]))
    print(json.dumps(summary["counts"], indent=1))

if __name__ == "__main__":
    main()
