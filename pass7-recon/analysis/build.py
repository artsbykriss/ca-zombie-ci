#!/usr/bin/env python3
"""Build rows.json + counts from analysis/DISPOSITIONS.md (source of truth)."""
import json, re, os, collections

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "DISPOSITIONS.md")

rows = []
with open(SRC) as f:
    for line in f:
        line = line.rstrip("\n")
        if not line.startswith("| "):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 8:
            continue
        idx = cells[0]
        if not re.fullmatch(r"\d+", idx):
            continue
        lane, cand, chain, funds, verdict, disp, cite = cells[1:]
        disp_key = re.sub(r"\*\*", "", disp).strip()
        # normalise to the leading disposition token (handles "ASSIGNED (PRIOR-PARTIAL: ...)")
        m = re.match(r"(README-FINDING|README-CLOSED|LANE-CLOSED|PRIOR-COVERED|"
                     r"PRIOR-PARTIAL|NOT-A-PROTOCOL|ASSIGNED|OPEN)", disp_key)
        if not m:
            raise SystemExit(f"row {idx}: unrecognised disposition {disp_key!r}")
        disp_key = m.group(1)
        rows.append({
            "id": int(idx),
            "lane": lane,
            "candidate": cand,
            "chain": chain,
            "funds": funds,
            "lane_verdict": verdict,
            "disposition": disp_key,
            "cite": cite,
        })

counts = collections.Counter(r["disposition"] for r in rows)
open_rows = [r for r in rows if r["disposition"] == "OPEN"]

out = {
    "candidate_count": len(rows),
    "counts": dict(counts),
    "open": open_rows,
    "rows": rows,
}
with open(os.path.join(HERE, "rows.json"), "w") as f:
    json.dump(out, f, indent=1)

print("candidates:", len(rows))
for k in ["README-FINDING", "README-CLOSED", "LANE-CLOSED", "PRIOR-COVERED",
          "PRIOR-PARTIAL", "NOT-A-PROTOCOL", "ASSIGNED", "OPEN"]:
    print(f"  {k:16s} {counts.get(k,0)}")
print("OPEN rows:")
for r in open_rows:
    print("  -", r["id"], r["candidate"], "|", r["chain"], "|", r["funds"])
