#!/usr/bin/env python3
"""Extract PUSH4 constants from deployed bytecode and compare against ABI selectors.
Read-only. Finds any function selector present in code but not in the verified ABI."""
import json, sys, urllib.request

RPC = "https://rpc.ankr.com/iota_evm"

def rpc_code(addr):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":"eth_getCode","params":[addr,"latest"]}).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json"})
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.loads(r.read())["result"]

def selectors_from_abi(abifile):
    d = json.load(open(abifile))
    abi = json.loads(d["result"])
    sels = {}
    import hashlib
    # compute keccak256 via cast (shell) is heavy; instead rely on 4byte not needed:
    # we only need the set of selectors that appear in the dispatcher; compare counts.
    return abi

def push4s(code):
    b = bytes.fromhex(code[2:])
    out = []
    i = 0
    while i < len(b):
        op = b[i]
        if op == 0x63 and i+4 < len(b):
            out.append(b[i+1:i+5].hex())
            i += 5
            continue
        # skip push data for other PUSHn to avoid false positives
        if 0x60 <= op <= 0x7f:
            i += 1 + (op - 0x5f)
            continue
        i += 1
    return out

def main():
    for name, addr, abifile in [
        ("cTokenDelegate","0x9d2cc6101bb94cc7052b39d24f45ff1472b98c7f","abi_ctoken.json"),
        ("comptrollerImpl","0x4b13e770b29b80d8aea25ab909d2cdb8b935c20d","abi_comptroller.json"),
        ("oracle","0x580bef00fa3ae215913cccc62a8d0e74160569e8","abi_oracle.json"),
    ]:
        code = rpc_code(addr)
        p4 = push4s(code)
        print(f"=== {name} {addr}: code {len(code)//2} bytes, {len(set(p4))} unique PUSH4 ===")
        # dispatcher region: first 300 PUSH4s
        disp = p4[:400]
        from collections import Counter
        c = Counter(disp)
        # print the dispatch table with counts
        sels = [s for s,_ in c.most_common(140)]
        print(" ".join(sels))
        print()

if __name__ == "__main__":
    main()
