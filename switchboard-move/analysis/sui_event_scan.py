#!/usr/bin/env python3
"""Sui event scan for the Switchboard package family (read-only)."""
import json, sys
from sui_query import q

PKG = "0xc3c7e6eb7202e9fb0389a2f7542b91cc40e4f7a33c02554fec11c4c92f938ea3"
MODULES = ["aggregator_submit_result_action","oracle_attest_action","oracle_init_action",
           "oracle_queue_init_action","guardian_queue_init_action","aggregator_init_action",
           "queue_override_oracle_action","aggregator_delete_action","emergency_action",
           "on_demand","queue","oracle","aggregator","aggregator_set_authority_action",
           "aggregator_set_configs_action","queue_set_authority_action","queue_add_fee_coin_action",
           "queue_remove_fee_coin_action","queue_set_configs_action"]

def scan(mod, last=10, before=None):
    b = f', before: \"{before}\"' if before else ''
    query = ('{ events(filter: {module: \"%s::%s\"}, last: %d%s) { nodes { sender { address } timestamp '
             'contents { type { repr } json } transaction { digest } } pageInfo { startCursor endCursor hasPreviousPage } } }') % (PKG, mod, last, b)
    return q(query)

if __name__ == "__main__":
    out = {}
    for m in MODULES:
        d = scan(m)
        if 'errors' in d:
            out[m] = {"error": str(d['errors'])[:200]}; print(m, 'ERR'); continue
        ev = d['data']['events']
        nodes = ev['nodes']
        out[m] = {"count": len(nodes), "nodes": nodes, "pageInfo": ev['pageInfo']}
        if nodes:
            print(f"== {m}: {len(nodes)} events, latest={nodes[-1]['timestamp']}, earliest_of_page={nodes[0]['timestamp']}")
            for n in nodes[-4:]:
                print('   ', n['timestamp'], n['sender']['address'][:16], n['contents']['type']['repr'].split('::')[-1], json.dumps(n['contents']['json'])[:120])
        else:
            print(f"== {m}: 0 events")
    json.dump(out, open('sui_events_scan.json','w'), indent=1)
