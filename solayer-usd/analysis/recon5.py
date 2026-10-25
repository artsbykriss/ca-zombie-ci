#!/usr/bin/env python3
"""recon5: fetch sunset / migrate / claim / frozen txs; and a real withdraw+resolve pair with deltas."""
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s, solsim as S

PROG="s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
out = {"slot": s.get_slot()["result"]}

def fetch_sigs(addr, limit=40):
    return [x["signature"] for x in (s.get_signatures(addr, limit=limit).get("result") or [])]

def txfull(sig):
    return s.get_transaction(sig, encoding="json").get("result")

def keys_of(tx):
    m = tx["transaction"]["message"]; k = list(m["accountKeys"])
    la = tx["meta"].get("loadedAddresses") or {}
    k += list(la.get("writable") or []); k += list(la.get("readonly") or [])
    return k

def ixs_of(tx):
    m = tx["transaction"]["message"]; keys = keys_of(tx); res=[]
    def one(ix):
        pid = keys[ix["programIdIndex"]]
        if pid != PROG: return None
        return {"accounts":[keys[a] for a in ix["accounts"]], "data": ix["data"]}
    for ix in m["instructions"]:
        r = one(ix)
        if r: res.append(("top", r))
    for g in tx["meta"].get("innerInstructions") or []:
        for ix in g["instructions"]:
            r = one(ix)
            if r: res.append(("inner%d"%g["index"], r))
    return res

def deltas(tx):
    keys = keys_of(tx)
    pre = {b["accountIndex"]: (keys[b["accountIndex"]] if b["accountIndex"]<len(keys) else None, b["mint"], int(b["uiTokenAmount"]["amount"])) for b in (tx["meta"].get("preTokenBalances") or [])}
    post = {b["accountIndex"]: (keys[b["accountIndex"]] if b["accountIndex"]<len(keys) else None, b["mint"], int(b["uiTokenAmount"]["amount"])) for b in (tx["meta"].get("postTokenBalances") or [])}
    out=[]
    for i in sorted(set(pre)|set(post)):
        if pre.get(i)!=post.get(i):
            out.append({"acct": (post.get(i) or pre.get(i))[0], "mint": (post.get(i) or pre.get(i))[1],
                        "pre": (pre.get(i) or (None,None,0))[2], "post": (post.get(i) or (None,None,0))[2]})
    return out

# 1) MigratedDepositProof txs
for pk in ["3U2chkhnisqEoPT8WToTqRSSNKZuNJ45NJJxCNVc6ZHX","B1L4836Xvs4hyPyVgPiABqDLJcwEWZWNGcwNzmJHjiKe"]:
    sigs = fetch_sigs(pk, 20)
    out["migproof_%s"%pk[:6]] = []
    for sg in sigs[:6]:
        tx = txfull(sg)
        if not tx: continue
        out["migproof_%s"%pk[:6]].append({"sig":sg,"slot":tx["slot"],"ixs":ixs_of(tx),
            "deltas":deltas(tx),"err":tx["meta"]["err"],
            "logs":[l for l in tx["meta"].get("logMessages",[]) if "Instruction:" in l]})

# 2) sunset txs
for sg in ["fP98Tq5uZJgoLUv8NQg14AhCYimS9SsxTGGrvDpXBhL4qsDZaVZtqui1urAuBmHnKprExPcmVpmcohaXGkWiNdU",
           "4Nom8BfTy3a7VRgVtE7EfV4T7SsCsbB1gS6TPnHvD4NKjLiA5Y8caoVKv5HEXdeknNXGEdDeBNtXjerFqeWixArV"]:
    tx = txfull(sg)
    if tx:
        out["sunset_%s"%sg[:6]] = {"slot":tx["slot"],"ixs":ixs_of(tx),"deltas":deltas(tx),
            "err":tx["meta"]["err"],"logs":tx["meta"].get("logMessages",[])}

# 3) pool account sigs -> find handleFrozenAccounts / claim
psigs = fetch_sigs("FhVcYNEe58SMtxpZGnTu2kpYJrTu2vwCZDGpPLqbd2yG", 60)
out["pool_sigs"] = psigs

json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "recon5.json"),"w"), indent=1)
print("saved")
for k,v in out.items():
    if k.startswith("migproof") or k.startswith("sunset"):
        print(k, json.dumps(v)[:1500])
