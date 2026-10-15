#!/usr/bin/env python3
"""Process raw getProgramAccounts bank dump -> decoded banks + vault balances.
Usage: python3 fetch_banks.py
Inputs:  banks_raw2.json (raw RPC response)
Outputs: banks.json (decoded banks), vaults.json (token account balances)
RPC: env SOLANA_RPC or default public endpoints (no secrets).
"""
import json, base64, sys, time, urllib.request, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from decode_bank import decode_bank

ENDPOINTS = [os.environ.get("SOLANA_RPC", ""), "https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]
ENDPOINTS = [e for e in ENDPOINTS if e]

def rpc(method, params, tries=6):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        ep = ENDPOINTS[i % len(ENDPOINTS)]
        try:
            req = urllib.request.Request(ep, data=body, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=90) as f:
                r = json.load(f)
            if "error" in r:
                last = r["error"]; time.sleep(1 + i); continue
            return r["result"]
        except Exception as e:
            last = str(e); time.sleep(1 + i)
    raise RuntimeError(f"rpc {method} failed: {last}")

def main():
    raw = json.load(open("banks_raw2.json"))["result"]
    banks = {}
    sizes = {}
    for item in raw:
        pk = item["pubkey"]
        data = base64.b64decode(item["account"]["data"][0])
        sizes[len(data)] = sizes.get(len(data), 0) + 1
        try:
            b = decode_bank(data)
        except Exception as e:
            b = {"_decode_error": str(e), "_account_bytes": len(data)}
        b["_pubkey"] = pk
        b["_lamports"] = item["account"]["lamports"]
        banks[pk] = b
    print("account sizes:", sizes, file=sys.stderr)
    print("banks decoded:", len(banks), file=sys.stderr)

    # group by group + mint for overview
    from collections import Counter
    print("groups:", Counter(b.get("group") for b in banks.values()).most_common(), file=sys.stderr)

    json.dump(banks, open("banks.json", "w"), indent=1)

    # vault balances
    vaults = {}
    addrs = []
    for pk, b in banks.items():
        for k in ("liquidity_vault", "insurance_vault", "fee_vault"):
            v = b.get(k)
            if v and v not in vaults:
                vaults[v] = {"kind": k, "bank": pk}
                addrs.append(v)
    print("vaults to fetch:", len(addrs), file=sys.stderr)
    out = {}
    for i in range(0, len(addrs), 100):
        chunk = addrs[i:i+100]
        res = rpc("getMultipleAccounts", [chunk, {"encoding": "jsonParsed"}])
        for a, v in zip(chunk, res["value"]):
            if v is None:
                out[a] = {"exists": False}
            else:
                try:
                    info = v["data"]["parsed"]["info"]
                    out[a] = {"exists": True, "mint": info["mint"], "owner": info["owner"],
                              "amount": info["tokenAmount"]["amount"], "decimals": info["tokenAmount"]["decimals"],
                              "ui": info["tokenAmount"].get("uiAmountString")}
                except Exception as e:
                    out[a] = {"exists": True, "parse_error": str(e), "owner": v.get("owner")}
        print(f"fetched {min(i+100, len(addrs))}/{len(addrs)}", file=sys.stderr)
        time.sleep(0.3)
    json.dump(out, open("vaults.json", "w"), indent=1)
    slot = rpc("getSlot", [])
    json.dump({"slot": slot}, open("fetch_slot.json", "w"))
    print("slot", slot, file=sys.stderr)

if __name__ == "__main__":
    main()
