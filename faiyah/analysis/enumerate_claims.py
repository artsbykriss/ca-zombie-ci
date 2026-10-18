#!/usr/bin/env python3
"""Enumerate every stake in selected Faiyah pools and sum accrued/claimable rewards.

Read-only. Uses claimableReward(uint256) -> (bool claimableNow, uint256 accrued).
Writes ci-out/claims.json (or analysis/claims_local.json with --out).

Usage:
  python3 enumerate_claims.py 33,37,44,45,21
  python3 enumerate_claims.py all            # all pools with nextStakeId>0
"""
import json, os, subprocess, sys, time
import rpc

F = '0x95c8853e6bD1DBCE2428Aa6953eb7680261F22fe'


def sig(s):
    return subprocess.run(['cast', 'sig', s], capture_output=True, text=True).stdout.strip()


SEL_NEXT = sig('nextStakeId()')
SEL_CLAIM = sig('claimableReward(uint256)')
SEL_STAKES = sig('stakes(uint256)')
SEL_STAKED = sig('totalStaked()')
SEL_REWARD = sig('totalReward()')
SEL_DEBT = sig('rewardDebtTotal()')
SEL_BAL = sig('balanceOf(address)')


def words(raw):
    raw = raw[2:] if raw.startswith('0x') else raw
    return [raw[i:i + 64] for i in range(0, len(raw), 64)]


def batch_retry(calls, chunk=60, tries=5):
    out = []
    for s in range(0, len(calls), chunk):
        part = calls[s:s + chunk]
        for t in range(tries):
            try:
                out += rpc.batch(part)
                break
            except Exception as e:
                if t == tries - 1:
                    raise
                time.sleep(2 * (t + 1))
    return out


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else 'all'
    outpath = 'analysis/claims.json'
    if '--out' in sys.argv:
        outpath = sys.argv[sys.argv.index('--out') + 1]

    bn = rpc.block_number()
    ts = int(rpc.rpc('eth_getBlockByNumber', [hex(bn), False])['timestamp'], 16)
    n = rpc.dec_uint(rpc.call(F, sig('idCounter()')))
    pools = []
    for i in range(0, n, 20):
        res = rpc.batch([('eth_call', [{'to': F, 'data': sig('allPools(uint256)') + rpc.hexword(j)}, 'latest'])
                         for j in range(i, min(i + 20, n))])
        pools += [rpc.dec_addr(r) for r in res]

    if arg == 'all':
        want = list(range(n))
    else:
        want = [int(x) for x in arg.split(',')]

    out = {'block': bn, 'timestamp': ts, 'factory': F, 'pools': {}}
    for i in want:
        p = pools[i]
        nxt = rpc.dec_uint(rpc.call(p, SEL_NEXT)) or 0
        if nxt == 0:
            continue
        staked = rpc.dec_uint(rpc.call(p, SEL_STAKED))
        reward = rpc.dec_uint(rpc.call(p, SEL_REWARD))
        debt = rpc.dec_uint(rpc.call(p, SEL_DEBT))
        stok = rpc.dec_addr(rpc.call(p, sig('stakingToken()')))
        if stok and stok != '0x' + '0' * 40:
            bal = rpc.dec_uint(rpc.call(stok, SEL_BAL + rpc.enc_addr(p)))
        else:
            bal = rpc.dec_uint(rpc.rpc('eth_getBalance', [p, 'latest']))
        print(f'#{i} {p} next={nxt} staked={staked} bal={bal} debt={debt} ...', flush=True)

        calls = [('eth_call', [{'to': p, 'data': SEL_CLAIM + rpc.hexword(j)}, 'latest']) for j in range(nxt)]
        raw = batch_retry(calls, 60)
        now_sum = 0
        acc_sum = 0
        now_cnt = 0
        acc_rows = []
        bad = 0
        for j, r in enumerate(raw):
            if not r or len(r) < 130:
                bad += 1
                continue
            w = words(r)
            claimable_now = int(w[0], 16) != 0
            amt = int(w[1], 16)
            if claimable_now:
                now_sum += amt
                now_cnt += 1
            acc_sum += amt
            if amt > 0:
                acc_rows.append([j, amt, 1 if claimable_now else 0])
        print(f'  -> accrued={acc_sum} claimableNow={now_sum} ({now_cnt} stakes) bad={bad}', flush=True)
        out['pools'][str(i)] = {
            'addr': p, 'nextStakeId': nxt, 'totalStaked': staked, 'balance': bal,
            'totalReward': reward, 'rewardDebtTotal': debt,
            'accruedTotal': acc_sum, 'claimableNow': now_sum,
            'claimableNowCount': now_cnt, 'badReads': bad,
            'topAccrued': sorted(acc_rows, key=lambda x: -x[1])[:40],
        }
        with open(outpath, 'w') as f:
            json.dump(out, f, indent=1)
    print('wrote', outpath)


if __name__ == '__main__':
    main()
