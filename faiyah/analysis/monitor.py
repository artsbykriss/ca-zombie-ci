#!/usr/bin/env python3
"""Faiyah Staking monitor — read-only snapshot + diff against a baseline.

Tracks the commingled-principal flaw:
  * deficit = rewardDebtTotal - totalReward  (rewards already paid out of principal)
  * unfunded liabilities vs pool balance
  * new reward funding (totalReward increase) and new stakes (nextStakeId increase)
  * claim-bot / exit activity (rewardDebtTotal and totalStaked deltas)

Usage:
  python3 monitor.py --out monitor_snapshot.json
  python3 monitor.py --baseline monitor_baseline.json --out monitor_snapshot.json
Exit code 1 if any alert fires (useful for a scheduled CI monitor).
"""
import argparse, json, subprocess, sys
import rpc

F = '0x95c8853e6bD1DBCE2428Aa6953eb7680261F22fe'
POOLS = {
    '41': '0xca3aab5282586efd5c38edb5083fed87da11ccd9',
    '42': '0x895b1761941a3ffe6282dbcd312d45399ac0af4e',
    '33': '0xc9ee0d33e6bf0626332b47d0507352f2595ae989',
    '37': '0x5287909a936cdf881223e533bf93957b78ff02b9',
    '44': '0x0a1ff9a1e02c09beb918658e9a9d8f5f752f0090',
    '45': '0x56b51a11200b5070f67652778a15166068d037dc',
    '21': '0x7d89c976cfca1dfb94d82e441f15381d6362756a',
    '9': '0x2a2e7919c9d4edc815a0754ba4a539a245d864ad',
    '32': '0x85427e2f6ca737614e3a771b8de43e8473161e5e',
}


def sig(s):
    return subprocess.run(['cast', 'sig', s], capture_output=True, text=True).stdout.strip()


S = {n: sig(f) for n, f in {
    'totalStaked': 'totalStaked()', 'totalReward': 'totalReward()',
    'rewardDebtTotal': 'rewardDebtTotal()', 'nextStakeId': 'nextStakeId()',
    'status': 'status()', 'stakingToken': 'stakingToken()', 'apr': 'apr()',
    'endTime': 'endTime()', 'claimDelay': 'claimDelay()',
}.items()}
S['balanceOf'] = sig('balanceOf(address)')


def read_pool(p):
    e = {}
    for n in S:
        if n in ('balanceOf', 'stakingToken'):
            continue
        e[n] = rpc.dec_uint(rpc.call(p, S[n]))
    stok = rpc.dec_addr(rpc.call(p, S['stakingToken']))
    e['stakingToken'] = stok
    zero = '0x' + '0' * 40
    e['balance'] = (rpc.dec_uint(rpc.call(stok, S['balanceOf'] + rpc.enc_addr(p)))
                    if stok != zero else rpc.dec_uint(rpc.rpc('eth_getBalance', [p, 'latest'])))
    e['deficit'] = max(0, e['rewardDebtTotal'] - e['totalReward'])
    e['fundedBucket'] = e['totalReward'] - e['rewardDebtTotal']
    # liabilities = principal + outstanding accrued; only principal is observable here.
    e['principalCoverage'] = (e['balance'] / e['totalStaked']) if e['totalStaked'] else None
    return e


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--baseline')
    ap.add_argument('--out', default='monitor_snapshot.json')
    a = ap.parse_args()
    bn = rpc.block_number()
    ts = int(rpc.rpc('eth_getBlockByNumber', [hex(bn), False])['timestamp'], 16)
    snap = {'block': bn, 'timestamp': ts, 'factory': F, 'pools': {}}
    for k, p in POOLS.items():
        snap['pools'][k] = read_pool(p)
    alerts = []
    if a.baseline:
        base = json.load(open(a.baseline))
        bts = base.get('timestamp', 0)
        for k, e in snap['pools'].items():
            b = base.get('pools', {}).get(k)
            if not b:
                continue
            if e['deficit'] > b['deficit']:
                alerts.append(f"pool #{k}: deficit grew {(e['deficit']-b['deficit'])/1e18:.4f} (units) "
                              f"{b['deficit']} -> {e['deficit']}")
            if e['totalReward'] > b['totalReward']:
                alerts.append(f"pool #{k}: NEW REWARD FUNDING +{e['totalReward']-b['totalReward']} (units)")
            if e['nextStakeId'] > b['nextStakeId']:
                alerts.append(f"pool #{k}: {e['nextStakeId']-b['nextStakeId']} new stake(s)")
            if e['status'] != b['status']:
                alerts.append(f"pool #{k}: status {b['status']} -> {e['status']}")
            if e['totalStaked'] < b['totalStaked']:
                alerts.append(f"pool #{k}: principal exited {b['totalStaked']-e['totalStaked']} (units)")
            if e['principalCoverage'] is not None and e['principalCoverage'] < 1:
                alerts.append(f"pool #{k}: principal coverage {e['principalCoverage']:.6f} < 1")
        print(f"baseline ts {bts}, now {ts}, dt {ts-bts}s")
    for k, e in snap['pools'].items():
        print(f"#{k} status={e['status']} staked={e['totalStaked']} bal={e['balance']} "
              f"reward={e['totalReward']} debt={e['rewardDebtTotal']} deficit={e['deficit']} "
              f"coverage={e['principalCoverage']}")
    for x in alerts:
        print('ALERT:', x)
    snap['alerts'] = alerts
    json.dump(snap, open(a.out, 'w'), indent=1)
    print('wrote', a.out)
    return 1 if alerts else 0


if __name__ == '__main__':
    sys.exit(main())
