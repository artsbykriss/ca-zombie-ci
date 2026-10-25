#!/usr/bin/env python3
import json, os, sys
src = sys.argv[1]; outdir = sys.argv[2]
raw = open(src).read()
if raw.startswith("{{"): raw = raw[1:-1]
d = json.loads(raw)
os.makedirs(outdir, exist_ok=True)
for path, obj in d["sources"].items():
    p = os.path.join(outdir, path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write(obj["content"])
print("extracted", len(d["sources"]), "files to", outdir)
