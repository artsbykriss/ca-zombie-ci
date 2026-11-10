#!/usr/bin/env python3
"""Render the CA3 reconciliation register to JSON + markdown tables."""
import json, os, sys
from candidates import ROWS, counts, DISPOS, PA, PC, PP, RO, NP, OP

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE)

def grade(r):
    s = r["sec"]
    if s in ("C1","C2","C3","C4","C5"): return "CRITICAL"
    if s in ("H1","H2","H3","H4"): return "HIGH"
    if s in ("L1","L2","L3","L4"): return "LOW"
    if s == "§7": return "LOW/watch"
    return "—"

def esc(x):
    return str(x).replace("|", "\\|")

def table(rows):
    out = []
    out.append("| # | Candidate | Chain | CA3 grade | Disposition | Live state / verdict | USD context | Conf. | Key address / prior evidence |")
    out.append("|---|---|---|---|---|---|---:|---|---|")
    for r in rows:
        out.append("| {id} | **{name}** | {chain} | {grade} | `{disp}` | {verdict} | {usd} | {conf} | `{addr}` — {evidence} |".format(
            id=r["id"], name=esc(r["name"]), chain=esc(r["chain"]), grade=grade(r),
            disp=r["disp"], verdict=esc(r["verdict"]),
            usd=("${:,.0f}".format(r["usd"]) if r["usd"] else "$0"),
            conf=esc(r["conf"]), addr=esc(r["addr"]), evidence=esc(r["evidence"])))
    return "\n".join(out)

counts_d = counts()
readme_rows = [r for r in ROWS if r["src"] == "README"]
research_rows = [r for r in ROWS if r["src"] == "RESEARCH"]

data = {
    "generated": "2026-11-10",
    "campaign": "CA3 residual reconciliation (2026-11-09 corpus)",
    "rows": len(ROWS),
    "counts": {
        "total": len(ROWS),
        "readme_sourced": len(readme_rows),
        "research_sourced": len(research_rows),
        "prior_assigned": counts_d[PA],
        "prior_covered": counts_d[PC],
        "prior_partial": counts_d[PP],
        "prior_total": counts_d[PA] + counts_d[PC] + counts_d[PP],
        "research_only_closed": counts_d[RO],
        "not_a_protocol": counts_d[NP],
        "open": counts_d[OP],
    },
    "open": [r for r in ROWS if r["disp"] == OP],
    "candidates": ROWS,
}
with open(os.path.join(HERE, "candidates.json"), "w") as f:
    json.dump(data, f, indent=2)
with open(os.path.join(HERE, "tables.md"), "w") as f:
    f.write("## A. README-sourced candidates (45)\n\n")
    f.write(table(readme_rows) + "\n\n")
    f.write("## B. Research-file-sourced candidates (42)\n\n")
    f.write(table(research_rows) + "\n")

print(json.dumps(data["counts"], indent=2))
print("wrote analysis/candidates.json and analysis/tables.md")
