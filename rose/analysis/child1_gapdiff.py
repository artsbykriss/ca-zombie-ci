#!/usr/bin/env python3
"""Child1: reusable kmer-anchor diff; prints length-changing gaps + big content gaps."""
import json, sys, collections
from bisect import bisect_left

K = 16

def strip_meta(code):
    ml = int.from_bytes(code[-2:], "big")
    return code[: -(ml + 2)]

def anchor_chain(a, b, k=K):
    pos_a = collections.defaultdict(list)
    for i in range(len(a) - k + 1):
        pos_a[a[i:i+k]].append(i)
    pos_b = collections.defaultdict(list)
    for j in range(len(b) - k + 1):
        pos_b[b[j:j+k]].append(j)
    pairs = []
    for key, ia in pos_a.items():
        if len(ia) == 1:
            jb = pos_b.get(key)
            if jb is not None and len(jb) == 1:
                pairs.append((ia[0], jb[0]))
    pairs.sort()
    js = [j for _, j in pairs]
    tails, tails_idx, prev = [], [], [-1] * len(pairs)
    for idx, j in enumerate(js):
        p = bisect_left(tails, j)
        if p == len(tails):
            tails.append(j); tails_idx.append(idx)
        else:
            tails[p] = j; tails_idx[p] = idx
        prev[idx] = tails_idx[p - 1] if p > 0 else -1
    chain = []
    cur = tails_idx[-1] if tails_idx else -1
    while cur != -1:
        chain.append(pairs[cur]); cur = prev[cur]
    chain.reverse()
    ch = []
    li = lj = -1
    for i, j in chain:
        if i >= li + k and j >= lj + k:
            ch.append((i, j)); li, lj = i, j
    return ch

def gapdiff(a, b, label_a="A", label_b="B", print_big=40):
    ch = anchor_chain(a, b)
    gaps = []
    pi = pj = 0
    for i, j in ch:
        if i > pi or j > pj:
            gaps.append((pi, i, pj, j))
        pi, pj = i + K, j + K
    if pi < len(a) or pj < len(b):
        gaps.append((pi, len(a), pj, len(b)))
    print(f"anchors={len(ch)} gaps={len(gaps)} {label_a}={len(a)} {label_b}={len(b)}")
    for (i0, i1, j0, j1) in gaps:
        la, lb = i1 - i0, j1 - j0
        if la != lb:
            print(f"LENCHG {label_a}@{i0}({la}) {label_b}@{j0}({lb}) delta={lb-la:+d}")
            seg_a = a[i0:i1]; seg_b = b[j0:j1]
            if la <= 120: print(f"   {label_a}: {seg_a.hex()}")
            else: print(f"   {label_a}: {seg_a[:60].hex()}...")
            if lb <= 120: print(f"   {label_b}: {seg_b.hex()}")
            else: print(f"   {label_b}: {seg_b[:60].hex()}...")
        elif la > print_big:
            print(f"BIGEQ  {label_a}@{i0}({la}) {label_b}@{j0}({lb})")
            print(f"   {label_a}: {a[i0:i1][:60].hex()}...")
            print(f"   {label_b}: {b[j0:j1][:60].hex()}...")
    return gaps

if __name__ == "__main__":
    Analysis = "/home/heisenberg/CA/rose/analysis"
    # args: fileA hex | fileB hex? simpler: use compiled artifact tag + live name
    tag = sys.argv[1]           # vase1 etc
    live = sys.argv[2]          # vase|bentobox
    out = json.load(open(f"{Analysis}/child1_solc_{tag}.json"))
    db = bytes.fromhex(out["contracts"]["BentoBoxFlat.sol"]["BentoBoxV1"]["evm"]["deployedBytecode"]["object"])
    d = json.load(open(f"{Analysis}/child1_bytecodes.json"))
    lc = bytes.fromhex(d[live]["code"][2:])
    a = strip_meta(db); b = strip_meta(lc)
    # mask immutables (zeros in compiled; mask live too at compiled positions)
    imm = out["contracts"]["BentoBoxFlat.sol"]["BentoBoxV1"]["evm"]["deployedBytecode"].get("immutableReferences", {})
    positions = sorted({r["start"] for refs in imm.values() for r in refs})
    a = bytearray(a); b = bytearray(b)
    for p in positions:
        for k in range(32):
            if p + k < len(a): a[p+k] = 0
            if p + k < len(b): b[p+k] = 0
    gapdiff(bytes(a), bytes(b), label_a=tag, label_b=live)
