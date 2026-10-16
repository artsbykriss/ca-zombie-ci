#!/usr/bin/env python3
"""Read UNCX vesting schedules: public getter + private _depositedShares (slot 12) + claimable estimate.

Usage: python3 read_schedules.py <rpc_url> <vm_address> <block|latest> <id1,id2,...>
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
    for item in out: res[item['id']] = item.get('result')
    return res

def slot_map_u256(key_int, base_slot):
    key = hex(key_int)[2:].rjust(64,'0')
    s = hex(base_slot)[2:].rjust(64,'0')
    return '0x'+keccak(bytes.fromhex(key+s)).hex()

def selector(sig): return '0x'+keccak(text=sig)[:4].hex()
def enc_u256(x): return hex(x)[2:].rjust(64,'0')

# struct: (address token,address creator,address beneficiary,uint256 totalAmount,uint256 released,bool isSoft,bool isNftized,bool isTopable,bool cancelled,uint8 vestingType, (uint256,uint256,uint8)[] tranches)
SIG = "getVestingSchedule(uint256)((address,address,address,uint256,uint256,bool,bool,bool,bool,uint8,(uint256,uint256,uint8)[]))"

def main():
    url, vm, block = sys.argv[1], sys.argv[2], sys.argv[3]
    ids = [int(x) for x in sys.argv[4].split(',')]
    blk = block if block=='latest' else hex(int(block))
    calls = []
    for i in ids:
        calls.append(("eth_call",[{"to":vm,"data":selector("getVestingSchedule(uint256)")+enc_u256(i)}, blk]))
        calls.append(("eth_getStorageAt",[vm, slot_map_u256(i,12), blk]))  # _depositedShares
    res = rpc_batch(url, calls)
    # decode schedule via cast (simpler): use eth_abi
    from eth_abi import decode as abi_decode
    out = []
    for idx, i in enumerate(ids):
        raw = res[2*idx]
        D = int(res[2*idx+1],16)
        rec = {"id": i, "depositedShares": D}
        if raw and raw != '0x':
            try:
                (token, creator, beneficiary, totalAmount, released, isSoft, isNftized, isTopable, cancelled, vtype, tranches) = abi_decode(
                    ["address","address","address","uint256","uint256","bool","bool","bool","bool","uint8","(uint256,uint256,uint8)[]"],
                    bytes.fromhex(raw[2:]))
                rec.update(token=token, creator=creator, beneficiary=beneficiary,
                           totalAmount=totalAmount, released=released, isSoft=isSoft,
                           isTopable=isTopable, cancelled=cancelled, nTranches=len(tranches),
                           tranches=[(t,a,e) for (t,a,e) in tranches])
            except Exception as e:
                rec['err'] = str(e)
        out.append(rec)
    print(json.dumps(out, indent=1))

if __name__ == '__main__':
    main()
