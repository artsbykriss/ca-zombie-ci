#!/usr/bin/env python3
"""Step 3: instruction surface from real tx logs + Anchor IDL lookup + account discriminator id."""
import json, base64, sys, os, struct, collections, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solrpc as s

A = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58enc(b):
    n = int.from_bytes(b, "big"); out = ""
    while n > 0:
        n, r = divmod(n, 58); out = A[r] + out
    pad = 0
    for c in b:
        if c == 0: pad += 1
        else: break
    return "1" * pad + (out or "")
def b58dec(sv):
    n = 0
    for c in sv: n = n*58 + A.index(c)
    b = n.to_bytes((n.bit_length()+7)//8, "big"); pad = 0
    for c in sv:
        if c == "1": pad += 1
        else: break
    return b"\x00"*pad + b

PROG = "s1aysqpEyZyijPybUV89oBGeooXrR22wMNLjnG2SWJA"
out = {"slot": s.get_slot()["result"]}

# --- Anchor IDL PDA ---
seed_idl = b"anchor:idl"
for bump in range(255, -1, -1):
    h = hashlib.sha256(seed_idl + bytes([bump]) + b58dec(PROG) + b"ProgramDerivedAddress").digest()
    # off-curve check: try ed25519 point decompression (need pysodium-free). Use simple check via nacl if present
    break
# just query candidates via findProgramAddress style: try all bumps, check account exists
found_idl = None
for bump in range(255, -1, -1):
    h = hashlib.sha256(seed_idl + bytes([bump]) + b58dec(PROG) + b"ProgramDerivedAddress").digest()
    v = s.get_account_info(b58enc(h))["result"]["value"]
    if v is not None:
        found_idl = {"addr": b58enc(h), "owner": v["owner"], "space": v["space"]}
        break
out["anchor_idl_pda"] = found_idl
print("anchor idl pda:", found_idl)

# --- instruction scan ---
def keys_of(tx):
    m = tx["transaction"]["message"]
    k = list(m["accountKeys"])
    la = tx["meta"].get("loadedAddresses") or {}
    k += list(la.get("writable") or []); k += list(la.get("readonly") or [])
    return k

def prog_ixs(tx):
    """yield (data, accounts) for instructions whose program == PROG, jsonParsed tolerant."""
    m = tx["transaction"]["message"]
    keys = keys_of(tx)
    res = []
    def one(ix):
        pid = ix.get("programId")
        if pid is None:
            pii = ix.get("programIdIndex")
            if pii is not None and pii < len(keys): pid = keys[pii]
        if pid != PROG: return None
        accts = ix.get("accounts") or []
        # jsonParsed accounts may be a list of indices or list of {pubkey}
        accs = []
        for a in accts:
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

sigs = s.get_signatures(PROG, limit=1000).get("result") or []
print("sigs:", len(sigs))
hist = collections.Counter(); samples = {}; disc_map = {}
txs_ok = 0
for i, sg in enumerate(sigs):
    try:
        tx = s.get_transaction(sg["signature"]).get("result")
    except Exception:
        tx = None
    if not tx: continue
    txs_ok += 1
    names = [l.split("Instruction: ",1)[1] for l in (tx["meta"].get("logMessages") or [])
             if l.startswith("Program log: Instruction: ")]
    ixres = prog_ixs(tx)
    # map names to data by order
    for j, (kind, r) in enumerate(ixres):
        d = r["data"]
        try:
            raw = b58dec(d) if isinstance(d, str) else bytes(d)
        except Exception:
            raw = b""
        disc = raw[:8].hex() if len(raw) >= 8 else raw.hex()
        nm = names[j] if j < len(names) else "?"
        key = "%s|%s" % (nm, disc)
        hist[key] += 1
        disc_map.setdefault(disc, nm)
        if key not in samples:
            samples[key] = {"sig": sg["signature"], "slot": tx["slot"], "kind": kind,
                            "disc": disc, "data_hex": raw.hex(), "name": nm,
                            "accounts": r["accounts"], "err": tx["meta"]["err"]}
    if i % 100 == 99:
        print("scan...", i+1, len(hist), flush=True)

out["ix_hist"] = dict(hist); out["ix_samples"] = samples; out["disc_map"] = disc_map
out["txs_ok"] = txs_ok
print("HIST:")
for k, v in sorted(hist.items(), key=lambda x: -x[1]):
    print("   ", v, k)
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "recon3.json"), "w"), indent=1)
print("saved recon3.json")
