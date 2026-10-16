#!/usr/bin/env python3
"""Build fingerprinting: download program code, hash, search Anchor discriminators."""
import json, sys, base64, hashlib
import sol_rpc as S

def code_of(pd_addr):
    a = S.get_account(pd_addr)
    raw = base64.b64decode(a["value"]["data"][0])
    return raw[45:]  # strip ProgramData header

def anchor_disc(name):
    return hashlib.sha256(("global:" + name).encode()).digest()[:8]

def anchor_acc_disc(name):
    return hashlib.sha256(("account:" + name).encode()).digest()[:8]

INSTR_NAMES = [
    "submit_signatures", "add_collateral_admin", "withdraw_collateral_asset",
    "add_admin", "withdraw_collateral", "withdraw", "deposit_collateral",
    "submit_signature", "initialize", "initialize_collateral_account",
    "create_collateral_account", "add_collateral", "withdraw_funds",
    "withdraw_collateral_assets", "set_collateral_admin", "admin_withdraw",
]
ACC_NAMES = [
    "CollateralAccount", "CardAccount", "Collateral", "UserAccount",
    "CardBalance", "Account", "Signatures", "Signature",
]

def fingerprint(code):
    found = {}
    for n in INSTR_NAMES:
        d = anchor_disc(n)
        idx = code.find(d)
        if idx >= 0:
            found.setdefault("ix", {})[n] = idx
    for n in ACC_NAMES:
        d = anchor_acc_disc(n)
        idx = code.find(d)
        if idx >= 0:
            found.setdefault("acc", {})[n] = idx
    return found

if __name__ == "__main__":
    out = {}
    for pd in sys.argv[1:]:
        code = code_of(pd)
        h = hashlib.sha256(code).hexdigest()
        fp = fingerprint(code)
        out[pd] = {"code_size": len(code), "sha256": h, "anchors": fp}
        print(json.dumps({pd: out[pd]}))
    json.dump(out, open("build_fingerprints.json", "w"), indent=1)
