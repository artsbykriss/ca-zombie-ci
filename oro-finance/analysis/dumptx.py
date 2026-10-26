import sys,json
sys.path.insert(0,'.')
import rpc2
def fullkeys(tx):
    m=tx["transaction"]["message"]; k=[x["pubkey"] for x in m["accountKeys"]]
    la=tx["meta"].get("loadedAddresses") or {}
    k+=list(la.get("writable") or []); k+=list(la.get("readonly") or [])
    return k
def show(sig):
    tx=rpc2.call("getTransaction",[sig,{"encoding":"jsonParsed","maxSupportedTransactionVersion":0}])
    if not tx: print("no tx"); return
    keys=fullkeys(tx)
    print("SIG",sig,"SLOT",tx["slot"])
    print("KEYS")
    for i,k in enumerate(keys): print("  ",i,k)
    print("TOP")
    for ix in tx["transaction"]["message"]["instructions"]:
        print("  ",ix.get("programId"), str(ix.get("data"))[:80], ix.get("accounts"))
    print("INNER")
    for g in tx["meta"].get("innerInstructions") or []:
        for ix in g["instructions"]:
            print("  ",ix.get("programId"), str(ix.get("data"))[:80], ix.get("accounts"))
    print("LOGS")
    for l in tx["meta"].get("logMessages") or []: print("   ",l)
if __name__=="__main__":
    show(sys.argv[1])
