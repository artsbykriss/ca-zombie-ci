#!/usr/bin/env python3
"""Fetch all upgrade-authority txs with full details (batched, read-only) and classify."""
import json, os, sys, time, urllib.request

OUT = os.path.dirname(os.path.abspath(__file__))
URL = "https://api.mainnet-beta.solana.com"
AUTH = "6dDjBZdpafRKe7WuVHYTF1HphW1BWiKqioMD5eBGYipS"
LOADER = "BPFLoaderUpgradeab1e11111111111111111111111"

def batch(reqs):
    payload = json.dumps(reqs).encode()
    last=None
    for a in range(8):
        try:
            req = urllib.request.Request(URL, data=payload, headers={"Content-Type": "application/json", "User-Agent": "zr/1.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                out = json.loads(r.read())
            if isinstance(out, dict) and out.get("error"):
                time.sleep(2*(a+1)); last=out["error"]; continue
            return out
        except Exception as ex:
            last=str(ex); time.sleep(2*(a+1))
    raise RuntimeError(f"batch failed: {last}")

def all_sigs(addr, limit=1000, max_pages=10):
    sigs, before = [], None
    for _ in range(max_pages):
        params = [addr, {"limit": limit, "commitment": "confirmed"}]
        if before: params[1]["before"] = before
        r = batch([{"jsonrpc":"2.0","id":1,"method":"getSignaturesForAddress","params":params}])
        res = r[0].get("result", [])
        if not res: break
        sigs.extend(res)
        before = res[-1]["signature"]
        if len(res) < limit: break
    return sigs

def fetch_txs(sigs):
    out = []
    for i in range(0, len(sigs), 8):
        chunk = sigs[i:i+8]
        reqs = [{"jsonrpc":"2.0","id":j,"method":"getTransaction",
                 "params":[s["signature"],{"encoding":"json","maxSupportedTransactionVersion":0,"commitment":"confirmed"}]}
                for j,s in enumerate(chunk)]
        res = batch(reqs)
        byid = {r["id"]: r.get("result") for r in res if isinstance(r, dict)}
        for j,s in enumerate(chunk):
            tx = byid.get(j)
            if tx is None:  # try v1
                res2 = batch([{"jsonrpc":"2.0","id":0,"method":"getTransaction",
                    "params":[s["signature"],{"encoding":"json","maxSupportedTransactionVersion":1,"commitment":"confirmed"}]}])
                tx = res2[0].get("result")
            out.append({"sig": s["signature"], "slot": s["slot"], "tx": tx})
        print(f"  fetched {min(i+8,len(sigs))}/{len(sigs)}", file=sys.stderr)
    return out

if __name__ == "__main__":
    sigs = all_sigs(AUTH)
    print("authority txs:", len(sigs))
    data = fetch_txs(sigs)
    json.dump(data, open(os.path.join(OUT, "authority-txs.json"), "w"), indent=1)

    print("\n=== classify ===")
    for d in data:
        tx = d["tx"]
        if not tx: print(d["slot"], d["sig"][:16], "NO TX"); continue
        msg = tx["transaction"]["message"]
        meta = tx["meta"]
        keys = [k["pubkey"] if isinstance(k,dict) else k for k in msg["accountKeys"]]
        loaded = (meta.get("loadedAddresses") or {})
        keys += list(loaded.get("writable",[])) + list(loaded.get("readonly",[]))
        tags = []
        for ins in msg["instructions"]:
            pid = keys[ins["programIdIndex"]]
            if pid == LOADER:
                data_b58 = ins["data"]
                # decode discriminator
                ALPHA='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
                n=0
                for c in data_b58: n=n*58+ALPHA.index(c)
                raw=n.to_bytes((n.bit_length()+7)//8,'big') if n else b''
                disc = int.from_bytes(raw[:4],'little') if len(raw)>=4 else None
                names={0:"InitializeBuffer",1:"Write",2:"DeployWithMaxDataLen",3:"Upgrade",4:"SetAuthority",5:"Close"}
                tag=f"LOADER:{names.get(disc,disc)}"
                if disc==3 and len(ins["accounts"])>=7:
                    tag += f" programdata={keys[ins['accounts'][0]]} buffer={keys[ins['accounts'][2]]}"
                if disc==4 and len(ins["accounts"])>=2:
                    tag += f" acct={keys[ins['accounts'][0]]} new_auth={keys[ins['accounts'][1]] if len(ins['accounts'])>1 else '?'}"
                tags.append(tag)
            elif pid == "ComputeBudget111111111111111111111111111111":
                pass
            else:
                tags.append(f"pid={pid[:16]}")
        print(d["slot"], d["sig"][:20], "err", meta.get("err"), " | ".join(tags))
