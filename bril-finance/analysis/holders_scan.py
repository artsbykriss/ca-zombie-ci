#!/usr/bin/env python3
"""Compute current share holders for each Bril/ICHI vault from full ERC20 transfer history
via Alchemy getAssetTransfers (BNB). Key read from /home/heisenberg/CA/.env at runtime; never stored.
Outputs analysis/holders.json (no secrets).
"""
import json, os, re, subprocess, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
env = open("/home/heisenberg/CA/.env").read()
key = re.search(r"^ALCHEMY_API_KEY_2=(.*)$", env, re.M).group(1).strip().strip('"')
RPC = f"https://bnb-mainnet.g.alchemy.com/v2/{key}"

def transfers(contract, page_key=None):
    p = {"fromBlock": "0x0", "toBlock": "latest", "contractAddresses": [contract],
         "category": ["erc20"], "maxCount": "0x3e8", "order": "asc", "withMetadata": False, "excludeZeroValue": True}
    if page_key:
        p["pageKey"] = page_key
    payload = {"jsonrpc": "2.0", "id": 1, "method": "alchemy_getAssetTransfers", "params": [p]}
    last = None
    for attempt in range(6):
        try:
            out = subprocess.check_output(["curl", "-s", "--max-time", "120", "-H", "content-type: application/json",
                                           "-H", "User-Agent: Mozilla/5.0", "-d", json.dumps(payload), RPC], timeout=140)
            d = json.loads(out)
            if "error" in d:
                raise RuntimeError(str(d["error"])[:200])
            return d["result"]
        except Exception as e:
            last = e
            time.sleep(1 + attempt)
    raise last

def main():
    vs = json.load(open(os.path.join(HERE, "vault_state.json")))
    out = {}
    outp = os.path.join(HERE, "holders.json")
    if os.path.exists(outp):
        try: out = json.load(open(outp))
        except Exception: out = {}
    for v, o in vs.items():
        if v in out and out[v].get("complete"):
            print("skip", v); continue
        bal = {}
        page = None
        n = 0
        pages = 0
        while True:
            r = transfers(v, page)
            for t in r["transfers"]:
                frm = t["from"].lower(); to = t["to"].lower()
                val = int(t["rawContract"]["value"], 16) if isinstance(t["rawContract"].get("value"), str) and t["rawContract"]["value"].startswith("0x") else 0
                if val == 0:
                    # fall back to decimal value field * 1e18 (shares are 18dp)
                    try:
                        val = int(float(t["value"]) * 10**18)
                    except Exception:
                        val = 0
                bal[frm] = bal.get(frm, 0) - val
                bal[to] = bal.get(to, 0) + val
                n += 1
            pages += 1
            page = r.get("pageKey")
            if not page or pages > 200:
                break
            time.sleep(0.05)
        nz = {k: v2 for k, v2 in bal.items() if v2 > 0}
        tot = sum(nz.values())
        out[v] = {"totalSupply": o["totalSupply"], "sum_from_transfers": tot, "n_transfers": n, "complete": True,
                  "holders": dict(sorted(nz.items(), key=lambda x: -x[1]))}
        top = list(out[v]["holders"].items())[:5]
        print(f"{v} transfers={n} holders={len(nz)} top={[(a[:10], x) for a, x in top]}")
        json.dump(out, open(outp, "w"), indent=1)
    print("done")

if __name__ == "__main__":
    main()
