#!/usr/bin/env python3
import json, sys, base64
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call
from solders.transaction import VersionedTransaction

PROGRAM = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV"
imap = json.load(open("/home/heisenberg/CA/exceed-finance/analysis/childB/ix-disc.json"))
rev = {v: k for k, v in imap.items()}

def dump(sig):
    r = call("getTransaction", [sig, {"encoding": "base64", "maxSupportedTransactionVersion": 0}])["result"]
    vtx = VersionedTransaction.from_bytes(base64.b64decode(r["transaction"][0]))
    msg = vtx.message
    keys = [str(k) for k in msg.account_keys]
    print(f"\n### {sig} slot={r['slot']}")
    for i, ix in enumerate(msg.instructions):
        pid = keys[ix.program_id_index]
        d = bytes(ix.data)[:8].hex()
        name = imap.get(d, f"UNKNOWN({d})")
        print(f"  ix[{i}] program={pid} name={name} datalen={len(bytes(ix.data))} data={bytes(ix.data).hex()}")
        if pid == PROGRAM:
            for j, a in enumerate(ix.accounts):
                print(f"      acct[{j}] {keys[a]}")
    print("  signers:", keys[:msg.header.num_required_signatures])

# from tx-mix.json find stake / swap_lst sigs
rows = json.load(open("/home/heisenberg/CA/exceed-finance/analysis/childB/tx-mix.json"))
seen = set()
for row in rows:
    if row["ix"] in ("stake", "swap_lst", "request_withdraw", "execute_withdraw") and row["ix"] not in seen:
        seen.add(row["ix"])
        dump(row["sig"])
