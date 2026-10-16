#!/usr/bin/env python3
"""Fleet-wide fund scan: for every program, derive each collateral's vault ATAs and sum balances."""
import json, base64, sys, time
import sol_rpc as S

COLL_DISC = bytes.fromhex("132d631dc432e475")
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
ATA_PROG = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
MINTS = {
    "USDC": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
    "USDT": "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB",
}
b58disc = S.b58encode(COLL_DISC)

def collaterals_of(program_id):
    res = S.rpc("getProgramAccounts", [program_id, {
        "encoding": "base64",
        "filters": [{"memcmp": {"offset": 0, "bytes": b58disc}}, {"dataSize": 177}],
        "commitment": "finalized"}])
    return [it["pubkey"] for it in res]

def vault_authority(collateral, program_id):
    pda, _ = S.find_pda([b"CollateralAuthority", S.b58decode(collateral)], program_id)
    return pda

def ata(owner, mint):
    pda, _ = S.find_pda([S.b58decode(owner), S.b58decode(TOKEN), S.b58decode(mint)], ATA_PROG)
    return pda

def get_many(addrs):
    out = {}
    for i in range(0, len(addrs), 100):
        chunk = addrs[i:i+100]
        res = S.rpc("getMultipleAccounts", [chunk, {"encoding": "base64", "commitment": "finalized"}])
        for a, v in zip(chunk, res["value"]):
            if v is None:
                continue
            raw = base64.b64decode(v["data"][0])
            if len(raw) >= 72:
                out[a] = int.from_bytes(raw[64:72], "little")
    return out

def scan(program_id, mint_names=("USDC", "USDT"), progress=None):
    colls = collaterals_of(program_id)
    atamap = {}
    for c in colls:
        v = vault_authority(c, program_id)
        for mn in mint_names:
            atamap[ata(v, MINTS[mn])] = (c, mn)
    keys = list(atamap.keys())
    bal = get_many(keys)
    nonzero = {k: v for k, v in bal.items() if v > 0}
    per_mint = {}
    for k, v in nonzero.items():
        c, mn = atamap[k]
        per_mint[mn] = per_mint.get(mn, 0) + v
    return {"program": program_id, "n_collaterals": len(colls),
            "n_nonzero": len(nonzero),
            "per_mint_raw": per_mint,
            "examples": [{"ata": k, "collateral": atamap[k][0], "mint": atamap[k][1], "raw": v}
                          for k, v in list(nonzero.items())[:20]]}

if __name__ == "__main__":
    rows = [json.loads(l) for l in open("fleet_map_main.jsonl")]
    results = []
    t0 = time.time()
    for i, r in enumerate(rows):
        pid = r["program"]
        try:
            res = scan(pid)
        except Exception as e:
            res = {"program": pid, "error": str(e)[:120]}
        results.append(res)
        print(json.dumps({k: v for k, v in res.items() if k != "examples"}), flush=True)
        if (i+1) % 5 == 0:
            json.dump(results, open("fleet_fund_scan.json", "w"), indent=1)
    json.dump(results, open("fleet_fund_scan.json", "w"), indent=1)
    print("DONE in", round(time.time()-t0, 1), "s")
