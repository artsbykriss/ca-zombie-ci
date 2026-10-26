#!/usr/bin/env python3
"""Rebuild a real TurboFlow ix as a legacy message and simulate with a substituted signer.
Read-only: simulateTransaction only, sigVerify=false. Never signs/sends."""
import sys, json, base64, hashlib
from rpc import call
from b58 import b58dec, b58enc
from solmsg import build, order_keys
from sim import simulate

PID = "HwWQZdX116omFGrygkpng7fTzMbrg6JGpLaoM77cM7vg"

def get_bh():
    return call("getLatestBlockhash", [{"commitment": "processed"}])["value"]["blockhash"]

def fetch(sig):
    return call("getTransaction", [sig, {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}])

def extract_bridge_ix(tx, want_disc):
    """Return (accounts, data) of the first top-level ix for PID with matching disc."""
    msg = tx["transaction"]["message"]
    for ix in msg["instructions"]:
        if ix.get("programId") != PID:
            continue
        raw = b58dec(ix["data"])
        if raw[:8].hex() == want_disc:
            return ix["accounts"], ix["data"]
    return None, None

def run(sig, want_disc, swap_signer, attacker, drop_system=True, tag=""):
    tx = fetch(sig)
    msg = tx["transaction"]["message"]
    keymeta = {}
    for k in msg["accountKeys"]:
        if isinstance(k, dict):
            keymeta[k["pubkey"]] = (k["signer"], k["writable"])
        else:
            keymeta[k] = (False, False)
    accts, data = extract_bridge_ix(tx, want_disc)
    if accts is None:
        print(f"[{tag}] no ix with disc {want_disc}"); return None
    d = b58dec(data)
    orig = [a for a in accts if keymeta.get(a, (False, False))[0]]
    print(f"[{tag}] original signers in ix: {orig}")
    payer = attacker if swap_signer else orig[0]
    if swap_signer:
        accts = [attacker if a in orig else a for a in accts]
    # build key list
    keys_flags = [(payer, True, True)]
    seen = {payer}
    for a in accts:
        if a in seen:
            continue
        seen.add(a)
        s, w = keymeta.get(a, (False, False))
        keys_flags.append((a, s, w))
    keys_flags = order_keys(keys_flags)
    if PID not in [k for k, _, _ in keys_flags]:
        keys_flags.append((PID, False, False))
    ix = (PID, accts, d)
    bh = get_bh()
    txb64 = build(keys_flags, bh, [ix])
    r = simulate(txb64)
    v = r["value"]
    print(f"[{tag}] err={json.dumps(v.get('err'))} units={v.get('unitsConsumed')}")
    for l in (v.get("logs") or []):
        print("   ", l)
    return v

if __name__ == "__main__":
    sig = sys.argv[1]
    disc = sys.argv[2]
    attacker = sys.argv[3] if len(sys.argv) > 3 else b58enc(hashlib.sha256(b"attacker").digest())
    print("attacker:", attacker)
    print("=== control: original signer ===")
    run(sig, disc, False, None, tag="control")
    print("=== attacker signer ===")
    run(sig, disc, True, attacker, tag="attacker")
