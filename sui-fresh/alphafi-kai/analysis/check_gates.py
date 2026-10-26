#!/usr/bin/env python3
"""For each alphalend version's alpha_lending module, list public functions and whether
the function body (directly) calls verify_version."""
import re, glob, os, sys

d = os.path.dirname(os.path.abspath(__file__)) + "/disasm"

def functions(text):
    lines = text.splitlines()
    # find function declarations at column 0
    decls = []
    for i, ln in enumerate(lines):
        m = re.match(r'^(public |fun )(\S+?)(<.*?>)?\((.*?)\)(.*)\{$', ln)
        if m:
            decls.append((i, m.group(1).strip(), m.group(2), ln))
    out = []
    for idx, (i, vis, name, decl) in enumerate(decls):
        end = decls[idx+1][0] if idx+1 < len(decls) else len(lines)
        body = "\n".join(lines[i:end])
        out.append((vis, name, "verify_version" in body, "verify_admin_cap" in body, "verify_not_paused" in body))
    return out

for f in sorted(glob.glob(f"{d}/alphalend_v*_alpha_lending.mv"), key=lambda p: int(re.search(r'_v(\d+)_', p).group(1))):
    v = re.search(r'_v(\d+)_', f).group(1)
    text = open(f).read()
    fns = functions(text)
    pub = [x for x in fns if x[0] == "public"]
    novv = [x for x in pub if not x[2]]
    print(f"=== v{v}: {len(pub)} public fns, {len(novv)} without verify_version ===")
    for vis, name, vv, va, vp in novv:
        print(f"    {name}")
