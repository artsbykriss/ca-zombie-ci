#!/usr/bin/env python3
"""Read totalSupply() for every manager-funded DAO's governance token to classify the
STUCK (S) subset: a DAO whose token has totalSupply == 0 can never create a vote
(Voting._newVote reverts ERROR_NO_VOTING_POWER), so nobody — not even governance — can move it.
Keyless / env RPC only."""
import json, os, urllib.request, time
from concurrent.futures import ThreadPoolExecutor
from Crypto.Hash import keccak

HERE = os.path.dirname(os.path.abspath(__file__))
RPCS = []
for key, tmpl in [("ANKR_API_KEY", "https://rpc.ankr.com/eth/{}"),
                  ("DRPC_API_KEY", "https://lb.drpc.org/ogrpc?network=ethereum&dkey={}"),
                  ("INFURA_API_KEY", "https://mainnet.infura.io/v3/{}")]:
    if os.environ.get(key):
        RPCS.append(tmpl.format(os.environ[key]))
RPCS += ["https://eth.drpc.org", "https://1rpc.io/eth", "https://ethereum-rpc.publicnode.com"]

S = lambda sig: "0x" + keccak.new(digest_bits=256, data=sig.encode()).hexdigest()[:8]
TS = S("totalSupply()")
_i = [0]


def call(to, data):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_call",
                       "params": [{"to": to, "data": data}, "latest"]}).encode()
    for a in range(6):
        u = RPCS[(_i[0] + a) % len(RPCS)]
        try:
            req = urllib.request.Request(u, data=body, headers={"content-type": "application/json",
                                                                "User-Agent": "ag/1"})
            r = json.load(urllib.request.urlopen(req, timeout=15))
            if "result" in r:
                return r["result"]
            if "error" in r and "revert" in str(r["error"]).lower():
                return "0x0"
        except Exception:
            pass
        _i[0] += 1
    return None


mgr = [x for x in json.load(open(os.path.join(HERE, "aragon_mgr_scan.json"))) if x["isMgr"]]
join = {r["dao"]: r for r in json.load(open(os.path.join(HERE, "aragon_join.json")))}


def work(x):
    r = join[x["dao"]]
    tok = r["token"]
    s = call(tok, TS)
    try:
        v = int(s, 16)
    except Exception:
        v = None
    return {"dao": x["dao"], "eth": r["eth"], "minAQ": r["minAQ"], "token": tok, "totalSupply": v}


t = time.time()
with ThreadPoolExecutor(max_workers=24) as ex:
    out = list(ex.map(work, mgr))
zero = [x for x in out if x["totalSupply"] == 0]
unk = [x for x in out if x["totalSupply"] is None]
print(f"manager-funded tokens read: {len(out)} ({time.time()-t:.0f}s); supply==0: {len(zero)}; unknown: {len(unk)}")
print(f"stuck ETH (supply==0): {sum(x['eth'] for x in zero)/1e18:.4f}")
for x in sorted(zero, key=lambda y: -y["eth"])[:20]:
    print(f"  {x['dao']} eth={x['eth']/1e18:.4f} token={x['token']}")
json.dump(out, open(os.path.join(HERE, "token_supply.json"), "w"), indent=1)
print("wrote token_supply.json")
