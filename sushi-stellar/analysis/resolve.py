#!/usr/bin/env python3
"""Resolve WAT export -> transitive host imports, with a path, to learn the letter->name mapping."""
import re, sys
from collections import defaultdict

def load(path):
    src = open(path).read()
    imports = {}
    for m in re.finditer(r'\(import "([^"]+)" "([^"]+)" \(func \(;(\d+);\)', src):
        imports[int(m.group(3))] = f'{m.group(1)}.{m.group(2)}'
    exports = {}
    for m in re.finditer(r'\(export "([^"]+)" \(func (\d+)\)', src):
        exports[m.group(1)] = int(m.group(2))
    funcs = {}
    for m in re.finditer(r'\(func \(;(\d+);\)', src):
        idx = int(m.group(1)); start = m.start(); depth = 0; i = start
        while i < len(src):
            if src[i] == '(': depth += 1
            elif src[i] == ')':
                depth -= 1
                if depth == 0: break
            i += 1
        funcs[idx] = src[start:i+1]
    return imports, exports, funcs

def calls(body):
    return [int(m.group(1)) for m in re.finditer(r'\bcall (\d+)\b', body)]

def transitive(f, funcs, imports, seen=None, path=None):
    seen = seen if seen is not None else set()
    path = path or []
    out = []
    for c in calls(funcs.get(f, '')):
        if c in imports:
            out.append((imports[c], path + [c]))
        elif c in funcs and c not in seen:
            seen.add(c)
            out.extend(transitive(c, funcs, imports, seen, path + [c]))
    return out

if __name__ == '__main__':
    path = sys.argv[1]
    imports, exports, funcs = load(path)
    for name in sys.argv[2:]:
        if name in exports:
            t = transitive(exports[name], funcs, imports)
            s = sorted({x[0] for x in t})
            print(f'{name}: {s}')
