#!/usr/bin/env python3
"""Probe the gRPC-JSON ProgrammableTransaction field names for simulateTransaction."""
import json, os, urllib.request, itertools

ENDPOINT = os.environ.get("SUI_GRAPHQL", "https://graphql.mainnet.sui.io/graphql")
SENDER = "0x0000000000000000000000000000000000000000000000000000000000000005"

def gql(q, v):
    req = urllib.request.Request(ENDPOINT, data=json.dumps({"query": q, "variables": v}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

Q = """query($t:JSON!){ simulateTransaction(transaction:$t, checksEnabled:true, doGasSelection:true){ effects{ status } } }"""

def run(ptb):
    tx = {"sender": SENDER, "kind": {"programmableTransaction": ptb}}
    r = gql(Q, {"t": tx})
    return json.dumps(r.get("data") or r.get("errors"))[:220]

# bad movecall (nonexistent package) to force an execution error if the command is parsed
mc = {"package": "0x9999999999999999999999999999999999999999999999999999999999999999",
      "module": "nope", "function": "nope", "typeArguments": [], "arguments": []}
for txfield in ["transactions", "commands"]:
    for cmdwrap in ["moveCall", "move_call"]:
        ptb = {txfield: [{cmdwrap: mc}]}
        print(f"field={txfield:12s} cmdwrap={cmdwrap:9s} -> {run(ptb)}")

# also test a transferObjects command variant to detect the oneof names
print("--- transfer variants ---")
for txfield in ["transactions", "commands"]:
    for cw in ["transferObjects", "transfer_objects"]:
        ptb = {txfield: [{cw: {"objects": [], "address": {"input": 0}}}]}
        print(f"field={txfield:12s} cmd={cw:16s} -> {run(ptb)}")
