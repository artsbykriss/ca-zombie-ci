#!/usr/bin/env python3
"""Fetch upgrade-authority tx history + router program info (read-only)."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rpc import rpc

OUT = os.path.dirname(os.path.abspath(__file__))
AUTH = "6dDjBZdpafRKe7WuVHYTF1HphW1BWiKqioMD5eBGYipS"
ROUTER = "MsefSitidhtBWC4qGJGRKqTRKXwoZ7Wj7WPqzgv22x5"
ROUTER_PD = "49d2feff345a7283713b62aba3bbcb1d31848ff15b256e33f5bccb8d88c99a47"  # from earlier hex? verify below

def all_sigs(addr, limit=1000, max_pages=200):
    sigs, before = [], None
    for _ in range(max_pages):
        params = [addr, {"limit": limit, "commitment": "confirmed"}]
        if before: params[1]["before"] = before
        r = rpc("getSignaturesForAddress", params)
        res = r.get("result", [])
        if not res: break
        sigs.extend(res)
        before = res[-1]["signature"]
        if len(res) < limit: break
    return sigs

sigs = all_sigs(AUTH)
json.dump(sigs, open(os.path.join(OUT, "history-upgrade-authority.json"), "w"), indent=1)
print("authority tx count:", len(sigs))
if sigs:
    print("  newest:", sigs[0]["slot"], sigs[0].get("blockTime"))
    print("  oldest:", sigs[-1]["slot"], sigs[-1].get("blockTime"))

# router program account -> programdata
r = rpc("getAccountInfo", [ROUTER, {"encoding": "base64", "commitment": "confirmed"}])
v = (r.get("result") or {}).get("value")
import base64
if v:
    raw = base64.b64decode(v["data"][0])
    print("router prog acct owner:", v["owner"], "len", len(raw), "exec", v["executable"])
    if len(raw) == 36:
        import sys as _s
        ALPHA='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
        def b58e(b):
            n=int.from_bytes(b,'big'); out=''
            while n: n,r2=divmod(n,58); out=ALPHA[r2]+out
            for c in b:
                if c==0: out='1'+out
                else: break
            return out
        pd = b58e(raw[4:36])
        print("router programdata:", pd)
        r2 = rpc("getAccountInfo", [pd, {"encoding": "base64", "commitment": "confirmed"}])
        v2 = (r2.get("result") or {}).get("value")
        if v2:
            raw2 = base64.b64decode(v2["data"][0])
            import struct
            print("router pdata len", len(raw2), "tag", struct.unpack("<I", raw2[:4])[0],
                  "lastDeploy", struct.unpack("<Q", raw2[4:12])[0], "hasAuth", raw2[12],
                  "auth", b58e(raw2[13:45]))
            json.dump({"programdata": pd, "lastDeploy": struct.unpack("<Q", raw2[4:12])[0],
                       "authority": b58e(raw2[13:45])}, open(os.path.join(OUT, "router-programdata.json"), "w"), indent=1)

# dijkbk program owner check
r = rpc("getAccountInfo", ["dijkbkCAKfFTCxQg3u1pg82gVU1jJGHBBRcteD11mBu", {"encoding": "base64", "commitment": "confirmed"}])
v = (r.get("result") or {}).get("value")
print("dijkbk account:", None if not v else (v["owner"], v["executable"], v["lamports"]))
