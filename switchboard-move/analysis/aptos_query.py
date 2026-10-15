#!/usr/bin/env python3
"""Read-only Aptos indexer GraphQL query helper (public endpoint, no keys)."""
import json, sys, urllib.request

URL = "https://api.mainnet.aptoslabs.com/v1/graphql"

def q(query, variables=None):
    body = {"query": query}
    if variables:
        body["variables"] = variables
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

if __name__ == "__main__":
    print(json.dumps(q(sys.argv[1]), indent=1))
