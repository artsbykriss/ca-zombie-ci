#!/usr/bin/env python3
"""Derive the reconciliation facts from the live-state scans. Read-only, no secrets."""
import json

eth = json.load(open('eth_schedules_latest.json'))
bsc = json.load(open('bsc_schedules_latest.json'))
logs = json.load(open('logs_since_containment.json'))

def counts(d):
    S, T = d['schedules'], d['tokens']
    live = [s for s in S if not s['cancelled']]
    st = [s for s in live if s['soft'] and s['topable']]
    return {
        'schedules': len(S),
        'tokens': len(T),
        'cancelled': sum(1 for s in S if s['cancelled']),
        'live': len(live),
        'live_soft_topable': len(st),
        'live_soft_topable_positive_claim': len([s for s in st if s['claimable'] and int(s['claimable']) > 0]),
        'live_soft_topable_creators': sorted(set(s['creator'] for s in st)),
        'live_soft_topable_max_claim': max([int(s['claimable'] or 0) for s in st] or [0]),
        'pools_1to1': len([t for t, m in T.items() if m['totalShares'] == m['balance']]),
        'pools_not_1to1': [t for t, m in T.items() if m['totalShares'] != m['balance']],
        'rel_reverts': sum(1 for s in S if s['relReverts']),
        'nftized': sum(1 for s in S if s['nftized']),
    }

# nominal marks captured 2026-10-20 from Blockscout token endpoint + DefiLlama (TCT)
prices = {'VEK': 0.01001408, 'AXGT': 0.00749204, 'AXGT2': 0.00242024,
          'OXN': 0.00041693, 'TCT': 0.0014631574419741824}
dec = {'VEK': 18, 'AXGT': 18, 'AXGT2': 18, 'OXN': 18, 'TCT': 8}
addr = {'VEK': '0xb4fa28e9dBA552dF8a55579Bc9494f0F7486d215',
        'AXGT': '0x6112C3509A8a787df576028450FebB3786A2274d',
        'AXGT2': '0xDd66781D0E9a08D4FBb5eC7BAc80B691BE27F21D',
        'OXN': '0x609e79A9FB9A71655b017F637a962B9962f4A9Fc',
        'TCT': '0xE9db0A36877dE86EfD134F87CAF3Db29f90b275c'}
liquidity = {'VEK': 0, 'AXGT': 154294.82, 'AXGT2': 0, 'OXN': 0, 'TCT': 32080.89}
rows = []
for sym, a in addr.items():
    m = eth['tokens'][a.lower()]
    bal = int(m['balance']) / 10 ** dec[sym]
    paper = bal * prices[sym]
    hard_lo = 0 if liquidity[sym] == 0 else 0.25 * liquidity[sym]
    hard_hi = 0 if liquidity[sym] == 0 else 0.50 * liquidity[sym]
    rows.append({'symbol': sym, 'address': addr[sym], 'balance': str(m['balance']),
                 'shares': m['totalShares'], 'one_to_one': m['totalShares'] == m['balance'],
                 'balance_tokens': bal, 'price_usd': prices[sym], 'paper_usd': round(paper, 2),
                 'dex_liquidity_usd': liquidity[sym],
                 'hard_realizable_usd': [round(hard_lo, 2), round(hard_hi, 2)]})

bsc_pairs = {
    'DROPS': {'address': '0xff0e7232c902d96b57cc99e52c1056acdd64bd5c', 'paper': 1121453.40,
              'liq': 29767.83, 'hard': [7441.96, 14883.92]},
    'LOOPRA': {'address': '0x46be5c507b218d7facd13aed8fcfbaba4d36e943', 'paper': 459000.0,
               'liq': 45885.04, 'hard': [11471.26, 22942.52]},
}
eth_hard = [sum(r['hard_realizable_usd'][i] for r in rows) for i in (0, 1)]
bsc_hard = [sum(v['hard'][i] for v in bsc_pairs.values()) for i in (0, 1)]


S = {s['id']: s for s in eth['schedules']}
key_ids = [5040, 4939, 5035, 4963, 4972, 5063, 5030]
facts_key = {}
for i in key_ids:
    s = S[i]
    facts_key[str(i)] = {k: s[k] for k in
        ('token', 'creator', 'beneficiary', 'T', 'released', 'soft', 'nftized',
         'cancelled', 'topable', 'relShares', 'claimable')}

facts = {
    'generated_utc': '2026-10-20',
    'scope': 'ZH4-PASS2 corrections reconciliation — P2-03 UNCX (excluded/prior-corpus protocol)',
    'ethereum': {
        'block': eth['block'],
        'manager': eth['manager'],
        'code_size': eth['codeSize'],
        'flatFee': eth['flatFee'],
        'feePercentage': eth['feePercentage'],
        'nextVestingId': eth['nextVestingId'],
        'counts': counts(eth),
        'key_schedules': facts_key,
    },
    'bsc': {
        'block': bsc['block'],
        'manager': bsc['manager'],
        'code_size': bsc['codeSize'],
        'flatFee': bsc['flatFee'],
        'feePercentage': bsc['feePercentage'],
        'nextVestingId': bsc['nextVestingId'],
        'counts': counts(bsc),
        'btcle_pool': bsc['tokens']['0x9d2144328e1d618f54cd38540f5ee50671f6a208'],
    },
    'recent_releases_since_containment': [
        {'id': 5040, 'block': 26209802,
         'tx': '0x6d88947837a29ab2a08125249b9b67439367cc800234c8d7cf80dc40426dde33',
         'caller': '0x648F3FD329b8c8a83e1D6cd069e1FdC619094285',
         'beneficiary': '0x648F3FD329b8c8a83e1D6cd069e1FdC619094285',
         'caller_is_beneficiary': True, 'amount_wei': '100000000000000000000000'},
        {'id': 4939, 'block': 26228470,
         'tx': '0xf427acce73a510ff1784664f978229cbb5fac3e20c3f1e216a8a002882c0c11f',
         'caller': '0xDfF7D686C7c77418b8838734761d3b6a0DeD02Ef',
         'beneficiary': '0xDfF7D686C7c77418b8838734761d3b6a0DeD02Ef',
         'caller_is_beneficiary': True, 'amount_wei': '99500000000000'},
    ],
    'events_since_containment': {
        'containment_last_block': 26197490,
        'VestingCreated': len(logs['VestingCreated']),
        'VestingCancelled': len(logs['VestingCancelled']),
        'TokensReleased': len(logs['TokensReleased']),
        'FlatFeeUpdated_after_containment': 0,
        'CreatorFeeExemptionUpdated_after_containment': 0,
    },
    'nominal_vs_realizable_eth': {
        'pass2_nominal_usd': 4180000,
        'rows': rows,
        'paper_total_top5': round(sum(r['paper_usd'] for r in rows), 2),
        'hard_realizable_total_usd': [round(eth_hard[0], 2), round(eth_hard[1], 2)],
        'note': 'VEK/AXGT2/OXN have no DexScreener pair at all -> $0 hard despite Blockscout marks; '
                'AXGT and TCT are bounded by 25-50% of the deepest pool depth ($154,294.82 / $32,080.89).',
    },
    'nominal_vs_realizable_bsc': {
        'pass2_nominal_usd': 1480000,
        'rows': bsc_pairs,
        'hard_realizable_total_usd': [round(bsc_hard[0], 2), round(bsc_hard[1], 2)],
        'note': 'DROPS has a $29.8k PancakeSwap pool (paper $1.12M); CDT has no pair; '
                'LOOPRA has a $45.9k pool (paper ~$459k); BTCLE (the attacked pool) holds 4.21e-8.',
    },
    'combined_hard_realizable_if_bug_were_reachable_usd': [round(eth_hard[0] + bsc_hard[0], 2),
                                                           round(eth_hard[1] + bsc_hard[1], 2)],
    'pass2_claims': {
        'release_cancel_permissionless': 'REJECTED — release() requires msg.sender == beneficiary/NFT owner; '
                                         'cancel() requires msg.sender == creator (source lines 597-601, 670-677).',
        'creation_fee_does_not_gate_release': 'TRUE but irrelevant — the exploit needs to create schedules first; '
                                              'createVesting/createDailySoft/createAirdrop all require msg.value >= flatFee = uint256.max.',
        'totalTokenShares_equals_balances_1to1': 'CONFIRMED for VEK/AXGT/OXN — and this shows the pools are NOT '
                                                  'share-corrupted; a release pays exactly the pro-rata claim, no premium.',
        'release_processed_oct17': 'CONFIRMED — but the caller was exactly the schedule beneficiary; a normal claim.',
        'non_proxy_no_pause': 'CONFIRMED — code 18,010 bytes, EIP-1967 impl slot 0, no pause in the ABI/source.',
        'nominal_5_7m': 'NOMINAL ONLY — three of the five largest ETH marks have no DEX pair; hard realizable '
                        '~$70k-140k if the bug were reachable, and $0 live because it is not.',
    },
    'verdict': {
        'live_EU_usd': 0,
        'confidence': 'high',
        'reasons': [
            'flatFee = uint256.max on ETH (and 35,000 BNB on BSC) with zero creator/token exemptions -> no new schedules',
            'all 39 cancelled / 5061 live ETH schedules scanned: the only live soft+topable schedule (5063) has claim 0 '
            'and its PEPE pool holds 288.9 PEPE (~$40); 0 live soft+topable schedules have a positive claim',
            'BSC: 66 live soft+topable schedules, all created by the Oct-14 helper 0x8174eee3, all claim 0; BTCLE pool 4.21e-8',
            'release()/cancel() are role-gated: no third party can operate another user\'s schedule; NFT transfers update '
            'the beneficiary but never the creator, so buying a vesting NFT grants release only',
            'the double-debit requires a release followed by a creator-cancel of a soft schedule; no attacker-controlled '
            'schedule remains in a funded pool',
        ],
    },
    'conditional_rearm': {
        'trigger': 'owner setFlatFee(lower) or setCreatorFeeExempt/setTokenFeeExempt',
        'proven_by': 'test_H_feeZeroReArmsCreation (fork: flatFee->0 and feePercentage->0; create/release/cancel succeed)',
        'monitor': 'FlatFeeUpdated / CreatorFeeExemptionUpdated / TokenFeeExemptionUpdated on ETH 0xA98F... and BSC 0x7f3f...',
    },
}
json.dump(facts, open('reconcile_facts.json', 'w'), indent=1)
print(json.dumps({k: facts[k] for k in ('verdict', 'combined_hard_realizable_if_bug_were_reachable_usd')}, indent=1))
print('ETH hard', facts['nominal_vs_realizable_eth']['hard_realizable_total_usd'])
print('BSC hard', facts['nominal_vs_realizable_bsc']['hard_realizable_total_usd'])
print('counts eth', facts['ethereum']['counts'])
print('counts bsc', facts['bsc']['counts'])
