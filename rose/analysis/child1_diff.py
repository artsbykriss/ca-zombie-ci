#!/usr/bin/env python3
"""Child1: rigorous byte-level alignment of VASE (Aurora) vs BentoBox V1 (Ethereum) bodies.

Method: strip solc metadata -> anchor on unique 16-byte windows -> longest increasing
subsequence of anchors -> every gap between anchors contains all byte differences.
Classify each gap. Outputs child1_diff.json.
"""
import json, re, sys
from bisect import bisect_left

d = json.load(open("child1_bytecodes.json"))
VASE = bytes.fromhex(d["vase"]["code"][2:])
BENTO = bytes.fromhex(d["bentobox"]["code"][2:])


def strip_metadata(code):
    ml = int.from_bytes(code[-2:], "big")
    return code[: -(ml + 2)], code[-(ml + 2):], ml


vb, vmeta, vml = strip_metadata(VASE)
bb, bmeta, bml = strip_metadata(BENTO)
print(f"vase body={len(vb)} meta={vml}+2  bento body={len(bb)} meta={bml}+2")

K = 16

def anchors(a, b, k=K):
    """Return monotonic chain of (i, j) unique-kmer anchors."""
    import collections
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
    # longest increasing subsequence on j (strictly increasing)
    js = [j for _, j in pairs]
    # patience LIS
    tails = []           # tails[l] = smallest possible tail j for lis length l+1
    tails_idx = []       # index into pairs of the tail element
    prev = [-1] * len(pairs)
    for idx, j in enumerate(js):
        p = bisect_left(tails, j)
        if p == len(tails):
            tails.append(j)
            tails_idx.append(idx)
        else:
            tails[p] = j
            tails_idx[p] = idx
        prev[idx] = tails_idx[p - 1] if p > 0 else -1
    # rebuild
    chain = []
    if tails_idx:
        cur = tails_idx[-1]
        while cur != -1:
            chain.append(pairs[cur])
            cur = prev[cur]
        chain.reverse()
    return chain, len(pairs)


chain_all, npairs = anchors(vb, bb)
# keep only non-overlapping anchors (kmer hits can overlap by < K bytes)
chain = []
last_i_used = last_j_used = -1
for (i, j) in chain_all:
    if i >= last_i_used + K and j >= last_j_used + K:
        chain.append((i, j))
        last_i_used, last_j_used = i, j
print(f"unique-kmer anchor pairs={npairs} monotonic chain={len(chain_all)} non-overlapping={len(chain)}")

# gaps = regions between anchors (in a and b separately)
gaps = []
prev_i = prev_j = 0
for (i, j) in chain:
    if i > prev_i or j > prev_j:
        gaps.append({"a": [prev_i, i], "b": [prev_j, j]})
    prev_i, prev_j = i + K, j + K
if prev_i < len(vb) or prev_j < len(bb):
    gaps.append({"a": [prev_i, len(vb)], "b": [prev_j, len(bb)]})

total_a = sum(g["a"][1] - g["a"][0] for g in gaps)
total_b = sum(g["b"][1] - g["b"][0] for g in gaps)
assert total_a + len(chain) * K == len(vb), (total_a, len(chain), len(vb))
assert total_b + len(chain) * K == len(bb), (total_b, len(chain), len(bb))
assert total_b - total_a == len(bb) - len(vb), (total_b - total_a, len(bb) - len(vb))
print(f"gaps={len(gaps)} accounted: vase={total_a}+{len(chain)*K} anchors={len(vb)} OK; "
      f"bento={total_b}+{len(chain)*K}={len(bb)} OK; net={total_a-total_b}")

report = []
for n, g in enumerate(gaps):
    a_seg = vb[g["a"][0]:g["a"][1]]
    b_seg = bb[g["b"][0]:g["b"][1]]
    entry = {
        "n": n,
        "a_off": g["a"][0], "b_off": g["b"][0],
        "a_len": len(a_seg), "b_len": len(b_seg),
        "a_hex": a_seg.hex(), "b_hex": b_seg.hex(),
        "a_asc": ''.join(chr(c) if 32 <= c < 127 else '.' for c in a_seg),
        "b_asc": ''.join(chr(c) if 32 <= c < 127 else '.' for c in b_seg),
    }
    report.append(entry)

json.dump(report, open("child1_diff.json", "w"), indent=1)
for e in report:
    print(f"\n--- gap {e['n']}: vase[{e['a_off']}:{e['a_off']+e['a_len']}] ({e['a_len']}B) "
          f"bento[{e['b_off']}:{e['b_off']+e['b_len']}] ({e['b_len']}B)")
    if e["a_len"] <= 80:
        print(f"    VASE : {e['a_hex']}")
    else:
        print(f"    VASE : {e['a_hex'][:160]}...")
    if e["b_len"] <= 80:
        print(f"    BENTO: {e['b_hex']}")
    else:
        print(f"    BENTO: {e['b_hex'][:160]}...")
    print(f"    VASE asc: {e['a_asc'][:120]}")
    print(f"    BENTO asc: {e['b_asc'][:120]}")
