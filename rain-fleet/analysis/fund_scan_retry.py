#!/usr/bin/env python3
"""Retry scan for the big programs that failed on rate limits."""
import json, base64, sys, time, os, threading
from concurrent.futures import ThreadPoolExecutor, as_completed
import urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sol_rpc as S

COLL_DISC = bytes.fromhex("132d631dc432e475")
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
ATA_PROG = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
MINTS = {"USDC": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
         "USDT": "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"}

env = {}
for line in open("/home/heisenberg/CA/.env"):
    if "=" in line and not line.startswith("#"):
        k, v = line.strip().split("=", 1); env[k] = v.strip('"').strip("'")

RPCS = []
if env.get("ALCHEMY_API_KEY"):
    RPCS.append(f"https://solana-mainnet.g.alchemy.com/v2/{env['ALCHEMY_API_KEY']}")
if env.get("ANKR_API_KEY"):
    RPCS.append(f"https://rpc.ankr.com/solana/{env['ANKR_API_KEY']}")
RPCS += ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
_rr = [0]; _lock = threading.Lock()

def rpc(method, params, retries=6):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for attempt in range(retries):
        with _lock:
            url = RPCS[_rr[0] % len(RPCS)]; _rr[0] += 1
        try:
            req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read().decode())
            if "error" in out:
                last = out["error"]; time.sleep(1.0 + 0.8 * attempt); continue
            return out["result"]
        except Exception as e:
            last = str(e); time.sleep(1.0 + 0.8 * attempt)
    raise RuntimeError(f"rpc fail: {last}")

def derive(coll, program_id):
    v, _ = S.find_pda([b"CollateralAuthority", S.b58decode(coll)], program_id)
    return [(S.find_pda([S.b58decode(v), S.b58decode(TOKEN), S.b58decode(m)], ATA_PROG)[0], coll, mn)
            for mn, m in MINTS.items()]

def get_chunk(chunk):
    res = rpc("getMultipleAccounts", [chunk, {"encoding": "base64", "commitment": "finalized"}])
    out = {}
    for a, v in zip(chunk, res["value"]):
        if v is None: continue
        raw = base64.b64decode(v["data"][0])
        if len(raw) >= 72:
            out[a] = int.from_bytes(raw[64:72], "little")
    return out

def scan(program_id):
    res = rpc("getProgramAccounts", [program_id, {"encoding": "base64",
        "filters": [{"memcmp": {"offset": 0, "bytes": S.b58encode(COLL_DISC)}}, {"dataSize": 177}], "commitment": "finalized"}])
    colls = [it["pubkey"] for it in res]
    atamap = {}
    with ThreadPoolExecutor(max_workers=6) as ex:
        for f in as_completed([ex.submit(derive, c, program_id) for c in colls]):
            for a, c, mn in f.result():
                atamap[a] = (c, mn)
    keys = list(atamap.keys())
    bal = {}
    chunks = [keys[i:i+100] for i in range(0, len(keys), 100)]
    with ThreadPoolExecutor(max_workers=4) as ex:
        for r in ex.map(get_chunk, chunks):
            bal.update(r)
    nz = {k: v for k, v in bal.items() if v > 0}
    per = {}
    for k, v in nz.items():
        c, mn = atamap[k]
        per[mn] = per.get(mn, 0) + v
    return {"program": program_id, "n_collaterals": len(colls), "n_nonzero": len(nz), "per_mint_raw": per,
            "examples": [{"ata": k, "collateral": atamap[k][0], "mint": atamap[k][1], "raw": v}
                          for k, v in sorted(nz.items(), key=lambda x: -x[1])[:10]]}

if __name__ == "__main__":
    targets = json.loads(sys.argv[1])
    out = []
    for pid in targets:
        t0 = time.time()
        try:
            r = scan(pid)
        except Exception as e:
            r = {"program": pid, "error": str(e)[:150]}
        r["seconds"] = round(time.time()-t0, 1)
        out.append(r)
        print(json.dumps({k: v for k, v in r.items() if k != "examples"}), flush=True)
    json.dump(out, open("fleet_fund_scan_retry.json", "w"), indent=1)
    print("DONE")
