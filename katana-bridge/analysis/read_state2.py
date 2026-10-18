#!/usr/bin/env python3
"""Read-only batched state reader. RPCs from env. No secrets stored."""
import json, os, urllib.request
from eth_utils import keccak

ETH = os.environ.get("RPC_URL", "https://ethereum-rpc.publicnode.com")
KAT = os.environ.get("KATANA_RPC_URL", "https://rpc.katana.network")

def sel(sig): return "0x" + keccak(text=sig)[:4].hex()

def batch(url, calls):
    reqs = []
    for i, (to, sig, args) in enumerate(calls):
        data = sel(sig)
        for a in args:
            data += a.to_bytes(32, "big").hex() if isinstance(a, int) else ("0"*24 + a[2:].lower() if len(a) == 42 else a)
        reqs.append({"jsonrpc": "2.0", "id": i, "method": "eth_call", "params": [{"to": to, "data": data}, "latest"]})
    body = json.dumps(reqs).encode()
    req = urllib.request.Request(url, data=body, headers={"content-type": "application/json", "user-agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        res = json.loads(r.read())
    out = [None]*len(calls)
    for d in res:
        out[d["id"]] = d.get("result") if "error" not in d else None
    return out

L1 = {
 "vbUSDC":"0x53E82ABbb12638F09d9e624578ccB666217a765e",
 "vbUSDT":"0x6d4f9f9f8f0155509ecd6Ac6c544fF27999845CC",
 "vbWBTC":"0x2C24B57e2CCd1f273045Af6A5f632504C432374F",
 "vbETH":"0x2DC70fb75b88d2eB4715bc06E1595E6D97c34DFF",
 "vbUSDS":"0x3DD459dE96F9C28e3a343b831cbDC2B93c8C4855",
 "adapter":"0xb5bada33542a05395d504a25885e02503a957bb3",
 "yieldVaultUSDC":"0xbeefb9f61cc44895d8aec381373555a64191a9c4",
 "yvUSDC":"0x80c34BD3A3569E126e7055831036aa7b212cB159",
}
L2 = {
 "minter":"0x807275727dd3e640c5f2b5de7d1ec72b4dd293c0",
 "vbUSDC":"0x203A662b0BD271A6ed5a60EdFbd04bFce608FD36",
 "vbUSDT":"0x2DCa96907fde857dd3D816880A0df407eeB2D2F2",
 "vbWBTC":"0x0913DA6Da4b42f538B445599b46Bb4622342Cf52",
 "vbETH":"0xEE7D8BCFb72bC1880D0Cf19822eB0A2e6577aB62",
 "yvvbUSDC":"0x80c34BD3A3569E126e7055831036aa7b212cB159",
}
SPECS = {
 "name()":(), "symbol()":(), "decimals()":(), "totalSupply()":(), "totalAssets()":(),
 "asset()":(), "owner()":(), "paused()":(), "token()":(), "endpoint()":(), "bridge()":(),
 "globalInitializationCounter()":(), "secondaryChainBalance()":(), "approvalRequired()":(),
 "totalDebt()":(), "balance()":(), "peers(uint32)":(30101,), "peers2(uint32)":(30495,),
}
def read(url, targets, specs):
    calls=[]; keys=[]
    for n,a in targets.items():
        for s,args in specs.items():
            if s=="peers2(uint32)": s="peers(uint32)"
            calls.append((a,s,args)); keys.append((n,s))
    vals = batch(url, calls)
    out={}
    for (n,s),v in zip(keys,vals):
        out.setdefault(n,{})[s]=v
    return out

def dec_str(raw):
    if not raw or len(raw)<130: return None
    try:
        ln=int(raw[2:66],16); return bytes.fromhex(raw[130:130+ln*2]).decode(errors="replace")
    except Exception: return None
def u(raw): return None if raw in (None,"0x") else int(raw,16)
def addr(raw): return None if not raw or raw=="0x" else "0x"+raw[-40:]
def b32(raw): return raw

res={"eth_block":int(batch(ETH,[("0x0000000000000000000000000000000000000000","eth_blockNumber_dummy",())])[0] or "0x0",0) if False else None,
     "l1":{},"l2":{}}
for url in (ETH,KAT):
    try:
        b=json.loads(urllib.request.urlopen(urllib.request.Request(url,data=b'{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}',headers={"content-type":"application/json","user-agent":"Mozilla/5.0"}),timeout=30).read())["result"]
        res["eth_block" if url==ETH else "kat_block"]=int(b,16)
    except Exception as e: res["err_"+("eth" if url==ETH else "kat")]=str(e)[:100]

for tag,url,targets in [("l1",ETH,L1),("l2",KAT,L2)]:
    d=read(url,targets,SPECS)
    for n,fields in d.items():
        o={}
        for s,v in fields.items():
            if s in ("name()","symbol()"): o[s]=dec_str(v)
            elif s=="peers(uint32)": o[s]=v
            elif s in ("totalSupply()","totalAssets()","globalInitializationCounter()","secondaryChainBalance()","paused()","totalDebt()","balance()","decimals()"): o[s]=u(v)
            elif s=="approvalRequired()": o[s]=u(v)
            else: o[s]=addr(v)
        res[tag][n]=o
print(json.dumps(res,indent=1))
