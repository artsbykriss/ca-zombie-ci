import sys,json,time
sys.path.insert(0,'.')
import rpc2
PID="iNtiXEFgDNrc6FUt4cFALDe3D8RF3sVnNuKSHwxZRop"
sigs=json.load(open("oro_sigs.json"))
cand=[s for s in sigs if not s.get("memo")]
out=[]
for k,s in enumerate(cand):
    if k>400: break
    try:
        tx=rpc2.call("getTransaction",[s["signature"],{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}])
    except Exception as e:
        time.sleep(1); continue
    if not tx: continue
    inv=[]
    for ix in tx["transaction"]["message"]["instructions"]:
        if ix.get("programId")==PID: inv.append(ix)
    for g in tx["meta"].get("innerInstructions") or []:
        for ix in g["instructions"]:
            if ix.get("programId")==PID: inv.append(ix)
    if inv:
        keys=[x["pubkey"] for x in tx["transaction"]["message"]["accountKeys"]]
        la=tx["meta"].get("loadedAddresses") or {}
        keys+=list(la.get("writable") or []); keys+=list(la.get("readonly") or [])
        out.append({"sig":s["signature"],"slot":s["slot"],
            "logs":[l for l in (tx["meta"].get("logMessages") or []) if "Instruction:" in l],
            "ixs":[{"data":ix.get("data"),"accts":ix.get("accounts")} for ix in inv],
            "keys":keys})
        json.dump(out,open("inv_hits.json","w"),indent=1)
    if k%25==0: sys.stderr.write(f"{k} hits={len(out)}\n")
    time.sleep(0.12)
print("DONE",len(out))
