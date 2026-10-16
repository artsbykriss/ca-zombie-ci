#!/usr/bin/env python3
"""Fetch & summarize UNCX VestingManager event history for a range.

Usage: python3 logs_scan.py <rpc_url> <vm_address> <from_block> <to_block>
Outputs JSON summary: creations (with soft/topable flags), topups, releases, cancels,
fee-exemption updates.
"""
import json, sys, urllib.request
from eth_utils import keccak
from eth_abi import decode as abi_decode

def rpc(url, method, params):
    req = urllib.request.Request(url, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
        headers={'Content-Type':'application/json','User-Agent':'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req, timeout=120))

EV = {
 'VestingCreated': ("VestingCreated(uint256,address,address,(uint256,uint256,uint8)[],bool,bool,bool)",
   [("uint256",True),("address",True),("address",False),("(uint256,uint256,uint8)[]",False),("bool",False),("bool",False),("bool",False)]),
 'VestingToppedUp': ("VestingToppedUp(uint256,address,uint256,(uint256,uint256,uint8)[])",
   [("uint256",True),("address",True),("uint256",False),("(uint256,uint256,uint8)[]",False)]),
 'TokensReleased': ("TokensReleased(uint256,address,uint256)", [("uint256",True),("address",True),("uint256",False)]),
 'VestingCancelled': ("VestingCancelled(uint256)", [("uint256",True)]),
 'CreatorFeeExemptionUpdated': ("CreatorFeeExemptionUpdated(address,bool)", [("address",False),("bool",False)]),
 'TokenFeeExemptionUpdated': ("TokenFeeExemptionUpdated(address,bool)", [("address",False),("bool",False)]),
 'FlatFeeUpdated': ("FlatFeeUpdated(uint256)", [("uint256",False)]),
 'FeePercentageUpdated': ("FeePercentageUpdated(uint256)", [("uint256",False)]),
}
BY_TOPIC = {keccak(text=v[0]).hex(): (k,v[1]) for k,v in EV.items()}

def decode_log(lg, spec):
    name, items = spec
    indexed = [i for i,(t,ix) in enumerate(items) if ix]
    nonidx = [t for (t,ix) in items if not ix]
    vals = list(abi_decode(nonidx, bytes.fromhex(lg['data'][2:]))) if nonidx else []
    out = {}
    vi = 0
    for idx,(t,ix) in enumerate(items):
        if ix:
            out[f"a{idx}"] = lg['topics'][1+indexed.index(idx)]
        else:
            out[f"a{idx}"] = vals[vi]; vi += 1
    return name, out

def main():
    url, vm, frm, to = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
    # fetch in chunks
    all_logs = []
    step = 2000
    b = frm
    while b <= to:
        e = min(b+step-1, to)
        r = rpc(url, "eth_getLogs", [{"address": vm, "fromBlock": hex(b), "toBlock": hex(e)}])
        if 'error' in r:
            print("RPC ERROR:", r['error'], file=sys.stderr); sys.exit(1)
        all_logs += r['result']
        b = e+1
    out = []
    for lg in all_logs:
        t0 = lg['topics'][0][2:]
        if t0 not in BY_TOPIC: continue
        try:
            name, args = decode_log(lg, BY_TOPIC[t0])
        except Exception as ex:
            name, args = 'DECODE_ERR', {'err': str(ex), 'topic': t0}
        out.append({"block": int(lg['blockNumber'],16), "logIndex": int(lg['logIndex'],16), "tx": lg['transactionHash'], "name": name, **args})
    print(json.dumps(out, indent=1))

if __name__ == '__main__':
    main()
