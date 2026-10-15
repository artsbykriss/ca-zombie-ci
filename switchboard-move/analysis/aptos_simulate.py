#!/usr/bin/env python3
"""Read-only Aptos transaction simulation helper (public fullnode, no keys).
Simulation is a node-side dry run: nothing is signed or submitted to the chain.
The signature is a dummy; the node does not verify it in simulate mode, but the
auth-key check needs a real on-chain public key, so we borrow one from a recent
public transaction (public data only).
"""
import json, sys, urllib.request, time

URL = "https://fullnode.mainnet.aptoslabs.com/v1/transactions/simulate"
FULLNODE = "https://fullnode.mainnet.aptoslabs.com/v1"
PKG = "0xfea54925b5ac1912331e2e62049849b37842efaea298118b66f85a59057752b8"

def live_sender():
    """Return (sender, public_key, sequence_number) from a recent public tx."""
    with urllib.request.urlopen(FULLNODE + "/transactions?limit=30", timeout=30) as r:
        txs = json.load(r)
    for t in txs:
        sig = t.get("signature")
        if (t.get("type") == "user_transaction" and isinstance(sig, dict)
                and sig.get("type") == "ed25519_signature" and sig.get("public_key")):
            sender = t["sender"]
            with urllib.request.urlopen(FULLNODE + "/accounts/" + sender, timeout=30) as r2:
                acct = json.load(r2)
            return sender, sig["public_key"], acct["sequence_number"]
    raise RuntimeError("no suitable sender found")

def simulate(payload, sender=None, seq=None, pubkey=None, gas="100000", price="100", ttl=600):
    if sender is None:
        sender, pubkey, seq = live_sender()
    body = {
        "sender": sender,
        "sequence_number": str(seq),
        "max_gas_amount": gas,
        "gas_unit_price": price,
        "expiration_timestamp_secs": str(int(time.time()) + ttl),
        "payload": payload,
        "signature": {"type": "ed25519_signature",
                      "public_key": pubkey or ("0x" + "00" * 32),
                      "signature": "0x" + "00" * 64},
    }
    req = urllib.request.Request(URL, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return {"_http_error": e.code, "_body": e.read().decode()[:1000]}

def entry(fn, type_args=None, args=None):
    return {"type": "entry_function_payload", "function": fn,
            "type_arguments": type_args or [], "arguments": args or []}

if __name__ == "__main__":
    mode = sys.argv[1]
    if mode == "raw":
        print(json.dumps(simulate(entry(sys.argv[2], sys.argv[3].split(",") if len(sys.argv) > 3 and sys.argv[3] else [], sys.argv[4:] if len(sys.argv) > 4 else [])), indent=1)[:4000])
