#!/usr/bin/env python3
"""Extract a function body from a disassembly .mv file.
Usage: python3 tools/mvfn.py <file> <fnname>
Prints from the line matching '^<vis> <fnname>...' to the matching closing '}' at col0.
"""
import sys, re
f, fn = sys.argv[1], sys.argv[2]
lines = open(f).read().splitlines()
start = None
for i, l in enumerate(lines):
    m = re.match(r'^(public|entry|public\(friend\)|native|fun)?\s*' + re.escape(fn) + r'(<|\(|:)', l)
    if m and l.rstrip().endswith('{'):
        start = i; break
if start is None:
    print("NOT FOUND"); sys.exit(1)
depth = 0
for j in range(start, len(lines)):
    depth += lines[j].count('{') - lines[j].count('}')
    print(lines[j])
    if depth == 0 and j > start:
        break
