#!/usr/bin/env python3
"""Child1: compare compiled runtime vs live code with immutables+metadata masked."""
import json, sys

ANALYSIS = "/home/heisenberg/CA/rose/analysis"

def strip_meta(code: bytes):
    ml = int.from_bytes(code[-2:], "big")
    return code[: -(ml + 2)]

def load_artifact(variant):
    out = json.load(open(f"{ANALYSIS}/child1_solc_{variant}.json"))
    art = out["contracts"]["BentoBoxFlat.sol"]["BentoBoxV1"]
    db = bytes.fromhex(art["evm"]["deployedBytecode"]["object"])
    imm = art["evm"]["deployedBytecode"].get("immutableReferences", {})
    return db, imm

def load_live(which):
    d = json.load(open(f"{ANALYSIS}/child1_bytecodes.json"))
    return bytes.fromhex(d[which]["code"][2:])

def mask(code, imm, offsets=None):
    c = bytearray(code)
    for mid, refs in imm.items():
        for r in refs:
            s = r["start"]
            if offsets is None or s in offsets:
                for i in range(s, s + r["length"]):
                    if i < len(c):
                        c[i] = 0
    return bytes(c)

def diff_regions(a, b):
    """report contiguous differing regions"""
    n = min(len(a), len(b))
    regions = []
    i = 0
    while i < n:
        if a[i] != b[i]:
            j = i
            while j < n and a[j] != b[j]:
                j += 1
            regions.append((i, j))
            i = j
        else:
            i += 1
    return regions

def compare(variant, live_name, mask_imm=True, verbose=True):
    db, imm = load_artifact(variant)
    live = load_live(live_name)
    live_body, db_body = strip_meta(live), strip_meta(db)
    if mask_imm:
        imm_offsets = sorted({r["start"] for refs in imm.values() for r in refs})
        db_body = mask(db_body, imm, set(imm_offsets))
        live_body = mask(live_body, imm, set(imm_offsets))
    print(f"=== {variant} (compiled) vs live {live_name}")
    print(f"    compiled body={len(db_body)} live body={len(live_body)} live total={len(live)}")
    if len(db_body) != len(live_body):
        print("    LENGTH MISMATCH")
    regs = diff_regions(db_body, live_body)
    eq = sum((e - s) for s, e in regs)
    print(f"    differing regions: {len(regs)}, differing bytes: {eq} / {min(len(db_body),len(live_body))}")
    show = 0
    for s, e in regs:
        show += 1
        if show > 40:
            print("    ...")
            break
        ln = e - s
        seg_c = db_body[s:e]
        seg_l = live_body[s:e]
        # skip zero-filled immutable placeholder regions (compiled zeros vs masked zeros equal anyway)
        print(f"    [{s}:{e}] len={ln}")
        if ln <= 96:
            print(f"       compiled: {seg_c.hex()}")
            print(f"       live    : {seg_l.hex()}")
        else:
            print(f"       compiled: {seg_c[:48].hex()}...")
            print(f"       live    : {seg_l[:48].hex()}...")
    return regs

if __name__ == "__main__":
    variant = sys.argv[1]
    live = sys.argv[2]
    compare(variant, live)
