#!/usr/bin/env python3
"""Read-only Sui GraphQL query helper (public endpoint, no keys)."""
import json, sys, urllib.request

URL = "https://graphql.mainnet.sui.io/graphql"

def q(query, variables=None):
    body = {"query": query}
    if variables:
        body["variables"] = variables
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

def events(module_filter, last=5):
    query = """
    query($f: String!, $n: Int) {
      events(filter: {module: $f}, last: $n) {
        totalCount
        nodes {
          sender { address }
          timestamp
          contents { type { repr } json }
          transaction { digest }
        }
      }
    }"""
    return q(query, {"f": module_filter, "n": last})

if __name__ == "__main__":
    if sys.argv[1] == "events":
        d = events(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 5)
        print(json.dumps(d, indent=1))
    else:
        print(json.dumps(q(sys.argv[1]), indent=1))
