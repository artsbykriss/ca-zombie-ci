#!/usr/bin/env python3
"""Scan token balances (direct balanceOf) of all Horizon Protocol contracts.
Public RPC only. Output: balances.json (incremental)."""
import json, time
import bsc

TOKENS = {
    "WBNB": "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",
    "BUSD": "0xe9e7cea3dedca5984780bafc599bd69add087d56",
    "USDT": "0x55d398326f99059ff775485246999027b3197955",
    "USDC": "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d",
    "BTCB": "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c",
    "ETH": "0x2170ed0880ac9a755fd29b2688956bd959f933f8",
    "CAKE": "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82",
    "HZN": "0xc0eff7749b125444953ef89682201fb8c6a917cd",
    "PHB": "0x0409633a72d846fc5bbe2f98d88564d35987904d",
}

def main():
    synths = json.load(open("synth-enum.json"))["synths"]
    for a, v in synths.items():
        TOKENS[v["currencyKey"]] = a
    res = json.load(open("resolver-enum.json"))
    addrs = sorted(set(list(res.values()) + [
        "0xa1771dcfb7822c8853d7e64b86e58f7f1eb5e33e",
        "0x67d5a94f444df4bba254645065a4137fc665bf98",
        "0x84838d0ab37857fad5979fcf6bddf8ddb1cc1da8",
        "0x5646aa2f9408c7c2ee1dc7db813c8b687a959a85",
        "0xdc9a574b9b341d4a98ce29005b614e1e27430e74",
        "0xc3bf4e0ea6b76c8edd838e14be2116c862c88bdf",
        "0x81752bc7d54a45bdb9005223d61d2cbd33d04857",
    ]))
    out = {a: {} for a in addrs}

    # native balances via eth_getBalance batches
    calls = [{"to": None, "addr": a} for a in addrs]
    for i in range(0, len(calls), 20):
        chunk = calls[i:i+20]
        reqs = [{"jsonrpc": "2.0", "id": j, "method": "eth_getBalance",
                 "params": [c["addr"], "latest"]} for j, c in enumerate(chunk)]
        import urllib.request
        for attempt in range(4):
            try:
                r = urllib.request.Request(bsc.RPCS[attempt % len(bsc.RPCS)],
                                           data=json.dumps(reqs).encode(),
                                           headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(r, timeout=30) as resp:
                    o = json.loads(resp.read())
                break
            except Exception as e:
                print("native retry", attempt, str(e)[:60], flush=True)
                time.sleep(2)
        for d in o:
            out[chunk[d["id"]]["addr"]]["BNB"] = str(int(d["result"], 16))
        print(f"native chunk {i} done", flush=True)

    # token balances
    tcalls = []
    for a in addrs:
        for sym, tok in TOKENS.items():
            tcalls.append({"to": tok, "data": "0x70a08231" + a[2:].rjust(64, "0"), "tag": f"{a}|{sym}"})
    total = len(tcalls)
    for i in range(0, total, 40):
        chunk = tcalls[i:i+40]
        r = bsc.batch(chunk)
        for j, c in enumerate(chunk):
            a, sym = c["tag"].split("|")
            v = r.get(j)
            if isinstance(v, str) and v.startswith("0x"):
                out[a][sym] = str(int(v, 16))
        if i % 400 == 0:
            json.dump(out, open("balances.json", "w"), indent=1, sort_keys=True)
            print(f"token chunk {i}/{total}", flush=True)
    json.dump(out, open("balances.json", "w"), indent=1, sort_keys=True)
    for a, toks in sorted(out.items()):
        nz = {k: v for k, v in toks.items() if int(v) > 0}
        if nz:
            print(a, json.dumps(nz), flush=True)

if __name__ == "__main__":
    main()
