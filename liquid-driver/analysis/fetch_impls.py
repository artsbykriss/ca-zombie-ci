#!/usr/bin/env python3
"""Fetch implementation addresses + selectors for proxied Liquid Driver contracts."""
import json, urllib.request, sys

def post(url, payload, timeout=30):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc(url, method, params):
    d = post(url, {"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    return d.get("result")

def get_impl(url, addr):
    slot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
    v = rpc(url, "eth_getStorageAt", [addr, slot, "latest"])
    return "0x" + v[-40:] if v and len(v) >= 42 else None

def selectors(code):
    b = bytes.fromhex(code[2:])
    sels = set()
    i = 0
    while i < len(b):
        if b[i] == 0x63 and i + 5 <= len(b):
            sels.add("0x" + b[i+1:i+5].hex())
            i += 5
        else:
            i += 1
    return sorted(sels)

FB = "https://fantom.drpc.org"
BS = "https://bsc-rpc.publicnode.com"

out = {}
targets = [
    ("fantom", FB, "minichef_ftm_proxy", "0x6e2ad6527901c9664f016466b8da1357a004db0f"),
    ("fantom", FB, "hundred_dai_proxy", "0x79364E45648Db09eE9314E47b2fD31c199Eb03B9"),
    ("bsc", BS, "minichef_bsc_proxy", "0xd46db083de31c64af3f680f139a31ff37bac004f"),
]
for chain, url, nm, a in targets:
    try:
        impl = get_impl(url, a)
        out[nm] = {"proxy": a, "impl": impl}
        print(nm, "impl", impl, flush=True)
        if impl:
            code = rpc(url, "eth_getCode", [impl, "latest"])
            if code and len(code) > 4:
                out[nm]["impl_codesize"] = (len(code)-2)//2
                out[nm]["impl_selectors"] = selectors(code)
                print("   codesize", out[nm]["impl_codesize"], "sels", out[nm]["impl_selectors"][:40], flush=True)
    except Exception as e:
        out[nm] = {"proxy": a, "error": str(e)}
        print(nm, "ERR", e, flush=True)

with open("/home/heisenberg/CA/liquid-driver/analysis/impls.json", "w") as f:
    json.dump(out, f, indent=1)
print("saved")
