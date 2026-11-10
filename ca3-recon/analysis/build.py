#!/usr/bin/env python3
"""Inject the generated disposition tables into README.md."""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

tpl = open(os.path.join(HERE, "README.template.md")).read()
tables = open(os.path.join(HERE, "tables.md")).read()

# split tables.md into sections
a = tables.split("## A. README-sourced candidates (45)\n\n", 1)[1]
a, b = a.split("\n\n## B. Research-file-sourced candidates (42)\n\n", 1)
a = a.strip()
b = b.strip()

out = tpl.replace("{{TABLE_A}}", a).replace("{{TABLE_B}}", b)

# preserve the CI URL if already filled by a previous build
old = os.path.join(ROOT, "README.md")
ci_url = "pending"
if os.path.exists(old):
    m = re.search(r"\*\*CI run:\*\* `([^`]+)`", open(old).read())
    if m:
        ci_url = m.group(1)
out = out.replace("{{CI_URL}}", ci_url)

open(os.path.join(ROOT, "README.md"), "w").write(out)
print("wrote README.md", len(out.splitlines()), "lines")
