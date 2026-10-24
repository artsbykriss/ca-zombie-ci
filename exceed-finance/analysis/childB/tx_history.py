#!/usr/bin/env python3
import json, sys, base64, time
sys.path.insert(0, "/home/heisenberg/CA/exceed-finance/analysis/childB")
from rpc import call
from solders.transaction import VersionedTransaction

PROGRAM = "par1tyqusak2f2DXg9RHv78SVHNWXkJLSbtJZQSuWjV"
imap = json.load(open("/home/heisenberg/CA/exceed-finance/analysis/childB/ix-disc.json"))

sigs = call("getSignaturesForAddress", [PROGRAM, {"limit": 60}])["result"]
print("fetched", len(sigs), "signatures")
rows = []
counts = {}
signers_seen = {}
for s in sigs:
    if s.get("err"):
        continue
    r = call("getTransaction", [s["signature"], {"encoding": "base64", "maxSupportedTransactionVersion": 0}])
    tx = r.get("result")
    if not tx:
        continue
    slot = tx["slot"]
    raw = base64.b64decode(tx["transaction"][0])
    vtx = VersionedTransaction.from_bytes(raw)
    msg = vtx.message
    keys = [str(k) for k in msg.account_keys]
    num_signed = msg.header.num_required_signatures
    signers = keys[:num_signed]
    for ix in msg.instructions:
        pid = keys[ix.program_id_index]
        if pid != PROGRAM:
            continue
        data = bytes(ix.data)
        d = data[:8].hex()
        name = imap.get(d, f"UNKNOWN({d})")
        counts[name] = counts.get(name, 0) + 1
        # first account = usually the authority/pair
        acct0 = keys[ix.accounts[0]] if ix.accounts else None
        rows.append(dict(sig=s["signature"], slot=slot, ix=name, disc=d,
                         n_accounts=len(ix.accounts), data_len=len(data),
                         signers=signers, first_acct=acct0, keys=keys[:8]))
    time.sleep(0.12)

print("\n=== instruction mix (successful txs) ===")
for k, v in sorted(counts.items(), key=lambda x: -x[1]):
    print(f"  {k:32s} {v}")
print("\n=== sample rows ===")
for r in rows[:60]:
    print(f"  slot={r['slot']} {r['ix']:26s} n={r['n_accounts']:2d} dl={r['data_len']:3d} signers={r['signers'][:2]}")
json.dump(rows, open("/home/heisenberg/CA/exceed-finance/analysis/childB/tx-mix.json","w"), indent=2)
