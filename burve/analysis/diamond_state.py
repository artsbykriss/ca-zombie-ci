#!/usr/bin/env python3
"""Read the Burve SimplexDiamond state: tokens, closures, values, owner, fees."""
import json, urllib.request, concurrent.futures
from bera import rpc, call, words, addr

RPCS = ["https://berachain-rpc.publicnode.com", "https://rpc.berachain.com", "https://berachain.drpc.org"]
D = "0xa1beD164c12CD9479A1049f97BDe5b3D6EC21089"

def rp(method, params):
    last=None
    for u in RPCS:
        try:
            req=urllib.request.Request(u,data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            with urllib.request.urlopen(req,timeout=30) as r: j=json.loads(r.read())
            if "result" in j: return j["result"]
            last=j
        except Exception as e: last=e
    raise RuntimeError(str(last))

def call_(to,data): return rp("eth_call",[{"to":to,"data":data},"latest"])
def dec_str(h):
    try:
        h=h[2:]; off=int(h[:64],16)*2; ln=int(h[off:off+64],16)
        if ln==0 or ln>200: return None
        return bytes.fromhex(h[off+64:off+64+ln*2]).decode('utf-8','replace')
    except Exception: return None

blk=int(rp("eth_blockNumber",[]),16)
print("block",blk)

# getTokens() -> address[]
raw=call_(D,"0xaa6ca808")
w=words(raw); n=int(w[1],16)
tokens=[addr(w[2+i]) for i in range(n)]
print("numTokens",n)
for i,t in enumerate(tokens):
    nm=dec_str(call_(t,"0x06fdde03")); sym=dec_str(call_(t,"0x95d89b41"))
    dec=int(call_(t,"0x313ce567"),16)
    print(f"  token[{i}] {t} {nm}/{sym} dec={dec}")

# SimplexGetFacet selectors we know from source: getClosureValue, getSimplexInfo etc.
# Get simplex info
print("=== owner", addr(words(call_(D,"0x8da5cb5b"))[0]))
# protocolTakeX128 etc via SimplexGetFacet selectors
sels={
 "getProtocolTakeX128()":"0x",
 "deMinimusValue()":"0x",
}
# from SimplexGetFacet source, find view fns
import re, os
src=open("src/src__multi__facets__SimplexGetFacet.sol").read()
fns=re.findall(r'function\s+(\w+)\s*\(([^)]*)\)\s*([^;{]*)', src)
print("=== SimplexGetFacet fns ===")
for f in fns: print("  ",f)
print("=== QueryValueFacet fns ===")
src=open("src/src__multi__facets__QueryValueFacet.sol").read()
for f in re.findall(r'function\s+(\w+)\s*\(([^)]*)\)\s*([^;{]*)', src): print("  ",f)
