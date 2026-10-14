#!/usr/bin/env python3
"""Read live state of all Bril/ICHI vaults on BSC (read-only, public RPC)."""
import json, os, urllib.request

RPC = os.environ.get("BRIL_RPC", "https://bsc-rpc.publicnode.com")
HERE = os.path.dirname(os.path.abspath(__file__))

def rpc(calls):
    payload = []
    for i, (to, data) in enumerate(calls):
        payload.append({"jsonrpc": "2.0", "id": i, "method": "eth_call",
                        "params": [{"to": to, "data": data}, "latest"]})
    req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    d = json.load(urllib.request.urlopen(req, timeout=120))
    m = {x["id"]: x for x in d}
    return [m[i].get("result") if "error" not in m[i] else ("0xerr:" + json.dumps(m[i]["error"])) for i in range(len(payload))]

import subprocess
def sel(sig):
    return subprocess.check_output(["cast", "sig", sig], text=True).strip()
def enc(a):
    return a.lower().replace("0x", "").rjust(64, "0")
def words(h):
    if not h or not h.startswith("0x") or h.startswith("0xerr"): return None
    return [h[2:][i:i+64] for i in range(0, len(h[2:]), 64)]
def addr(w): return "0x" + w[-40:]
def u(w): return int(w, 16)

S = {
 "owner": sel("owner()"), "t0": sel("token0()"), "t1": sel("token1()"),
 "ts": sel("totalSupply()"), "gta": sel("getTotalAmounts()"),
 "baseLower": sel("baseLower()"), "baseUpper": sel("baseUpper()"),
 "limitLower": sel("limitLower()"), "limitUpper": sel("limitUpper()"),
 "twap": sel("twapPeriod()"), "hyst": sel("hysteresis()"),
 "d0max": sel("deposit0Max()"), "d1max": sel("deposit1Max()"),
 "maxTS": sel("maxTotalSupply()"), "affiliate": sel("affiliate()"),
 "balOf": sel("balanceOf(address)"),
}

def main():
    d = json.load(open(os.path.join(HERE, "live_state.json")))
    vaults = sorted({s["vault"].lower() for s in d["strategies"]})
    factory = d["factory"]
    print("vaults:", len(vaults))
    out = {}
    for v in vaults:
        calls = [(v, S[k]) for k in ["owner","t0","t1","ts","gta","baseLower","baseUpper","limitLower","limitUpper","twap","hyst","d0max","d1max","maxTS","affiliate"]]
        # share balances of interesting addresses: Safe, factory, each strategy of this vault
        strat_of = [s["strategy"] for s in d["strategies"] if s["vault"].lower() == v]
        for a in [ "0x05cC3CA6E768a68A7f86b09e3ceE754437bd5f12", factory ] + strat_of:
            calls.append((v, S["balOf"] + enc(a)))
        res = rpc(calls)
        g = words(res[4])
        o = {
            "vault": v, "owner": addr(words(res[0])[0]), "token0": addr(words(res[1])[0]), "token1": addr(words(res[2])[0]),
            "totalSupply": u(words(res[3])[0]),
            "total0": u(g[0]), "total1": u(g[1]),
            "baseLower": int(words(res[5])[0],16), "baseUpper": int(words(res[6])[0],16),
            "limitLower": int(words(res[7])[0],16), "limitUpper": int(words(res[8])[0],16),
            "twapPeriod": u(words(res[9])[0]), "hysteresis": u(words(res[10])[0]),
            "deposit0Max": u(words(res[11])[0]), "deposit1Max": u(words(res[12])[0]),
            "maxTotalSupply": u(words(res[13])[0]), "affiliate": addr(words(res[14])[0]),
            "strategies": strat_of,
        }
        # balances
        bal = {}
        for i, a in enumerate([ "0x05cC3CA6E768a68A7f86b09e3ceE754437bd5f12", factory ] + strat_of):
            r = res[15+i]
            w = words(r)
            bal[a] = u(w[0]) if w else None
        o["share_balances"] = bal
        out[v] = o
        print(v, o["owner"], "TS", o["totalSupply"], "tot0", o["total0"], "tot1", o["total1"], "twap", o["twapPeriod"], "hyst", o["hysteresis"], "d0max", o["deposit0Max"], "d1max", o["deposit1Max"])
    json.dump(out, open(os.path.join(HERE, "vault_state.json"), "w"), indent=1)
    print("wrote vault_state.json")

if __name__ == "__main__":
    main()
