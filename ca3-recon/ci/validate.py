#!/usr/bin/env python3
"""CA3 reconciliation validator — no network, no secrets, deterministic.

Checks:
  1. register integrity (87 rows, 45 README + 42 research, unique ids)
  2. disposition counts match summary.json
  3. every OPEN row has an address, a next check, and no claim above the bar
  4. every id appears in README.md (nothing silently dropped)
  5. no .env / private key / keyed URL in the folder
  6. the 48-file research corpus is acknowledged in the README
"""
import json, os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "ci-out")
os.makedirs(OUT, exist_ok=True)

def fail(msg):
    print("FAIL:", msg)
    sys.exit(1)

data = json.load(open(os.path.join(ROOT, "analysis", "candidates.json")))
rows = data["candidates"]
counts = data["counts"]

if len(rows) != 87: fail(f"row count {len(rows)} != 87")
if len({r["id"] for r in rows}) != 87: fail("duplicate id")
if sum(1 for r in rows if r["src"] == "README") != 45: fail("README count")
if sum(1 for r in rows if r["src"] == "RESEARCH") != 42: fail("research count")

recomputed = {"total": len(rows), "readme_sourced": 45, "research_sourced": 42,
              "prior_assigned": 0, "prior_covered": 0, "prior_partial": 0,
              "prior_total": 0, "research_only_closed": 0, "not_a_protocol": 0, "open": 0}
for r in rows:
    d = r["disp"]
    key = {"PRIOR-ASSIGNED": "prior_assigned", "PRIOR-COVERED": "prior_covered",
           "PRIOR-PARTIAL": "prior_partial", "RESEARCH-ONLY": "research_only_closed",
           "NOT-A-PROTOCOL": "not_a_protocol", "OPEN": "open"}[d]
    recomputed[key] += 1
recomputed["prior_total"] = recomputed["prior_assigned"] + recomputed["prior_covered"] + recomputed["prior_partial"]
for k, v in recomputed.items():
    if counts.get(k) != v: fail(f"count mismatch {k}: {counts.get(k)} != {v}")

open_rows = [r for r in rows if r["disp"] == "OPEN"]
if len(open_rows) != 3: fail(f"OPEN count {len(open_rows)} != 3")
for r in open_rows:
    if not r.get("addr") or not r.get("next"): fail(f"OPEN {r['id']} missing address/next")
    if not r["verdict"].startswith("OPEN-LOW"): fail(f"OPEN {r['id']} verdict not OPEN-LOW")
    if r["usd"] > 10_000_000_000: fail(f"OPEN {r['id']} implausible usd")
for r in rows:
    if r["disp"] != "OPEN" and r["verdict"].startswith("OPEN"):
        fail(f"non-OPEN row {r['id']} has OPEN verdict")

readme = open(os.path.join(ROOT, "README.md")).read()
missing = [r["id"] for r in rows if f"| {r['id']} |" not in readme]
if missing: fail(f"ids missing from README: {missing[:10]}")
if "48" not in readme: fail("README does not mention the 48-file corpus")

# secret scan: fail closed on .env, private keys, keyed URLs, known key names
bad = []
for p in glob.glob(os.path.join(ROOT, "**", "*"), recursive=True):
    if not os.path.isfile(p): continue
    base = os.path.basename(p)
    if base in (".env", "firecrawl.env") or base.startswith(".env."):
        bad.append((p, "env file"))
        continue
    if p.endswith((".png", ".jpg", ".pdf", ".zip")): continue
    try:
        txt = open(p, errors="ignore").read()
    except Exception:
        continue
    for pat, label in [
        (r"-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----", "private key"),
        (r"(?i)\b(private[_-]?key|mnemonic|seed[_-]?phrase)\s*[:=]\s*['\"]?[0-9a-fA-Fx]{32,}", "key material"),
        (r"(?i)\b(api[_-]?key|apikey|access[_-]?token|secret)\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{20,}", "api key"),
        (r"https?://[^\s\"'`)]*(apikey|api_key|key=|token=)[^\s\"'`)]+", "keyed URL"),
    ]:
        if re.search(pat, txt):
            bad.append((p, label))
if bad:
    for p, label in bad[:20]: print("SECRET HIT:", p, label)
    fail(f"{len(bad)} secret-scan hits")

report = {
    "generated": "2026-11-10",
    "corpus": {"readme_lines": 466, "research_files": 48},
    "counts": recomputed,
    "open": [{"id": r["id"], "name": r["name"], "chain": r["chain"], "usd": r["usd"],
              "addr": r["addr"], "next": r["next"]} for r in open_rows],
    "checks": {
        "register_integrity": "PASS",
        "disposition_counts": "PASS",
        "open_completeness": "PASS",
        "readme_coverage": "PASS",
        "secret_scan": "PASS",
        "research_corpus_ack": "PASS",
    },
    "headline_new_extractable_usd": 0,
}
json.dump(report, open(os.path.join(OUT, "recon-report.json"), "w"), indent=2)

lines = [
    "CA3 RESIDUAL RECONCILIATION — CI VALIDATOR",
    "=" * 48,
    f"rows                : {recomputed['total']}",
    f"README-sourced      : {recomputed['readme_sourced']}",
    f"research-sourced    : {recomputed['research_sourced']}",
    f"prior-assigned      : {recomputed['prior_assigned']}",
    f"prior-covered       : {recomputed['prior_covered']}",
    f"prior-partial       : {recomputed['prior_partial']}",
    f"prior total         : {recomputed['prior_total']}",
    f"research-only closed: {recomputed['research_only_closed']}",
    f"not-a-protocol      : {recomputed['not_a_protocol']}",
    f"OPEN (LOW only)     : {recomputed['open']}",
    f"new extractable USD : 0",
    "",
    "OPEN list (funds x plausibility):",
]
for r in open_rows:
    lines.append(f"  [{r['id']}] {r['name']} | {r['chain']} | ${r['usd']:,.0f} | {r['addr'][:70]}")
lines += ["", "All checks PASS.", ""]
open(os.path.join(OUT, "SUMMARY.txt"), "w").write("\n".join(lines))
print("\n".join(lines))
