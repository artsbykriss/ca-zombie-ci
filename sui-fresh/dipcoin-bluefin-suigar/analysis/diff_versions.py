#!/usr/bin/env python3
"""Diff function-signature sets across package versions, per module.
Reports signatures present in version A but absent in version B (and vice versa).
Usage: diff_versions.py <folder> <vA> <vB>
"""
import json, sys, os, re, glob

FUN_RE = re.compile(
    r'^(?P<vis>(public\(friend\)|public\(package\)|public\(script\)|public|entry|native|friend)\s+)*'
    r'(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*(?P<generics><[^>]*>)?\s*\((?P<args>[^)]*)\)\s*(:\s*[^\{]+)?\{\s*$')

def load(folder, v):
    f = glob.glob(os.path.join(folder, f"v{v:02d}_*.json"))[0]
    return json.load(open(f))

def sigs_by_mod(d):
    out = {}
    for mod, dis in d["modules"].items():
        ss = []
        for line in (dis or "").splitlines():
            if line and line[0] not in " \t" and FUN_RE.match(line.rstrip()):
                ss.append(line.rstrip())
        out[mod] = set(ss)
    return out

def main(folder, va, vb):
    A, B = load(folder, va), load(folder, vb)
    sa, sb = sigs_by_mod(A), sigs_by_mod(B)
    mods = sorted(set(sa) | set(sb))
    print(f"### {folder}: v{va} vs v{vb}")
    for m in mods:
        a, b = sa.get(m, set()), sb.get(m, set())
        only_a, only_b = a - b, b - a
        if only_a or only_b:
            print(f"\n[{m}]")
            for s in sorted(only_a):
                print(f"  -v{va} only: {s}")
            for s in sorted(only_b):
                print(f"  +v{vb} only: {s}")

if __name__ == "__main__":
    main(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
