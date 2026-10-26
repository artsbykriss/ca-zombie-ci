#!/usr/bin/env python3
"""Rebuild a real TurboFlow ix as a legacy message with account substitutions and/or data patch,
then simulate (read-only, sigVerify=false). Never signs/sends.

Usage:
  python3 sim_sub.py <SIG> <DISC_HEX> [--signer ADDR] [--replace OLD=NEW]... [--patch-u64-off N=VALUE]
"""
import sys, json, base64
from rpc import call
from b58 import b58dec, b58enc
from solmsg import build, order_keys
from sim import simulate

PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"

def get_bh():
    return call("getLatestBlockhash", [{"commitment": "processed"}])["value"]["blockhash"]

def fetch(sig):
    return call("getTransaction", [sig, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])

def main():
    sig = sys.argv[1]
    disc = sys.argv[2]
    args = sys.argv[3:]
    signer = None
    repl = {}
    patch = None
    i = 0
    while i < len(args):
        if args[i] == "--signer":
            signer = args[i+1]; i += 2
        elif args[i] == "--replace":
            o, n = args[i+1].split("="); repl[o] = n; i += 2
        elif args[i] == "--patch-u64":
            off, val = args[i+1].split("="); patch = (int(off), int(val)); i += 2
        else:
            i += 1
    tx = fetch(sig)
    msg = tx["transaction"]["message"]
    keymeta = {}
    for k in msg["accountKeys"]:
        if isinstance(k, dict):
            keymeta[k["pubkey"]] = (k["signer"], k["writable"])
        else:
            keymeta[k] = (False, False)
    target = None
    for ix in msg["instructions"]:
        if ix.get("programId") == PID and b58dec(ix["data"])[:8].hex() == disc:
            target = ix
    if target is None:
        print("no matching ix"); return
    accts = list(target["accounts"])
    data = bytearray(b58dec(target["data"]))
    orig_signers = [a for a in accts if keymeta.get(a, (False, False))[0]]
    if patch:
        off, val = patch
        data[8+off:8+off+8] = val.to_bytes(8, "little")
    accts = [repl.get(a, a) for a in accts]
    if signer:
        accts = [signer if a in orig_signers else a for a in accts]
    payer = signer if signer else orig_signers[0]
    keys_flags = [(payer, True, True)]
    seen = {payer}
    for a in accts:
        if a in seen:
            continue
        seen.add(a)
        s, w = keymeta.get(a, (False, False))
        keys_flags.append((a, s, w))
    keys_flags = order_keys(keys_flags)
    if PID not in [k for k, _, _ in keys_flags]:
        keys_flags.append((PID, False, False))
    txb64 = build(keys_flags, get_bh(), [(PID, accts, bytes(data))])
    v = simulate(txb64)["value"]
    print("accounts:", accts)
    print("err:", json.dumps(v.get("err")), "units:", v.get("unitsConsumed"))
    for l in (v.get("logs") or []):
        print("  ", l)

if __name__ == "__main__":
    main()
