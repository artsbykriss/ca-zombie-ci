#!/usr/bin/env python3
"""Minimal Solana legacy-transaction builder + simulate (read-only, keyless).

No signing, no broadcast. simulateTransaction(sigVerify=false,
replaceRecentBlockhash=true).
"""
import base64
import json
import os
import time
import urllib.request

import omni as O

ENDPOINTS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
    "https://solana.drpc.org",
]
if os.environ.get("OMNI_RPC_URL"):
    ENDPOINTS.insert(0, os.environ["OMNI_RPC_URL"])
# neutral, real, funded fee-payer used only as the tx payer in simulation
NEUTRAL_PAYER = "5Q544fKrFoe6tsEbD7S8EmxGTJYAKtTVhAW5Q5pge4j1"


def cu(n):
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            break
    return bytes(out)


def _post(url, body, timeout=90):
    req = urllib.request.Request(url, data=body,
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": "Mozilla/5.0"})
    return urllib.request.urlopen(req, timeout=timeout)


def call(method, params, retries=6):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method,
                       "params": params}).encode()
    last = None
    for i in range(retries):
        url = ENDPOINTS[i % len(ENDPOINTS)]
        try:
            r = json.load(_post(url, body))
            if "error" in r:
                raise RuntimeError(r["error"])
            return r["result"]
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(min(20, 1.2 * (2 ** i)))
    raise last


def build_legacy(payer, writable, readonly, blockhash, instructions,
                 signers=None):
    """instructions: list of (program_id, [account_pubkeys], data_bytes).

    Account keys are collected from the instructions (plus the payer), then
    ordered per the legacy-message layout: writable signers, readonly signers,
    writable non-signers, readonly non-signers.  `writable`/`readonly` are
    treated as membership sets (duplicates are harmless).
    """
    signers = signers or [payer]
    if payer not in signers:
        signers = [payer] + list(signers)
    wset = set(writable)
    rset = set(readonly)

    keys = []
    for k in signers:
        if k not in keys:
            keys.append(k)
    for pid, accts, _ in instructions:
        for k in [pid] + list(accts):
            if k not in keys:
                keys.append(k)

    def is_signer(k):
        return k in signers

    def is_writable(k):
        if k in rset:
            return False
        return k in wset or k in signers

    signer_w = [k for k in keys if is_signer(k) and is_writable(k)]
    signer_ro = [k for k in keys if is_signer(k) and not is_writable(k)]
    ns_w = [k for k in keys if not is_signer(k) and is_writable(k)]
    ns_ro = [k for k in keys if not is_signer(k) and not is_writable(k)]
    keys = signer_w + signer_ro + ns_w + ns_ro
    idx = {k: i for i, k in enumerate(keys)}
    nreq = len(signers)
    nro_signed = len(signer_ro)
    nro_unsigned = len(ns_ro)
    msg = bytearray()
    msg += bytes([nreq, nro_signed, nro_unsigned])
    msg += cu(len(keys))
    for k in keys:
        msg += O.b58dec(k)
    msg += O.b58dec(blockhash)
    msg += cu(len(instructions))
    for pid, accts, data in instructions:
        msg += bytes([idx[pid]])
        msg += cu(len(accts))
        for a in accts:
            msg += bytes([idx[a]])
        msg += cu(len(data))
        msg += data
    sigs = b"".join(b"\x00" * 64 for _ in signers)
    return base64.b64encode(cu(len(signers)) + sigs + bytes(msg)).decode()


def simulate(tx_b64, commitment="confirmed", extra=None):
    cfg = {"encoding": "base64", "sigVerify": False,
           "replaceRecentBlockhash": True, "commitment": commitment}
    if extra:
        cfg.update(extra)
    return call("simulateTransaction", [tx_b64, cfg])


def blockhash():
    return call("getLatestBlockhash", [{"commitment": "confirmed"}])["value"]["blockhash"]


if __name__ == "__main__":
    print("blockhash", blockhash())
