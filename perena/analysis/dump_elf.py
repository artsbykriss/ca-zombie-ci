#!/usr/bin/env python3
"""Dump an upgradeable program's ELF (ProgramData) to a local file. Read-only.
Usage: python3 dump_elf.py <PROGRAM_ID> <outfile.so>
"""
import sys, base64
from rpc import call
from b58 import b58enc

def main():
    pid, out = sys.argv[1], sys.argv[2]
    a = call("getAccountInfo", [pid, {"encoding": "base64"}])["value"]
    raw = base64.b64decode(a["data"][0])
    pd = b58enc(raw[4:36])
    pda = call("getAccountInfo", [pd, {"encoding": "base64"}])["value"]
    praw = base64.b64decode(pda["data"][0])
    # ProgramData: u32 tag(3) + u64 slot + u8 has_auth + 32 auth + elf
    elf = praw[13 + 32:]
    with open(out, "wb") as f:
        f.write(elf)
    print(f"{pid} -> {out} ({len(elf)} bytes elf)")

if __name__ == "__main__":
    main()
