#!/usr/bin/env python3
"""Whole-history log scan for Segment opBNB markets (50k chunks, batched, resumable)."""
import json, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import RPCS, block_number
import urllib.request

MKTS = ["0xfe62ba7400d902A9773dA9F7469dA457cF54a565",
        "0x7ADd376cF7b33B7d09B0F0f4Ef0a741C3cB95102",
        "0x81b98b2896f1F262714F12Be36264AA8E02A08D2",
        "0x567558167F102BB45c0437F1Fd5a527c5c534c3C",
        "0x7e844423510A5081DE839e600F7960C7cE84eb82"]
TOPICS = ["0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80",
          "0xb4c03061fb5b7fed76389d5af8f2e0ddb09f8c70d1333abbb62582835e10accb",
          "0xa24ddbdf0865ba440d364725c062eac72a908faeedffc33fe64d4640c82e3ab8",
          "0xbd5034ffbd47e4e72a94baa2cdb74c6fad73cb3bcdc13036b72ec8306f5a7646",
          "0x1a2a22cb034d26d1854bdc6666a5b91fe25efbbb5dcad3b0355478d6f5c362a1",
          "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52",
          "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
          "0x8ab5fde7c5be61dc8bf79f3a8004ddf869905e9b5d9a358639c73e4c84cc1aee",
          "0x4dec04e750ca11537cabcd8a9eab06494de08da3735bc8871cd41250e190bc04"]
CHUNK = 50000
BATCH = 10
STATE = "/tmp/opencode/scan_state.json"
OUT = "/tmp/opencode/segment_logs.jsonl"

def post(url, payload, timeout=90):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "research/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)

def main():
    tip = block_number()
    nchunks = tip // CHUNK + 1
    done = 0
    if os.path.exists(STATE):
        done = json.load(open(STATE)).get("done", 0)
    print(f"tip={tip} chunks={nchunks} resuming at {done}", flush=True)
    out = open(OUT, "a")
    start = time.time()
    c = done
    while c < nchunks:
        payload = []
        ids = []
        for i in range(BATCH):
            cc = c + i
            if cc >= nchunks:
                break
            lo = cc * CHUNK
            hi = min(lo + CHUNK - 1, tip)
            payload.append({"jsonrpc": "2.0", "id": cc, "method": "eth_getLogs",
                            "params": [{"fromBlock": hex(lo), "toBlock": hex(hi),
                                        "address": MKTS, "topics": [TOPICS]}]})
            ids.append(cc)
        resp = None
        for attempt in range(10):
            try:
                resp = post(RPCS[attempt % 2], payload)
                if any("error" in it and it["error"].get("code") in (-32005, -32602) and "exceed" not in str(it["error"]) for it in resp):
                    # rate limited -> retry with backoff
                    resp = None
                    raise RuntimeError("rate limited")
                break
            except Exception as e:
                print("retry", attempt, str(e)[:120], flush=True)
                time.sleep(1.5 * (attempt + 1))
        if resp is None:
            raise RuntimeError("batch failed")
        ok = 0
        for item in resp:
            if "result" in item and isinstance(item["result"], list) and item["result"]:
                for lg in item["result"]:
                    lg["_chunk"] = item["id"]
                    out.write(json.dumps(lg) + "\n")
                ok += len(item["result"])
            elif "error" in item:
                if "exceed" in str(item.get("error", {})):
                    print("RANGE ERR at chunk", c, "-> reduce CHUNK", flush=True)
                    return
                raise RuntimeError(str(item["error"]))
        out.flush()
        c += BATCH
        time.sleep(0.05)
        json.dump({"done": c, "tip": tip}, open(STATE, "w"))
        if c % 500 == 0 or c >= nchunks:
            el = time.time() - start
            print(f"progress {c}/{nchunks} logs_found={ok} elapsed={el:.0f}s", flush=True)
    out.close()
    print("DONE", flush=True)

if __name__ == "__main__":
    main()
