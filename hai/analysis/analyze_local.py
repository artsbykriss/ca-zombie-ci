#!/usr/bin/env python3
"""Mine local Blockscout dumps: proposer census, proposal cadence, vote power, payloads."""
import json, collections, datetime, re

logs = json.load(open('gov_logs_all.json'))
txs = json.load(open('gov_txs_all.json'))

def params(x):
    d = x.get('decoded') or {}
    return {p['name']: p.get('value') for p in d.get('parameters', [])}

def ev(x):
    d = x.get('decoded') or {}
    return (d.get('method_call') or '').split('(')[0]

created = [x for x in logs if ev(x) == 'ProposalCreated']
votes = [x for x in logs if ev(x) == 'VoteCast']
queued = [x for x in logs if ev(x) == 'ProposalQueued']
executed = [x for x in logs if ev(x) == 'ProposalExecuted']

print('proposals', len(created), 'votes', len(votes), 'queued', len(queued), 'executed', len(executed))

# proposer census
prop = collections.Counter()
prop_first = {}
prop_last = {}
for x in created:
    p = params(x)
    a = p['proposer'].lower()
    prop[a] += 1
    ts = x['block_timestamp']
    prop_first[a] = min(prop_first.get(a, ts), ts)
    prop_last[a] = max(prop_last.get(a, ts), ts)
print('\nTOP PROPOSERS')
for a, n in prop.most_common(12):
    print(a, n, prop_first[a], prop_last[a])

# recent cadence
cut = '2026-10-11'
recent = [x for x in created if x['block_timestamp'] >= cut]
print('\nproposals since', cut, len(recent))
print('by proposer', collections.Counter(params(x)['proposer'].lower() for x in recent).most_common())
for day, n in sorted(collections.Counter(x['block_timestamp'][:10] for x in created if x['block_timestamp'] >= '2026-09-01').items()):
    print(' ', day, n)

# vote census
vot = collections.Counter()
vweight = collections.Counter()
vsupport = collections.defaultdict(collections.Counter)
for x in votes:
    p = params(x)
    v = p['voter'].lower()
    vot[v] += 1
    vweight[v] += int(p['weight'])
    vsupport[v][p['support']] += 1
print('\nTOP VOTERS (count, summed weight/1e18, support dist)')
for a, n in vot.most_common(12):
    print(a, n, vweight[a] / 1e18, dict(vsupport[a]))

# all-time support totals / recent
print('\nVOTE support totals all-time', collections.Counter(params(x)['support'] for x in votes))
recent_v = [x for x in votes if x['block_timestamp'] >= cut]
print('votes since', cut, len(recent_v), collections.Counter(params(x)['support'] for x in recent_v))
print('vote weights since', cut, sum(int(params(x)['weight']) for x in recent_v) / 1e18)

# latest proposals detail
print('\nLAST 15 PROPOSALS')
for x in sorted(created, key=lambda x: int(x['block_number']))[-15:]:
    p = params(x)
    print(x['block_number'], x['block_timestamp'], 'id', p['proposalId'][:12], 'proposer', p['proposer'],
          'desc', (p['description'] or '')[:70].replace('\n', ' '),
          'targets', p.get('targets'), 'calldatas', [c[:10] for c in (p.get('calldatas') or [])])

# hardening proposal id
print('\nQUEUED last 10')
for x in sorted(queued, key=lambda x: int(x['block_number']))[-10:]:
    p = params(x)
    print(x['block_number'], x['block_timestamp'], p['proposalId'], 'eta', p.get('etaSeconds'))
print('\nEXECUTED last 10')
for x in sorted(executed, key=lambda x: int(x['block_number']))[-10:]:
    p = params(x)
    print(x['block_number'], x['block_timestamp'], p['proposalId'])

# any proposal with description mentioning harden
print('\nHARDENING-ish proposals')
for x in created:
    p = params(x)
    d = (p.get('description') or '').lower()
    if 'harden' in d or 'quorum' in d or 'voting period' in d or 'security' in d:
        print(x['block_number'], x['block_timestamp'], p['proposalId'], p['proposer'], (p.get('description') or '')[:120].replace('\n', ' '))

# tx census: methods + from
print('\nTX methods', collections.Counter(t.get('method') for t in txs).most_common(15))
print('TX senders', collections.Counter((t.get('from') or {}).get('hash', '').lower() for t in txs).most_common(8))
