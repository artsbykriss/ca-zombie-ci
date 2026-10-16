#!/usr/bin/env python3
"""Fleet-wide fund scan (threaded): for every program, derive each collateral's vault ATAs and sum balances."""
import json, base64, sys, time, threading
from concurrent.futures import ThreadPoolExecutor, as_completed
import urllib.request

COLL_DISC = bytes.fromhex("132d631dc432e475")
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
ATA_PROG = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
MINTS = {
    "USDC": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
    "USDT": "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB",
}
import os
RPCS = []
for k in ("SOLANA_RPC_URL",):
    v = os.environ.get(k)
    if v: RPCS.append(v)
RPCS += ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
_rr = [0]
_lock = threading.Lock()

def rpc(method, params, retries=4):
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for attempt in range(retries):
        with _lock:
            url = RPCS[_rr[0] % len(RPCS)]; _rr[0] += 1
        try:
            req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read().decode())
            if "error" in out:
                last = out["error"]; time.sleep(0.4 * (attempt + 1)); continue
            return out["result"]
        except Exception as e:
            last = str(e); time.sleep(0.4 * (attempt + 1))
    raise RuntimeError(f"rpc fail: {last}")

# import PDA derivation from sol_rpc (no RPC use there)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sol_rpc as S

def collaterals_of(program_id):
    b58disc = S.b58encode(COLL_DISC)
    res = rpc("getProgramAccounts", [program_id, {"encoding": "base64",
        "filters": [{"memcmp": {"offset": 0, "bytes": b58disc}}, {"dataSize": 177}], "commitment": "finalized"}])
    return [it["pubkey"] for it in res]

def derive(coll, program_id):
    v, _ = S.find_pda([b"CollateralAuthority", S.b58decode(coll)], program_id)
    out = []
    for mn, mint in MINTS.items():
        a, _ = S.find_pda([S.b58decode(v), S.b58decode(TOKEN), S.b58decode(mint)], ATA_PROG)
        out.append((a, coll, mn))
    return out

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
    colls = collaterals_of(program_id)
    atamap = {}
    with ThreadPoolExecutor(max_workers=8) as ex:
        futs = [ex.submit(derive, c, program_id) for c in colls]
        for f in as_completed(futs):
            for a, c, mn in f.result():
                atamap[a] = (c, mn)
    keys = list(atamap.keys())
    bal = {}
    chunks = [keys[i:i+100] for i in range(0, len(keys), 100)]
    with ThreadPoolExecutor(max_workers=12) as ex:
        for res in ex.map(get_chunk, chunks):
            bal.update(res)
    nonzero = {k: v for k, v in bal.items() if v > 0}
    per_mint = {}
    for k, v in nonzero.items():
        c, mn = atamap[k]
        per_mint[mn] = per_mint.get(mn, 0) + v
    return {"program": program_id, "n_collaterals": len(colls), "n_nonzero": len(nonzero),
            "per_mint_raw": per_mint,
            "examples": [{"ata": k, "collateral": atamap[k][0], "mint": atamap[k][1], "raw": v}
                          for k, v in sorted(nonzero.items(), key=lambda x: -x[1])[:10]]}

if __name__ == "__main__":
    rows = [json.loads(l) for l in open("fleet_map_main.jsonl")]
    # sort: big programs first (they dominate); skip already-scanned
    order = sys.argv[1] if len(sys.argv) > 1 else "as-is"
    results = []
    t0 = time.time()
    for i, r in enumerate(rows):
        pid = r["program"]
        try:
            res = scan(pid)
        except Exception as e:
            res = {"program": pid, "error": str(e)[:150]}
        results.append(res)
        print(json.dumps({k: v for k, v in res.items() if k != "examples"}), flush=True)
        json.dump(results, open("fleet_fund_scan.json", "w"), indent=1)
    print("DONE", round(time.time()-t0, 1), "s")
