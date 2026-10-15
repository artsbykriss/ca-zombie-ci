#!/usr/bin/env python3
"""Pull attack tx details, package publication times, override history (Sui, read-only)."""
import json
from sui_query import q

V = {1:"0xc3c7e6eb7202e9fb0389a2f7542b91cc40e4f7a33c02554fec11c4c92f938ea3",
     2:"0xe6717fb7c9d44706bf8ce8a651e25c0a7902d32cb0ff40c0976251ce8ac25655",
     3:"0x846e4d912db89d9db299db0cc7f56f281846ce058fb336ba76e39927836da0ac",
     4:"0xa81086572822d67a1559942f23481de9a60c7709c08defafbb1ca8dffc44e210",
     5:"0x1d5a2e826bdab3cce5cb2493aa36dcf058aa0017c4118738e6967df8821060bf",
     6:"0xf347253e6aa6f81e9da16e841c089fb09c42f7b6ec9514eeee1b5606e23f64f9"}

out = {}
# 1) package publication times
out['package_prev_tx'] = {}
for v, pkg in V.items():
    d = q('{ object(address: "%s") { previousTransaction { digest effects { timestamp status } } } }' % pkg)
    out['package_prev_tx'][f'v{v}'] = d.get('data', {}).get('object')
    print(f"v{v} prevTx:", json.dumps(out['package_prev_tx'][f'v{v}'])[:220])

# 2) oracle 0x0f307cb2 last mutation
d = q('{ object(address: "0x0f307cb2c7e1fe98587f7022ed327e2b5e8372bfa17b8a7a5f1ce6f56f911b81") { previousTransaction { digest effects { timestamp } } } }')
out['oracle_target_prev_tx'] = d.get('data', {}).get('object')
print("target oracle prevTx:", json.dumps(out['oracle_target_prev_tx'])[:250])

# 3) attestation events with full digests
d = q('{ events(filter: {module: "0xa81086572822d67a1559942f23481de9a60c7709c08defafbb1ca8dffc44e210::oracle_attest_action"}, last: 10) { nodes { timestamp sender { address } contents { json } transaction { digest } } } }')
out['attestation_events'] = d['data']['events']['nodes']
print("attestation events:")
for x in out['attestation_events']:
    print('  ', x['timestamp'], x['transaction']['digest'], json.dumps(x['contents']['json'])[:160])

# 4) all override events across v4/v5/v6 with full JSON
out['overrides'] = []
for v in [4,5,6]:
    d = q('{ events(filter: {module: "%s::queue_override_oracle_action"}, last: 50) { nodes { timestamp sender { address } contents { json } transaction { digest } } } }' % V[v])
    ev = d['data']['events']['nodes']
    for x in ev:
        x['_v'] = v
        out['overrides'].append(x)
    print(f"v{v} overrides on page:", len(ev))
for x in out['overrides'][:40]:
    print('  ', x['timestamp'], 'v%d' % x['_v'], x['sender']['address'][:14], json.dumps(x['contents']['json'])[:170])

json.dump(out, open('sui_attack_forensics.json','w'), indent=1)
print('saved sui_attack_forensics.json')
