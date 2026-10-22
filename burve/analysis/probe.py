#!/usr/bin/env python3
import json, urllib.request, concurrent.futures, sys

RPCS = ["https://berachain-rpc.publicnode.com", "https://rpc.berachain.com", "https://berachain.drpc.org"]

def rpc(method, params, url=None):
    urls = [url] if url else RPCS
    last=None
    for u in urls:
        try:
            req = urllib.request.Request(u, data=json.dumps(
                {"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=30) as r:
                j=json.loads(r.read())
            if "result" in j: return j["result"]
            last=j
        except Exception as e:
            last=e
    raise RuntimeError(str(last))

def dec_str(h):
    try:
        h=h[2:]
        if len(h)<128: return None
        off=int(h[:64],16)*2
        ln=int(h[off:off+64],16)
        if ln==0 or ln>200: return None
        return bytes.fromhex(h[off+64:off+64+ln*2]).decode('utf-8','replace')
    except Exception: return None

def probe(a):
    row={"addr":a}
    for k,sel in (("name","0x06fdde03"),("symbol","0x95d89b41")):
        try: row[k]=dec_str(rpc("eth_call",[{"to":a,"data":sel},"latest"]))
        except Exception: row[k]=None
    try:
        r=rpc("eth_call",[{"to":a,"data":"0x3a2aabcc"},"latest"])
        row["queryTVL"]=r
    except Exception as e:
        row["queryTVL"]=None
    return row

if __name__=="__main__":
    addrs=[l.split()[0] for l in open(sys.argv[1]) if l.strip()]
    out=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:
        for r in ex.map(probe, addrs):
            out.append(r)
            if r["name"] or r["symbol"] or r["queryTVL"]:
                print(json.dumps(r))
    json.dump(out, open(sys.argv[2],"w"), indent=1)
