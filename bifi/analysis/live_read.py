import json, urllib.request, sys

RPCS = {
 "ethereum": "https://ethereum-rpc.publicnode.com",
 "bsc": "https://bsc-dataseed.binance.org",
 "avalanche": "https://api.avax.network/ext/bc/C/rpc",
 "kaia": "https://public-en.node.kaia.io",
}
SEL = {
 "getCircuitBreaker()":"0x7b66a7da",
}

def rpc(url, method, params):
    req = urllib.request.Request(url, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(), headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=40) as r:
        j = json.load(r)
    if "error" in j: raise Exception(j["error"])
    return j["result"]

def call(url, to, data, block="latest"):
    return rpc(url, "eth_call", [{"to":to,"data":data}, block])

def dec(h):
    return int(h,16) if isinstance(h,str) and h.startswith("0x") and len(h)>2 else 0

from eth_utils import keccak
def sel(sig): return "0x"+keccak(text=sig)[:4].hex()

print(sel("getCircuitBreaker()"))
