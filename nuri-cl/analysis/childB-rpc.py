#!/usr/bin/env python3
"""Read-only Scroll RPC helper for childB NFP/veNURI audit. No secrets; uses public RPC."""
import json, sys, urllib.request

RPC = "https://rpc.scroll.io"

def rpc(method, params, batch=None):
    calls = batch if batch is not None else [{"jsonrpc":"2.0","id":1,"method":method,"params":params}]
    req = urllib.request.Request(RPC, data=json.dumps(calls).encode(),
        headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    out = json.load(urllib.request.urlopen(req, timeout=60))
    if batch is None:
        return out
    return out

def call(to, data, tag="latest"):
    return {"jsonrpc":"2.0","id":1,"method":"eth_call","params":[{"to":to,"data":data},tag]}

def enc(sig):
    import hashlib
    return "0x" + hashlib.sha3_256  # placeholder unused

def sel(sig):
    # keccak256 first 4 bytes via eth call is fine; use pycryptodome-free: use hashlib sha3? keccak != sha3
    from subprocess import check_output
    return check_output(["cast","sig",sig]).decode().strip()[:10]

if __name__ == "__main__":
    print(json.dumps(rpc("eth_blockNumber", []), indent=1))
