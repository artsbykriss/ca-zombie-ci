#!/usr/bin/env python3
"""solsim.py - build legacy Solana txs and simulate them (read-only, sigVerify=false).

No signing, no broadcast. Only simulateTransaction.
"""
import json, base64, sys, os, struct, time
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
    for c in sv: n = n * 58 + A.index(c)
    b = n.to_bytes((n.bit_length() + 7) // 8, "big"); pad = 0
    for c in sv:
        if c == "1": pad += 1
        else: break
    return b"\x00" * pad + b

def cu(n):
    out = bytearray()
    while True:
        b = n & 0x7F; n >>= 7
        if n: out.append(b | 0x80)
        else: out.append(b); break
    return bytes(out)

def build(signer, ixs, extra_writable=(), extra_readonly=(), blockhash=None):
    """ixs: list of (programId, [ (pubkey, is_writable, is_signer), ... ], data_bytes)."""
    if blockhash is None:
        blockhash = s.get_latest_blockhash()["result"]["value"]["blockhash"]
    writable, readonly, signers = [], [], []
    def add(k, w, sg):
        if sg:
            if k not in signers: signers.append(k)
            return
        if w:
            if k not in writable and k not in signers: writable.append(k)
        else:
            if k not in readonly and k not in writable and k not in signers: readonly.append(k)
    # program ids are readonly
    progs = []
    for pid, accts, data in ixs:
        if pid not in progs: progs.append(pid)
    for pid, accts, data in ixs:
        for (k, w, sg) in accts:
            add(k, w, sg)
    for k in extra_writable: add(k, True, False)
    for k in extra_readonly: add(k, False, False)
    # signer first
    if signer in writable: writable.remove(signer)
    if signer in readonly: readonly.remove(signer)
    signers = [signer] + [x for x in signers if x != signer]
    for pid in progs:
        if pid in writable: writable.remove(pid)
        if pid in readonly: readonly.remove(pid)
        if pid not in signers: readonly.append(pid)
    keys = signers + writable + readonly
    idx = {k: i for i, k in enumerate(keys)}
    msg = bytearray()
    msg += bytes([len(signers), 0, len(readonly)])
    msg += cu(len(keys))
    for k in keys: msg += b58dec(k)
    msg += b58dec(blockhash)
    msg += cu(len(ixs))
    for pid, accts, data in ixs:
        msg += bytes([idx[pid]])
        msg += cu(len(accts))
        for (k, w, sg) in accts: msg += bytes([idx[k]])
        msg += cu(len(data)); msg += bytes(data)
    return base64.b64encode(cu(len(signers)) + b"\x00" * 64 * len(signers) + bytes(msg)).decode()

def simulate(tx_b64):
    r = s.simulate_transaction(tx_b64, sig_verify=False, replace_recent=True)
    return r.get("result", {})

def run(label, signer, ixs, extra_writable=(), extra_readonly=()):
    try:
        tx = build(signer, ixs, extra_writable, extra_readonly)
        r = simulate(tx)
    except Exception as e:
        return {"label": label, "rpc_error": str(e)}
    v = r.get("value") or {}
    logs = v.get("logs") or []
    return {"label": label, "err": v.get("err"), "cu": v.get("unitsConsumed"),
            "logs": [l for l in logs if ("failed" in l or "Error" in l or "Program log" in l or "consumed" in l)][:40],
            "all_logs": logs, "pre": v.get("preTokenBalances"), "post": v.get("postTokenBalances"),
            "preLamports": v.get("preBalances"), "postLamports": v.get("postBalances"),
            "accounts": v.get("accounts")}

if __name__ == "__main__":
    print(b58enc(b58dec("11111111111111111111111111111111")))
