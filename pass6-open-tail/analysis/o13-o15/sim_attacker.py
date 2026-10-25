#!/usr/bin/env python3
"""Attacker-substitution simulator.

Takes a real tx signature, rebuilds a LEGACY message with the original signer(s)
replaced by a fixed attacker pubkey (attacker = only signer), preserves account
order, and simulates with sigVerify:false + replaceRecentBlockhash:true.

Also runs the CONTROL: the original tx bytes simulated as-is (sigVerify:false).
"""
import json, base64, sys, struct, hashlib
from sol_rpc import get_transaction, rpc

ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def b58decode(s):
    n=0
    for ch in s: n=n*58+ALPHABET.index(ch)
    b=n.to_bytes((n.bit_length()+7)//8,"big")
    pad=0
    for ch in s:
        if ch=="1": pad+=1
        else: break
    return b"\x00"*pad+b
def b58encode(b):
    n=int.from_bytes(b,"big"); out=""
    while n>0: n,r=divmod(n,58); out=ALPHABET[r]+out
    pad=0
    for c in b:
        if c==0: pad+=1
        else: break
    return "1"*pad+(out or "")

# fixed attacker pubkey (deterministic, not a real key we control)
ATTACKER = b58encode(hashlib.sha256(b"pass6-open-tail-attacker").digest())  # 32 bytes

_attacker_cache = {"pk": None}
def get_attacker(avoid=None):
    """Pick a real, existing (funded) unprivileged wallet to act as the attacker.
    Uses the fee payer of a recent unrelated transaction."""
    if _attacker_cache["pk"]:
        return _attacker_cache["pk"]
    from sol_rpc import get_signatures
    avoid = set(avoid or [])
    # busy program: Jupiter v6 aggregator
    for prog in ["JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4",
                 "ComputeBudget111111111111111111111111111111"]:
        try:
            rs = get_signatures(prog, limit=20).get("result") or []
        except Exception:
            continue
        for s in rs:
            try:
                tx = get_transaction(s["signature"], encoding="jsonParsed")
            except Exception:
                continue
            if not tx.get("result"): continue
            keys = tx["result"]["transaction"]["message"]["accountKeys"]
            fp = keys[0]["pubkey"]
            if fp not in avoid:
                _attacker_cache["pk"] = fp
                return fp
    # fallback
    _attacker_cache["pk"] = ATTACKER
    return ATTACKER

def _compact_u16(b, off):
    v = b[off]; off += 1
    if v & 0x80:
        v = (v & 0x7f) | (b[off] << 7); off += 1
    return v, off

def patch_signers(raw, attacker_b58):
    """Patch the raw versioned/legacy tx: replace all required-signer pubkeys with attacker.
    Keeps message/account order and lookup tables intact."""
    b = bytearray(raw)
    nsig, off = _compact_u16(b, 0)
    sig_end = off + nsig*64
    moff = sig_end
    # v0 versioned message has a leading version byte with high bit set (0x80)
    if b[moff] & 0x80:
        moff += 1
    hdr = b[moff:moff+3]
    n_required = hdr[0]
    # static account keys start after header
    o = moff+3
    nkeys, o = _compact_u16(b, o)
    atk = b58decode(attacker_b58)
    # first n_required static keys are the signers
    for i in range(min(n_required, nkeys)):
        b[o+i*32 : o+i*32+32] = atk
    return bytes(b)

def _decode_data(s):
    """jsonParsed instruction data may be base58 (spec) or base64 (some nodes). Try base58 first."""
    if not s:
        return b""
    try:
        return b58decode(s)
    except Exception:
        pass
    try:
        return base64.b64decode(s)
    except Exception:
        return b""

def simulate_b64(tx_bytes):
    return rpc("simulateTransaction", [base64.b64encode(tx_bytes).decode(),
        {"encoding":"base64","sigVerify":False,"replaceRecentBlockhash":True,"commitment":"confirmed"}])

def run(sig, only_program=None, extra_accounts_ok=True):
    tx = get_transaction(sig, encoding="jsonParsed")
    if not tx.get("result"):
        return {"sig":sig,"error":"tx not found"}
    res = tx["result"]
    msg = res["transaction"]["message"]
    keys = msg["accountKeys"]
    pub = [k["pubkey"] for k in keys]
    signer = [k.get("signer",False) for k in keys]
    writable = [k.get("writable",False) for k in keys]
    prog_idx = None
    target = None
    all_ix = list(msg["instructions"])
    for ii in (res.get("meta",{}) or {}).get("innerInstructions",[]) or []:
        all_ix.extend(ii.get("instructions",[]))
    for ix in all_ix:
        if only_program and ix["programId"] != only_program: continue
        prog_idx = pub.index(ix["programId"])
        target = ix
        break
    if target is None:
        return {"sig":sig,"error":"target program ix not found"}
    acct_list = target["accounts"]
    if acct_list and isinstance(acct_list[0], str):
        acct_indices = [pub.index(a) for a in acct_list]
    else:
        acct_indices = list(acct_list)
    data = _decode_data(target.get("data") or "")
    # CONTROL: original tx (need raw base64)
    raw = get_transaction(sig, encoding="base64")
    control = None
    atk = None
    if raw.get("result"):
        try:
            rb = base64.b64decode(raw["result"]["transaction"][0])
            control = simulate_b64(rb)
            atk_pk = get_attacker(avoid=[pub[i] for i,s in enumerate(signer) if s])
            patched = patch_signers(rb, atk_pk)
            atk = simulate_b64(patched)
        except Exception as e:
            control = {"err":str(e)}
            atk = {"err":str(e)}
    return {"sig":sig,"disc":data[:8].hex(),"dlen":len(data),"n_accts":len(acct_indices),
            "orig_signers":[pub[i] for i,s in enumerate(signer) if s],
            "attacker_pubkey": _attacker_cache["pk"],
            "control":control,"attacker":atk}

def summarize(sim):
    if not sim: return "none"
    v = sim.get("result",{}).get("value") if "result" in sim else sim
    if v is None:
        return json.dumps(sim)[:200]
    err = v.get("err")
    logs = v.get("logs") or []
    return json.dumps({"err":err,"cu":v.get("unitsConsumed"),
                       "lastlogs":logs[-4:]})

if __name__=="__main__":
    import sys
    prog = None; sigs=[]
    for a in sys.argv[1:]:
        if a.startswith("--prog="): prog=a.split("=",1)[1]
        else: sigs.append(a)
    for s in sigs:
        r = run(s, only_program=prog)
        print("SIG", s)
        print("  disc", r.get("disc"), "dlen", r.get("dlen"), "naccts", r.get("n_accts"),
              "orig_signers", r.get("orig_signers"), "err", r.get("error"))
        print("  CONTROL :", summarize(r.get("control")))
        print("  ATTACKER:", summarize(r.get("attacker")))
