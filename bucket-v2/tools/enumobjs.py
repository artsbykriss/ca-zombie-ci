#!/usr/bin/env python3
"""Enumerate objects of a type with pagination (read-only)."""
import sys, json, os
sys.path.insert(0, os.path.dirname(__file__))
from sui import gql

def enum(t, limit=200):
    out, cursor = [], None
    while True:
        q = """query($t:String!,$c:String){ objects(first:50, after:$c, filter:{type:$t}){
          pageInfo{hasNextPage endCursor}
          nodes{ address version asMoveObject{ contents{ type{repr} json } } } } }"""
        r = gql(q, {"t": t, "c": cursor})
        if r.get("errors"):
            return {"errors": r["errors"]}
        o = r["data"]["objects"]
        out += o["nodes"]
        if o["pageInfo"]["hasNextPage"] and len(out) < limit:
            cursor = o["pageInfo"]["endCursor"]
        else:
            break
    return out

if __name__ == "__main__":
    t = sys.argv[1]
    res = enum(t)
    if isinstance(res, dict):
        print(json.dumps(res)[:500]); sys.exit(1)
    print(f"# {len(res)} objects of {t}")
    for n in res:
        j = n["asMoveObject"]["contents"]["json"]
        print(json.dumps({"addr": n["address"], "v": n["version"], "type": n["asMoveObject"]["contents"]["type"]["repr"], "json": j}))
