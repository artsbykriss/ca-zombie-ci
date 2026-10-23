#!/usr/bin/env python3
"""Extract all Rust string literals from an anchor-lang crate source tree and
compare sets across versions to find version-discriminating strings."""
import os, re, sys, json

SRC = "/tmp/opencode/anchor-src"
STR_RE = re.compile(r'"((?:[^"\\]|\\.){3,200})"')

def strings_of(d):
    out = set()
    for root, _, files in os.walk(d):
        if "/tests/" in root or "/target/" in root:
            continue
        for fn in files:
            if not fn.endswith(".rs"):
                continue
            p = os.path.join(root, fn)
            try:
                t = open(p, encoding="utf-8", errors="replace").read()
            except Exception:
                continue
            for m in STR_RE.findall(t):
                out.add(m)
    return out

vers = sys.argv[1:] or ["0.29.0","0.30.1","0.31.0","0.31.1","0.31.2","0.32.0","0.32.2","1.0.0","1.0.1","1.0.2","1.0.3","1.2.1"]
sets = {}
for v in vers:
    d = os.path.join(SRC, f"anchor-lang-{v}")
    if os.path.isdir(d):
        sets[v] = strings_of(d)

# pairwise: which strings distinguish 1.0.1 from 1.0.2
def diff(a, b):
    only_a = sorted(sets[a] - sets[b])
    only_b = sorted(sets[b] - sets[a])
    return only_a, only_b

print("counts:", {k: len(v) for k, v in sets.items()})
if "1.0.1" in sets and "1.0.2" in sets:
    a, b = diff("1.0.1", "1.0.2")
    print("\n== strings only in 1.0.1 (not 1.0.2):", len(a))
    for s in a: print("   -", s[:120])
    print("\n== strings only in 1.0.2 (not 1.0.1):", len(b))
    for s in b: print("   +", s[:120])
if "1.0.0" in sets and "1.0.1" in sets:
    a, b = diff("1.0.0", "1.0.1")
    print("\n== only in 1.0.0:", len(a), a[:20])
    print("== only in 1.0.1:", len(b), b[:20])
# family signature: strings present in all 1.0.x but absent from all 0.31.x
fam10 = set.intersection(*[sets[v] for v in ["1.0.0","1.0.1","1.0.2","1.0.3"] if v in sets])
fam31 = set.union(*[sets[v] for v in ["0.31.0","0.31.1","0.31.2","0.32.0","0.32.2"] if v in sets])
print("\n== strings in ALL 1.0.x and NO 0.31/0.32 (family marker):", len(fam10 - fam31))
for s in sorted(fam10 - fam31): print("   1.0x>", s[:120])
print("\n== strings in ALL 0.31/0.32 and NO 1.0.x:", len(fam31 - fam10))
for s in sorted(fam31 - fam10): print("   0.3x>", s[:120])
