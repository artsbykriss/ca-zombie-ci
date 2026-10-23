#!/usr/bin/env python3
"""Merge pinned on-chain metadata with anchor-family classification -> analysis/version_table.json + CSV."""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from classify_anchor import classify

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pinned = json.load(open(os.path.join(ROOT, "analysis/pinned_raw.json")))
elfdir = os.path.join(ROOT, "analysis/elf")

rows = []
for name, p in pinned.items():
    row = {
        "name": name,
        "program": p.get("program"),
        "error": p.get("error"),
        "last_deploy_slot": p.get("last_deploy_slot"),
        "last_deploy_utc": p.get("last_deploy_utc"),
        "upgrade_authority": p.get("upgrade_authority"),
        "elf_len_true": p.get("elf_len_true"),
        "programdata": p.get("programdata"),
    }
    fp = os.path.join(elfdir, p.get("program", "") + ".so")
    if os.path.exists(fp):
        c = classify(fp)
        row.update({k: c[k] for k in ["anchor_family", "markers_1_0_x", "markers_le_0_32",
                                      "marker_0_31_plus", "marker_le_0_30", "registry_hashes", "hashbrown"]})
    rows.append(row)

json.dump(rows, open(os.path.join(ROOT, "analysis/version_table.json"), "w"), indent=2)

hdr = ["name", "anchor_family", "last_deploy_utc", "elf_len_true", "marker_le_0_30", "marker_0_31_plus", "markers_1_0_x"]
print("| " + " | ".join(hdr) + " |")
print("|" + "|".join(["---"] * len(hdr)) + "|")
for r in rows:
    vals = []
    for h in hdr:
        v = r.get(h)
        if isinstance(v, list):
            v = ";".join(v) if v else "-"
        vals.append(str(v))
    print("| " + " | ".join(vals) + " |")
