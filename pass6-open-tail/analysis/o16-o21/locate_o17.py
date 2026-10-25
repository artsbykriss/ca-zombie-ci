#!/usr/bin/env python3
"""Locate O17 Loyal Earn + verify O16-O21 protocol<->program associations.
Read-only: keyless Solana RPC + DefiLlama HTTP. No secrets."""
import json, sys, os, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "o13-o15"))
from sol_rpc import get_account_info, get_signatures, get_transaction, rpc

def http(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

def llama(slug):
    try:
        d = http(f"https://api.llama.fi/protocol/{slug}")
        return {"name": d.get("name"), "slug": d.get("slug"),
                "chains": d.get("chains"), "tvl": d.get("currentChainTvls"),
                "url": d.get("url"), "address": d.get("address")}
    except Exception as e:
        return {"error": str(e)}

def main():
    out = {}
    # 1) DefiLlama metadata for the named protocols
    for slug in ["loyal-earn", "sat-rush", "true-dex", "pascal", "n1-exchange",
                 "byzanlink", "diversifi", "overpass", "zodial"]:
        out.setdefault("llama", {})[slug] = llama(slug)
    # 2) Loyal Earn mint on-chain
    mint = "LYLikzBQtpa9ZgVrJsqYGQpR3cC1WMJrBHaXGrQmeta"
    v = get_account_info(mint).get("result", {}).get("value")
    mint_info = None
    if v:
        import base64
        raw = base64.b64decode(v["data"][0])
        mint_info = {"owner": v.get("owner"), "lamports": v.get("lamports"),
                     "data_len": len(raw), "raw_head_hex": raw[:120].hex()}
        # SPL mint layout: mint_authority(4+32), supply(8), decimals(1) OR token-2022 (165+ext)
    out["loyal_earn_mint"] = {"pubkey": mint, "info": mint_info}
    # recent sigs on the mint -> find the program that interacts
    try:
        sigs = get_signatures(mint, limit=50).get("result") or []
        out["loyal_earn_mint"]["n_sigs"] = len(sigs)
        progs = {}
        for s in sigs[:15]:
            tx = get_transaction(s["signature"]).get("result")
            if not tx: continue
            msg = tx["transaction"]["message"]
            for ix in msg.get("instructions", []):
                p = ix.get("programId")
                progs[p] = progs.get(p, 0) + 1
        out["loyal_earn_mint"]["programs_in_txs"] = progs
    except Exception as e:
        out["loyal_earn_mint"]["sig_error"] = str(e)
    print(json.dumps(out, indent=1)[:6000])

if __name__ == "__main__":
    main()
