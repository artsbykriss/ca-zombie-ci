#!/usr/bin/env python3
"""Extract WAT function bodies and resolve call targets (imports + internal funcs)."""
import re, sys

def load(path):
    src = open(path).read()
    # imports: (import "mod" "name" (func (;N;) (type T)))
    imports = {}
    for m in re.finditer(r'\(import "([^"]+)" "([^"]+)" \(func \(;(\d+);\)', src):
        imports[int(m.group(3))] = f'{m.group(1)}.{m.group(2)}'
    # exports
    exports = {}
    for m in re.finditer(r'\(export "([^"]+)" \(func (\d+)\)', src):
        exports[m.group(1)] = int(m.group(2))
    # functions: (func (;N;) (type T) ... )  -- bodies may nest parens
    funcs = {}
    for m in re.finditer(r'\(func \(;(\d+);\)', src):
        idx = int(m.group(1)); start = m.start()
        # find matching close paren
        depth = 0; i = start
        while i < len(src):
            if src[i] == '(':
                depth += 1
            elif src[i] == ')':
                depth -= 1
                if depth == 0:
                    break
            i += 1
        funcs[idx] = src[start:i+1]
    return imports, exports, funcs

def resolve_calls(body, imports):
    out = []
    for m in re.finditer(r'\(call (\d+)\)', body):
        n = int(m.group(1))
        out.append((n, imports.get(n, f'func{n}')))
    return out

if __name__ == '__main__':
    path = sys.argv[1]
    target = sys.argv[2] if len(sys.argv) > 2 else None
    imports, exports, funcs = load(path)
    print('imports:', len(imports), 'funcs:', len(funcs))
    if target:
        idx = exports.get(target)
        print(f'export {target} -> func {idx}')
        body = funcs.get(idx, '')
        print('--- calls ---')
        for n, name in resolve_calls(body, imports):
            print(f'  {name}')
    else:
        for name, idx in exports.items():
            body = funcs.get(idx, '')
            calls = resolve_calls(body, imports)
            print(f'{name} (func {idx}): {[c[1] for c in calls]}')
