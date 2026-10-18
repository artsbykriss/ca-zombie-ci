#!/usr/bin/env python3
"""Per-proposal tally + payload decode for the attacker-era proposals."""
import json, collections

logs = json.load(open('gov_logs_all.json'))
def p(x):
    return {q['name']: q.get('value') for q in (x.get('decoded') or {}).get('parameters', [])}
def ev(x):
    return ((x.get('decoded') or {}).get('method_call') or '').split('(')[0]

created = [x for x in logs if ev(x) == 'ProposalCreated']
votes = [x for x in logs if ev(x) == 'VoteCast']
created.sort(key=lambda x: int(x['block_number']))

# proposals since attacker started
att = [x for x in created if p(x)['proposer'].lower() == '0xdc6a914c4fa69917f4bc6a93cce46cc348a6ec0c']
print('attacker proposals', len(att), 'first', att[0]['block_timestamp'], 'last', att[-1]['block_timestamp'])

vt = collections.defaultdict(lambda: [0, 0, 0])  # against, for, abstain
vcount = collections.Counter()
for v in votes:
    q = p(v); pid = q['proposalId']; s = int(q['support']); w = int(q['weight'])
    vt[pid][s] += w
    vcount[pid] += 1

rows = []
for x in att:
    q = p(x); pid = q['proposalId']
    a, f, ab = vt[pid]
    rows.append((x['block_timestamp'], pid[:14], f / 1e18, a / 1e18, ab / 1e18, vcount[pid], q['proposer']))

print('\nattacker proposals with forVotes > 0:')
for r in rows:
    if r[2] > 0:
        print(r)
print('\nmax forVotes', max(r[2] for r in rows), 'max against', max(r[3] for r in rows))
print('with quorum-reaching forVotes', sum(1 for r in rows if r[2] >= 9739.67))
print('with any vote at all', sum(1 for r in rows if r[5] > 0))

# last 40 with tallies
print('\nLAST 15 attacker proposals tally (ts, pid, for, against, abstain, nvotes)')
for r in rows[-15:]:
    print(r[:6])

# distinct voters on recent attacker proposals and their support
recent_pids = {r[1] for r in rows[-200:]}
rec = [v for v in votes if p(v)['proposalId'][:14] in recent_pids]
print('\nrecent voter census', collections.Counter((p(v)['voter'].lower(), p(v)['support']) for v in rec).most_common(10))

# decode one attacker calldata
print('\n=== payloads (targets/calldata selectors) ===')
for x in att[-3:]:
    q = p(x)
    print(x['block_timestamp'], q['proposalId'][:14], 'targets', q['targets'], 'calldata len', [len(c) for c in q['calldatas']])
json.dump({'sample': p(att[-1]), 'ids': [p(x)['proposalId'] for x in att]}, open('attacker_samples.json', 'w'))
