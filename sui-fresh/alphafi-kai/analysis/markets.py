#!/usr/bin/env python3
"""Enumerate AlphaLend markets (Table<u64,Market>) via GraphQL multiGetDynamicFields."""
import json, urllib.request, base64, sys

EP = "https://graphql.mainnet.sui.io/graphql"
MARKETS_TABLE = "0x2326d387ba8bb7d24aa4cfa31f9a1e58bf9234b097574afb06c5dfb267df4c2e"

def gql(q, v):
    body = json.dumps({"query": q, "variables": v}).encode()
    req = urllib.request.Request(EP, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

Q = """query($k:[NameKey!]!){ multiGetDynamicFields(keys:$k){
  name{ type{repr} json } value{ __typename ... on MoveValue{ type{repr} json } } } }"""

def bcs_u64(n):
    return base64.b64encode(n.to_bytes(8, "little")).decode()

def main():
    keys = [{"parent": MARKETS_TABLE, "name": {"type": "u64", "bcs": bcs_u64(i)}} for i in range(1, 40)]
    out = {}
    for i in range(0, len(keys), 10):
        j = gql(Q, {"k": keys[i:i+10]})
        for n in j["data"]["multiGetDynamicFields"]:
            if n is None:
                continue
            mid = n["name"]["json"]
            out[mid] = n["value"]["json"] if n["value"] else None
    json.dump(out, open(sys.argv[1] if len(sys.argv) > 1 else "markets.json", "w"), indent=1)
    print("markets:", len(out))
    for mid, m in out.items():
        if not m:
            print(mid, "NULL"); continue
        ct = m.get("coin_type", "").split("::")[-1]
        print(f"  #{mid} {ct:12s} xtoken_supply={m.get('xtoken_supply')} ratio={m.get('xtoken_ratio',{}).get('value')} borrowed={m.get('borrowed_amount')} bal={m.get('balance_holding')} active={m['config'].get('active')} borrow_limit={m['config'].get('borrow_limit')} deposit_limit={m['config'].get('deposit_limit')}")

if __name__ == "__main__":
    main()
