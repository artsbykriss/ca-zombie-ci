#!/usr/bin/env python3
"""Live simulateTransaction (never broadcast) of Manifest global_evict.
Builds a wire-format legacy transaction, base64-encodes it, and asks the RPC
to simulate with sigVerify=false. Keyless public RPC only.
"""
import json, base64, struct, urllib.request, time, os
import base58

RPC = os.environ.get("SOL_RPC", "https://api.mainnet-beta.solana.com")
PROG = "MNFSTqtC93rEfYHB6hF82sKdZpUDFWkViLByLd1k1Ms"
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
SYSTEM = "11111111111111111111111111111111"

def rpc(m, p, tries=8):
    for i in range(tries):
        time.sleep(1.0)
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":m,"params":p}).encode(),
                                         headers={"Content-Type":"application/json","User-Agent":"zh4/1.0"})
            r = json.load(urllib.request.urlopen(req, timeout=90))
            if "error" in r:
                print("ERR", r["error"]); time.sleep(3); continue
            return r["result"]
        except Exception as e:
            print("retry", e); time.sleep(3)
    return None

def shortvec(n):
    out = b""
    while True:
        b = n & 0x7F
        n >>= 7
        if n == 0:
            out += bytes([b]); return out
        out += bytes([b | 0x80])

def build_tx(keys, ix_accounts, data, blockhash, num_sig=1, num_ro_signed=0, num_ro_unsigned=0, prog_idx=0):
    m = bytes([num_sig, num_ro_signed, num_ro_unsigned])
    m += shortvec(len(keys))
    for k in keys:
        m += base58.b58decode(k)
    m += base58.b58decode(blockhash)
    m += shortvec(1)
    m += bytes([prog_idx]) + shortvec(len(ix_accounts)) + bytes(ix_accounts) + shortvec(len(data)) + data
    return shortvec(1) + bytes(64) + m

GLOBAL = "YWE5YVRbkoT5q51SqenUVVeXnag17SgjDrWxYxNn4bM"
MINT = "GkdbD4KjQgBgpsyoK71kLan2AVXTDckGLFsyYmyD5JTM"
VAULT = "XCBApZcW3RhnCVZYoid2awpvJAxqqYcHZuUko9n9Gad"
PAYER = "8MaVa9kdt3NW4Q5HyNAm1X5LbR8PQRVDc1W8NMVK88D5"
PAYER_TOKEN = "13v7id1mhiUybpzS2ik3dzQwmMMXYSKogrhZgiEy5UgK"

slot = rpc("getSlot", [{"commitment": "confirmed"}])
bh = rpc("getLatestBlockhash", [{"commitment": "confirmed"}])["value"]["blockhash"]

data = bytes([11]) + struct.pack("<Q", 1_000_000_000_000)  # GlobalEvict, huge deposit
# Solana message ordering: writable signers, readonly signers, writable non-signers, readonly non-signers
keys = [PAYER, GLOBAL, VAULT, PAYER_TOKEN, PROG, MINT, TOKEN, SYSTEM]
ix_accounts = [0, 1, 5, 2, 3, 3, 6, 7]   # payer, global, mint, vault, trader_token, evictee_token, token, system
raw = build_tx(keys, ix_accounts, data, bh, 1, 0, 4, prog_idx=4)
res = rpc("simulateTransaction", [base64.b64encode(raw).decode(),
                                 {"encoding": "base64", "sigVerify": False,
                                  "replaceRecentBlockhash": True, "commitment": "confirmed"}])
print("slot", slot)
print(json.dumps(res, indent=1)[:4000])
json.dump({"slot": slot, "payer": PAYER, "global": GLOBAL, "result": res}, open("sim_evict.json", "w"), indent=1)
