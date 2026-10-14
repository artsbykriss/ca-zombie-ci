#!/usr/bin/env python3
"""Scan recent blocks for Saddle TokenSwap/AddLiquidity/RemoveLiquidity events on MinMax pools
(read-only; proves the call paths are live and who uses them)."""
import json, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

RPC = "https://babel-api.mainnet.iotex.io"
TOPICS = {
 "TokenSwap": "0xc6c1e0630dbe9130cc068028486c0d118ddcea348550819defd5cb8c257f8a38",
 "TokenAddLiquidity": "0xde4be9fadea9049e5b3573196f666d473d1a63e93d5f9f5a031f768b66e5488f",
 "TokenRemoveLiquidity": "0xcf0404f532398248f163842c3b795a7fe2151093134f1096b80587ea5ec50aa8",
}
POOLS = {
 "P1_E4": "0x89963FCD25Cd3b369A2e0642521BCA7Cf0B9d547",
 "P2_XIM": "0x2c1B1DE747043f7C7c8e0896EB33b09eD9ED55c5",
 "P3_E3": "0xC264ED05ed2aF451732EF05C480d9e51b92a07aC",
 "P5_B3": "0x09A1B7d922BcfECa097b06498Bc992A83b0BCc42",
 "P6_XIM": "0xe409587F043f74e47eFB0C10aAf40808D4e037cE",
 "P7_USDT": "0x074ec23e80bd1fd26b822305614fb10b97847a35",
 "P9_M3": "0xdab7B4D2CA330dde50ce611E2177271fD3Eb3F5F",
 "P11_XIM": "0x73541e9ffb9F4B8d13C2E5621b1Cede1981aD0d9",
 "A8D_io3": "0xA8D60c3574f2A3f32bA6226939Df15092DD03617",
}

def rpc(method, params, retries=3):
    for _ in range(retries + 1):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(0.5)
    return {}

def scan(args):
    pool, name, topic_name, lo, hi = args
    d = rpc("eth_getLogs", [{"fromBlock": hex(lo), "toBlock": hex(hi), "address": pool, "topics": [TOPICS[topic_name]]}])
    if "result" not in d:
        return pool, name, topic_name, None, d.get("error")
    return pool, name, topic_name, d["result"], None

if __name__ == "__main__":
    bn = int(rpc("eth_blockNumber", {})["result"], 16)
    # 6 windows x 3000 blocks = 18k blocks (~25h) for the active pools only (bounded call count)
    windows = [(bn - (k + 1) * 3000, bn - k * 3000) for k in range(6)]
    ACTIVE = {k: v for k, v in POOLS.items() if k in ("P1_E4", "P2_XIM", "P3_E3", "P5_B3", "P6_XIM", "P7_USDT", "P9_M3", "P11_XIM", "A8D_io3")}
    jobs = []
    for pool, name in ACTIVE.items():
        for tname in TOPICS:
            for lo, hi in windows:
                jobs.append((pool, name, tname, lo, hi))
    print("jobs:", len(jobs), flush=True)
    counts = {}
    errors = {}
    samples = []
    with ThreadPoolExecutor(max_workers=6) as ex:
        for pool, name, tname, logs, err in ex.map(scan, jobs):
            if err is not None:
                errors[f"{name}|{tname}"] = errors.get(f"{name}|{tname}", 0) + 1
                continue
            if logs:
                counts[(name, tname)] = counts.get((name, tname), 0) + len(logs)
                for L in logs[:3]:
                    samples.append({"pool": name, "event": tname, "block": int(L["blockNumber"], 16),
                                    "tx": L["transactionHash"], "topics": L["topics"][:2], "data": L["data"][:130]})
    out = {"block": hex(bn), "window_blocks": 18000, "counts": {f"{k[0]}|{k[1]}": v for k, v in counts.items()},
           "errors": errors, "samples": samples}
    json.dump(out, open(sys.argv[1] if len(sys.argv) > 1 else "events.json", "w"), indent=1)
    print(json.dumps(out["counts"], indent=1))
    print("errors:", errors)
    print("samples:", len(samples))
