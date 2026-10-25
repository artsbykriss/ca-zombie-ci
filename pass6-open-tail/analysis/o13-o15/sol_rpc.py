#!/usr/bin/env python3
"""Read-only Solana JSON-RPC helper. No secrets, keyless public endpoints."""
import json, sys, time, urllib.request, urllib.error

ENDPOINTS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
]
_state = {"i": 0}

def _post(endpoint, payload, timeout=40):
    data = json.dumps(payload).encode()
    req = urllib.request.Request(endpoint, data=data,
        headers={"Content-Type": "application/json", "User-Agent": "audit-readonly/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc(method, params=None, retries=3):
    payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params or []}
    last = None
    for attempt in range(retries):
        for ep in ENDPOINTS:
            try:
                out = _post(ep, payload)
                if "error" in out:
                    # -32602 / -32000 etc: return so caller can inspect
                    return out
                return out
            except urllib.error.HTTPError as e:
                last = f"HTTP {e.code} on {ep}"
                if e.code == 429:
                    time.sleep(2)
                    continue
            except Exception as e:
                last = f"{type(e).__name__}: {e} on {ep}"
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
    # query all endpoints and return the longest (some public nodes have stale indexes)
    best = None
    for ep in ENDPOINTS:
        try:
            out = _post(ep, {"jsonrpc":"2.0","id":1,"method":"getSignaturesForAddress",
                             "params":[address, opts]})
            res = out.get("result")
            if res is not None and (best is None or len(res) > len(best.get("result") or [])):
                best = out
        except Exception:
            continue
    if best is None:
        return {"result": []}
    return best

def get_transaction(sig, encoding="jsonParsed"):
    # try all endpoints; some nodes return null for txs they don't retain
    for ep in ENDPOINTS:
        try:
            out = _post(ep, {"jsonrpc":"2.0","id":1,"method":"getTransaction",
                             "params":[sig, {"encoding": encoding,
                                             "maxSupportedTransactionVersion": 0,
                                             "commitment": "confirmed"}]})
            if out.get("result"):
                return out
        except Exception:
            continue
    return {"result": None}

def simulate_transaction(tx_b64, sig_verify=False, replace_recent=True):
    cfg = {"encoding": "base64", "sigVerify": sig_verify,
           "replaceRecentBlockhash": replace_recent, "commitment": "confirmed"}
    return rpc("simulateTransaction", [tx_b64, cfg])

def get_latest_blockhash():
    return rpc("getLatestBlockhash", [{"commitment": "confirmed"}])

def get_epoch_info():
    return rpc("getEpochInfo", [])

def get_version():
    return rpc("getVersion", [])

def get_balance(pubkey):
    return rpc("getBalance", [pubkey, {"commitment": "confirmed"}])

if __name__ == "__main__":
    print(json.dumps(get_version(), indent=2))
