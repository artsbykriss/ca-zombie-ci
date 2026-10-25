#!/usr/bin/env python3
"""Compute Anchor discriminators for candidate instructions + enumerate program accounts."""
import hashlib, json
from sol_rpc import get_program_accounts

def disc(name):
    return hashlib.sha256(("global:" + name).encode()).digest()[:8].hex()

IX = {
 "O13": ["initialize","initialize_deposit","refund_deposit","deposit","initialize_withdrawal",
         "refund_withdrawal","withdraw","rebalance","update_oracle","update_weights","update_fee",
         "update_manager","get_vault_balances"],
 "O14": ["init_global_config","update_global_config","deposit_kvault","withdraw_kvault",
         "create_klend_wrapper","deposit_klend","withdraw_klend","create_save_wrapper","deposit_save",
         "withdraw_save","create_lulo_protected_wrapper","deposit_lulo_protected","withdraw_lulo_protected",
         "create_marginfi_wrapper","deposit_marginfi","withdraw_marginfi","claim_creator_fees",
         "update_creator_fee","claim_protocol_fees"],
}

PROGS = {"O13":"3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk",
         "O14":"WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum",
         "O15":"zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ"}

print("=== DISCRIMINATORS ===")
for k, names in IX.items():
    for n in names:
        print(f"{k} {n:34s} {disc(n)}")

print("\n=== ACCOUNT ENUMERATION (dataSize histogram) ===")
for k, pid in PROGS.items():
    r = get_program_accounts(pid, encoding="base64", dataSlice={"offset":0,"length":0})
    res = r.get("result")
    if res is None:
        print(k, "ERR", json.dumps(r)[:200]); continue
    from collections import Counter
    sizes = Counter()
    samples = {}
    for acc in res:
        d = acc["account"]
        L = d["space"] if "space" in d else None
        if L is None:
            L = len(d["data"]) if isinstance(d["data"], str) else 0
        sizes[L] += 1
    print(f"{k} {pid}: {len(res)} accounts")
    for L,c in sizes.most_common(20):
        print(f"    dataSize={L:6d} count={c}")
