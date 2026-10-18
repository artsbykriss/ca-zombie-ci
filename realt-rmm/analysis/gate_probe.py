"""RU03 compliance-gate re-verification at the live block.

Primary probe: Processor.canTransfer(from=wrapper, to=dest, amount) called with eth_call
`from = token` (the Processor resolves rules via msg.sender == the RealToken; a Multicall
wrapper would set msg.sender = Multicall3 and revert, so these are individual eth_calls,
batched at the JSON-RPC level).

Secondary probe: RealToken.transfer(dest, amount) with eth_call `from = wrapper` (the token
holder) -- the exact transfer performed by liquidationCall(receiveMethod=1) and withdraw.

Also: wallet-style withdraw(to=Safe) vs withdraw(to=fresh) for the incumbent Safe, and
aRTW.transfer from a whitelisted holder.

Writes analysis/gate_probe.json.
"""
import json
import os
import random
import sys
import time

from eth_abi import encode as abi_encode

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gnosis as g  # noqa: E402

WRAPPER = "0x10497611Ee6524D75FC45E3739F472F83e282AD5"
PROCESSOR = "0x3221a28eD2b2e955DA64d1d299956f277562C95c"
ARTW = "0xF3220Cd8F66AEB86fC2A82502977EAb4BFd2f647"
SAFE = "0x4F7765c9feBc51cD63F68f573920c0B7bF803151"
VICTIM = "0x529f288298fe949c9c5c3323554c782db5021ed0"
EXIT = "0x134d928B26DB2Da678F16974580B22E799293E6c"
OWNER1 = "0xCa543f90a221dac783490BfeE4a1173AE07547c2"
DC0604 = "0xDc0604B378adCa99a9e2096707aD4830673CE5B8"
FRESH = "0x1111111111111111111111111111111111111111"
FRESH2 = "0x000000000000000000000000000000000000bEEF"
FRESH3 = "0x9b6c1a6c1b7f4b0b1c5e2d3a4f6e8d0c2b4a6f8e"

DESTS = {"fresh_1111": FRESH, "fresh_beef": FRESH2, "fresh_random": FRESH3,
         "incumbent_safe": SAFE, "exit_wallet": EXIT, "owner1": OWNER1,
         "victim_529f": VICTIM, "buyer_dc0604": DC0604}


def main():
    block = g.latest_block()
    ts = g.block_ts(block)
    wt = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "wrapper_tokens.json")))
    toks = [t["address"] for t in wt["tokens"]]
    sample = toks[:30]
    rng = random.Random(7)
    sample += rng.sample(toks[30:], 10)
    sample = list(dict.fromkeys(sample))
    print("block", block, "tokens sampled", len(sample), flush=True)

    probes = []
    for n, t in enumerate(sample):
        calls = [(PROCESSOR, g.sel("canTransfer(address,address,uint256)") +
                  abi_encode(["address", "address", "uint256"],
                             [WRAPPER.lower(), d.lower(), 10 ** 18]).hex())
                 for d in DESTS.values()]
        try:
            res = g.rpc_batch([("eth_call", [{"to": c[0], "from": t, "data": c[1]}, hex(block)])
                               for c in calls])
        except Exception as e:  # noqa: BLE001
            print("batch failed token", t, str(e)[:100], flush=True)
            time.sleep(1)
            res = [None] * len(calls)
        for (label, d), r in zip(DESTS.items(), res):
            rec = {"token": t, "dest_label": label, "dest": d}
            if isinstance(r, str) and len(r) >= 194:
                v = g.abi_decode(["bool", "uint256", "uint256"], bytes.fromhex(r[2:]))
                rec.update({"allowed": v[0], "rule_id": v[1], "reason": v[2]})
            else:
                rec["error"] = "call failed"
            probes.append(rec)
        if n % 10 == 9:
            print("  probed", n + 1, "tokens", flush=True)

    stats = {}
    for label in DESTS:
        rows = [p for p in probes if p["dest_label"] == label]
        stats[label] = {
            "probes": len(rows),
            "allowed": sum(1 for p in rows if p.get("allowed") is True),
            "denied": sum(1 for p in rows if p.get("allowed") is False),
            "errors": sum(1 for p in rows if "error" in p),
            "denied_rule_ids": sorted({p.get("rule_id") for p in rows if p.get("allowed") is False}),
        }

    # --- direct transfer probes on a subset (captures the literal RU03 revert) ---
    transfer = []
    for t in sample[:8]:
        for label, d in DESTS.items():
            try:
                g.eth_call(t, g.sel("transfer(address,uint256)") +
                           abi_encode(["address", "uint256"], [d.lower(), 10 ** 18]).hex(),
                           block=block, frm=WRAPPER)
                transfer.append({"token": t, "dest_label": label, "result": "OK"})
            except Exception as e:  # noqa: BLE001
                s = str(e)
                transfer.append({"token": t, "dest_label": label,
                                 "result": "RU03" if "RU03" in s else "REVERT",
                                 "revert": s[:160]})
    tstats = {}
    for label in DESTS:
        rows = [p for p in transfer if p["dest_label"] == label]
        tstats[label] = {"OK": sum(1 for p in rows if p["result"] == "OK"),
                         "RU03": sum(1 for p in rows if p["result"] == "RU03"),
                         "other_revert": sum(1 for p in rows if p["result"] == "REVERT")}

    # --- wallet-style withdraw: Safe -> Safe vs Safe -> fresh ---
    withdraw = {}
    tok = "0x964ee9e5d9d8abfc768f8d860cc6c33e75d37112"  # Safe ledger position (dust)
    amt = 10 ** 9
    for label, to in [("to_safe", SAFE), ("to_fresh", FRESH)]:
        try:
            g.eth_call(WRAPPER, g.sel("withdraw(address,uint256,address)") +
                       abi_encode(["address", "uint256", "address"], [tok.lower(), amt, to.lower()]).hex(),
                       block=block, frm=SAFE)
            withdraw[label] = "OK"
        except Exception as e:  # noqa: BLE001
            s = str(e)
            withdraw[label] = ("RU03" if "RU03" in s else "REVERT") + " :: " + s[:220]

    # --- aRTW transferability from a whitelisted holder ---
    artw = {}
    for label, frm in [("victim_529f", VICTIM), ("incumbent_safe", SAFE)]:
        try:
            g.eth_call(ARTW, g.sel("transfer(address,uint256)") +
                       abi_encode(["address", "uint256"], [FRESH.lower(), 1]).hex(),
                       block=block, frm=frm)
            artw[label] = "OK"
        except Exception as e:  # noqa: BLE001
            artw[label] = str(e)[:240]

    out = {"chain": "gnosis", "chain_id": 100, "block": block, "timestamp": ts,
           "wrapper": WRAPPER, "processor": PROCESSOR, "tokens_sampled": len(sample),
           "destinations": DESTS, "canTransfer_stats": stats, "canTransfer_probes": probes,
           "transfer_stats": tstats, "transfer_probes": transfer,
           "safe_withdraw": withdraw, "artw_transfer": artw}
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "gate_probe.json")
    with open(p, "w") as f:
        json.dump(out, f, indent=2)
    print("wrote", p)
    for k, v in stats.items():
        print(k, v)
    print("transfers", tstats)
    print("safe withdraw", withdraw)
    print("artw transfer", artw)


if __name__ == "__main__":
    main()
