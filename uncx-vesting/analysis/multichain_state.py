#!/usr/bin/env python3
"""Multi-chain UNCX deployment state reader.

Usage: python3 multichain_state.py <chains.json>
chains.json: [{"name":"bsc","rpc":"https://...","vm":"0x...","explorer":"bscscan"}...]
Reads: codesize, flatFee, feePercentage, nextVestingId, owner, feeCollector.
"""
import json, sys, urllib.request
from eth_utils import keccak

def rpc(url, method, params):
    req = urllib.request.Request(url, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
        headers={'Content-Type':'application/json','User-Agent':'Mozilla/5.0'})
    return json.load(urllib.request.urlopen(req, timeout=60))

def sel(sig): return '0x'+keccak(text=sig)[:4].hex()

def call(url, to, sig):
    r = rpc(url, "eth_call", [{"to":to,"data":sel(sig)}, "latest"])
    if 'result' in r and r['result'] and r['result'] != '0x':
        return r['result']
    return None

def main():
    chains = json.load(open(sys.argv[1]))
    out = []
    for c in chains:
        url, vm = c['rpc'], c['vm']
        rec = {"chain": c['name'], "vm": vm}
        try:
            code = rpc(url, "eth_getCode", [vm, "latest"])['result']
            rec['codeBytes'] = (len(code)-2)//2 if code and code != '0x' else 0
        except Exception as e:
            rec['err_code'] = str(e)[:60]
        for sig, key in [("flatFee()(uint256)","flatFee"), ("feePercentage()(uint256)","feePercentage"),
                         ("nextVestingId()(uint256)","nextVestingId")]:
            try:
                r = call(url, vm, sig)
                rec[key] = int(r,16) if r else None
            except Exception as e:
                rec[key+'_err'] = str(e)[:50]
        for sig, key in [("owner()(address)","owner"), ("feeCollector()(address)","feeCollector"),
                         ("calculator()(address)","calculator")]:
            try:
                r = call(url, vm, sig)
                rec[key] = '0x'+r[2:][24:] if r else None
            except Exception as e:
                rec[key+'_err'] = str(e)[:50]
        try:
            rec['balance_native'] = int(rpc(url, "eth_getBalance", [vm,"latest"])['result'],16)
        except Exception as e:
            rec['balance_native_err'] = str(e)[:50]
        out.append(rec)
    print(json.dumps(out, indent=1))

if __name__ == '__main__':
    main()
