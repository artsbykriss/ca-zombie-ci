#!/usr/bin/env python3
"""Find DEX pairs for Horizon synths (PancakeSwap V2 + others). Output: synth-pairs.json"""
import json
import rpcmulti as R

FACTORIES = {
    "PancakeV2": "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73",
    "ApeSwap": "0x0841BD0B734E4F5853f0dD8d7Ea041c241fb0Da6",
    "BiSwap": "0x858E3312ed3A876947EA49d572A7C42DE08af7EE",
    "MDEX": "0x3CD1C46068dAEa5Ebb0d3f55F6915B10648062B8",
}
QUOTE = {
    "WBNB": "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",
    "BUSD": "0xe9e7cea3dedca5984780bafc599bd69add087d56",
    "USDT": "0x55d398326f99059ff775485246999027b3197955",
    "BTCB": "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c",
    "ETH": "0x2170ed0880ac9a755fd29b2688956bd959f933f8",
    "CAKE": "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82",
}
SEL_GETPAIR = "0xe6a43905"

def main():
    synths = json.load(open("synth-enum.json"))["synths"]
    jobs = []
    meta = []
    for sa, sv in synths.items():
        for qn, qa in QUOTE.items():
            for fn, fa in FACTORIES.items():
                data = SEL_GETPAIR + sa[2:].rjust(64, "0") + qa[2:].rjust(64, "0")
                jobs.append((lambda fa=fa, data=data: R.call(fa, data)))
                meta.append((sv["currencyKey"], sa, qn, fn))
    print("jobs:", len(jobs), flush=True)
    res = R.multi(jobs, workers=10)
    out = []
    for (key, sa, qn, fn), r in zip(meta, res):
        if isinstance(r, str) and r != "0x" + "0" * 64 and len(r) >= 42:
            addr = "0x" + r[-40:]
            if addr != "0x0000000000000000000000000000000000000000":
                out.append({"synth": key, "synth_addr": sa, "quote": qn, "dex": fn, "pair": addr})
                print(f"{key:8s} {qn:6s} {fn:10s} pair={addr}", flush=True)
    json.dump(out, open("synth-pairs.json", "w"), indent=1)

if __name__ == "__main__":
    main()
