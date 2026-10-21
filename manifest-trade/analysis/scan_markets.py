#!/usr/bin/env python3
"""Scan Manifest markets: token vault balances + global vaults. Keyless RPC.
Outputs analysis/market_scan.json. No secrets.
"""
import json, struct, base64, urllib.request, time, sys, pickle
import base58

RPC = "https://api.mainnet-beta.solana.com"
PROG = "MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms"
GLOBAL_DISC = 10787423733276977665
MARKET_DISC = 4859840929024028656

def rpc(method, params, tries=6):
    for i in range(tries):
        try:
            req = urllib.request.Request(RPC, data=json.dumps(
                {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "zh4/1.0"})
            r = json.load(urllib.request.urlopen(req, timeout=180))
            if "error" in r:
                print("ERR", r["error"], file=sys.stderr); time.sleep(2); continue
            return r["result"]
        except Exception as e:
            print("retry", i, e, file=sys.stderr); time.sleep(3)
    raise SystemExit("rpc failed: " + method)

slot = rpc("getSlot", [{"commitment": "confirmed"}])
mb58 = base58.b58encode(struct.pack("<Q", MARKET_DISC)).decode()
gb58 = base58.b58encode(struct.pack("<Q", GLOBAL_DISC)).decode()
markets = rpc("getProgramAccounts", [PROG, {"encoding": "base64", "commitment": "confirmed",
    "filters": [{"memcmp": {"offset": 0, "bytes": mb58}}]}])
globals_ = rpc("getProgramAccounts", [PROG, {"encoding": "base64", "commitment": "confirmed",
    "filters": [{"memcmp": {"offset": 0, "bytes": gb58}}, {"dataSize": 96}]}])

recs = []
vault_keys = []
for m in markets:
    d = base64.b64decode(m["account"]["data"][0])[:256]
    rec = {
        "market": m["pubkey"],
        "base_dec": d[9], "quote_dec": d[10],
        "base_mint": base58.b58encode(d[16:48]).decode(),
        "quote_mint": base58.b58encode(d[48:80]).decode(),
        "base_vault": base58.b58encode(d[80:112]).decode(),
        "quote_vault": base58.b58encode(d[112:144]).decode(),
        "num_bytes_allocated": struct.unpack_from("<I", d, 152)[0],
    }
    recs.append(rec)
    vault_keys.append(rec["base_vault"]); vault_keys.append(rec["quote_vault"])

grecs = []
for g in globals_:
    d = base64.b64decode(g["account"]["data"][0])
    grecs.append({"global": g["pubkey"],
                  "mint": base58.b58encode(d[8:40]).decode(),
                  "vault": base58.b58encode(d[40:72]).decode(),
                  "num_seats": struct.unpack_from("<H", d, 94)[0],
                  "lamports": g["account"]["lamports"],
                  "owner": g["account"]["owner"]})
    vault_keys.append(grecs[-1]["vault"])

# batch getMultipleAccounts
bal = {}
for i in range(0, len(vault_keys), 100):
    chunk = vault_keys[i:i+100]
    res = rpc("getMultipleAccounts", [chunk, {"encoding": "base64", "commitment": "confirmed"}])
    for k, a in zip(chunk, res["value"]):
        if a is None:
            bal[k] = None; continue
        raw = base64.b64decode(a["data"][0])
        bal[k] = {"amount": int.from_bytes(raw[64:72], "little"),
                  "owner": a["owner"], "lamports": a["lamports"]}
    time.sleep(0.2)

out = {"slot": slot, "markets": recs, "globals": grecs, "vault_balances": bal}
json.dump(out, open("market_scan.json", "w"))
print("slot", slot, "markets", len(recs), "globals", len(grecs))
for g in grecs:
    print(g, bal.get(g["vault"]))
