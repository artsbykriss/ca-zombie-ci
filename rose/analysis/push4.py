#!/usr/bin/env python3
"""Extract PUSH4 constants from bytecode = function dispatch selectors. Keyless read-only."""
import json, re, urllib.request, sys

RPC = "https://mainnet.aurora.dev"
def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))["result"]

CONTRACTS = {
 "0xc90dB0d8713414d78523436dC347419164544A3f":"poolA",
 "0xee793001Ce9Fa988712B15a59CCf5dC7d54b22FF":"poolB",
 "0x8fe44f5cce02D5BE44e3446bBc2e8132958d22B8":"h8fe4",
 "0xa34315F1ef49392387Dd143f4578083A9Bd33E94":"ha343",
 "0x65a761136815B45A9d78d9781d22d47247B49D23":"h65a7",
 "0xe23d2289FBca7De725DC21a13fC096787A85e16F":"stROSE",
}
res = {}
for addr, label in CONTRACTS.items():
    code = rpc("eth_getCode", [addr, "latest"]).lower()
    p4 = re.findall(r'63([0-9a-f]{8})', code)
    # filter out obvious non-selectors: those with 00000000 or that appear inside data
    uniq = sorted(set(p4))
    res[addr] = {"label": label, "selectors": uniq, "codelen": (len(code)-2)//2}
    print(f"=== {label} {addr} codelen={res[addr]['codelen']} uniq_push4={len(uniq)}")
    print(" ".join(uniq))
json.dump(res, open("push4.json","w"), indent=1)
