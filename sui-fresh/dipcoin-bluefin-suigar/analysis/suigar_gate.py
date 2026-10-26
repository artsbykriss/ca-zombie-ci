#!/usr/bin/env python3
"""Suigar gate check: which public/entry fns do NOT reach sweethouse::assert_valid_version.
Also flags fns reaching it. Mirrors gate_check.py with a Suigar-specific GATE set.
"""
import json, glob, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gate_check as g

g.GATE = {("sweethouse", "assert_valid_version")}

def main(folder):
    for f in sorted(glob.glob(os.path.join(folder, "v*.json"))):
        d = json.load(open(f))
        fns_by_mod = {m: g.parse(dis) for m, dis in d["modules"].items()}
        print(f"\n===== {os.path.basename(f)} v{d['version']} =====")
        for mod, fns in fns_by_mod.items():
            if mod in ("core", "float", "i64", "math"):  # framework/utility modules
                pass
            for fn, (hdr, body) in fns.items():
                vis = hdr.split(fn)[0].strip()
                callable_ = ("entry" in vis) or (vis.startswith("public") and "friend" not in vis and "package" not in vis)
                if not callable_:
                    continue
                gated = g.reachable_gate(mod, fn, fns_by_mod, set())
                if not gated:
                    print(f"  UNGATED {mod}::{fn}   ({vis})")

if __name__ == "__main__":
    main(sys.argv[1])
