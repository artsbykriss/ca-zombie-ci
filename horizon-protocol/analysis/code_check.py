#!/usr/bin/env python3
"""Check which resolver addresses have code; fetch owner() where available.
Public RPC only."""
import json, time
import bsc

SEL = {
    "owner()": "0x8da5cb5b",
    "target()": "0xc5c16b4b" if False else None,
}

def main():
    res = json.load(open("resolver-enum.json"))
    addrs = sorted(set(res.values()))
    # get code for each
    reqs = [{"jsonrpc": "2.0", "id": i, "method": "eth_getCode", "params": [a, "latest"]} for i, a in enumerate(addrs)]
    body = json.dumps(reqs).encode()
    import urllib.request
    for rpc in ["https://bsc-rpc.publicnode.com", "https://bsc-mainnet.public.blastapi.io"]:
        try:
            r = urllib.request.Request(rpc, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(r, timeout=45) as resp:
                out = json.loads(resp.read())
            break
        except Exception as e:
            print("retry", e)
            time.sleep(2)
    codes = {}
    for d in out:
        codes[d["id"]] = d.get("result", "")
    info = {}
    for i, a in enumerate(addrs):
        c = codes.get(i, "0x")
        info[a] = {"code_len": (len(c) - 2) // 2, "live": len(c) > 2}
    json.dump(info, open("code-check.json", "w"), indent=1, sort_keys=True)
    for a, v in info.items():
        print(f"{a} code={v['code_len']} live={v['live']}")

if __name__ == "__main__":
    main()
