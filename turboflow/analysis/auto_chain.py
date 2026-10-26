#!/usr/bin/env python3
"""Iteratively discover the full account list for an instruction by substituting the
expected PDA reported in each ConstraintSeeds error (read-only sim)."""
import sys, json, re
from rpc import call
from solmsg import build, order_keys
from sim import simulate

PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"
SG = "GUAujt5S2yvnY4HVj5ysiiHfskmLXPkcbVfxcgLVd1is"

def get_bh():
    return call("getLatestBlockhash", [{"commitment": "processed"}])["value"]["blockhash"]

def run(accts, data, signer=SG):
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
    return v

def parse(v):
    logs = v.get("logs") or []
    field = None; left = None; right = None; msg = None
    for i, l in enumerate(logs):
        m = re.search(r"caused by account: (\w+)", l)
        if m: field = m.group(1)
        if l.strip() == "Program log: Left:" and i+1 < len(logs):
            left = logs[i+1].replace("Program log: ", "").strip()
        if l.strip() == "Program log: Right:" and i+1 < len(logs):
            right = logs[i+1].replace("Program log: ", "").strip()
        m2 = re.search(r"Error Message: (.*)", l)
        if m2: msg = m2.group(1)
    return field, left, right, msg, json.dumps(v.get("err"))

def main():
    disc = bytes.fromhex(sys.argv[1])
    body = bytes.fromhex(sys.argv[2])
    base = sys.argv[3].split(",") if len(sys.argv) > 3 else []
    accts = list(base)
    for it in range(25):
        v = run(accts, disc + body)
        field, left, right, msg, err = parse(v)
        print(f"iter {it}: field={field!r} msg={msg!r} err={err}")
        if right and (err and "2006" in err):
            # replace the occurrence of `left` in accts with `right`
            newaccts = [right if a == left else a for a in accts]
            if newaccts == accts:
                # left not in list; append
                newaccts = accts + [right]
            accts = newaccts
            print(f"   set {field}: {left} -> {right}")
            continue
        print("final accts:", ",".join(accts))
        break

if __name__ == "__main__":
    main()
