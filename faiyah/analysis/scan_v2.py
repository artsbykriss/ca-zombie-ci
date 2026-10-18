#!/usr/bin/env python3
"""Batched, read-only enumeration of all Faiyah pools at latest block.
Reads core state + BOTH staking/reward token balances and checks the
commingled-balance identity: balance == totalStaked + totalReward - rewardDebtTotal.
Public keyless RPCs only (see rpc.py)."""
import json, subprocess, sys
import rpc

F = '0x95c8853e6bD1DBCE2428Aa6953eb7680261F22fe'
ZERO = '0x' + '0' * 40
IMPL_SLOT = '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc'


def sig(s):
    return subprocess.run(['cast', 'sig', s], capture_output=True, text=True).stdout.strip()


SEL = {n: sig(s) for n, s in {
    'poolImplementation': 'poolImplementation()',
    'idCounter': 'idCounter()',
    'allPools': 'allPools(uint256)',
    'stakingToken': 'stakingToken()',
    'rewardToken': 'rewardToken()',
    'totalStaked': 'totalStaked()',
    'totalReward': 'totalReward()',
    'rewardDebtTotal': 'rewardDebtTotal()',
    'apr': 'apr()',
    'claimDelay': 'claimDelay()',
    'unstakeDelay': 'unstakeDelay()',
    'interestDelay': 'interestDelay()',
    'interestTime': 'interestTime()',
    'startTime': 'startTime()',
    'endTime': 'endTime()',
    'status': 'status()',
    'nextStakeId': 'nextStakeId()',
    'minStakePerTx': 'minStakePerTx()',
    'maxStakePerTx': 'maxStakePerTx()',
    'stakingLimit': 'stakingLimit()',
    'ownerPool': 'ownerPool()',
    'stakingTokenDecimals': 'stakingTokenDecimals()',
    'rewardTokenDecimals': 'rewardTokenDecimals()',
    'settlementFee': 'settlementFee()',
    'emergencyCloseTime': 'emergencyCloseTime()',
    'treasury': 'treasury()',
    'paused': 'paused()',
}.items()}

ADDR_FIELDS = {'stakingToken', 'rewardToken', 'ownerPool', 'treasury'}
UINT_FIELDS = [k for k in SEL if k not in ADDR_FIELDS and k not in ('allPools', 'idCounter', 'poolImplementation')]


def main():
    bn = rpc.block_number()
    blk = rpc.rpc('eth_getBlockByNumber', [hex(bn), False])
    ts = int(blk['timestamp'], 16)
    n = rpc.dec_uint(rpc.call(F, SEL['idCounter']))
    impl = rpc.dec_addr(rpc.call(F, SEL['poolImplementation']))
    print(f'block={bn} ts={ts} idCounter={n} impl={impl}', flush=True)

    pools = []
    for i in range(0, n, 20):
        idxs = list(range(i, min(i + 20, n)))
        res = rpc.batch([('eth_call', [{'to': F, 'data': SEL['allPools'] + rpc.hexword(j)}, 'latest']) for j in idxs])
        pools += [rpc.dec_addr(r) for r in res]

    # build one flat batch
    calls, keys = [], []
    for i, p in enumerate(pools):
        for f in UINT_FIELDS + list(ADDR_FIELDS):
            calls.append(('eth_call', [{'to': p, 'data': SEL[f]}, 'latest']))
            keys.append((i, f))
        calls.append(('eth_getStorageAt', [p, IMPL_SLOT, 'latest']))
        keys.append((i, '__impl'))

    out = []
    for start in range(0, len(calls), 60):
        chunk = calls[start:start + 60]
        res = rpc.batch(chunk)
        for (i, f), r in zip(keys[start:start + 60], res):
            while len(out) <= i:
                out.append({})
            if f == '__impl':
                out[i]['impl'] = rpc.dec_addr(r) if r else None
            elif f in ADDR_FIELDS:
                out[i][f] = rpc.dec_addr(r) if r else None
            else:
                out[i][f] = rpc.dec_uint(r)

    # balances (staking + reward token), native-aware
    bcalls, bkeys = [], []
    for i, e in enumerate(out):
        for tag in ('stakingToken', 'rewardToken'):
            t = e.get(tag)
            if t and t != ZERO:
                bcalls.append(('eth_call', [{'to': t, 'data': sig('balanceOf(address)') + rpc.enc_addr(pools[i])}, 'latest']))
            else:
                bcalls.append(('eth_getBalance', [pools[i], 'latest']))
            bkeys.append((i, tag))
    for start in range(0, len(bcalls), 60):
        res = rpc.batch(bcalls[start:start + 60])
        for (i, tag), r in zip(bkeys[start:start + 60], res):
            out[i]['bal_' + tag] = rpc.dec_uint(r)

    # token metadata
    meta = {}
    for t in sorted({e.get('stakingToken') for e in out} | {e.get('rewardToken') for e in out}):
        if not t or t == ZERO:
            meta[t] = {'symbol': 'NATIVE', 'decimals': 18}
            continue
        sym = rpc.call(t, sig('symbol()'))
        dec = rpc.call(t, sig('decimals()'))
        try:
            sym = bytes.fromhex(sym[2:]).rstrip(b'\x00').decode()
        except Exception:
            sym = sym
        meta[t] = {'symbol': sym, 'decimals': rpc.dec_uint(dec)}

    res = {'block': bn, 'timestamp': ts, 'factory': F, 'poolImplementation': impl,
           'poolCount': n, 'tokenMeta': meta, 'pools': {}}
    for i, e in enumerate(out):
        e['idx'] = i
        e['addr'] = pools[i]
        st, rt = e.get('stakingToken'), e.get('rewardToken')
        same = st == rt
        e['sameToken'] = same
        # identity uses the token that carries principal (same token => that one)
        bal = e.get('bal_stakingToken')
        e['identityDelta'] = None
        e['fundedBucket'] = None
        e['deficit'] = None
        if e.get('totalStaked') is not None and e.get('totalReward') is not None and e.get('rewardDebtTotal') is not None:
            e['fundedBucket'] = e['totalReward'] - e['rewardDebtTotal']
            if bal is not None:
                e['identityDelta'] = bal - (e['totalStaked'] + e['totalReward'] - e['rewardDebtTotal'])
            e['deficit'] = max(0, e['rewardDebtTotal'] - e['totalReward'])
        if same:
            e['deficit'] = max(0, (e['rewardDebtTotal'] or 0) - (e['totalReward'] or 0))
        res['pools'][pools[i]] = e
        print(f"#{i} {pools[i]} {meta.get(st,{}).get('symbol','?')}->{meta.get(rt,{}).get('symbol','?')} "
              f"same={same} staked={e.get('totalStaked')} bal={bal} rw={e.get('totalReward')} "
              f"debt={e.get('rewardDebtTotal')} funded={e.get('fundedBucket')} "
              f"deficit={e.get('deficit')} idDelta={e.get('identityDelta')} status={e.get('status')} "
              f"end={e.get('endTime')} apr={e.get('apr')} next={e.get('nextStakeId')}", flush=True)
    json.dump(res, open('pools_state_v2.json', 'w'), indent=1)
    print('saved pools_state_v2.json')


if __name__ == '__main__':
    main()
