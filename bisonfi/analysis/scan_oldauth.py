#!/usr/bin/env python3
"""Full scan of old-authority (UfSM2ZFR) txs: extract ALL loader instructions to build the fleet upgrade timeline.
Writes JSONL incrementally so it can be resumed. Read-only."""
import json, os, sys, time, urllib.request

OUT = os.path.dirname(os.path.abspath(__file__))
URL = "https://api.mainnet-beta.solana.com"
LOADER = "BPFLoaderUpgradeab1e11111111111111111111111"
NAMES = {0:"InitializeBuffer",1:"Write",2:"DeployWithMaxDataLen",3:"Upgrade",4:"SetAuthority",5:"Close",6:"ExtendProgram",7:"SetAuthorityChecked"}
ALPHA='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58d(s):
    n=0
    for c in s: n=n*58+ALPHA.index(c)
    return n.to_bytes((n.bit_length()+7)//8,'big') if n else b''

def batch(reqs, retries=10):
    payload = json.dumps(reqs).encode()
    last=None
    for a in range(retries):
        try:
            req = urllib.request.Request(URL, data=payload, headers={"Content-Type": "application/json", "User-Agent": "zr/1.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                out = json.loads(r.read())
            if isinstance(out, dict) and out.get("error"):
                time.sleep(min(2*(a+1),20)); last=out["error"]; continue
            return out
        except Exception as ex:
            last=str(ex); time.sleep(min(1.5*(a+1),20))
    raise RuntimeError(f"batch failed: {last}")

def main():
    sigs=json.load(open(os.path.join(OUT,"history-old-authority.json")))
    # sort oldest first, only slots < 424_100_000 (before handover)
    sigs=[s for s in sigs if s["slot"] < 424_100_000]
    sigs.sort(key=lambda s:s["slot"])
    print("to scan:", len(sigs), flush=True)
    outpath=os.path.join(OUT,"oldauth-loader-ops.jsonl")
    done=set()
    if os.path.exists(outpath):
        for line in open(outpath):
            try: done.add(json.loads(line)["sig"])
            except Exception: pass
    print("already done:", len(done), flush=True)
    f=open(outpath,"a")
    B=30
    for i in range(0, len(sigs), B):
        chunk=[s for s in sigs[i:i+B] if s["signature"] not in done]
        if not chunk: continue
        reqs=[{"jsonrpc":"2.0","id":j,"method":"getTransaction",
               "params":[s["signature"],{"encoding":"json","maxSupportedTransactionVersion":0,"commitment":"confirmed"}]}
              for j,s in enumerate(chunk)]
        try:
            res=batch(reqs)
        except Exception as e:
            print("batch err", e, flush=True); time.sleep(5); continue
        byid={r.get("id"):r.get("result") for r in res if isinstance(r,dict)}
        # fallback v1 for missing
        missing=[j for j,s in enumerate(chunk) if byid.get(j) is None]
        if missing:
            reqs2=[{"jsonrpc":"2.0","id":j,"method":"getTransaction",
                    "params":[chunk[j]["signature"],{"encoding":"json","maxSupportedTransactionVersion":1,"commitment":"confirmed"}]}
                   for j in missing]
            try:
                res2=batch(reqs2)
                for r in res2:
                    if isinstance(r,dict) and r.get("result"): byid[r["id"]]=r["result"]
            except Exception: pass
        for j,s in enumerate(chunk):
            tx=byid.get(j)
            if not tx: continue
            meta=tx["meta"]; msg=tx["transaction"]["message"]
            keys=[k["pubkey"] if isinstance(k,dict) else k for k in msg["accountKeys"]]
            loaded=(meta.get("loadedAddresses") or {})
            keys += list(loaded.get("writable",[])) + list(loaded.get("readonly",[]))
            for ins in msg["instructions"]:
                pid=keys[ins["programIdIndex"]]
                if pid!=LOADER: continue
                raw=b58d(ins["data"])
                disc=int.from_bytes(raw[:4],'little') if len(raw)>=4 else None
                accts=[keys[a] for a in ins["accounts"]]
                rec={"sig":s["signature"],"slot":s["slot"],"blockTime":tx.get("blockTime"),
                     "disc":disc,"name":NAMES.get(disc,str(disc)),"accts":accts,"err":meta.get("err")}
                if rec["name"] not in ("Write","InitializeBuffer"):
                    f.write(json.dumps(rec)+"\n"); f.flush()
                    print(rec["slot"], rec["name"], accts[0] if accts else None, flush=True)
        if i % 500 == 0:
            print(f"progress {i}/{len(sigs)}", flush=True)
        time.sleep(0.05)
    f.close()
    print("DONE", flush=True)

if __name__=="__main__":
    main()
