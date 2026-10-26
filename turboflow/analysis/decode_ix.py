#!/usr/bin/env python3
"""Decode TurboFlow svm-bridge instruction data + RoleData account. Read-only."""
import sys, json, base64, struct
from rpc import call
from b58 import b58dec, b58enc

PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"
ROLEDATA = "8BXB7nkesJEu8JwjrAkP7zMYaSzJ6pe8HLf9mbXLSG47"

def hx(b):
    return b.hex()

def decode_ix(name, b58data):
    raw = b58dec(b58data)
    print(f"--- {name}: {len(raw)} bytes")
    print("    disc:", raw[:8].hex())
    body = raw[8:]
    print("    body hex:", hx(body))
    # try: first u64, then strings
    return raw

def main():
    # instruction samples from tx_scan
    samples = {
        "review_token": "AwSXTbKMPfqoTy82D5jx9LeDMwVFN1j8RgKgDudzMK8Y4Qiw8LfZmabssGeDG6xJyNUsEb",
        "propose_deposit": "rdcMW2QXrhjMso9Koo59h7nqoDmH7p8VYvZcZZbKWvUtrwJSRcmcfRJvfeMp3wVKVUtbTayTA3pVxsffgAfq7MT87oBykt3PTSYa7vqyt9fbMghDmg39Rf6YcvyBjFGEscgR18f1x3AtEUAhtz6vw5zmZhaprVauYxso61coLcFFAFiPHbB9xQLb67WdCwpanwY2LH9drMpPp7FmnkE3G71k3h51jEE2xvuEgrHhSq4Q6Y9f6BQtNFHm3NowXmS3xcNwF36YBGJeqJyAL49NfWed1b3NgN68yRSiQk6gfYdjNjZxHMa7wRdtkDNFHbkAXykWsZzmnbAD5suq",
        "deposit_token": "5XJQVLxeaKJEzTgdgiCsfxN9URAmS9eFPeEqFv3Y391Hu7XfdrPaeLqJRbPh3UCedp7CSsB7CgscFdi6nj8TKoHzCJ",
    }
    for n, d in samples.items():
        decode_ix(n, d)
    print()
    r = call("getAccountInfo", [ROLEDATA, {"encoding": "base64"}])
    raw = base64.b64decode(r["value"]["data"][0])
    print("RoleData len", len(raw))
    print("disc", raw[:8].hex())
    print("full hex:")
    for i in range(0, len(raw), 32):
        c = raw[i:i+32]
        print(f"  {i:04x}  {' '.join(f'{x:02x}' for x in c)}  {''.join(chr(x) if 32<=x<127 else '.' for x in c)}")

if __name__ == "__main__":
    main()
