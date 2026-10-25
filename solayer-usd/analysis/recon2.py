#!/usr/bin/env python3
"""Step 2: decode sUSD mint, pool state account, and dump instruction surface from tx logs."""
import json, base64, sys, os, struct, collections, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58enc(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = A[r] + out
    pad = 0
    for c in b:
        if c == 0: pad += 1
        else: break
    return "1" * pad + (out or "")
def b58dec(sv):
    n = 0
    for c in sv: n = n*58 + A.index(c)
    b = n.to_bytes((n.bit_length()+7)//8, "big"); pad = 0
    for c in sv:
        if c == "1": pad += 1
        else: break
    return b"\x00"*pad + b

PROG  = "s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
POOL  = "FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG"
SUSD  = "susdabGDNbhrnCa6ncrYo81u4s9GM8ecK2UwMyZiq4X"
CUSDO = "BnANu5CtUogLqcvBNByJuwaRvRxNtVuDcAytwjsUUtqs"
USDC  = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
T22   = "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"

out = {}
out["slot"] = s.get_slot()["result"]

# sUSD mint parsed
r = s.rpc("getAccountInfo", [SUSD, {"encoding": "jsonParsed", "commitment": "confirmed"}])
out["susd_mint"] = r["result"]["value"]
print("sUSD mint:", json.dumps(r["result"]["value"].get("data", {}).get("parsed", {}).get("info", {})))
sup = s.get_token_supply(SUSD)["result"]["value"]
out["susd_supply"] = sup
print("sUSD supply:", sup)

# pool account raw decode
pv = s.get_account_info(POOL)["result"]["value"]
raw = base64.b64decode(pv["data"][0])
out["pool_raw_hex"] = raw.hex()
out["pool_space"] = pv["space"]
print("pool 379 bytes hex:", raw.hex())

# interpret: anchor discriminator + fields
disc = raw[:8]
print("pool disc:", disc.hex())
# print all 32-byte aligned words
words = []
for i in range(0, len(raw) - 31, 32):
    w = raw[i:i+32]
    words.append((i, b58enc(w) if w != b"\x00"*32 else None, w.hex()))
print("pool 32-byte words:")
for off, b, h in words:
    print("  ", off, b, h)

# tail bytes
print("tail:", raw[8+32*((len(raw)-8)//32):].hex())

json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "recon2.json"), "w"), indent=1)

# ---- instruction surface from tx logs ----
def fullkeys(tx):
    m = tx["transaction"]["message"]
    k = list(m["accountKeys"])
    la = tx["meta"].get("loadedAddresses") or {}
    k += list(la.get("writable") or []); k += list(la.get("readonly") or [])
    return k

sigs = s.get_signatures(PROG, limit=1000).get("result") or []
print("program sigs:", len(sigs))
hist = collections.Counter(); samples = {}
txs_ok = 0
for i, sg in enumerate(sigs):
    try:
        tx = s.get_transaction(sg["signature"]).get("result")
    except Exception:
        tx = None
    if not tx: continue
    txs_ok += 1
    logs = tx["meta"].get("logMessages") or []
    for l in logs:
        if l.startswith("Program log: Instruction: "):
            name = l.split("Instruction: ",1)[1]
            hist[name] += 1
            if name not in samples:
                # collect ix data + accounts for this program
                keys = fullkeys(tx)
                for ix in tx["transaction"]["message"]["instructions"]:
                    if keys[ix["programIdIndex"]] == PROG:
                        samples[name] = {"sig": sg["signature"], "slot": tx["slot"],
                                         "data": ix["data"], "accounts": [keys[a] for a in ix["accounts"]],
                                         "err": tx["meta"]["err"]}
                        break
    if i % 100 == 99:
        print("scan...", i+1, dict(hist), flush=True)
out["ix_hist"] = dict(hist); out["ix_samples"] = samples; out["txs_ok"] = txs_ok
print("HIST:", dict(hist))
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "recon2.json"), "w"), indent=1)
print("saved recon2.json")
