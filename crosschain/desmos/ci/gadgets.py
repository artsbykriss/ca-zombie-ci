#!/usr/bin/env python3
"""gadgets.py — extract CWA-2026-006 native-chain gadgets from a Go node/harness objdump.

Usage: gadgets.py <objdump.txt> <out.json>

Emits a JSON inventory of the gadget *shapes* the verified PoC chain needs, with
every candidate address (non-PIE ET_EXEC => these are compile-time constants):
  pivot_add_poprbp : add $S,%rsp ; pop %rbp ; ret        (the PoC pivot, harness 0x4d93f8)
  pivot_add_ret    : add $S,%rsp ; ret
  pop_rax          : pop %rax ; ret                       (loads runtime.g0)
  guard_movups     : movups %xmmN,0x10(%rXX) ; ret        (zero g0.stackguard0/1)
  guard_movq0      : movq $0x0,0x10(%rXX) ; ret           (partial: guard0 only)
  xor_xmm          : xorps/xorpd/pxor %xmm*               (XMM-zero precondition)
  ud2              : ud2                                  (terminal landing)
  jmp_ind / call_ind                                      (Option-D / JOP notes)
Read-only static analysis.
"""
import re, sys, json

asm, outp = sys.argv[1], sys.argv[2]
rx = re.compile(r'^\s*([0-9a-f]+):\t([0-9a-f ]+)\t(.*)$')
insn = []
with open(asm, errors='replace') as f:
    for line in f:
        m = rx.match(line)
        if m:
            # objdump pads mnemonics with runs of spaces -> normalize to single spaces
            insn.append((int(m.group(1), 16), ' '.join(m.group(3).split())))
N = len(insn)


def win(i, k=6):
    out = []
    for j in range(i, min(i + k, N)):
        out.append(insn[j][1])
        if insn[j][1] == 'ret':
            break
    return out


keys = ['pivot_add_poprbp', 'pivot_add_ret', 'pop_rax', 'guard_movups',
        'guard_movq0', 'xor_xmm', 'ud2', 'jmp_ind', 'call_ind']
res = {k: [] for k in keys}
for i, (a, t) in enumerate(insn):
    w = win(i)
    s = ' ; '.join(w)
    if re.match(r'^add\s+\$0x[0-9a-f]+,%rsp$', t):
        if len(w) >= 3 and w[1] == 'pop %rbp' and w[2] == 'ret':
            res['pivot_add_poprbp'].append([a, s])
        if len(w) >= 2 and w[1] == 'ret':
            res['pivot_add_ret'].append([a, s])
    if t == 'pop %rax' and len(w) >= 2 and w[1] == 'ret':
        res['pop_rax'].append([a, s])
    m2 = re.match(r'^movups\s+%xmm([0-9]+),\s*0x10\(%r([a-z0-9]+)\)$', t)
    if m2 and len(w) >= 2 and w[1] == 'ret':
        res['guard_movups'].append([a, s, int(m2.group(1)), m2.group(2)])
    if re.match(r'^movq\s+\$0x0,\s*0x10\(%r[a-z0-9]+\)$', t) and len(w) >= 2 and w[1] == 'ret':
        res['guard_movq0'].append([a, s])
    if re.match(r'^(xorps|xorpd|pxor)\s+%xmm', t):
        res['xor_xmm'].append([a, s])
    if t.startswith('ud2'):
        res['ud2'].append([a, s])
    if re.match(r'^jmp\s+\*', t):
        res['jmp_ind'].append([a, s])
    if re.match(r'^call\s+\*', t):
        res['call_ind'].append([a, s])

out = {k: res[k][:400] for k in keys}
out['_counts'] = {k: len(res[k]) for k in keys}
out['_n_insn'] = N
json.dump(out, open(outp, 'w'))
print(json.dumps(out['_counts']))
