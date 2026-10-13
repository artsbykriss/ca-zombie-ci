#!/usr/bin/env python3
"""Read-only Solana state dump for the '01' (01 Exchange) target.
Endpoint: public RPC (no keys). Saves raw JSON to analysis/.
"""
import json, urllib.request, sys, time

RPC = "https://api.mainnet-beta.solana.com"
# fallback list
FALLBACKS = ["https://solana-rpc.publicnode.com", "https://api.mainnet-beta.solana.com"]

def rpc(method, params, url=RPC, retries=4):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last = None
    for i in range(retries):
        try:
            req = urllib.request.Request(url, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read())
            if "error" in out:
                raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last = e
            time.sleep(1.5*(i+1))
    raise RuntimeError(f"{method} failed: {last}")

if __name__ == "__main__":
    wallet = "HjHSNe8hhvZ8hKCRrhKg1DGiGPd9NYQbUjT1SQRDo4kZ"
    out = {}
    # 1. wallet account
    out["wallet_account"] = rpc("getAccountInfo", [wallet, {"encoding":"jsonParsed"}])
    # 2. all SPL token accounts (jsonParsed => includes delegate/closeAuthority/state)
    out["token_accounts"] = rpc("getTokenAccountsByOwner",
        [wallet, {"programId":"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"}, {"encoding":"jsonParsed"}])
    # 3. Token-2022 accounts too
    out["token2022_accounts"] = rpc("getTokenAccountsByOwner",
        [wallet, {"programId":"TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"}, {"encoding":"jsonParsed"}])
    # 4. recent signatures
    out["signatures"] = rpc("getSignaturesForAddress", [wallet, {"limit":100}])
    # 5. balance
    out["balance"] = rpc("getBalance", [wallet])
    with open("analysis/state_dump_raw.json","w") as f:
        json.dump(out, f, indent=1)
    print("wallet:", json.dumps(out["wallet_account"]["result"]["value"]))
    tas = out["token_accounts"]["result"]["value"]
    print("SPL token accounts:", len(tas))
    print("Token-2022 accounts:", len(out["token2022_accounts"]["result"]["value"]))
    print("recent sigs:", len(out["signatures"]["result"]))
    print("balance lamports:", out["balance"]["result"]["value"])
