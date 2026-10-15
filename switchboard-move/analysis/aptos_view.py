#!/usr/bin/env python3
"""Read-only Aptos view-function caller (public fullnode, no keys)."""
import json, sys, urllib.request

URL = "https://fullnode.mainnet.aptoslabs.com/v1/view"

def view(function, type_args=None, args=None):
    body = {"function": function, "type_arguments": type_args or [], "arguments": args or []}
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)

if __name__ == "__main__":
    fn = sys.argv[1]
    args = sys.argv[2:]
    try:
        print(json.dumps(view(fn, [], args), indent=1))
    except urllib.error.HTTPError as e:
        print("HTTP", e.code, e.read().decode()[:500])
