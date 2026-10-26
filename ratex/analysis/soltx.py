#!/usr/bin/env python3
"""Build a legacy Solana transaction for read-only simulateTransaction, preserving the
instruction's account ORDER (program semantics) while satisfying the message header rule
(signers first). All non-program accounts are marked writable to avoid readonly-write errors."""
import base64
try:
    import base58 as b58
except Exception:
    import b58
import solrpc as s

def _u16(n):
    out=bytearray()
    while True:
        b=n & 0x7f; n >>= 7
        if n: out.append(b|0x80)
        else: out.append(b); break
    return bytes(out)

def build_tx(accounts, signers, program_id, data, blockhash=None, fee_payer=None):
    signers=[a for a in accounts if a in signers]
    nons=[a for a in accounts if a not in signers]
    if fee_payer and fee_payer not in signers:
        signers=[fee_payer]+signers
    # dedupe preserving order
    keys=[]
    for a in signers+nons+[program_id]:
        if a not in keys: keys.append(a)
    idx={a:i for i,a in enumerate(keys)}
    num_signers=len(signers)
    num_ro_unsigned=len([a for a in keys[num_signers:] if a==program_id])
    header=bytes([num_signers, 0, num_ro_unsigned])
    msg=bytearray()
    msg += header
    msg += _u16(len(keys))
    for a in keys: msg += b58.b58decode(a)
    msg += b58.b58decode(blockhash) if blockhash else bytes(32)
    msg += _u16(1)
    msg += bytes([idx[program_id]])
    acct_idx=[idx[a] for a in accounts]
    msg += _u16(len(acct_idx))
    msg += bytes(acct_idx)
    msg += _u16(len(data))
    msg += data
    tx=bytearray()
    tx += _u16(num_signers)
    tx += bytes(64*num_signers)
    tx += msg
    return base64.b64encode(bytes(tx)).decode(), keys

def sim(accounts, signers, program_id, data, blockhash=None, fee_payer=None):
    b64,keys=build_tx(accounts, signers, program_id, data, blockhash, fee_payer)
    res=s.simulate_transaction(b64)
    return res, keys

def summarize(res):
    r=res.get("result")
    if r is None:
        return {"raw":res}
    v=r.get("value",{})
    logs=v.get("logs",[])
    return {"err":v.get("err"),"units":v.get("unitsConsumed"),
            "logs":logs,
            "anchor_err":[l for l in logs if "AnchorError" in l or "Error Message" in l or "custom program error" in l or "Error Code" in l]}
