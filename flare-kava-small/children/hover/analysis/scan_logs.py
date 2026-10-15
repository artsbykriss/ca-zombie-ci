#!/usr/bin/env python3
"""Scan hUSDT/hATOM/hKAVA market logs for Borrow/Mint/Redeem/LiquidateBorrow events.
Usage: python3 scan_logs.py <market> <topic0> <startHint> [--coarse]
Coarse: probe 10k windows every 500k blocks to find first activity.
"""
import json, sys, time, urllib.request

RPC = "https://kava-evm-rpc.publicnode.com"
TOPICS = {
    "Borrow": "0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80",
    "Mint": "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f",
    "Redeem": "0xbd5034ffbd47e4e72a94baa2cdb74c6fad73cb3bcdc13036b72ec8306f5a7646",
    "LiquidateBorrow": "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52",
    "Transfer": "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
}

def rpc(method, params, tries=4):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(tries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                out = json.loads(r.read())
            if "result" in out: return out["result"]
            last = out.get("error")
            if last and "exceed maximum" in str(last): 
                time.sleep(0.5); continue
        except Exception as e:
            last = e
        time.sleep(0.7)
    raise RuntimeError(f"{method} failed: {last}")

def get_logs(addr, topic0, lo, hi, chunk=10000):
    out=[]
    b=lo
    while b <= hi:
        top = min(b+chunk-1, hi)
        params = {"fromBlock": hex(b), "toBlock": hex(top), "address": addr}
        if topic0: params["topics"] = [topic0]
        res = rpc("eth_getLogs", [params])
        out.extend(res)
        b = top+1
    return out

if __name__ == "__main__":
    mode = sys.argv[1]
    if mode == "coarse":
        addr = sys.argv[2]; ev = sys.argv[3]
        topic = TOPICS[ev]
        step = 500000
        found=None
        b = 10000000
        tip = int(rpc("eth_blockNumber", []),16)
        while b < tip:
            hi = min(b+9999, tip)
            res = rpc("eth_getLogs", [{"fromBlock": hex(b), "toBlock": hex(hi), "address": addr, "topics":[topic]}])
            if res:
                print(f"first activity window: {b}-{hi} ({len(res)} events)")
                found=b; break
            b += step
        if not found: print("no activity found")
    elif mode == "scan":
        addr = sys.argv[2]; ev = sys.argv[3]; lo=int(sys.argv[4]); hi=int(sys.argv[5]) if len(sys.argv)>5 else None
        tip = int(rpc("eth_blockNumber", []),16)
        if hi is None: hi = tip
        res = get_logs(addr, TOPICS[ev], lo, hi)
        out = f"logs_{addr}_{ev}_{lo}_{hi}.json"
        json.dump(res, open(out,"w"), indent=0)
        print(f"{len(res)} events -> {out}")
