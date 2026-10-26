#!/usr/bin/env python3
"""Explode Etherscan V2 source bundles ({{...}} JSON) into per-file .sol files."""
import json, os, glob
SRC="/home/heisenberg/CA/hyperbeat-earn/analysis/src"
def load_bundle(path):
    raw=open(path).read()
    s=raw.strip()
    if s.startswith("{{"): s=s[1:-1]
    try:
        return json.loads(s)
    except Exception:
        return None
for path in glob.glob(f"{SRC}/*.srccode.txt"):
    name=os.path.basename(path).replace(".srccode.txt","")
    j=load_bundle(path)
    if not j or "sources" not in j:
        print("SKIP",name,"(not multi-file or plain)"); continue
    d=f"{SRC}/{name}"
    os.makedirs(d,exist_ok=True)
    for fname,fdata in j["sources"].items():
        rel=fname.replace("/","__")
        open(f"{d}/{rel}","w").write(fdata.get("content",""))
    print("EXPLODED",name,len(j["sources"]),"files ->",d)
