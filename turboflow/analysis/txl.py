from b58 import b58dec,b58enc
PID="ALPHAQmeA7bjrVuccPsYPiCvsi428SNwte66Srvs4pHA"
def fullkeys(tx):
    m=tx["transaction"]["message"]
    k=list(m["accountKeys"])
    la=tx["meta"].get("loadedAddresses") or {}
    k+= list(la.get("writable") or [])
    k+= list(la.get("readonly") or [])
    return k
def alphaq_ixs(tx):
    keys=fullkeys(tx)
    out=[]
    for ix in tx["transaction"]["message"]["instructions"]:
        if keys[ix["programIdIndex"]]==PID:
            out.append(("top",ix,keys))
    for grp in tx["meta"].get("innerInstructions") or []:
        for ix in grp["instructions"]:
            if ix["programIdIndex"]<len(keys) and keys[ix["programIdIndex"]]==PID:
                out.append((f"inner{grp['index']}",ix,keys))
    return out
