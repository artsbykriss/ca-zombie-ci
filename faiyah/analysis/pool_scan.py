#!/usr/bin/env python3
"""Enumerate all Faiyah pools and read core state (light, read-only)."""
import rpc, subprocess, json, sys

F = '0x95c8853e6bD1DBCE2428Aa6953eb7680261F22fe'

def sig(s):
    return subprocess.run(['cast', 'sig', s], capture_output=True, text=True).stdout.strip()

SELS = {
    'poolImplementation': sig('poolImplementation()'),
    'idCounter': sig('idCounter()'),
    'allPools': sig('allPools(uint256)'),
    'stakingToken': sig('stakingToken()'),
    'rewardToken': sig('rewardToken()'),
    'totalStaked': sig('totalStaked()'),
    'totalReward': sig('totalReward()'),
    'rewardDebtTotal': sig('rewardDebtTotal()'),
    'apr': sig('apr()'),
    'claimDelay': sig('claimDelay()'),
    'unstakeDelay': sig('unstakeDelay()'),
    'interestDelay': sig('interestDelay()'),
    'interestTime': sig('interestTime()'),
    'startTime': sig('startTime()'),
    'endTime': sig('endTime()'),
    'status': sig('status()'),
    'nextStakeId': sig('nextStakeId()'),
    'minStakePerTx': sig('minStakePerTx()'),
    'maxStakePerTx': sig('maxStakePerTx()'),
    'stakingLimit': sig('stakingLimit()'),
    'ownerPool': sig('ownerPool()'),
    'poolName': sig('poolName()'),
    'stakingTokenDecimals': sig('stakingTokenDecimals()'),
    'rewardTokenDecimals': sig('rewardTokenDecimals()'),
    'settlementFee': sig('settlementFee()'),
    'factory': sig('factory()'),
    'poolId': sig('poolId()'),
    'emergencyCloseTime': sig('emergencyCloseTime()'),
}

def main():
    bn = rpc.block_number()
    print('latest block:', bn)
    n = rpc.dec_uint(rpc.call(F, SELS['idCounter']))
    impl = rpc.dec_addr(rpc.call(F, SELS['poolImplementation']))
    print('idCounter:', n, 'poolImplementation:', impl)

    pools = []
    for i in range(n):
        r = rpc.call(F, SELS['allPools'] + rpc.hexword(i))
        pools.append(rpc.dec_addr(r))
    print('pools:', json.dumps(pools, indent=0))

    out = {'block': bn, 'factory': F, 'poolImplementation': impl, 'pools': {}}
    IMPL_SLOT = '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc'

    for i, p in enumerate(pools):
        entry = {'idx': i, 'addr': p}
        # proxy impl
        try:
            entry['impl'] = rpc.dec_addr(rpc.rpc('eth_getStorageAt', [p, IMPL_SLOT, 'latest']))
        except Exception as e:
            entry['impl'] = None
        for name in ['stakingToken', 'rewardToken', 'totalStaked', 'totalReward', 'rewardDebtTotal',
                     'apr', 'claimDelay', 'unstakeDelay', 'interestDelay', 'interestTime',
                     'startTime', 'endTime', 'status', 'nextStakeId', 'minStakePerTx', 'maxStakePerTx',
                     'stakingLimit', 'ownerPool', 'stakingTokenDecimals', 'rewardTokenDecimals',
                     'settlementFee', 'emergencyCloseTime']:
            try:
                raw = rpc.call(p, SELS[name])
                if name in ('stakingToken', 'rewardToken', 'ownerPool'):
                    entry[name] = rpc.dec_addr(raw)
                else:
                    entry[name] = rpc.dec_uint(raw)
            except Exception as e:
                entry[name] = None
        # token balance of pool
        try:
            st = entry['stakingToken']
            bal = rpc.call(st, sig('balanceOf(address)') + rpc.enc_addr(p))
            entry['balance'] = rpc.dec_uint(bal)
        except Exception:
            entry['balance'] = None
        out['pools'][p] = entry
        print(f"#{i} {p} impl={entry['impl'][:12] if entry['impl'] else None} "
              f"st={entry['stakingToken'] if entry['stakingToken'] else '-'} "
              f"totalStaked={entry['totalStaked']} bal={entry['balance']} "
              f"rewardDebt={entry['rewardDebtTotal']} totalReward={entry['totalReward']} "
              f"status={entry['status']} nextStakeId={entry['nextStakeId']}", flush=True)

    json.dump(out, open('pools_state.json', 'w'), indent=1)
    print('saved pools_state.json')

if __name__ == '__main__':
    main()
