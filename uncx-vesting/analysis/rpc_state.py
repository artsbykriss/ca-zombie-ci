#!/usr/bin/env python3
"""Fast batched JSON-RPC state reader for UNCX VestingManager contracts.

Usage: python3 rpc_state.py <rpc_url> <block|latest> <vm_address> [token1,token2,...]
Prints JSON with fee params, per-token totalShares/balance/shareRatio, nextVestingId.

NEVER hardcode RPC urls with keys in this file - pass as argv.
"""
import json, sys, urllib.request
from eth_utils import keccak

def rpc_batch(url, calls):
    payload = [{"jsonrpc":"2.0","id":i,"method":m,"params":p} for i,(m,p) in enumerate(calls)]
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
        headers={'Content-Type':'application/json','User-Agent':'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=60) as r:
        out = json.load(r)
    res = [None]*len(calls)
    for item in out:
        res[item['id']] = item.get('result')
    return res

def slot_map(key_hex, base_slot):
    key = key_hex[2:].rjust(64,'0') if key_hex.startswith('0x') else key_hex.rjust(64,'0')
    s = hex(base_slot)[2:].rjust(64,'0')
    return '0x'+keccak(bytes.fromhex(key+s)).hex()

def slot_num(i):
    return '0x'+hex(i)[2:].rjust(64,'0')

def selector(sig):
    return '0x'+keccak(text=sig)[:4].hex()

def enc_addr(a):
    return a[2:].rjust(64,'0')

def enc_u256(x):
    return hex(x)[2:].rjust(64,'0')

def main():
    url = sys.argv[1]
    block = sys.argv[2]
    vm = sys.argv[3]
    tokens = sys.argv[4].split(',') if len(sys.argv)>4 else []
    blk = block if block=='latest' else hex(int(block))
    calls = []
    # fee params + nextVestingId + svgGenerator + feeCollector
    for slot in [9,10,16,17,18]:
        calls.append(("eth_getStorageAt",[vm, slot_num(slot), blk]))
    for t in tokens:
        calls.append(("eth_getStorageAt",[vm, slot_map(t,11), blk]))   # totalTokenShares
        calls.append(("eth_getStorageAt",[vm, slot_map(t,15), blk]))   # shareRatio
        calls.append(("eth_call",[{"to":t,"data":selector("balanceOf(address)")+enc_addr(vm)}, blk]))
    res = rpc_batch(url, calls)
    def as_int(x): return int(x,16) if x else 0
    out = {
        "block": block,
        "svgGenerator": res[0],
        "nextVestingId": as_int(res[1]),
        "feePercentage": as_int(res[2]),
        "flatFee": as_int(res[3]),
        "feeCollector": res[4],
        "tokens": {}
    }
    i = 5
    for t in tokens:
        out["tokens"][t] = {
            "totalShares": as_int(res[i]),
            "shareRatio": as_int(res[i+1]),
            "balance": as_int(res[i+2]),
        }
        i += 3
    print(json.dumps(out, indent=1))

if __name__ == '__main__':
    main()
