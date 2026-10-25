#!/usr/bin/env python3
"""READ-ONLY. Find Unichain Eco Vault proxies (impl 0x3fd339..) that currently hold USDC/USDT0,
by scanning recent USDC transfer recipients. Public endpoints only."""
import json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
BS = "https://unichain.blockscout.com/api/v2"
RPC = "https://mainnet.unichain.org"
H = {"User-Agent": "Mozilla/5.0 (research; read-only)"}
USDC = "0x078D782b760474a361dDA0AF3839290b0EF57AD6"
USDT0 = "0x9151434b16b9763660705744891fA906F660EcC5"
VAULT_IMPL = "0x3fd339e58769a56d08dcd2683f9012e881287476"

def get(url, tries=4):
    for i in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=H), timeout=45) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(1.0*(i+1))
    return None

def rpc_batch(calls):
    body = json.dumps([{"jsonrpc":"2.0","id":i,"method":m,"params":p} for i,(m,p) in enumerate(calls)]).encode()
    req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research"})
    with urllib.request.urlopen(req, timeout=60) as r:
        out = json.loads(r.read())
    res = [None]*len(calls)
    for o in out:
        if isinstance(o, dict): res[o["id"]] = o.get("result")
    return res

def bal(a):
    data = "0x70a08231" + "0"*24 + a[2:].lower()
    r = rpc_batch([("eth_call", [{"to":USDC,"data":data},"latest"]), ("eth_call", [{"to":USDT0,"data":data},"latest"])])
    u = int(r[0],16) if r[0] and r[0]!="0x" else 0
    t = int(r[1],16) if r[1] and r[1]!="0x" else 0
    return u,t

def main():
    # scan recent transfers of both tokens, collect recipients that are vault proxies
    cands = {}
    for token in (USDC, USDT0):
        url = f"{BS}/tokens/{token}/transfers"
        params = {}
        pages = 0
        while pages < 12:
            u = url + ("?" + "&".join(f"{k}={v}" for k,v in params.items()) if params else "")
            d = get(u)
            if not d: break
            items = d.get("items", [])
            for it in items:
                to = (it.get("to") or {}).get("hash")
                if to: cands[to] = cands.get(to,0)+1
            nxt = d.get("next_page_params")
            if not nxt: break
            params = nxt; pages += 1
            time.sleep(0.2)
    print("unique recipients scanned:", len(cands), file=sys.stderr)
    # filter to vault proxies
    addrs = list(cands.keys())
    vaults = []
    for i in range(0, len(addrs), 10):
        chunk = addrs[i:i+10]
        codes = rpc_batch([("eth_getCode",[a,"latest"]) for a in chunk])
        for a,c in zip(chunk,codes):
            if c and VAULT_IMPL[2:] in c.lower():
                vaults.append(a)
    print("vault proxies among recipients:", len(vaults), file=sys.stderr)
    res = []
    for a in vaults:
        u,t = bal(a)
        if u>0 or t>0:
            res.append({"addr":a,"usdc":u,"usdt0":t})
    json.dump(res, open(os.path.join(HERE,"current_funded_vaults.json"),"w"), indent=1)
    print("currently funded vaults:", len(res))
    for r in res[:60]:
        print(r["addr"], r["usdc"]/1e6, r["usdt0"]/1e6)
    print("SUM usdc", sum(r["usdc"] for r in res)/1e6, "usdt0", sum(r["usdt0"] for r in res)/1e6)

if __name__=="__main__":
    main()
