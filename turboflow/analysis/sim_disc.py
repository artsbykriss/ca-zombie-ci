#!/usr/bin/env python3
"""Probe an instruction by discriminator with a caller-chosen account list (read-only sim).
Usage: python3 sim_disc.py <DISC_HEX> <SIGNER> <ACCT,ACCT,...> [argbytes_hex]
"""
import sys, json
from rpc import call
from b58 import b58dec, b58enc
from solmsg import build, order_keys
from sim import simulate

PID = "HwWQZdX116amFGrygkpng7fTzMbrg6JGpLaoM77cM7vg".replace("am", "om")
PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"

def get_bh():
    return call("getLatestBlockhash", [{"commitment": "processed"}])["value"]["blockhash"]

def main():
    disc = bytes.fromhex(sys.argv[1])
    signer = sys.argv[2]
    accts = [a for a in sys.argv[3].split(",") if a]
    extra = bytes.fromhex(sys.argv[4]) if len(sys.argv) > 4 else b"\x00" * 40
    data = disc + extra
    # flags: signer is signer+writable; any account equal to signer also signer; all others writable
    keys_flags = [(signer, True, True)]
    seen = {signer}
    for a in accts:
        if a in seen:
            continue
        seen.add(a)
        keys_flags.append((a, a == signer, True))
    keys_flags = order_keys(keys_flags)
    keys_flags.append((PID, False, False))
    txb64 = build(keys_flags, get_bh(), [(PID, accts, data)])
    v = simulate(txb64)["value"]
    print("disc", disc.hex(), "signer", signer)
    print("err:", json.dumps(v.get("err")), "units:", v.get("unitsConsumed"))
    for l in (v.get("logs") or []):
        print("  ", l)

if __name__ == "__main__":
    main()
