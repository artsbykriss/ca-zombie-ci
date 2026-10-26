#!/usr/bin/env python3
"""Read a PriceInfo dynamic field (keyed by TypeName) from an oracle object."""
import json, urllib.request, base64, sys

EP = "https://graphql.mainnet.sui.io/graphql"

def gql(q, v):
    body = json.dumps({"query": q, "variables": v}).encode()
    req = urllib.request.Request(EP, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

def uleb(n):
    out = bytearray()
    while True:
        b = n & 0x7f
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            break
    return bytes(out)

def typename_bcs(t):
    b = t.encode()
    return base64.b64encode(uleb(len(b)) + b).decode()

Q = """query($k:[NameKey!]!){ multiGetDynamicFields(keys:$k){
  name{ type{repr} json } value{ __typename ... on MoveValue{ type{repr} json } } } }"""

def main():
    parent = sys.argv[1]
    types = sys.argv[2:]
    keys = [{"parent": parent, "name": {"type": "0x1::type_name::TypeName", "bcs": typename_bcs(t)}} for t in types]
    j = gql(Q, {"k": keys})
    print(json.dumps(j, indent=1)[:6000])

if __name__ == "__main__":
    main()
