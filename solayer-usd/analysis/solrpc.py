#!/usr/bin/env python3
"""Read-only Solana JSON-RPC helper (keyless public endpoints only)."""
import json, sys, time, base64, urllib.request, urllib.error

ENDPOINTS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
    "https://solana.drpc.org",
]

def _post(endpoint, payload, timeout=45):
    data = json.dumps(payload).encode()
    req = urllib.request.Request(endpoint, data=data,
        headers={"Content-Type": "application/json", "User-Agent": "audit-readonly/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc(method, params=None, retries=4, endpoints=None):
    payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params or []}
    eps = endpoints or ENDPOINTS
    last = None
    for attempt in range(retries):
        for ep in eps:
            try:
                out = _post(ep, payload)
                return out
            except urllib.error.HTTPError as e:
                last = f"HTTP {e.code} {ep}"
                if e.code == 429:
                    time.sleep(2); continue
            except Exception as e:
                last = f"{type(e).__name__}: {e} {ep}"
        time.sleep(1.5)
    raise RuntimeError(f"rpc failed {method}: {last}")

def get_account_info(pubkey, encoding="base64"):
    return rpc("getAccountInfo", [pubkey, {"encoding": encoding, "commitment": "confirmed"}])

def get_program_accounts(program_id, filters=None, encoding="base64", dataSlice=None, extra=None):
    cfg = {"encoding": encoding, "commitment": "confirmed"}
    if filters: cfg["filters"] = filters
    if dataSlice: cfg["dataSlice"] = dataSlice
    if extra: cfg.update(extra)
    return rpc("getProgramAccounts", [program_id, cfg])

def get_signatures(address, limit=100, before=None, until=None):
    opts = {"limit": limit}
    if before: opts["before"] = before
    if until: opts["until"] = until
    best = None
    for ep in ENDPOINTS:
        try:
            out = _post(ep, {"jsonrpc":"2.0","id":1,"method":"getSignaturesForAddress","params":[address, opts]})
            res = out.get("result")
            if res is not None and (best is None or len(res) > len(best.get("result") or [])):
                best = out
        except Exception:
            continue
    return best if best is not None else {"result": []}

def get_transaction(sig, encoding="jsonParsed"):
    for ep in ENDPOINTS:
        try:
            out = _post(ep, {"jsonrpc":"2.0","id":1,"method":"getTransaction","params":[sig, {"encoding": encoding, "maxSupportedTransactionVersion": 0, "commitment": "confirmed"}]})
            if out.get("result"):
                return out
        except Exception:
            continue
    return {"result": None}

def simulate_transaction(tx_b64, sig_verify=False, replace_recent=True):
    cfg = {"encoding": "base64", "sigVerify": sig_verify, "replaceRecentBlockhash": replace_recent, "commitment": "confirmed"}
    return rpc("simulateTransaction", [tx_b64, cfg])

def get_latest_blockhash():
    return rpc("getLatestBlockhash", [{"commitment": "confirmed"}])

def get_slot():
    return rpc("getSlot", [{"commitment": "confirmed"}])

def get_balance(pubkey):
    return rpc("getBalance", [pubkey, {"commitment": "confirmed"}])

def get_multiple_accounts(keys, encoding="base64"):
    return rpc("getMultipleAccounts", [keys, {"encoding": encoding, "commitment": "confirmed"}])

def get_token_accounts_by_owner(owner, mint=None, program_id="TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"):
    cfg = {"encoding": "jsonParsed", "commitment": "confirmed"}
    if mint: cfg["mint"] = mint
    else: cfg["programId"] = program_id
    return rpc("getTokenAccountsByOwner", [owner, cfg])

def get_token_supply(mint):
    return rpc("getTokenSupply", [mint, {"commitment": "confirmed"}])

def get_epoch_info():
    return rpc("getEpochInfo", [])

if __name__ == "__main__":
    print(json.dumps(get_slot(), indent=2))
    print(json.dumps(rpc("getVersion"), indent=2))
