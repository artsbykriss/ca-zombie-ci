#!/usr/bin/env python3
"""Trace which internal function in an export reaches require_auth (call 11 for pool.wat)."""
import re, sys

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
        idx = int(m.group(1)); start = m.start()
        depth = 0; i = start
        while i < len(src):
            if src[i] == '(': depth += 1
            elif src[i] == ')':
                depth -= 1
                if depth == 0: break
            i += 1
        funcs[idx] = src[start:i+1]
    return src, imports, exports, funcs

def calls_of(body):
    return [int(m.group(1)) for m in re.finditer(r'\bcall (\d+)\b', body)]

if __name__ == "__main__":
    path, export = sys.argv[1], sys.argv[2]
    ra = int(sys.argv[3]) if len(sys.argv) > 3 else 11  # require_auth import index
    src, imports, exports, funcs = load(path)
    root = exports[export]
    # find which funcs directly contain "call ra"
    direct = {i for i,b in funcs.items() if re.search(rf'\bcall {ra}\b', b)}
    print('require_auth import idx:', ra, imports.get(ra))
    print('funcs directly calling require_auth:', sorted(direct))
    # BFS from root
    seen = set()
    frontier = [root]
    path_to = {root: [root]}
    while frontier:
        nxt = []
        for f in frontier:
            if f in seen: continue
            seen.add(f)
            if f in direct:
                print(f'PATH to require_auth: {path_to[f]}')
            for c in calls_of(funcs.get(f, '')):
                if c >= 62:  # internal funcs start after imports (62 imports)
                    if c not in path_to:
                        path_to[c] = path_to[f] + [c]
                    nxt.append(c)
        frontier = nxt
