#!/usr/bin/env python3
"""Read-only scan of NOXA LaunchLocker logs on Robinhood Chain (chain 4663).
No keys, public RPC only. Writes JSON summaries into analysis/.
Adaptive chunking to respect the RPC's 10k-log response limit.
"""
import json, time, urllib.request

RPC = "https://rpc.mainnet.chain.robinhood.com"
LOCKER = "0x7F03effbd7ceB22A3f80Dd468f67eF27826acD85"
TOPICS = {
    "FeesClaimed": "0x1547f2bd1a244399782ebde22047e2ede698ecdc4d6c7d4b3c4e2435f1e47f7a",
    "PositionLocked": "0xf3fabcec8f79e4c84abcb646b5b7eb0af5fa1fcc77977e928d8b87562cc96904",
    "FeeRedirectUpdated": "0x193b011c939ecb21a86f5a35de0149b61c53a0a2f825b8620b463b702b3a8dc6",
    "FeeCollectorUpdated": "0x7012a31b5f655fa379216a38cb9d43e11a0bbc71f686407d18a5d186729b4cbe",
}

def rpc(method, params, retries=6):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                d = json.loads(r.read())
            if "error" in d:
                raise RuntimeError(d["error"])
            return d["result"]
        except Exception as e:
            if i == retries - 1:
                raise
            time.sleep(1.0 * (i + 1))

def get_logs_chunk(topic, frm, to):
    return rpc("eth_getLogs", [{"fromBlock": hex(frm), "toBlock": hex(to), "address": LOCKER, "topics": [topic]}])

def scan(topic, frm, to, step):
    logs = []
    f = frm
    while f <= to:
        t = min(f + step - 1, to)
        try:
            got = get_logs_chunk(topic, f, t)
        except RuntimeError as e:
            if "exceeds limit" in str(e) and step > 1000:
                step = max(1000, step // 4)
                continue
            raise
        logs += got
        f = t + 1
    return logs

def main():
    tip = int(rpc("eth_blockNumber", []), 16)
    deploy = 61687
    out = {"tip": tip, "deploy": deploy, "topics": TOPICS, "by_topic": {}}
    for name, step in [("FeeCollectorUpdated", 5_000_000), ("FeeRedirectUpdated", 5_000_000), ("FeesClaimed", 250_000)]:
        logs = scan(TOPICS[name], deploy, tip, step)
        out["by_topic"][name] = logs
        print(name, len(logs), flush=True)
    for label, f, t, step in [("first", deploy, deploy + 500_000, 100_000), ("recent", tip - 2_000_000, tip, 100_000)]:
        logs = scan(TOPICS["PositionLocked"], f, t, step)
        out["by_topic"]["PositionLocked_" + label] = logs
        print("PositionLocked", label, len(logs), flush=True)
    with open("analysis/logs_rh_locker.json", "w") as fh:
        json.dump(out, fh)
    print("wrote analysis/logs_rh_locker.json")

if __name__ == "__main__":
    main()
