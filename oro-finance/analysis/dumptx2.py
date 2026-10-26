import sys,json,base64
sys.path.insert(0,'.')
import rpc2
def fullkeys(tx):
    m=tx["transaction"]["message"]; k=[(x["pubkey"],x.get("signer"),x.get("writable")) for x in m["accountKeys"]]
    la=tx["meta"].get("loadedAddresses") or {}
    for w in la.get("writable") or []: k.append((w,False,True))
    for r in la.get("readonly") or []: k.append((r,False,False))
    return k
def show(sig):
    tx=rpc2.call("getTransaction",[sig,{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}])
    if not tx: print("no tx"); return
    keys=fullkeys(tx)
    print("SIG",sig,"SLOT",tx["slot"])
    for i,(k,s,w) in enumerate(keys): print("  %2d %s %s%s"%(i,k,"S" if s else " ","W" if w else " "))
    print("TOP")
    for ix in tx["transaction"]["message"]["instructions"]:
        print("  ",ix.get("programId"), str(ix.get("data"))[:90])
        if ix.get("accounts"): print("     accts",ix["accounts"])
    print("INNER")
    for g in tx["meta"].get("innerInstructions") or []:
        for ix in g["instructions"]:
            print("  ",ix.get("programId"), json.dumps(ix.get("parsed"))[:160] if ix.get("parsed") else str(ix.get("data"))[:70], ix.get("accounts") or "")
    print("LOGS")
    for l in tx["meta"].get("logMessages") or []: print("   ",l)
    print("PRETOK",tx["meta"].get("preTokenBalances"))
    print("POSTTOK",tx["meta"].get("postTokenBalances"))
if __name__=="__main__": show(sys.argv[1])
