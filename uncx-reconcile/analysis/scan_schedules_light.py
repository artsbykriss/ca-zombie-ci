#!/usr/bin/env python3
"""Enumerate every UNCX VestingManager schedule + pool state at a fixed block.

Read-only. RPC URL comes from argv/env, never written to disk.
Usage: python3 scan_schedules.py <rpc_url> <block> <manager> <out.json>
"""
import json, os, sys, time, urllib.request
from eth_utils import keccak

def sel(sig: str) -> str:
    return '0x' + keccak(text=sig)[:4].hex()

def enc_u256(x: int) -> str:
    return hex(x)[2:].rjust(64, '0')

def enc_addr(a: str) -> str:
    return a[2:].rjust(64, '0')

def slot_map(key_hex: str, base_slot: int) -> str:
    key = key_hex[2:].rjust(64, '0') if key_hex.startswith('0x') else key_hex.rjust(64, '0')
    s = hex(base_slot)[2:].rjust(64, '0')
    return '0x' + keccak(bytes.fromhex(key + s)).hex()

def slot_num(i: int) -> str:
    return '0x' + hex(i)[2:].rjust(64, '0')

ERR = '__error__'

def rpc_batch(url, calls, tries=5):
    payload = [{"jsonrpc": "2.0", "id": i, "method": m, "params": p} for i, (m, p) in enumerate(calls)]
    last = None
    for k in range(tries):
        try:
            req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                         headers={'Content-Type': 'application/json',
                                                  'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=120) as r:
                out = json.load(r)
            if isinstance(out, dict):
                raise RuntimeError('rpc error: ' + json.dumps(out)[:200])
            res = [None] * len(calls)
            for item in out:
                if 'error' in item:
                    res[item['id']] = {ERR: item['error'].get('message', 'error')}
                else:
                    res[item['id']] = item.get('result')
            if any(x is None for x in res):
                raise RuntimeError('missing results')
            return res
        except Exception as e:  # noqa
            last = e
            time.sleep(0.8 * (k + 1))
    raise RuntimeError(f'batch failed after {tries}: {last}')

def as_int(x):
    if isinstance(x, dict) or x is None:
        return None
    return int(x, 16) if x != '0x' else 0

def main():
    url, block, vm, outpath = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    blk = hex(int(block))
    blknum = int(block)

    slots = {9: 'svgGenerator', 10: 'nextVestingId', 16: 'feePercentage',
             17: 'flatFee', 18: 'feeCollector'}
    res = rpc_batch(url, [("eth_getStorageAt", [vm, slot_num(s), blk]) for s in slots])
    params = {name: res[i] for i, name in enumerate(slots.values())}
    next_id = as_int(params['nextVestingId'])
    code = rpc_batch(url, [("eth_getCode", [vm, blk])])[0]
    out = {
        'manager': vm, 'block': blknum,
        'nextVestingId': next_id,
        'flatFee': str(as_int(params['flatFee'])),
        'feePercentage': as_int(params['feePercentage']),
        'feeCollector': '0x' + params['feeCollector'][-40:],
        'svgGenerator': '0x' + params['svgGenerator'][-40:],
        'codeSize': (len(code) - 2) // 2 if isinstance(code, str) else None,
        'schedules': [], 'tokens': {}, 'skipped': []
    }

    ids = list(range(next_id))
    raw = {}
    CH = int(os.environ.get('SCAN_CHUNK', '250'))
    for start in range(0, len(ids), CH):
        chunk = ids[start:start + CH]
        ccalls = []
        for i in chunk:
            ccalls.append(("eth_call", [{"to": vm, "data": sel('vestingSchedules(uint256)') + enc_u256(i)}, blk]))
            ccalls.append(("eth_call", [{"to": vm, "data": sel('_getReleasableShares(uint256)') + enc_u256(i)}, blk]))
        rr = rpc_batch(url, ccalls)
        for j, i in enumerate(chunk):
            sched_hex, rel_hex = rr[2 * j], rr[2 * j + 1]
            if isinstance(sched_hex, dict):
                out['skipped'].append(i)
                continue
            raw[i] = (sched_hex, rel_hex)
        print(f'{start + len(chunk)}/{len(ids)}', flush=True, file=sys.stderr)
        time.sleep(float(os.environ.get('SCAN_SLEEP', '0')))

    def dec_addr(h, off):
        return '0x' + h[2 + off * 64: 2 + (off + 1) * 64][-40:]

    def dec_u(h, off):
        return int(h[2 + off * 64: 2 + (off + 1) * 64], 16)

    tokens = {}
    for i, (h, rel_h) in raw.items():
        token = dec_addr(h, 0)
        s = {
            'id': i, 'token': token, 'creator': dec_addr(h, 1), 'beneficiary': dec_addr(h, 2),
            'T': str(dec_u(h, 3)), 'released': str(dec_u(h, 4)),
            'soft': bool(dec_u(h, 5)), 'nftized': bool(dec_u(h, 6)),
            'cancelled': bool(dec_u(h, 7)), 'topable': bool(dec_u(h, 8)),
            'vtype': dec_u(h, 9),
            'relShares': None if isinstance(rel_h, dict) or rel_h is None else str(as_int(rel_h)),
            'relReverts': isinstance(rel_h, dict),
            'depositedShares': None, 'claimable': None,
        }
        tokens.setdefault(token, []).append(i)
        out['schedules'].append(s)

    tokmeta = {}
    for t, sched_ids in tokens.items():
        r = rpc_batch(url, [
            ("eth_getStorageAt", [vm, slot_map(t, 11), blk]),
            ("eth_getStorageAt", [vm, slot_map(t, 15), blk]),
            ("eth_call", [{"to": t, "data": sel('balanceOf(address)') + enc_addr(vm)}, blk]),
        ])
        S, R, B = as_int(r[0]), as_int(r[1]), as_int(r[2])
        tokmeta[t] = {'totalShares': str(S), 'shareRatio': str(R), 'balance': str(B),
                      'schedules': len(sched_ids)}
    dep = {}
    nft_owner = {}
    for s in out['schedules']:
        S = int(tokmeta[s['token']]['totalShares'])
        B = int(tokmeta[s['token']]['balance'])
        s['depositedShares'] = str(dep.get(s['id'], 0))
        rel = int(s['relShares']) if s['relShares'] is not None else None
        if rel is None:
            s['claimable'] = None
        elif S == 0:
            s['claimable'] = '0'
        else:
            s['claimable'] = str(rel * B // S)
        s['nftOwner'] = nft_owner.get(s['id'])
    out['tokens'] = tokmeta

    with open(outpath, 'w') as f:
        json.dump(out, f, indent=1)
    print(json.dumps({'block': blknum, 'nextVestingId': next_id,
                      'schedules': len(out['schedules']), 'skipped': out['skipped'],
                      'tokens': len(tokmeta)}, indent=1))

if __name__ == '__main__':
    main()
