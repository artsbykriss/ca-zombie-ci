#!/usr/bin/env python3
"""Step 4: targeted instruction scan with IDL discriminators; save incrementally."""
import json, base64, sys, os, collections, traceback
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s
HERE = os.path.dirname(os.path.abspath(__file__))
A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58dec(sv):
    n = 0
    for c in sv: n = n*58 + A.index(c)
    b = n.to_bytes((n.bit_length()+7)//8, "big"); pad = 0
    for c in sv:
        if c == "1": pad += 1
        else: break
    return b"\x00"*pad + b

PROG = "s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
IDL = json.load(open(os.path.join(HERE, "idl.json")))
DISC = json.load(open(os.path.join(HERE, "discriminators.json")))["instructions"]

def keys_of(tx):
    m = tx["transaction"]["message"]
    k = list(m["accountKeys"])
    la = tx["meta"].get("loadedAddresses") or {}
    k += list(la.get("writable") or []); k += list(la.get("readonly") or [])
    return k

def prog_ixs(tx):
    m = tx["transaction"]["message"]; keys = keys_of(tx); res = []
    def one(ix):
        pid = ix.get("programId")
        if pid is None:
            pii = ix.get("programIdIndex")
            if pii is not None and pii < len(keys): pid = keys[pii]
        if pid != PROG: return None
        accs = []
        for a in ix.get("accounts") or []:
            if isinstance(a, int): accs.append(keys[a] if a < len(keys) else None)
            elif isinstance(a, dict): accs.append(a.get("pubkey"))
            else: accs.append(a)
        return {"data": ix.get("data"), "accounts": accs}
    for ix in m["instructions"]:
        r = one(ix)
        if r: res.append(("top", r))
    for g in tx["meta"].get("innerInstructions") or []:
        for ix in g["instructions"]:
            r = one(ix)
            if r: res.append(("inner%d" % g["index"], r))
    return res

sigs = s.get_signatures(PROG, limit=300).get("result") or []
print("sigs", len(sigs), flush=True)
hist = collections.Counter(); samples = {}
n = 0
for sg in sigs:
    try:
        tx = s.get_transaction(sg["signature"]).get("result")
    except Exception:
        tx = None
    if not tx: continue
    n += 1
    for kind, r in prog_ixs(tx):
        d = r["data"]
        try:
            raw = b58dec(d) if isinstance(d, str) else bytes(d)
        except Exception:
            raw = b""
        disc = raw[:8].hex()
        nm = DISC.get(disc, "UNK:" + disc)
        hist[nm] += 1
        samples.setdefault(nm, []).append({"sig": sg["signature"], "slot": tx["slot"],
                                           "kind": kind, "data_hex": raw.hex(),
                                           "accounts": r["accounts"], "err": tx["meta"]["err"]})
        if len(samples[nm]) > 6: samples[nm] = samples[nm][:6]
print("HIST", dict(hist), flush=True)
json.dump({"slot": s.get_slot()["result"], "hist": dict(hist), "samples": samples, "txs": n},
          open(os.path.join(HERE, "recon4.json"), "w"), indent=1)
print("saved recon4.json", flush=True)
