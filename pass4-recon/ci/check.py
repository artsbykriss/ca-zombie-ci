#!/usr/bin/env python3
"""pass4-recon — parse analysis/ALL-ROWS.md, count dispositions, compare to summary.json,
scan the folder for keyed-URL/secret patterns. Read-only. No secrets used."""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALLROWS = os.path.join(ROOT, "analysis", "ALL-ROWS.md")
SUMMARY = os.path.join(ROOT, "summary.json")
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)

DISP = ["README-FINDING", "README-CLOSED", "LANE-CLOSED", "PRIOR-COVERED",
        "PRIOR-PARTIAL", "NOT-A-PROTOCOL", "OPEN", "LANE-LEAD"]

def parse_rows():
    rows = []
    for line in open(ALLROWS, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 6:
            continue
        num = cells[0]
        if not num.isdigit():
            continue
        disp_cell = cells[5]
        m = re.search(r"\*\*([A-Z\-]+)\*\*", disp_cell)
        d = m.group(1) if m else "UNKNOWN"
        if d not in DISP:
            d = "UNKNOWN"
        rows.append((int(num), cells[1], d))
    return rows

def main():
    rows = parse_rows()
    counts = {d: 0 for d in DISP}
    counts["UNKNOWN"] = 0
    for _, _, d in rows:
        counts[d] += 1
    nums = [n for n, _, _ in rows]
    contiguous = (nums == list(range(1, len(nums) + 1))) if nums else False

    summary = json.load(open(SUMMARY, encoding="utf-8"))
    declared = summary.get("counts", {})
    declared_total = declared.get("named_candidates_enumerated")
    mismatches = []
    for d in DISP:
        key = {"README-FINDING": "readme_finding", "README-CLOSED": "readme_closed",
               "LANE-CLOSED": "lane_closed", "PRIOR-COVERED": "prior_covered",
               "PRIOR-PARTIAL": "prior_partial", "NOT-A-PROTOCOL": "not_a_protocol",
               "OPEN": "open", "LANE-LEAD": "lane_lead"}[d]
        if key in declared and declared[key] != counts[d]:
            mismatches.append(f"{key}: summary={declared[key]} parsed={counts[d]}")
    if declared_total != len(rows):
        mismatches.append(f"named_candidates_enumerated: summary={declared_total} parsed={len(rows)}")

    # secret scan
    secret_re = re.compile(
        r"(api[_-]?key=[A-Za-z0-9]{16,}|https?://[^\s\"]*(alchemy|infura|drpc|ankr|nodereal|blockpi|quiknode)"
        r"[^\s\"]*/[A-Za-z0-9_-]{12,}|0x[a-fA-F0-9]{64}|-----BEGIN [A-Z ]*PRIVATE KEY-----)",
        re.I)
    hits = []
    for dirpath, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in (".git", "ci-artifacts", "__pycache__")]
        for f in files:
            p = os.path.join(dirpath, f)
            if p.endswith((".pyc",)):
                continue
            try:
                txt = open(p, encoding="utf-8", errors="ignore").read()
            except Exception:
                continue
            for m in secret_re.finditer(txt):
                hits.append({"file": os.path.relpath(p, ROOT), "match": m.group(0)[:40]})

    result = {
        "rows_parsed": len(rows),
        "numbering_contiguous": contiguous,
        "counts_parsed": counts,
        "counts_declared": declared,
        "mismatches": mismatches,
        "secret_hits": hits,
        "pass": (not mismatches and not hits and contiguous),
    }
    json.dump(result, open(os.path.join(OUT, "validation.json"), "w"), indent=2)
    print(json.dumps(result, indent=2))
    return 0 if result["pass"] else 1

if __name__ == "__main__":
    sys.exit(main())
