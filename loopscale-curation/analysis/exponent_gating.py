#!/usr/bin/env python3
import solrpc as s, json, base64
try:
    import base58 as b58
except Exception:
    import b58, soltx
PROG="sVau1tXvayVWfotzm9Ahcv2qfnnfRWttt78BCnNC6dD"
NEUTRAL="5tzFkiKscXHK5ZXCGbXZxdw7gTjjD1mBwuoFbhUvuAi9"

def run(label, accounts, signers, data):
    res,keys=soltx.sim(accounts, signers, PROG, data, fee_payer=(list(signers)[0] if signers else NEUTRAL))
    sm=soltx.summarize(res)
    print(f"--- {label}: err={json.dumps(sm.get('err'))}")
    for l in (sm.get('logs') or [])[:10]:
        if "AnchorError" in l or "Error Message" in l or "Instruction:" in l or "failed" in l or "Error:" in l: print("     ",l)
    return sm

sigs=s.get_signatures(PROG, limit=40).get("result",[])
samples={}
for sg in sigs:
    if sg.get("err"): continue
    tx=s.get_transaction(sg["signature"], encoding="jsonParsed").get("result")
    if not tx: continue
    m=tx["transaction"]["message"]
    signers={k["pubkey"] for k in m["accountKeys"] if k.get("signer")}
    for ix in m["instructions"]:
        if ix.get("programId")!=PROG or not ix.get("data"): continue
        try: raw=b58.b58decode(ix["data"])
        except Exception: continue
        tag=raw[:1].hex() if len(raw)>=1 else ""
        key=tag
        if key not in samples:
            samples[key]={"sig":sg["signature"],"accounts":ix["accounts"],"data":raw,"signers":signers}
print("distinct tags:",len(samples))
for tag,v in list(samples.items())[:8]:
    acc=v["accounts"]; sg=v["signers"]; d=v["data"]
    # control
    ctl=run(f"tag {tag} control (orig signer)", acc, sg, d)
    # neutral: replace the signer account in the account list
    si=next((i for i,a in enumerate(acc) if a in sg),None)
    if si is not None:
        alt=list(acc); alt[si]=NEUTRAL
        run(f"tag {tag} neutral-signer (idx{si})", alt, {NEUTRAL}, d)
    else:
        print(f"    tag {tag}: signer not in ix accounts; testing with extra neutral fee payer only")
        run(f"tag {tag} neutral fee-payer only", acc, sg, d)
