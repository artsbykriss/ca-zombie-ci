#!/usr/bin/env python3
"""Extract function signatures per module/version from saved Sui disassembly."""
import json, sys, os, re, glob

FUN_RE = re.compile(
    r'^(?P<vis>(public\(friend\)|public\(package\)|public\(script\)|public|entry|native|friend)\s+)*'
    r'(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*(?P<generics><[^>]*>)?\s*\((?P<args>[^)]*)\)\s*(:\s*[^\{]+)?\{\s*$')

def sigs(dis):
    out = []
    for line in (dis or "").splitlines():
        if not line or line[0] in " \t":  # function headers are at column 0
            continue
        m = FUN_RE.match(line.rstrip())
        if m:
            out.append(line.rstrip())
    return out

def main(folder):
    for f in sorted(glob.glob(os.path.join(folder, "v*.json"))):
        d = json.load(open(f))
        print(f"\n===== {os.path.basename(f)}  (v{d['version']}) =====")
        for mod, dis in d["modules"].items():
            ss = sigs(dis)
            if ss:
                print(f"  [{mod}]")
                for s in ss:
                    print(f"    {s}")

if __name__ == "__main__":
    main(sys.argv[1])
