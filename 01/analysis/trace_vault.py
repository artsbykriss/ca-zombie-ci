#!/usr/bin/env python3
"""Trace the vault USDC token account (3er2PEW...) history: all flows, sum in/out."""
import json, urllib.request, time, base64, datetime

RPC = "https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=5, timeout=90):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                out = json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(1.5*(i+1))
    raise RuntimeError(str(last))

VAULT_ATA="3er2PEWxhpuRkbVwE3ks2nynr5EtcSjCs5fdDJiKQocp"
sigs=[]
before=None
for page in range(6):
    params=[VAULT_ATA,{"limit":1000}]
    if before: params[1]["before"]=before
    r=rpc("getSignaturesForAddress",params)
    batch=r["result"]
    if not batch: break
    sigs+=batch
    before=batch[-1]["signature"]
    if len(batch)<1000: break
print("total sigs on vault ATA:", len(sigs))
first=sigs[-1]; last=sigs[0]
print("oldest:", first["signature"][:20], datetime.datetime.utcfromtimestamp(first["blockTime"]) if first.get("blockTime") else None)
print("newest:", last["signature"][:20], datetime.datetime.utcfromtimestamp(last["blockTime"]) if last.get("blockTime") else None)
# sample transactions: get pre/post balance of the vault ATA
rows=[]
for s in sigs[:400]:
    try:
        v=rpc("getTransaction",[s["signature"],{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}])["result"]
        if not v: continue
        pre=post=None
        for b in v["meta"].get("preTokenBalances",[]):
            if b.get("accountIndex") is not None and b.get("mint")=="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v":
                idx=b["accountIndex"]
                # find if this account is the vault ATA
                keys=v["transaction"]["message"]["accountKeys"]
                pk=keys[idx]["pubkey"] if isinstance(keys[idx],dict) else keys[idx]
                if pk==VAULT_ATA: pre=float(b["uiTokenAmount"]["uiAmount"] or 0)
        for b in v["meta"].get("postTokenBalances",[]):
            if b.get("accountIndex") is not None and b.get("mint")=="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v":
                idx=b["accountIndex"]
                keys=v["transaction"]["message"]["accountKeys"]
                pk=keys[idx]["pubkey"] if isinstance(keys[idx],dict) else keys[idx]
                if pk==VAULT_ATA: post=float(b["uiTokenAmount"]["uiAmount"] or 0)
        bt=v.get("blockTime")
        logs=v["meta"].get("logMessages",[])
        ins=[l.split("Instruction: ")[1] for l in logs if "Instruction: " in l]
        if pre is not None or post is not None:
            rows.append({"sig":s["signature"],"bt":bt,"pre":pre,"post":post,"ins":ins,"err":v["meta"]["err"]})
    except Exception as e:
        pass
    time.sleep(0.1)
json.dump(rows, open("analysis/vault_ata_history.json","w"), indent=1)
print("rows with balances:", len(rows))
rows_sorted=sorted([r for r in rows if r["pre"] is not None and r["post"] is not None], key=lambda r:r["bt"] or 0)
for r in rows_sorted[:10]:
    print(datetime.datetime.utcfromtimestamp(r["bt"]), f"{r['pre']:>14.6f} -> {r['post']:>14.6f}  delta={r['post']-r['pre']:>12.6f}  {r['ins']} err={r['err']}")
print("...")
for r in rows_sorted[-15:]:
    print(datetime.datetime.utcfromtimestamp(r["bt"]), f"{r['pre']:>14.6f} -> {r['post']:>14.6f}  delta={r['post']-r['pre']:>12.6f}  {r['ins']} err={r['err']}")
tot_in=sum(r['post']-r['pre'] for r in rows_sorted if r['post']>r['pre'])
tot_out=sum(r['post']-r['pre'] for r in rows_sorted if r['post']<r['pre'])
print(f"sampled inflows: {tot_in:.6f}  outflows: {tot_out:.6f}")
