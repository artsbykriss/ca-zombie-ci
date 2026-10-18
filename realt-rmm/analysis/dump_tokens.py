"""Dump the wrapper's full RealToken basket + frozen marks to analysis/wrapper_tokens.json."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gnosis as g  # noqa: E402

WRAPPER = "0x10497611Ee6524D75FC45E3739F472F83e282AD5"


def main():
    block = g.latest_block()
    tl, amts = g.dec(["address[]", "uint256[]"],
                     g.call(WRAPPER, "getAllTokenBalancesOfWrapper()(address[],uint256[])", block=block))
    prices = g.multicall([(WRAPPER, g.sel("getRealTokenPrice(address)") + g.abi_encode(["address"], [t]).hex())
                          for t in tl], block=block)
    toks = []
    for t, a, (ok, ret) in zip(tl, amts, prices):
        p = int.from_bytes(ret[:32], "big") if ok else 0
        toks.append({"address": t.lower(), "amount": str(a), "price_1e8": p,
                     "value_usd": a * p / 1e8 / 1e18})
    toks.sort(key=lambda x: -x["value_usd"])
    out = {"block": block, "timestamp": g.block_ts(block), "count": len(toks),
           "total_value_usd_marks": round(sum(x["value_usd"] for x in toks), 2), "tokens": toks}
    p = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wrapper_tokens.json")
    with open(p, "w") as f:
        json.dump(out, f, indent=2)
    print("wrote", p, "count", out["count"], "value", out["total_value_usd_marks"])


if __name__ == "__main__":
    main()
