#!/usr/bin/env python3
"""Sample NOXA locked UniV3 positions on Robinhood Chain:
- read factory.getLaunchedToken(token) -> positionId/positionManager
- eth_call NPM.collect(tokenId, locker, max, max) from locker to get accrued fees
- sum fees in a sample and summarize; estimate total unclaimed fees.
Read-only; public RPC; no keys.
"""
import json, urllib.request, random
from concurrent.futures import ThreadPoolExecutor

RPC = "https://rpc.mainnet.chain.robinhood.com"
LOCKER = "0x7F03effbd7ceB22A3f80Dd468f67eF27826acD85"
FACTORY = "0xD9eC2db5f3D1b236843925949fe5bd8a3836FCcB"
NPM = "0x73991a25C818Bf1f1128dEAaB1492D45638DE0D3"

def rpc(method, params, retries=4):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=45) as r:
                d = json.loads(r.read())
            if "error" in d:
                raise RuntimeError(d["error"])
            return d["result"]
        except Exception:
            if i == retries - 1:
                raise

def word(x): return x[2:].rjust(64, "0")

def get_launched(token):
    r = rpc("eth_call", [{"to": FACTORY, "data": "0x3cf28b5a" + word(token)}, "latest"])
    b = r[2:]
    w = [b[i:i+64] for i in range(0, len(b), 64)]
    if len(w) < 13: return None
    return {
        "token": "0x" + w[0][-40:],
        "deployer": "0x" + w[1][-40:],
        "paired": "0x" + w[2][-40:],
        "positionManager": "0x" + w[3][-40:],
        "positionId": int(w[4], 16),
        "dexId": int(w[5], 16),
        "exists": bool(int(w[11], 16)),
    }

def collect_amounts(pos_id):
    # collect((uint256,address,uint128,uint128)) selector 0xfc6f7865
    data = "0xfc6f7865" + word(hex(pos_id)) + word(LOCKER) + "0"*32+"f"*32 + "0"*32+"f"*32
    r = rpc("eth_call", [{"to": NPM, "data": data, "from": LOCKER}, "latest"])
    b = r[2:]
    return int(b[0:64], 16), int(b[64:128], 16)

def position_info(pos_id):
    r = rpc("eth_call", [{"to": NPM, "data": "0x99fbab88" + word(hex(pos_id))}, "latest"])
    b = r[2:]
    w = [b[i:i+64] for i in range(0, len(b), 64)]
    # nonce, operator, token0, token1, fee, tickLower, tickUpper, liquidity, ...
    return {
        "token0": "0x" + w[2][-40:],
        "token1": "0x" + w[3][-40:],
        "fee": int(w[4], 16),
        "tickLower": int(w[5], 16, ) - (1 << 256) if int(w[5], 16) >= 1 << 255 else int(w[5], 16),
        "tickUpper": int(w[6], 16) - (1 << 256) if int(w[6], 16) >= 1 << 255 else int(w[6], 16),
        "liquidity": int(w[7], 16),
        "owed0": int(w[10], 16),
        "owed1": int(w[11], 16),
    }

def main():
    logs = json.load(open("analysis/logs_rh_locker.json"))["by_topic"]["FeesClaimed"]
    toks = []
    seen = set()
    for i, l in enumerate(logs):
        t = "0x" + l["topics"][1][-40:]
        if t not in seen:
            seen.add(t); toks.append(t)
    print("unique tokens in FeesClaimed:", len(toks))
    random.seed(19)
    sample = random.sample(toks, min(120, len(toks)))
    rows = []
    def work(t):
        try:
            info = get_launched(t)
            if not info or not info["exists"] or info["positionManager"].lower() != NPM.lower():
                return {"token": t, "skip": True, "info": info}
            a0, a1 = collect_amounts(info["positionId"])
            pi = position_info(info["positionId"])
            return {"token": t, "pos": info["positionId"], "a0": a0, "a1": a1, **pi}
        except Exception as e:
            return {"token": t, "err": str(e)[:120]}
    with ThreadPoolExecutor(max_workers=8) as ex:
        for r in ex.map(work, sample):
            rows.append(r)
    json.dump(rows, open("analysis/fee_sample_rh.json", "w"), indent=1)
    ok = [r for r in rows if "a0" in r]
    print("sampled", len(rows), "ok", len(ok))
    print("sum a0 (WETH wei):", sum(r["a0"] for r in ok))
    print("sum a1:", sum(r["a1"] for r in ok))
    print("nonzero a0 positions:", sum(1 for r in ok if r["a0"] > 0), "nonzero a1:", sum(1 for r in ok if r["a1"] > 0))
    print("max a0:", max([r["a0"] for r in ok] or [0]), "max a1:", max([r["a1"] for r in ok] or [0]))

if __name__ == "__main__":
    main()
