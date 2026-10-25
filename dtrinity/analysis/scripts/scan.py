import json, urllib.request
RPC = "https://evm.cronos.org"
MC  = "0x5795BE23A2C330209849e0D1D19cc05755E23Ca2"

def rpc_batch(calls):
    out = {}
    for start in range(0, len(calls), 10):
        chunk = calls[start:start+10]
        payload = []
        for i,(to,data) in enumerate(chunk):
            payload.append({"jsonrpc":"2.0","id":start+i,"method":"eth_call","params":[{"to":to,"data":data},"latest"]})
        req = urllib.request.Request(RPC, data=json.dumps(payload).encode(),
            headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
        res = json.loads(urllib.request.urlopen(req, timeout=90).read())
        for item in res:
            out[item["id"]] = item.get("result") if "result" in item else None
    return [out.get(i) for i in range(len(calls))]

if __name__ == "__main__":
    calls = [(MC, "0x1526fe27" + format(i,"064x")) for i in range(43)]
    res = rpc_batch(calls)
    pools = []
    for i,r in enumerate(res):
        if not r or len(r) < 2+64*5:
            print("pool",i,"bad"); continue
        w = r[2:]
        pools.append(dict(pid=i,
            lp="0x"+w[24:64], ap=int(w[64:128],16), lrb=int(w[128:192],16),
            acc=int(w[192:256],16), strat="0x"+w[280:320]))
    json.dump(pools, open("pools.json","w"), indent=1)
    for p in pools:
        print(p["pid"], p["lp"], p["ap"], p["lrb"], p["strat"])
