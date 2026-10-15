#!/usr/bin/env python3
"""Sui event scan across ALL package versions of the Switchboard family (read-only).
The Sui GraphQL event index keys events by the package version ID that was latest
when the event was indexed; scan all six version IDs."""
import json
from sui_query import q

VERSIONS = {
 1: "0xc3c7e6eb7202e9fb0389a2f7542b91cc40e4f7a33c02554fec11c4c92f938ea3",
 2: "0xe6717fb7c9d44706bf8ce8a651e25c0a7902d32cb0ff40c0976251ce8ac25655",
 3: "0x846e4d912db89d9db299db0cc7f56f281846ce058fb336ba76e39927836da0ac",
 4: "0xa81086572822d67a1559942f23481de9a60c7709c08defafbb1ca8dffc44e210",
 5: "0x1d5a2e826bdab3cce5cb2493aa36dcf058aa0017c4118738e6967df8821060bf",
 6: "0xf347253e6aa6f81e9da16e841c089fb09c42f7b6ec9514eeee1b5606e23f64f9",
}
MODULES = ["aggregator_submit_result_action","oracle_attest_action","oracle_init_action",
           "oracle_queue_init_action","guardian_queue_init_action","aggregator_init_action",
           "queue_override_oracle_action","aggregator_delete_action","emergency_action","on_demand"]

def scan(pkg, mod, last=5):
    query = ('{ events(filter: {module: \"%s::%s\"}, last: %d) { nodes { sender { address } timestamp '
             'contents { type { repr } json } transaction { digest } } } }') % (pkg, mod, last)
    d = q(query)
    if 'errors' in d:
        return {"error": str(d['errors'])[:150]}
    return d['data']['events']

if __name__ == "__main__":
    out = {}
    for v, pkg in VERSIONS.items():
        for m in MODULES:
            ev = scan(pkg, m)
            if ev.get('nodes'):
                key = f"v{v}:{m}"
                out[key] = ev
                n = ev['nodes']
                print(f"== v{v} {m}: {len(n)} events (page), latest={n[-1]['timestamp']}")
                for x in n[-5:]:
                    print('   ', x['timestamp'], x['sender']['address'][:16], x['contents']['type']['repr'].split('::')[-1], json.dumps(x['contents']['json'])[:110])
    json.dump(out, open('sui_events_all_versions.json','w'), indent=1)
    print('saved', len(out), 'non-empty (version,module) event sets')
