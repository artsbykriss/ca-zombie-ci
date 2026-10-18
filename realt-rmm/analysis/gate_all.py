"""Exhaustive RU03 gate census across ALL 623 RealTokens in the wrapper basket.

For each token: Processor.canTransfer(from=wrapper, to=dest, 1 wei-equivalent) with
eth_call `from = token` (so the Processor reads that token's rule set).
Destinations: fresh EOA 0x1111... (not whitelisted) and the incumbent Safe (whitelisted).

Any token that allows the fresh EOA would be a genuine bypass (seizable + receivable).
Writes analysis/gate_all.json.
"""
import json
import os
import sys

from eth_abi import encode as abi_encode

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gnosis as g  # noqa: E402

WRAPPER = "0x10497611Ee6524D75FC45E3739F472F83e282AD5"
PROCESSOR = "0x3221a28eD2b2e955DA64d1d299956f277562C95c"
FRESH = "0x1111111111111111111111111111111111111111"
FRESH2 = "0x000000000000000000000000000000000000bEEF"
SAFE = "0x4F7765c9feBc51cD63F68f573920c0B7bF803151"
VICTIM = "0x529f288298fe949c9c5c3323554c782db5021ed0"
DESTS = {"fresh_1111": FRESH, "fresh_beef": FRESH2, "incumbent_safe": SAFE, "victim_529f": VICTIM}


def main():
    block = g.latest_block()
    ts = g.block_ts(block)
    wt = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "wrapper_tokens.json")))
    toks = [t["address"] for t in wt["tokens"]]
    print("block", block, "tokens", len(toks), flush=True)

    rows = []
    for n, t in enumerate(toks):
        calls = [(PROCESSOR, g.sel("canTransfer(address,address,uint256)") +
                  abi_encode(["address", "address", "uint256"], [WRAPPER.lower(), d.lower(), 10 ** 18]).hex())
                 for d in DESTS.values()]
        try:
            res = g.rpc_batch([("eth_call", [{"to": c[0], "from": t, "data": c[1]}, hex(block)])
                               for c in calls], chunk=50)
        except Exception as e:  # noqa: BLE001
            print("batch error token", t, str(e)[:120], flush=True)
            res = [None] * len(calls)
        for (label, d), r in zip(DESTS.items(), res):
            rec = {"token": t, "dest_label": label, "dest": d}
            if isinstance(r, str) and len(r) >= 194:
                v = g.abi_decode(["bool", "uint256", "uint256"], bytes.fromhex(r[2:]))
                rec.update({"allowed": v[0], "rule_id": v[1], "reason": v[2]})
            else:
                rec["error"] = True
            rows.append(rec)
        if n % 100 == 99:
            print(" ", n + 1, "tokens", flush=True)

    summary = {}
    for label in DESTS:
        rr = [x for x in rows if x["dest_label"] == label]
        summary[label] = {
            "probes": len(rr),
            "allowed": sum(1 for x in rr if x.get("allowed") is True),
            "denied": sum(1 for x in rr if x.get("allowed") is False),
            "errors": sum(1 for x in rr if x.get("error")),
            "denied_rule_ids": sorted({x["rule_id"] for x in rr if x.get("allowed") is False}),
        }
    allowed_fresh = [x for x in rows if x["dest_label"].startswith("fresh") and x.get("allowed") is True]
    denied_safe = [x for x in rows if x["dest_label"] == "incumbent_safe" and x.get("allowed") is False]

    out = {"chain": "gnosis", "block": block, "timestamp": ts, "tokens": len(toks),
           "summary": summary,
           "bypass_fresh_allowed": allowed_fresh,
           "safe_denied": denied_safe,
           "rows": rows}
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "gate_all.json")
    json.dump(out, open(p, "w"), indent=2)
    print("wrote", p)
    print(json.dumps(summary, indent=1))
    print("fresh-allowed bypasses:", len(allowed_fresh), allowed_fresh[:5])
    print("safe-denied tokens:", len(denied_safe))


if __name__ == "__main__":
    main()
