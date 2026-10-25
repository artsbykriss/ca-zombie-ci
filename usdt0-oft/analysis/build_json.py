import json
from decode import parse

cfg = parse(open('cfg_all2.txt').read())          # current configs (snapshot)
peers = {}
for line in open('peers_full.txt'):
    e, p = line.split()
    peers[int(e)] = p
recv = {}
for line in open('recvlibs.txt'):
    parts = line.split()
    recv[int(parts[0])] = {"lib": parts[1], "isDefault": parts[2] == 'true'}

LABEL = {30101:"Ethereum",30102:"BNB Chain",30109:"Polygon",30110:"Arbitrum One",
         30111:"Optimism",30165:"zkSync Era",30181:"Mantle",30184:"Base",
         30214:"Scroll",30316:"Zircuit",30375:"Katana"}

out = {}
for eid_s, c in cfg.items():
    eid = int(eid_s)
    peer = peers.get(eid, "0x" + "00"*32)
    live = peer != "0x" + "00"*32
    out[eid_s] = {
        "eid": eid,
        "chain": LABEL.get(eid, f"eid {eid}"),
        "peer": peer,
        "peer_set": live,
        "route_state": "LIVE" if live else "DORMANT (no peer)",
        "receiveLibrary": recv.get(eid, {}).get("lib"),
        "receiveLibraryIsDefault": recv.get(eid, {}).get("isDefault"),
        **c,
        "threshold": f"{c['requiredDVNCount']}-of-{c['requiredDVNCount']}"
                     + (f" + {c['optionalDVNThreshold']}-of-{c['optionalDVNCount']} opt"
                        if c['optionalDVNCount'] else ""),
    }

json.dump(out, open('dvn_configs.json', 'w'), indent=2)
live = [e for e, v in out.items() if v['peer_set']]
dorm = [e for e, v in out.items() if not v['peer_set']]
print("live routes:", len(live), sorted(map(int, live)))
print("dormant routes:", len(dorm), sorted(map(int, dorm)))
weak_live = [e for e in live if out[e]['requiredDVNCount'] < 3]
print("live routes with <3 required DVN:", weak_live)
