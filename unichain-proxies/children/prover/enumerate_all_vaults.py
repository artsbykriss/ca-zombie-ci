#!/usr/bin/env python3
"""READ-ONLY. Enumerate every Eco Vault ever created on Unichain (from IntentFunded events),
derive its CREATE2 address, and read live USDC/USDT0 balance via public RPC.
No secrets. Writes JSON to this folder."""
import json, os, sys, time, urllib.request
from eth_hash.auto import keccak

HERE = os.path.dirname(os.path.abspath(__file__))
RPC = "https://mainnet.unichain.org"
H = {"User-Agent": "Mozilla/5.0 (research; read-only)"}
USDC = "0x078D782b760474a361dDA0AF3839290b0EF57AD6"
USDT0 = "0x9151434b16b9763660705744891fA906F660EcC5"
PORTAL = bytes.fromhex("399Dbd5DF04f83103F77A58cBa2B7c4d3cdede97")
ES = "https://api.etherscan.io/v2/api"
KEY = os.environ.get("ETHERSCANV2_API_KEY", "")
T_INTENTFUNDED = "0xc1ed05721d27ad6b2555d61388ac393b120f5cc0e6009e53230e02c68e60064a"
T_INTENTPUB = "0x43974895be1bcec7344337863fa7de24a0d1c315c0a994f663fe0ee220ddc8e4"

def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=H), timeout=60) as r:
        return json.loads(r.read())

def es_logs(topic, frm, to):
    url = f"{ES}?chainid=130&module=logs&action=getLogs&fromBlock={frm}&toBlock={to}&address=0x399Dbd5DF04f83103F77A58cBa2B7c4d3cdede97&topic0={topic}&apikey={KEY}"
    for attempt in range(4):
        d = get(url)
        r = d.get("result")
        if isinstance(r, list):
            return r
        time.sleep(1.5*(attempt+1))
    print("es_logs fail", frm, to, str(d)[:120], file=sys.stderr)
    return []

def rpc_batch(calls):
    body = json.dumps([{"jsonrpc":"2.0","id":i,"method":m,"params":p} for i,(m,p) in enumerate(calls)]).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research"})
    with urllib.request.urlopen(req, timeout=60) as r:
        out = json.loads(r.read())
    res=[None]*len(calls)
    for o in out:
        if isinstance(o,dict): res[o["id"]]=o.get("result")
    return res

def main():
    d=json.load(open(os.path.join(HERE,"..","..","analysis","immutableproxy_clone.json")))
    ich = keccak(bytes.fromhex(d['creation_bytecode'][2:]))
    # paginate IntentFunded
    hashes=set()
    lo,hi=40_000_000,53_100_000
    step=400_000
    b=lo
    while b<=hi:
        to=min(b+step-1,hi)
        try:
            r=es_logs(T_INTENTFUNDED,b,to)
        except Exception as e:
            print("err",b,e,file=sys.stderr); r=[]
        for x in r:
            if len(x.get("topics",[]))>1: hashes.add(x["topics"][1])
        b=to+1
        time.sleep(0.15)
    print("distinct funded intentHashes:",len(hashes))
    # derive vault addresses
    vaults={}
    for h in hashes:
        ih=bytes.fromhex(h[2:])
        a="0x"+keccak(b'\xff'+PORTAL+ih+ich)[12:].hex()
        vaults[a]=h
    addrs=list(vaults.keys())
    funded=[]
    for i in range(0,len(addrs),5):
        chunk=addrs[i:i+5]
        calls=[]
        for a in chunk:
            data="0x70a08231"+"0"*24+a[2:]
            calls.append(("eth_call",[{"to":USDC,"data":data},"latest"]))
            calls.append(("eth_call",[{"to":USDT0,"data":data},"latest"]))
        r=rpc_batch(calls)
        for j,a in enumerate(chunk):
            u=int(r[2*j],16) if r[2*j] and r[2*j]!="0x" else 0
            t=int(r[2*j+1],16) if r[2*j+1] and r[2*j+1]!="0x" else 0
            if u>0 or t>0:
                funded.append({"vault":a,"intentHash":vaults[a],"usdc":u,"usdt0":t})
    json.dump({"n_intents":len(hashes),"n_vaults":len(addrs),"funded":funded},
              open(os.path.join(HERE,"all_vaults_balance.json"),"w"), indent=1)
    print("distinct vaults:",len(addrs))
    print("currently funded vaults:",len(funded))
    print("SUM usdc", sum(f["usdc"] for f in funded)/1e6, "usdt0", sum(f["usdt0"] for f in funded)/1e6)
    for f in funded[:40]: print(f["vault"], f["usdc"]/1e6, f["usdt0"]/1e6)

if __name__=="__main__":
    main()
