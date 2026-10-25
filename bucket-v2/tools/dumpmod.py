#!/usr/bin/env python3
"""Dump disassembly modules from a saved pkg_*.json to .mv text files."""
import json, sys, os

f = sys.argv[1]
outdir = sys.argv[2] if len(sys.argv) > 2 else os.path.dirname(f)
d = json.load(open(f))
addr = d["address"]
os.makedirs(outdir, exist_ok=True)
for m in d["modules"]:
    path = os.path.join(outdir, f"{addr[:10]}_{m['name']}.mv")
    with open(path, "w") as fh:
        fh.write(f"// module {m['name']}  package {addr} (v{d['version']})\n")
        fh.write(m.get("disassembly") or "")
    print(path, len(m.get("disassembly") or ""))
