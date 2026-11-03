#!/usr/bin/env python3
"""Few-and-Far (NEAR) live verification.

Read-only. For the three collection contracts:
  * view_code -> code length + sha256 (base58 = NEAR code hash)
  * collections -> allow_listings / mint prices at the latest final block
  * nft_total_supply
  * top-level call_function of nft_resolve_transfer and migrate:
      - nft_resolve_transfer reaches `promise_result` in a view call => no
        #[private] guard ran first (a guarded method fails on
        current_account_id/predecessor_account_id instead).
      - migrate fails on predecessor_account_id and the literal
        "migrate is private" is present in the wasm => control.
Writes ci-out/near_check.json.
"""
import json, base64, hashlib, time, urllib.request, os

RPC = "https://rpc.mainnet.near.org"
CONTRACTS = [
    "fnf-club.collections.fewandfar.near",
    "zomland.nfts.fewandfar.near",
    "growfitter.nfts.fewandfar.near",
]
ALPH = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58(b):
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = ALPH[r] + s
    return "1" * (len(b) - len(b.lstrip(b"\0"))) + s


def rpc(method, params, tries=6):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(RPC, data=body,
                                         headers={"Content-Type": "application/json",
                                                  "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                d = json.load(r)
            if "error" in d:
                last = d["error"]
                time.sleep(2 + 2 * i)
                continue
            return d.get("result")
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(2 + 2 * i)
    raise RuntimeError(f"rpc failed: {last}")


def query(req, tries=6):
    last = None
    for i in range(tries):
        try:
            r = rpc("query", req)
            return r
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(2)
    raise RuntimeError(f"query failed: {last}")


def call(acct, method, args):
    res = query({"request_type": "call_function", "finality": "final",
                 "account_id": acct, "method_name": method,
                 "args_base64": base64.b64encode(json.dumps(args).encode()).decode()})
    err = res.get("error")
    val = None
    if "result" in res:
        try:
            val = json.loads(bytes(res["result"]))
        except Exception:  # noqa: BLE001
            val = None
    return {"block": res.get("block_height"), "error": err, "value": val}


def main():
    out = {"rpc": RPC, "contracts": {}}
    for a in CONTRACTS:
        rec = {}
        vc = query({"request_type": "view_code", "finality": "final", "account_id": a})
        code = base64.b64decode(vc.get("code_base64", ""))
        rec["code"] = {"block": vc.get("block_height"), "len": len(code),
                       "sha256": hashlib.sha256(code).hexdigest(),
                       "base58": b58(hashlib.sha256(code).digest()),
                       "literal_resolve_private": b"nft_resolve_transfer is private" in code,
                       "literal_migrate_private": b"migrate is private" in code}
        rec["collections"] = call(a, "collections", {"from_index": "0", "limit": 100})
        rec["total_supply"] = call(a, "nft_total_supply", {})
        rec["resolve_top_level"] = call(a, "nft_resolve_transfer",
                                        {"token_id": "1:1", "receiver_id": "x.near",
                                         "previous_owner_id": "y.near",
                                         "approved_account_ids": None})
        rec["migrate_top_level"] = call(a, "migrate", {})
        out["contracts"][a] = rec
        print(f"== {a}")
        print("  code", rec["code"]["len"], rec["code"]["base58"],
              "resolve_private_literal", rec["code"]["literal_resolve_private"],
              "migrate_private_literal", rec["code"]["literal_migrate_private"])
        cols = (rec["collections"].get("value") or [])
        print(f"  collections={len(cols)} total_supply={rec['total_supply'].get('value')} "
              f"block={rec['collections'].get('block')}")
        for c in cols:
            pub = (c.get("public_mint_config") or {})
            priv = (c.get("private_mint_config") or {})
            print(f"    id={c.get('collection_id')} allow_listings={c.get('allow_listings')} "
                  f"pub_price={pub.get('price')} priv_price={priv.get('price')} "
                  f"copies={(c.get('metadata') or {}).get('copies')}")
        print("  resolve_top_level:", rec["resolve_top_level"]["error"])
        print("  migrate_top_level:", rec["migrate_top_level"]["error"])

    os.makedirs("ci-out", exist_ok=True)
    with open(os.path.join("ci-out", "near_check.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("wrote ci-out/near_check.json")


if __name__ == "__main__":
    main()
