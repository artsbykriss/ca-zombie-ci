#!/usr/bin/env python3
"""Annotated disassembly dump: pc, opcode, imm, and PUSH4 constants resolved to ABI names."""
import sys, json
from Crypto.Hash import keccak
sys.path.insert(0, '/home/heisenberg/CA/ca2-open-sunswap/analysis')
from disasm import disasm, OPS

def h(sig):
    k = keccak.new(digest_bits=256); k.update(sig.encode()); return k.hexdigest()[:8]

def load_names(abi_path):
    d = json.load(open(abi_path)); m = {}
    def typ(x):
        t = x['type']
        if t.startswith('tuple'):
            return '(' + ','.join(typ(i) for i in x.get('components', [])) + ')' + t[5:]
        return t
    for e in d['abi']['entrys']:
        n = e.get('name')
        if not n: continue
        sig = n + '(' + ','.join(typ(i) for i in e.get('inputs', [])) + ')'
        m[h(sig)] = sig
        # also try canonical v4 pool key order variants
    return m

if __name__ == '__main__':
    code = bytes.fromhex(open(sys.argv[1]).read().strip())
    start = int(sys.argv[2], 0); ln = int(sys.argv[3], 0) if len(sys.argv) > 3 else 400
    names = load_names(sys.argv[4]) if len(sys.argv) > 4 else {}
    ins = disasm(code)
    for pc, n, a, s in ins:
        if pc < start: continue
        if pc > start + ln: break
        extra = ''
        if n == 'PUSH4' and a is not None:
            k = f'{a:08x}'
            if k in names: extra = '  ; ' + names[k]
        if n.startswith('PUSH') and a is not None and n not in ('PUSH4',):
            if a in (0x00, 0x04, 0x20, 0x40, 0x80, 0xa0): extra = '  ; small'
        print(f'{pc:06x}  {n:14} {("0x%x" % a) if a is not None else "":>12}{extra}')
