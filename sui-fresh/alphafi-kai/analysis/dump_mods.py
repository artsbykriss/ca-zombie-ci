#!/usr/bin/env python3
"""Extract module disassembly from the fetched version JSONs into readable .mv files.
Usage: dump_mods.py <label> <version>"""
import json, sys, glob, os

label = sys.argv[1]
ver = sys.argv[2]
d = os.path.dirname(os.path.abspath(__file__)) + "/disasm"
files = glob.glob(f"{d}/{label}_v{ver}_*.json")
for f in files:
    j = json.load(open(f))
    for m in j["modules"]["nodes"]:
        out = f"{d}/{label}_v{ver}_{m['name']}.mv"
        open(out, "w").write(m["disassembly"] or "")
        print(out, len(m["disassembly"] or ""))
