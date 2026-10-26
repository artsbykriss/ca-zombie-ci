#!/usr/bin/env python3
"""Classify each function in a version's disassembly as STUB vs REAL.
STUB = body begins with LdU64(999);Abort or Call error::method_deprecated;Abort.
"""
import json, glob, os, re, sys

FUN_RE = re.compile(
    r'^(?P<vis>(public\(friend\)|public\(package\)|public\(script\)|public|entry|native|friend)\s+)*'
    r'(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*(?P<generics><[^>]*>)?\s*\((?P<args>[^)]*)\)\s*(:\s*[^\{]+)?\{\s*$')

def parse(dis):
    fns = []; cur=None; buf=[]
    for line in dis.splitlines():
        if line and line[0] not in " \t":
            m = FUN_RE.match(line.rstrip())
            if m:
                if cur: fns.append((cur[0], cur[1], "\n".join(buf)))
                cur=(m.group("name"), line.rstrip()); buf=[]; continue
        if cur is not None: buf.append(line)
    if cur: fns.append((cur[0], cur[1], "\n".join(buf)))
    return fns

def is_stub(body):
    b = re.sub(r'^L\d+:.*\n', '', body, flags=re.M)
    first = [l.strip() for l in b.splitlines() if l.strip().startswith(tuple("0123456789"))][:2]
    s = " ".join(first)
    return ("LdU64(999)" in s) or ("method_deprecated" in s)

def main(folder, v):
    f = glob.glob(os.path.join(folder, f"v{v:02d}_*.json"))[0]
    d = json.load(open(f))
    for mod, dis in d["modules"].items():
        for name, hdr, body in parse(dis):
            stub = is_stub(body)
            vis = hdr.split(name)[0].strip()
            callable_ = ("entry" in vis) or (vis.startswith("public") and "friend" not in vis and "package" not in vis)
            tag = "STUB" if stub else "REAL"
            if not stub:
                print(f"  {tag} {'CALLABLE' if callable_ else 'internal'} {mod}::{name}  | {hdr[:90]}")

if __name__ == "__main__":
    main(sys.argv[1], int(sys.argv[2]))
