#!/usr/bin/env python3
"""Parse authority-txs.json: extract loader instructions (upgrades/deploys/setAuthority) per program."""
import json, os, sys

OUT = os.path.dirname(os.path.abspath(__file__))
LOADER = "BPFLoaderUpgradeab1e11111111111111111111111"
NAMES = {0:"InitializeBuffer",1:"Write",2:"DeployWithMaxDataLen",3:"Upgrade",4:"SetAuthority",5:"Close",6:"ExtendProgram",7:"SetAuthorityChecked"}
ALPHA='123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
def b58d(s):
    n=0
    for c in s: n=n*58+ALPHA.index(c)
    return n.to_bytes((n.bit_length()+7)//8,'big') if n else b''

data=json.load(open(os.path.join(OUT,"authority-txs.json")))
rows=[]
for d in data:
    tx=d["tx"]
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
        rows.append({"slot":d["slot"],"sig":d["sig"],"blockTime":tx.get("blockTime"),"err":meta.get("err"),
                     "disc":disc,"name":NAMES.get(disc,str(disc)),"accts":accts,"datalen":len(raw)})

rows.sort(key=lambda r:r["slot"])
print(f"loader instructions: {len(rows)}")
# group programdata
pds={}
for r in rows:
    if r["name"] in ("Upgrade","DeployWithMaxDataLen","SetAuthority","SetAuthorityChecked") and r["accts"]:
        pd=r["accts"][0]
        pds.setdefault(pd,[]).append(r)
print("\n=== ProgramData accounts ===")
for pd, rs in pds.items():
    print(f"{pd}: {len(rs)} ops, slots {rs[0]['slot']} .. {rs[-1]['slot']}")
    for r in rs[:3]:
        print("   ", r["slot"], r["name"], "accts:", r["accts"][:6], "err", r["err"])

print("\n=== FULL chronological loader ops (upgrades only) ===")
for r in rows:
    if r["name"] in ("Upgrade","DeployWithMaxDataLen","SetAuthority","SetAuthorityChecked"):
        bt=r["blockTime"]
        import datetime
        ts=datetime.datetime.utcfromtimestamp(bt).strftime("%Y-%m-%d %H:%M") if bt else "?"
        extra=""
        if r["name"]=="Upgrade" and len(r["accts"])>=3:
            extra=f" program={r['accts'][1]} buffer={r['accts'][2]}"
        print(f"{r['slot']} {ts} {r['name']:22s} pd={r['accts'][0]}{extra} err={r['err']} sig={r['sig'][:24]}")

print("\n=== non-upgrade loader ops ===")
for r in rows:
    if r["name"] not in ("Upgrade","DeployWithMaxDataLen","SetAuthority","SetAuthorityChecked"):
        import datetime
        bt=r["blockTime"]
        ts=datetime.datetime.utcfromtimestamp(bt).strftime("%Y-%m-%d %H:%M") if bt else "?"
        print(f"{r['slot']} {ts} {r['name']:22s} accts={r['accts'][:8]} datalen={r['datalen']} err={r['err']} sig={r['sig'][:24]}")
