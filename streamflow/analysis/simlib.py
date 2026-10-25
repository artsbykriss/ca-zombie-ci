#!/usr/bin/env python3
"""Minimal Solana legacy-transaction builder + simulation helpers (read-only).

Only used to build attacker-authored messages and call simulateTransaction with
sigVerify=false, replaceRecentBlockhash=true. Nothing is signed or sent.
"""
import base64, json, struct, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import b58dec, b58enc, simulate, get_account_info, get_program_accounts

SYSTEM = "11111111111111111111111111111111"
TOKEN = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
ATA = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
# neutral, real, funded account used only as the (unverified) fee payer in sims
NEUTRAL = "5SEpbdjFK5FxwTvfsGMXVQTD2v4M2c5tyRTxhdsPkgDw"

def sv(n):
    out = bytearray()
    while True:
        b = n & 0x7f
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            break
    return bytes(out)

def build_tx(payer, instructions, signers=None):
    """instructions: list of (program_id, [(pubkey, is_signer, is_writable)], data)
    payer: fee payer pubkey (first signer). signers: additional signer pubkeys (non-payer)."""
    signers = list(signers or [])
    signer_set = [payer] + [s for s in signers if s != payer]
    # collect accounts
    writable_signer, readonly_signer = [], []
    writable_non, readonly_non = [], []
    seen = {}
    def add(pk, is_signer, is_writable):
        if pk in seen:
            seen[pk][0] = seen[pk][0] or is_signer
            seen[pk][1] = seen[pk][1] or is_writable
            return
        seen[pk] = [is_signer, is_writable]
    add(payer, True, True)
    for s in signers:
        add(s, True, False)
    for pid, accts, data in instructions:
        add(pid, False, False)
        for pk, sg, wr in accts:
            add(pk, sg, wr)
    for pk, (sg, wr) in seen.items():
        if sg and wr: writable_signer.append(pk)
        elif sg: readonly_signer.append(pk)
        elif wr: writable_non.append(pk)
        else: readonly_non.append(pk)
    # payer must be first
    writable_signer = [payer] + [p for p in writable_signer if p != payer]
    ordered = writable_signer + readonly_signer + writable_non + readonly_non
    idx = {pk: i for i, pk in enumerate(ordered)}
    header = bytes([len(writable_signer) + len(readonly_signer),
                    len(readonly_signer), len(readonly_non)])
    keys = b"".join(b58dec(pk) for pk in ordered)
    msg = bytearray()
    msg += header
    msg += sv(len(ordered)) + keys
    msg += b"\x00" * 32  # recent blockhash (replaced by RPC)
    msg += sv(len(instructions))
    for pid, accts, data in instructions:
        msg += bytes([idx[pid]])
        msg += sv(len(accts))
        msg += bytes(idx[pk] for pk, _, _ in accts)
        msg += sv(len(data)) + bytes(data)
    n_sig = header[0]
    tx = sv(n_sig) + (b"\x00" * 64) * n_sig + bytes(msg)
    return base64.b64encode(tx).decode()

def sim(instructions, signers=None, payer=NEUTRAL):
    tx = build_tx(payer, instructions, signers=signers)
    return simulate(tx, sig_verify=False, replace_blockhash=True)

def summarize(res):
    if not isinstance(res, dict):
        return {"raw": str(res)[:300]}
    v = res.get("value") or {}
    logs = v.get("logs") or []
    return {
        "err": v.get("err"),
        "unitsConsumed": v.get("unitsConsumed"),
        "log_tail": logs[-6:],
    }
