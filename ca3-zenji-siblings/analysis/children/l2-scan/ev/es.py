#!/usr/bin/env python3
"""Etherscan V2 helper. Key from ETHERSCANV2_API_KEY env; never written to disk."""
import json, os, sys, urllib.parse, urllib.request

KEY = os.environ["ETHERSCANV2_API_KEY"]
BASE = "https://api.etherscan.io/v2/api"

def q(**params):
    params["apikey"] = KEY
    url = BASE + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"user-agent": "research/1.0"})
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.load(r)

if __name__ == "__main__":
    chain = sys.argv[1]
    args = dict(a.split("=", 1) for a in sys.argv[2:])
    args["chainid"] = chain
    print(json.dumps(q(**args)))
