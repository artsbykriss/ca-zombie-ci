#!/usr/bin/env python3
"""List, per alphalend version, the public functions that do NOT call verify_version,
and flag whether they look privileged (Cap arg) or value-moving."""
import re, glob, os

d = os.path.dirname(os.path.abspath(__file__)) + "/disasm"

def functions(text):
    lines = text.splitlines()
    decls = []
    for i, ln in enumerate(lines):
        m = re.match(r'^(public |fun )(\S+?)(<.*?>)?\((.*?)\)(.*)\{$', ln)
        if m:
            decls.append((i, m.group(1).strip(), m.group(2), ln))
    out = []
    for idx, (i, vis, name, decl) in enumerate(decls):
        end = decls[idx+1][0] if idx+1 < len(decls) else len(lines)
        body = "\n".join(lines[i:end])
        args = re.search(r'\((.*?)\)', decl).group(1)
        out.append(dict(vis=vis, name=name, vv=("verify_version" in body),
                        caps=("AdminCap" in args or "MarketCap" in args or "PauseAdminCap" in args
                              or "LendingProtocolCap" in args or "PartnerCap" in args),
                        decl=decl))
    return out

for v in range(1, 16):
    f = f"{d}/alphalend_v{v}_alpha_lending.mv"
    text = open(f).read()
    pub = [x for x in functions(text) if x["vis"] == "public"]
    novv = [x for x in pub if not x["vv"]]
    print(f"=== v{v}: {len(pub)} public, {len(novv)} no-verify_version ===")
    for x in novv:
        flag = "CAP" if x["caps"] else "!!UNPRIV"
        print(f"   [{flag}] {x['name']}")
