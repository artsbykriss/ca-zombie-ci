#!/usr/bin/env python3
"""Decode a Solana VersionedTransaction from publicnode's base64 wire form."""
import json, os, sys, base64, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from solrpc import rpc

B58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


def b58e(b):
    n = int.from_bytes(b, "big")
    s = ""
    while n:
        n, r = divmod(n, 58)
        s = B58[r] + s
    for byte in b:
        if byte == 0:
            s = "1" + s
        else:
            break
    return s


class Cur:
    def __init__(self, b):
        self.b = b
        self.i = 0

    def u8(self):
        v = self.b[self.i]; self.i += 1; return v

    def u16(self):
        v = self.b[self.i] | (self.b[self.i + 1] << 8); self.i += 2; return v

    def cu16(self):  # compact-u16
        v = 0; shift = 0
        while True:
            b = self.u8()
            v |= (b & 0x7F) << shift
            if not (b & 0x80):
                return v
            shift += 7

    def take(self, n):
        v = self.b[self.i:self.i + n]; self.i += n; return v


def decode_wire(b64):
    raw = base64.b64decode(b64)
    c = Cur(raw)
    nsigs = c.cu16()
    sigs = [c.take(64) for _ in range(nsigs)]
    # version prefix: >= 0x80 means versioned message
    version = 0
    if c.b[c.i] >= 0x80:
        version = c.u8() & 0x7F
    # message
    hdr = [c.u8(), c.u8(), c.u8()]
    nkeys = c.cu16()
    keys = [c.take(32) for _ in range(nkeys)]
    blockhash = c.take(32)
    nix = c.cu16()
    ixs = []
    for _ in range(nix):
        pid = c.u8()
        nacc = c.cu16()
        accs = [c.u8() for _ in range(nacc)]
        dlen = c.cu16()
        data = c.take(dlen)
        ixs.append({"pid": pid, "accs": accs, "data": data})
    lookups = []
    if version > 0:
        nlk = c.cu16()
        for _ in range(nlk):
            k = c.take(32)
            nw = c.cu16(); w = [c.u8() for _ in range(nw)]
            nr = c.cu16(); rr = [c.u8() for _ in range(nr)]
            lookups.append({"key": b58e(k), "w": w, "r": rr})
    return {"sigs": [b58e(s) for s in sigs], "header": hdr, "keys": [b58e(k) for k in keys],
            "blockhash": b58e(blockhash), "ixs": ixs, "version": version, "lookups": lookups}


def fetch_and_decode(sig):
    r = rpc("getTransaction", [sig, {"encoding": "base64", "maxSupportedTransactionVersion": 0}])
    tx = r.get("result")
    if not tx:
        return None, None
    t = tx["transaction"]
    b64 = t[0] if isinstance(t, list) else t
    dec = decode_wire(b64)
    # merge: jsonParsed gives the full resolved account list (static + ALT)
    r2 = rpc("getTransaction", [sig, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])
    jtx = r2.get("result")
    if jtx:
        jkeys = [k["pubkey"] for k in jtx["transaction"]["message"]["accountKeys"]]
        if len(jkeys) >= len(dec["keys"]):
            dec["keys"] = jkeys
            dec["jsonMeta"] = jtx.get("meta")
    return dec, tx


def main():
    sig = sys.argv[1]
    dec, tx = fetch_and_decode(sig)
    if not dec:
        print("no tx"); return
    meta = tx["meta"]
    print("slot", tx["slot"], "err", meta.get("err"))
    keys = dec["keys"]
    print("=== TOP ===")
    for i, ix in enumerate(dec["ixs"]):
        print(f"[{i}] pid={keys[ix['pid']]} data={ix['data'].hex()}")
        for a in ix["accs"]:
            print(f"      {a} {keys[a]}")
    print("=== INNER ===")
    for grp in meta.get("innerInstructions", []):
        print(f"-- outer {grp['index']}")
        for ix in grp["instructions"]:
            pid = keys[ix["programIdIndex"]]
            data = base64.b64decode(ix["data"][0]) if isinstance(ix["data"], list) else None
            if data is None:
                print("   (jsonParsed form) raw:", str(ix)[:200]); continue
            print(f"   pid={pid} data={data.hex()}")
            for a in ix["accounts"]:
                print(f"      {a} {keys[a]}")
    print("=== LOGS ===")
    for l in meta.get("logMessages", []):
        if "goonuddt" in l or "Goonfi" in l or "Program log: 0000" in l:
            print("  ", l)


if __name__ == "__main__":
    main()
