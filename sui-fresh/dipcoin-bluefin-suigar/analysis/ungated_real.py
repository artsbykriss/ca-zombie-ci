#!/usr/bin/env python3
"""Per version: list REAL + CALLABLE + UNGATED functions (candidate E-U surface)."""
import json, glob, os, re, sys
import gate_check as g
import real_fns as rf

def main(folder):
    for f in sorted(glob.glob(os.path.join(folder, "v*.json"))):
        d = json.load(open(f))
        fns_by_mod = {m: g.parse(dis) for m, dis in d["modules"].items()}
        print(f"\n===== {os.path.basename(f)} v{d['version']} =====")
        for mod, dis in d["modules"].items():
            for name, hdr, body in rf.parse(dis):
                if rf.is_stub(body):
                    continue
                vis = hdr.split(name)[0].strip()
                callable_ = ("entry" in vis) or (vis.startswith("public") and "friend" not in vis and "package" not in vis)
                if not callable_:
                    continue
                gated = g.reachable_gate(mod, name, fns_by_mod, set())
                if not gated:
                    print(f"  UNGATED-REAL {mod}::{name}   | {hdr[:110]}")

if __name__ == "__main__":
    main(sys.argv[1])
