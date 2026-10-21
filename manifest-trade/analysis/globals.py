#!/usr/bin/env python3
"""Enumerate Manifest global accounts (discriminator filter) and read their vault balances.
Keyless public RPC. Outputs JSON to stdout.
"""
import json, sys, struct, urllib.request, time, base64

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
            r = json.load(urllib.request.urlopen(req, timeout=120))
            if "error" in r:
                print("RPCERR", r["error"], file=sys.stderr); time.sleep(2); continue
            return r["result"]
        except Exception as e:
            print("retry", i, e, file=sys.stderr); time.sleep(2)
    return None

def disc_b64(v):
    return base64.b64encode(struct.pack("<Q", v)).decode()

def programs(disc):
    return rpc("getProgramAccounts", [PROG, {
        "encoding": "base64", "commitment": "confirmed",
        "filters": [{"memcmp": {"offset": 0, "bytes": disc_b64(disc)}}],
    }])

if __name__ == "__main__":
    slot = rpc("getSlot", [{"commitment": "confirmed"}])
    print("slot", slot, file=sys.stderr)
    g = programs(GLOBAL_DISC) or []
    print("globals", len(g), file=sys.stderr)
    out = []
    for a in g:
        raw = base64.b64decode(a["account"]["data"][0])
        # GlobalFixed: disc u64, mint[32], vault[32], root u32, root u32, max u32, free u32, num_bytes u32, vault_bump u8, global_bump u8, num_seats u16
        mint = a["account"]["data"][0]
        d = raw
        import base58
        rec = {
            "global": a["pubkey"],
            "mint": base58.b58encode(d[8:40]).decode(),
            "vault": base58.b58encode(d[40:72]).decode(),
            "global_traders_root_index": struct.unpack_from("<I", d, 72)[0],
            "global_deposits_root_index": struct.unpack_from("<I", d, 76)[0],
            "global_deposits_max_index": struct.unpack_from("<I", d, 80)[0],
            "free_list_head_index": struct.unpack_from("<I", d, 84)[0],
            "num_bytes_allocated": struct.unpack_from("<I", d, 88)[0],
            "vault_bump": d[92],
            "global_bump": d[93],
            "num_seats_claimed": struct.unpack_from("<H", d, 94)[0],
            "len": len(raw),
        }
        out.append(rec)
    json.dump({"slot": slot, "globals": out}, sys.stdout, indent=1)
