#!/usr/bin/env python3
"""Fetch an Anchor on-chain IDL for a program.
Anchor IDL account = createWithSeed(programId, "anchor:idl", programId) = sha256(program||"anchor:idl"||program).
Data: 8-byte disc 'anchor:idl' + u32 len + zlib(json).
Usage: python3 fetch_idl.py <PROGRAM_ID> [outfile.json]
"""
import sys, json, base64, zlib, hashlib
from rpc import call
from b58 import b58enc, b58dec

def create_with_seed(base, seed, owner):
    return hashlib.sha256(b58dec(base) + seed.encode() + b58dec(owner)).digest()

def main():
    pid = sys.argv[1]
    addr = b58enc(create_with_seed(pid, "anchor:idl", pid))
    print("idl account:", addr)
    a = call("getAccountInfo", [addr, {"encoding": "base64"}])
    v = a["value"]
    if v is None:
        print("NOT PUBLISHED (no account)"); return
    raw = base64.b64decode(v["data"][0])
    print("owner:", v["owner"], "len:", len(raw))
    # 8-byte discriminator then 4-byte LE length then zlib data
    body = raw[8:]
    # anchor writes: vec length (u32 LE) then compressed bytes
    n = int.from_bytes(body[:4], "little")
    comp = body[4:4+n]
    try:
        j = zlib.decompress(comp)
    except Exception as e:
        print("zlib fail:", e, "trying raw body")
        j = comp
    txt = j.decode("utf-8", "replace")
    if len(sys.argv) > 2:
        with open(sys.argv[2], "w") as f:
            f.write(txt)
        print("wrote", sys.argv[2], len(txt), "bytes")
    print(txt[:1500])

if __name__ == "__main__":
    main()
