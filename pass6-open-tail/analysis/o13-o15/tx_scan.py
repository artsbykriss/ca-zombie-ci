#!/usr/bin/env python3
"""Collect recent signatures + parse transactions to find instruction discriminators in use."""
import json, base64, sys
from collections import Counter
from sol_rpc import get_signatures, get_transaction

PROGS = {"O13":"3vyr9DRfMZb2KvUQdnps7YG3PY38XdguLBQaJ2DFkSxk",
         "O14":"WRAPdXmxrH37RKUbH1QMnYrKdNe8w4Kz44t1cXmYeum",
         "O15":"zod11Jzp72T6qBbGVJfR38y1pGY3dBK8nSuouD4mMkZ"}

IXD = {}
def load_ixd():
    import hashlib
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
    for k,names in IX.items():
        for n in names:
            d = hashlib.sha256(("global:"+n).encode()).digest()[:8].hex()
            IXD[d] = f"{k}:{n}"

def main():
    load_ixd()
    for k,pid in PROGS.items():
        print(f"\n===== {k} {pid} =====")
        sigs = []
        before = None
        for page in range(3):
            r = get_signatures(pid, limit=1000, before=before)
            res = r.get("result") or []
            if not res: break
            sigs.extend(res)
            before = res[-1]["signature"]
            if len(res) < 1000: break
        print(f"  total signatures fetched: {len(sigs)}")
        # sample up to 60 transactions spread across the list
        step = max(1, len(sigs)//60)
        sample = sigs[::step][:60]
        c = Counter()
        signers_seen = Counter()
        examples = {}
        for s in sample:
            try:
                tx = get_transaction(s["signature"])
            except Exception as e:
                continue
            if not tx.get("result"): continue
            msg = tx["result"]["transaction"]["message"]
            accts = msg.get("accountKeys", [])
            for ix in msg.get("instructions", []):
                prog = ix.get("programId")
                if prog != pid: continue
                data = ix.get("data")
                if isinstance(data, str):
                    try:
                        raw = base64.b64decode(data)
                    except Exception:
                        continue
                    d = raw[:8].hex()
                    c[d] += 1
                    if d not in examples:
                        examples[d] = {"sig": s["signature"], "n_accounts": len(ix.get("accounts", [])),
                                       "accounts": ix.get("accounts", []),
                                       "data_len": len(raw)}
                    # record signers
                    for a in accts:
                        if a.get("signer"):
                            signers_seen[a["pubkey"]] += 1
        print(f"  instruction discriminators seen (sampled {len(sample)} txs):")
        for d,cnt in c.most_common():
            print(f"    {d} x{cnt} -> {IXD.get(d,'?UNKNOWN?')}  ex={examples[d]['sig'][:20]} accts={examples[d]['n_accounts']} dlen={examples[d]['data_len']}")
        print(f"  top signers: {signers_seen.most_common(8)}")
        with open(f"tx_scan_{k}.json","w") as f:
            json.dump({"prog":pid,"n_sigs":len(sigs),"discs":dict(c),"examples":examples,
                       "signers":dict(signers_seen)}, f, indent=2)

if __name__=="__main__":
    main()
