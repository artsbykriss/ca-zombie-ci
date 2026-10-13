#!/usr/bin/env python3
"""Pull full account lists for non-redeem instructions (ZammTransfer, FinalizeWinddown, SettleCollateral, etc.)."""
import json, urllib.request, time, base64
RPC = "https://api.mainnet-beta.solana.com"
def rpc(method, params, retries=5):
    body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
    last=None
    for i in range(retries):
        try:
            req = urllib.request.Request(RPC, data=body, headers={"Content-Type":"application/json","User-Agent":"research/1.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                out = json.loads(r.read())
            if "error" in out: raise RuntimeError(out["error"])
            return out
        except Exception as e:
            last=e; time.sleep(1.2*(i+1))
    raise RuntimeError(str(last))

sigs=json.load(open("analysis/program_sig_sample.json"))
targets={"FinalizeWinddown":None,"InitWinddownBook":None,"ZammTransfer":None,"SetManualRatesAndOverrides":None,"SettleCollateral":None,"CloseMargin":None,"ConsumeEvents":None}
for t in sigs:
    for ins in t["ins"]:
        if ins in targets and targets[ins] is None:
            targets[ins]=t["sig"]
print(targets)
out={}
for name,s in targets.items():
    if not s: continue
    v=rpc("getTransaction",[s,{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}])["result"]
    msg=v["transaction"]["message"]
    keys=[k["pubkey"] if isinstance(k,dict) else k for k in msg["accountKeys"]]
    signers=[k["pubkey"] for k in msg["accountKeys"] if isinstance(k,dict) and k.get("signer")]
    print("="*100)
    print(name, s, "slot",v["slot"],"bt",v.get("blockTime"), "signers:", signers)
    for ins in msg["instructions"]:
        if isinstance(ins,dict) and ins.get("programId")=="Zo1ggzTUKMY5bYnDvT5mtVeZxzf2FaLTbKkmvGUhUQk":
            print("  data:", ins.get("data"))
            accts=ins.get("accounts")
            for i,a in enumerate(accts):
                print(f"    [{i}] {a}")
    out[name]={"sig":s,"signers":signers,"msg":msg,"keys":keys,"logs":v["meta"]["logMessages"]}
json.dump(out, open("analysis/instr_samples.json","w"), indent=1, default=str)
